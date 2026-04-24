import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../data/models/auth/auth_session_model.dart';
import '../../../providers/app_providers.dart';

class AuthState {
  const AuthState({
    this.session,
    this.loading = false,
    this.error,
    this.isInitialized = false,
  });

  final AuthSessionModel? session;
  final bool loading;
  final String? error;
  final bool isInitialized;

  bool get isAuthenticated => session != null;

  AuthState copyWith({
    AuthSessionModel? session,
    bool? loading,
    String? error,
    bool? isInitialized,
    bool clearSession = false,
    bool clearError = false,
  }) =>
      AuthState(
        session: clearSession ? null : (session ?? this.session),
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        isInitialized: isInitialized ?? this.isInitialized,
      );
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    return _restoreSession();
  }

  Future<AuthState> _restoreSession() async {
    final storage = ref.read(secureStorageProvider);
    final client = ref.read(apiClientProvider);
    final datasource = ref.read(authDatasourceProvider);

    final token = await storage.readToken();
    if (token == null) {
      return const AuthState(isInitialized: true);
    }

    client.setAccessToken(token);
    _wireRefreshCallback();

    try {
      final session = await datasource.me();
      return AuthState(session: session, isInitialized: true);
    } on UnauthorizedException {
      // Token is definitively rejected — try refresh token before giving up
      return await _tryRefreshOrClear();
    } on SocketException {
      // Network unavailable at startup — keep session optimistically (offline mode)
      return const AuthState(isInitialized: true);
    } on NetworkException {
      // Same: transient network error — keep session for offline use
      return const AuthState(isInitialized: true);
    } catch (_) {
      return const AuthState(isInitialized: true);
    }
  }

  /// Attempts to use the stored refresh token to get a new access token.
  /// If refresh also fails or refresh token doesn't exist, clears the session.
  Future<AuthState> _tryRefreshOrClear() async {
    final storage = ref.read(secureStorageProvider);
    final client = ref.read(apiClientProvider);
    final datasource = ref.read(authDatasourceProvider);

    final refreshToken = await storage.readRefreshToken();
    if (refreshToken == null) {
      await storage.clear();
      client.setAccessToken(null);
      return const AuthState(isInitialized: true);
    }

    try {
      final session = await datasource.refreshSession(refreshToken);
      await storage.saveToken(session.accessToken);
      // TODO: save new refresh token when backend returns it in refresh response
      _wireRefreshCallback();
      return AuthState(session: session, isInitialized: true);
    } catch (_) {
      await storage.clear();
      client.setAccessToken(null);
      return const AuthState(isInitialized: true);
    }
  }

  /// Wires the ApiClient refresh callback so 401s on API calls trigger
  /// a silent token refresh without forcing the user to log in again.
  void _wireRefreshCallback() {
    final client = ref.read(apiClientProvider);
    final storage = ref.read(secureStorageProvider);
    final datasource = ref.read(authDatasourceProvider);

    client.onTokenRefresh = () async {
      final refreshToken = await storage.readRefreshToken();
      if (refreshToken == null) return null;
      try {
        final session = await datasource.refreshSession(refreshToken);
        await storage.saveToken(session.accessToken);
        // Update the in-memory session state
        final current = state.valueOrNull;
        if (current?.session != null) {
          state = AsyncValue.data(
            AuthState(
              session: session.copyWith(
                // preserve business context from current session
                activeBusinessId: current!.session!.activeBusinessId,
              ),
              isInitialized: true,
            ),
          );
        }
        return session.accessToken;
      } catch (_) {
        // Refresh failed — force logout
        await logout();
        return null;
      }
    };
  }

  Future<void> login({required String identifier, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final datasource = ref.read(authDatasourceProvider);
      final storage = ref.read(secureStorageProvider);

      final session = await datasource.login(
        identifier: identifier,
        password: password,
      );
      await storage.saveToken(session.accessToken);
      if (session.activeBusinessId != null) {
        await storage.saveActiveBusinessId(session.activeBusinessId);
      }
      // TODO: save refresh token when backend returns it in login response
      // if (session.refreshToken != null) {
      //   await storage.saveRefreshToken(session.refreshToken!);
      // }
      _wireRefreshCallback();
      return AuthState(session: session, isInitialized: true);
    });
  }

  Future<void> switchBusiness(String businessId) async {
    final current = state.valueOrNull;
    if (current?.session == null) return;

    state = AsyncValue.data(current!.copyWith(loading: true));
    try {
      final datasource = ref.read(authDatasourceProvider);
      final storage = ref.read(secureStorageProvider);

      final session = await datasource.switchBusiness(businessId);
      await storage.saveToken(session.accessToken);
      await storage.saveActiveBusinessId(businessId);

      state = AsyncValue.data(AuthState(session: session, isInitialized: true));
    } catch (e) {
      state = AsyncValue.data(
        current.copyWith(loading: false, error: _errorMessage(e)),
      );
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(authDatasourceProvider).logout();
    } catch (_) {}
    final client = ref.read(apiClientProvider);
    client.onTokenRefresh = null;
    await ref.read(secureStorageProvider).clear();
    state = const AsyncValue.data(AuthState(isInitialized: true));
  }

  String _errorMessage(Object e) {
    if (e is AppException) return e.userMessage;
    return 'Error inesperado. Intenta de nuevo.';
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
