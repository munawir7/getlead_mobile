import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../storage/token_storage.dart';
import 'auth_repository.dart';

// Token storage provider.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

// API client provider.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStorage: ref.read(tokenStorageProvider),
  );
});

// Authentication repository provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.read(apiClientProvider),
    tokenStorage: ref.read(tokenStorageProvider),
  );
});

// Authentication controller provider.
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

// Authentication state.
class AuthState {
  const AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.errorMessage,
    this.user = const <String, dynamic>{},
  });

  final bool isLoading;
  final bool isLoggedIn;
  final String? errorMessage;

  // Logged-in user's information.
  final Map<String, dynamic> user;

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    String? errorMessage,
    bool clearError = false,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      errorMessage:
          clearError ? null : errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }
}

// Authentication controller.
class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);

    return const AuthState();
  }

  // Login.
  Future<void> login({
    required String identifier,
    required String password,
    required String deviceName,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final user = await _repository.login(
        identifier: identifier,
        password: password,
        deviceName: deviceName,
      );

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        user: user,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Logout.
  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      state = const AuthState();
    }
  }
}