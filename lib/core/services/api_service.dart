import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spendly/res/app_constants.dart';

class ApiService {
  static final String _baseUrl = AppConstants.baseUrl;

  static Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final resp = await http.get(url, headers: headers);
    _logResponse(endpoint, resp);
    return resp;
  }

  static Future<http.Response> post(String endpoint, {Map<String, String>? headers, dynamic body}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final resp = await http.post(
      url,
      headers: headers ?? {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    _logResponse(endpoint, resp);
    return resp;
  }

  static Future<http.Response> put(String endpoint, {Map<String, String>? headers, dynamic body}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final resp = await http.put(
      url,
      headers: headers ?? {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    _logResponse(endpoint, resp);
    return resp;
  }

  static Future<http.Response> delete(String endpoint, {Map<String, String>? headers}) async {
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
