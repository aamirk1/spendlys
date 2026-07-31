import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:spendly/app/data/services/secure_storage_service.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';
import 'package:spendly/app/routes/app_pages.dart';
import 'package:spendly/app/utils/utils.dart';

import 'package:spendly/app/data/services/api_constants.dart';

class ApiClient {
  late Dio _dio;
  final String baseUrl;
  final SecureStorageService _secureStorage;

  ApiClient(
      {required this.baseUrl, required SecureStorageService secureStorage})
      : _secureStorage = secureStorage {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupSSLPinning();

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final path = options.path;
        final publicEndpoints = {
          ApiConstants.login,
          ApiConstants.syncUser,
          ApiConstants.registerRequest,
          ApiConstants.registerVerify,
          ApiConstants.sendOtp,
          ApiConstants.verifyOtp,
          ApiConstants.forgotPasswordRequest,
          ApiConstants.forgotPasswordReset,
          ApiConstants.appConfig,
        };

        final isPublic =
            publicEndpoints.any((endpoint) => path.endsWith(endpoint));
        if (!isPublic) {
          final token = await _secureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        final path = e.requestOptions.path;
        final publicEndpoints = {
          ApiConstants.login,
          ApiConstants.syncUser,
          ApiConstants.registerRequest,
          ApiConstants.registerVerify,
          ApiConstants.sendOtp,
          ApiConstants.verifyOtp,
          ApiConstants.forgotPasswordRequest,
          ApiConstants.forgotPasswordReset,
          ApiConstants.appConfig,
        };

        final isPublic =
            publicEndpoints.any((endpoint) => path.endsWith(endpoint));

        if (!isPublic &&
            (e.response?.statusCode == 401 ||
                (e.response?.data is Map &&
                    e.response?.data['detail'] ==
                        'Could not validate credentials'))) {
          // Auto logout logic
          final box = GetStorage();
          await box.write("isLoggedIn", false);
          await _secureStorage.deleteToken();

          // Redirect to login
          Get.offAllNamed(RoutesName.loginView);

          Utils.showSnackbar("Session Expired", "Please login again",
              isError: true);
        }
        return handler.next(e);
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      rethrow;
    }
  }

  void _setupSSLPinning() {
    if (kIsWeb) return;
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient(
          context: SecurityContext(withTrustedRoots: true),
        );
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) {
          if (host == 'dailybachatapi.serwex.in' ||
              host.endsWith('.serwex.in')) {
            final certFingerprint =
                sha256.convert(cert.der).toString().toUpperCase();
            final isPinned =
                ApiConstants.allowedSSLPins.contains(certFingerprint);
            if (!isPinned) {
              debugPrint(
                  'SSL Pinning failed for $host. Fingerprint mismatch: $certFingerprint');
            }
            return isPinned;
          }
          return false;
        };
        return client;
      },
      validateCertificate: (cert, host, port) {
        if (cert == null) return false;
        if (host == 'dailybachatapi.serwex.in' ||
            host.endsWith('.serwex.in')) {
          final certFingerprint =
              sha256.convert(cert.der).toString().toUpperCase();
          final isPinned =
              ApiConstants.allowedSSLPins.contains(certFingerprint);
          if (!isPinned) {
            debugPrint(
                'SSL Pinning validateCertificate failed for $host: $certFingerprint');
          }
          return isPinned;
        }
        return true;
      },
    );
  }
}
