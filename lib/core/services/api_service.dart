import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:spendly/core/storage/secure_storage_service.dart';
import 'package:spendly/res/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendly/core/services/local_cache_service.dart';
import 'package:spendly/core/services/connectivity_service.dart';
import 'package:spendly/no_internet_screen.dart';
import 'package:spendly/core/network/api_constants.dart';

class ApiService {
  static final String _baseUrl = AppConstants.baseUrl;

  static ConnectivityService get _conn => Get.find<ConnectivityService>();

  /// Builds headers with Authorization token if available.
  static Future<Map<String, String>> _authHeaders(
      [Map<String, String>? extra]) async {
    final token = await Get.find<SecureStorageService>().getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?extra,
    };
  }

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

  static Future<http.Response> get(String endpoint,
      {Map<String, String>? headers, bool useCache = true}) async {
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
      return http.Response(
          '{"error": "Offline", "message": "Check your internet connection"}',
          503);
    }

    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      final mergedHeaders = await _authHeaders(headers);
      var resp = await http.get(url, headers: mergedHeaders);
      _logResponse(endpoint, resp);

      if (resp.statusCode == 401) {
        if (await _handle401()) {
          resp = await _retryRequest('GET', endpoint, headers: headers);
          _logResponse(endpoint, resp);
        }
      }

      if (resp.statusCode == 200 && useCache) {
        await LocalCacheService.setCache(cacheKey, jsonDecode(resp.body));
      }
      return resp;
    } catch (e) {
      // Network error — cache سے serve کریں اگر ملے
      if (useCache) {
        final cachedData = LocalCacheService.getCache(cacheKey);
        if (cachedData != null) {
          return http.Response(jsonEncode(cachedData), 200);
        }
      }
      // Cache بھی نہیں — screen دکھائیں
      _showNoInternetScreen();
      rethrow;
    }
  }

  static Future<http.Response> post(String endpoint,
      {Map<String, String>? headers,
      dynamic body,
      bool bypassCache = false}) async {
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

      return http.Response(
          '{"message": "Offline: Data queued for sync", "status": "pending_sync"}',
          202);
    }

    final url = Uri.parse('$_baseUrl$endpoint');
    final mergedHeaders = await _authHeaders(headers);
    var resp = await http.post(
      url,
      headers: mergedHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
    _logResponse(endpoint, resp);

    if (resp.statusCode == 401) {
      if (await _handle401()) {
        resp =
            await _retryRequest('POST', endpoint, headers: headers, body: body);
        _logResponse(endpoint, resp);
      }
    }

    return resp;
  }

  static Future<http.StreamedResponse> postMultipart(
      String endpoint, File file, String fieldName,
      {Map<String, String>? headers}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final request = http.MultipartRequest('POST', url);

    final mergedHeaders = await _authHeaders(headers);
    mergedHeaders.remove('Content-Type'); // Allow http to set multipart/form-data
    request.headers.addAll(mergedHeaders);

    request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

    final resp = await request.send();
    return resp;
  }

  static Future<http.Response> put(String endpoint,
      {Map<String, String>? headers,
      dynamic body,
      bool bypassCache = false}) async {
    if (!_conn.isOnline.value && !bypassCache) {
      await LocalCacheService.addPendingRequest(
        endpoint: endpoint,
        method: 'PUT',
        headers: headers,
        body: body,
      );
      return http.Response(
          '{"message": "Offline: Data queued for sync", "status": "pending_sync"}',
          202);
    }

    final url = Uri.parse('$_baseUrl$endpoint');
    final mergedHeaders = await _authHeaders(headers);
    var resp = await http.put(
      url,
      headers: mergedHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
    _logResponse(endpoint, resp);

    if (resp.statusCode == 401) {
      if (await _handle401()) {
        resp =
            await _retryRequest('PUT', endpoint, headers: headers, body: body);
        _logResponse(endpoint, resp);
      }
    }

    return resp;
  }

  static Future<http.Response> patch(String endpoint,
      {Map<String, String>? headers,
      dynamic body,
      bool bypassCache = false}) async {
    if (!_conn.isOnline.value && !bypassCache) {
      await LocalCacheService.addPendingRequest(
        endpoint: endpoint,
        method: 'PATCH',
        headers: headers,
        body: body,
      );
      return http.Response(
          '{"message": "Offline: Data queued for sync", "status": "pending_sync"}',
          202);
    }

    final url = Uri.parse('$_baseUrl$endpoint');
    final mergedHeaders = await _authHeaders(headers);
    var resp = await http.patch(
      url,
      headers: mergedHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
    _logResponse(endpoint, resp);

    if (resp.statusCode == 401) {
      if (await _handle401()) {
        resp =
            await _retryRequest('PATCH', endpoint, headers: headers, body: body);
        _logResponse(endpoint, resp);
      }
    }

    return resp;
  }

  static Future<http.Response> delete(String endpoint,
      {Map<String, String>? headers, bool bypassCache = false}) async {
    if (!_conn.isOnline.value && !bypassCache) {
      await LocalCacheService.addPendingRequest(
        endpoint: endpoint,
        method: 'DELETE',
        headers: headers,
      );
      return http.Response(
          '{"message": "Offline: Item scheduled for deletion", "status": "pending_sync"}',
          202);
    }

    final url = Uri.parse('$_baseUrl$endpoint');
    final mergedHeaders = await _authHeaders(headers);
    var resp = await http.delete(url, headers: mergedHeaders);
    _logResponse(endpoint, resp);

    if (resp.statusCode == 401) {
      if (await _handle401()) {
        resp = await _retryRequest('DELETE', endpoint, headers: headers);
        _logResponse(endpoint, resp);
      }
    }

    return resp;
  }

  static void _logResponse(String endpoint, http.Response response) {
    if (response.statusCode >= 400) {
      print(
          "API ERROR [$endpoint] Status: ${response.statusCode} Body: ${response.body}");
    }
  }

  /// Attempts to re-authenticate if 401 occurs
  static Future<bool> _handle401() async {
    try {
      final secureStorage = Get.find<SecureStorageService>();
      final credentials = await secureStorage.getCredentials();
      final email = credentials['email'];
      final password = credentials['password'];

      // 1. Try with stored Email/Password
      if (email != null &&
          password != null &&
          email.isNotEmpty &&
          password.isNotEmpty) {
        final loginResp = await http.post(
          Uri.parse('$_baseUrl${ApiConstants.login}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        );

        if (loginResp.statusCode == 200 || loginResp.statusCode == 201) {
          final data = jsonDecode(loginResp.body);
          final newToken = data['access_token'];
          if (newToken != null) {
            await secureStorage.saveToken(newToken);
            return true;
          }
        }
      }

      // 2. Try with Firebase User (Phone Auth or Email Auth)
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // Prepare sync data
        final syncBody = {
          "id": firebaseUser.uid,
          "phone_number": firebaseUser.phoneNumber,
          "email": firebaseUser.email ??
              "${firebaseUser.phoneNumber}@dailybachat.com",
          "name": firebaseUser.displayName ?? "User",
          "password": password ??
              "user.password", // fallback to common or stored password
        };

        final syncResp = await http.post(
          Uri.parse('$_baseUrl${ApiConstants.syncUser}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(syncBody),
        );

        if (syncResp.statusCode == 200 || syncResp.statusCode == 201) {
          final data = jsonDecode(syncResp.body);
          final newToken = data['access_token'];
          if (newToken != null) {
            await secureStorage.saveToken(newToken);
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      print("Auto re-auth failed: $e");
      return false;
    }
  }

  static Future<http.Response> _retryRequest(String method, String endpoint,
      {Map<String, String>? headers, dynamic body}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final mergedHeaders = await _authHeaders(headers);

    switch (method) {
      case 'GET':
        return await http.get(url, headers: mergedHeaders);
      case 'POST':
        return await http.post(url,
            headers: mergedHeaders,
            body: body != null ? jsonEncode(body) : null);
      case 'PUT':
        return await http.put(url,
            headers: mergedHeaders,
            body: body != null ? jsonEncode(body) : null);
      case 'PATCH':
        return await http.patch(url,
            headers: mergedHeaders,
            body: body != null ? jsonEncode(body) : null);
      case 'DELETE':
        return await http.delete(url, headers: mergedHeaders);
      default:
        throw Exception("Unsupported method $method");
    }
  }
}
