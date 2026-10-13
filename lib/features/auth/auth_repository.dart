import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import '../../api/endpoints.dart';
import '../../storage/token_storage.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  // Login and return the user's profile information.
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    required String deviceName,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'identifier': identifier,
        'password': password,
        'device_name': deviceName,
      },
    );

    final responseData = response.data;

    if (responseData is! Map) {
      throw Exception('Invalid login response.');
    }

    final rawData = responseData['data'];

    if (rawData is! Map) {
      throw Exception('Login data was not returned by the server.');
    }

    final data = Map<String, dynamic>.from(rawData);

    final token = data['token']?.toString();

    if (token == null || token.isEmpty) {
      throw Exception('Access token was not returned by the server.');
    }

    // Save the access token.
    await _tokenStorage.saveAccessToken(token);

    // Extract the user information.
    final rawUser = data['user'];

    if (rawUser is Map) {
      return Map<String, dynamic>.from(rawUser);
    }

    return <String, dynamic>{};
  }

  // Logout and clear local authentication tokens.
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } on DioException {
      // Clear local tokens even if the server is unavailable.
    } finally {
      await _tokenStorage.clearTokens();
    }
  }

  // Check whether an access token exists.
  Future<bool> isLoggedIn() async {
    final token = await _tokenStorage.getAccessToken();

    return token != null && token.isNotEmpty;
  }
}