import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../storage/token_storage.dart';
import 'auth_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStorage: ref.read(tokenStorageProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.read(apiClientProvider),
    tokenStorage: ref.read(tokenStorageProvider),
  );
});

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isLoggedIn;
  final String? errorMessage;

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    return const AuthState();
  }

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
      await _repository.login(
        identifier: identifier,
        password: password,
        deviceName: deviceName,
      );

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
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

  Future<void> logout() async {
    await _repository.logout();

    state = const AuthState();
  }
}