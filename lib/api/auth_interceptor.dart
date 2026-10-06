import 'dart:async';

import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../storage/token_storage.dart';
import 'endpoints.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
  }) : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;

    // Only handle unauthorized responses.
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Do not try to refresh these endpoints.
    if (_isAuthEndpoint(request.path)) {
      handler.next(err);
      return;
    }

    // Prevent more than one refresh/retry for the same request.
    final alreadyRetried = request.extra['retriedAfterRefresh'] == true;

    if (alreadyRetried) {
      await _tokenStorage.clearTokens();
      handler.next(err);
      return;
    }

    try {
      final newToken = await _refreshAccessToken();

      if (newToken == null || newToken.isEmpty) {
        await _tokenStorage.clearTokens();
        handler.next(err);
        return;
      }

      final retryRequest = request.copyWith(
        headers: {
          ...request.headers,
          'Authorization': 'Bearer $newToken',
        },
        extra: {
          ...request.extra,
          'retriedAfterRefresh': true,
        },
      );

      final retryDio = Dio(
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

      final response = await retryDio.fetch<dynamic>(retryRequest);

      handler.resolve(response);
    } catch (e) {
      await _tokenStorage.clearTokens();
      handler.next(err);
    }
  }

  bool _isAuthEndpoint(String path) {
    return path == ApiEndpoints.login ||
        path == ApiEndpoints.refresh ||
        path == ApiEndpoints.logout;
  }

  Future<String?> _refreshAccessToken() async {
    if (_isRefreshing && _refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final currentToken = await _tokenStorage.getAccessToken();

      if (currentToken == null || currentToken.isEmpty) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $currentToken',
          },
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.refresh,
      );

      final responseData = response.data;

      if (responseData is! Map<String, dynamic>) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final data = responseData['data'];

      if (data is! Map<String, dynamic>) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final newToken = data['token'];

      if (newToken is! String || newToken.isEmpty) {
        _refreshCompleter!.complete(null);
        return null;
      }

      await _tokenStorage.saveAccessToken(newToken);

      _refreshCompleter!.complete(newToken);

      return newToken;
    } catch (_) {
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(null);
      }

      return null;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }
}