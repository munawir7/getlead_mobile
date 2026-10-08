import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: tokenStorage,
      ),
    );
  }

  late final Dio _dio;

  Dio get dio => _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(
      path,
      queryParameters: queryParameters,
    );
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }

  Future<Response<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }
Future<Response<dynamic>> put(
  String path, {
  dynamic data,
  Map<String, dynamic>? queryParameters,
}) {
  return _dio.put(
    path,
    data: data,
    queryParameters: queryParameters,
  );
}
  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }
}