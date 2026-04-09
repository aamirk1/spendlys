import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:spendly/res/app_constants.dart';
import 'package:spendly/core/services/local_cache_service.dart';
import 'package:spendly/core/services/connectivity_service.dart';
import 'package:spendly/no_internet_screen.dart';

class ApiService {
  static final String _baseUrl = AppConstants.baseUrl;

  static ConnectivityService get _conn => Get.find<ConnectivityService>();

  /// صرف اس وقت NoInternetScreen دکھائیں جب API call ہو اور internet نہ ہو
  static void _showNoInternetScreen() {
    // اگر پہلے سے NoInternetScreen open ہے تو دوبارہ نہ کھولیں
    if (Get.currentRoute == '/no-internet') return;
    Get.to(
      () => const NoInternetScreen(),
      routeName: '/no-internet',
      transition: Transition.fade,
      duration: const Duration(milliseconds: 300),
    );
  }

  static Future<http.Response> get(String endpoint, {Map<String, String>? headers, bool useCache = true}) async {
    final cacheKey = 'GET_$endpoint';

    // Offline check
    if (!_conn.isOnline.value) {
      if (useCache) {
        final cachedData = LocalCacheService.getCache(cacheKey);
        if (cachedData != null) {
          // Cache ملا — silently serve کریں، screen نہ دکھائیں
          return http.Response(jsonEncode(cachedData), 200);
        }
      }
      // Cache نہیں، internet نہیں — NoInternetScreen دکھائیں
      _showNoInternetScreen();
      return http.Response('{"error": "Offline", "message": "Check your internet connection"}', 503);
    }

    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      final resp = await http.get(url, headers: headers);
      _logResponse(endpoint, resp);

      if (resp.statusCode == 200 && useCache) {
        await LocalCacheService.setCache(cacheKey, jsonDecode(resp.body));
      }
      return resp;
    } catch (e) {
      // Network error — cache سے serve کریں اگر ملے
      if (useCache) {
        final cachedData = LocalCacheService.getCache(cacheKey);
        if (cachedData != null) return http.Response(jsonEncode(cachedData), 200);
      }
      // Cache بھی نہیں — screen دکھائیں
      _showNoInternetScreen();
      rethrow;
    }
  }

  static Future<http.Response> post(String endpoint, {Map<String, String>? headers, dynamic body, bool bypassCache = false}) async {
    if (!_conn.isOnline.value && !bypassCache) {
      // 1. Optimistic Update: If it's a known resource type, append it to its GET list in cache
      // Example: POST /transactions -> try to update GET_transactions
      final baseResource = endpoint.split('/')[1]; // very basic heuristic
      final listCacheKey = 'GET_/$baseResource';
      
      final cachedList = LocalCacheService.getCache(listCacheKey);
      if (cachedList is List) {
        final newList = List.from(cachedList);
        newList.insert(0, {
          ...body,
          'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
          'status': 'syncing'
        });
        await LocalCacheService.setCache(listCacheKey, newList);
      }

      // 2. Queue it for sync
      await LocalCacheService.addPendingRequest(
        endpoint: endpoint,
        method: 'POST',
        headers: headers,
        body: body,
      );
      
      return http.Response('{"message": "Offline: Data queued for sync", "status": "pending_sync"}', 202);
    }

    final url = Uri.parse('$_baseUrl$endpoint');
    final resp = await http.post(
      url,
      headers: headers ?? {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    _logResponse(endpoint, resp);
    return resp;
  }

  static Future<http.Response> put(String endpoint, {Map<String, String>? headers, dynamic body, bool bypassCache = false}) async {
    if (!_conn.isOnline.value && !bypassCache) {
      await LocalCacheService.addPendingRequest(
        endpoint: endpoint,
        method: 'PUT',
        headers: headers,
        body: body,
      );
      return http.Response('{"message": "Offline: Data queued for sync", "status": "pending_sync"}', 202);
    }

    final url = Uri.parse('$_baseUrl$endpoint');
    final resp = await http.put(
      url,
      headers: headers ?? {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    _logResponse(endpoint, resp);
    return resp;
  }

  static Future<http.Response> delete(String endpoint, {Map<String, String>? headers, bool bypassCache = false}) async {
    if (!_conn.isOnline.value && !bypassCache) {
      await LocalCacheService.addPendingRequest(
        endpoint: endpoint,
        method: 'DELETE',
        headers: headers,
      );
      return http.Response('{"message": "Offline: Item scheduled for deletion", "status": "pending_sync"}', 202);
    }

    final url = Uri.parse('$_baseUrl$endpoint');
    final resp = await http.delete(url, headers: headers);
    _logResponse(endpoint, resp);
    return resp;
  }

  static void _logResponse(String endpoint, http.Response response) {
    if (response.statusCode >= 400) {
      print("API ERROR [$endpoint] Status: ${response.statusCode} Body: ${response.body}");
    }
  }
}

