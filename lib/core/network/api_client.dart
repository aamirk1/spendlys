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
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 ||
            (e.response?.data is Map &&
                e.response?.data['detail'] ==
                    'Could not validate credentials')) {
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
}
