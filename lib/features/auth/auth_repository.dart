
import 'package:flutter/foundation.dart';

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

  Future<void> login({
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

    // Print the login response for development/debugging.
    // The access token is intentionally hidden.
    if (kDebugMode) {
      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        final data = responseData['data'];

        if (data is Map<String, dynamic>) {
          final safeData = Map<String, dynamic>.from(data);

          if (safeData.containsKey('token')) {
            safeData['token'] = 'REDACTED';
          }

          debugPrint('LOGIN RESPONSE: $safeData');
        } else {
          debugPrint('LOGIN RESPONSE: $responseData');
        }
      } else {
        debugPrint('LOGIN RESPONSE: $responseData');
      }
    }

    final data = response.data['data'] as Map<String, dynamic>;
    final token = data['token'] as String?;

    if (token == null || token.isEmpty) {
      throw Exception('Access token was not returned by the server.');
    }

    await _tokenStorage.saveAccessToken(token);
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore network errors so tokens are always cleared even if offline
    } finally {
      await _tokenStorage.clearTokens();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _tokenStorage.getAccessToken();

    return token != null && token.isNotEmpty;
  }
}

