import 'package:dio/dio.dart';
import 'package:spendly/core/storage/secure_storage_service.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/utils/utils.dart';

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
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final path = options.path;
        final isPublicAuth = path.contains('/auth/login') ||
            path.contains('/auth/register') ||
            path.contains('/auth/otp') ||
            path.contains('/auth/forgot-password');

        if (!isPublicAuth) {
          final token = await _secureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        final path = e.requestOptions.path;
        final isAuthRequest = path.contains('/auth/login') ||
            path.contains('/auth/register') ||
            path.contains('/auth/otp') ||
            path.contains('/auth/forgot-password');

        if (!isAuthRequest &&
            (e.response?.statusCode == 401 ||
                (e.response?.data is Map &&
                    e.response?.data['detail'] ==
                        'Could not validate credentials'))) {
          // Auto logout logic only for authenticated session expiration
          final box = GetStorage();
          final bool wasLoggedIn = box.read("isLoggedIn") ?? false;
          await box.write("isLoggedIn", false);
          await _secureStorage.deleteToken();

          // Only redirect if user was logged in and not already on login page
          if (wasLoggedIn && Get.currentRoute != RoutesName.loginView) {
            Get.offAllNamed(RoutesName.loginView);
            Utils.showSnackbar("Session Expired", "Please login again",
                isError: true);
          }
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
      {Map<String, dynamic>? queryParameters,
      Duration timeout = const Duration(seconds: 20)}) async {
    try {
      return await _dio
          .get(path, queryParameters: queryParameters)
          .timeout(timeout);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String path,
      {dynamic data, Duration timeout = const Duration(seconds: 20)}) async {
    try {
      return await _dio.post(path, data: data).timeout(timeout);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(String path,
      {dynamic data, Duration timeout = const Duration(seconds: 20)}) async {
    try {
      return await _dio.put(path, data: data).timeout(timeout);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String path,
      {Duration timeout = const Duration(seconds: 20)}) async {
    try {
      return await _dio.delete(path).timeout(timeout);
    } catch (e) {
      rethrow;
    }
  }
}
