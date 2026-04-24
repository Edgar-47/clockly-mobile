import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:clockly_mobile/core/network/api_client.dart';
import 'package:clockly_mobile/core/storage/secure_storage.dart';
import 'package:clockly_mobile/data/datasources/auth_remote_datasource.dart';
import 'package:clockly_mobile/features/auth/providers/auth_provider.dart';
import 'package:clockly_mobile/providers/app_providers.dart';

import 'helpers/fake_secure_storage.dart';

void main() {
  group('AuthNotifier', () {
    ProviderContainer makeContainer({
      required http.Client httpClient,
      String? storedToken,
    }) {
      final fakeStorage = FakeFlutterSecureStorage()..storedToken = storedToken;
      final secureStorage = SecureStorage(storage: fakeStorage);
      final apiClient = ApiClient(httpClient: httpClient);

      return ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          secureStorageProvider.overrideWithValue(secureStorage),
          authDatasourceProvider
              .overrideWithValue(AuthRemoteDatasource(apiClient)),
        ],
      );
    }

    test('no token → unauthenticated state', () async {
      final c = makeContainer(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      addTearDown(c.dispose);

      await c.read(authProvider.future);
      final auth = c.read(authProvider).valueOrNull;
      expect(auth?.isAuthenticated, isFalse);
      expect(auth?.isInitialized, isTrue);
    });

    test('valid token → session restored', () async {
      const meResponse = '{"access":"tok","user":{"id":1,'
          '"identifier":"u","full_name":"Ana"},'
          '"businesses":[],"permissions":[]}';

      final c = makeContainer(
        httpClient: MockClient((req) async {
          if (req.url.path.endsWith('/auth/me')) {
            return http.Response(meResponse, 200);
          }
          return http.Response('{}', 404);
        }),
        storedToken: 'stored-token',
      );
      addTearDown(c.dispose);

      await c.read(authProvider.future);
      final auth = c.read(authProvider).valueOrNull;
      expect(auth?.isAuthenticated, isTrue);
      expect(auth?.isInitialized, isTrue);
    });

    test('401 from /auth/me with no refresh token → session cleared', () async {
      final fakeStorage =
          FakeFlutterSecureStorage()..storedToken = 'expired-token';
      final secureStorage = SecureStorage(storage: fakeStorage);
      final apiClient = ApiClient(
        httpClient: MockClient((req) async {
          if (req.url.path.endsWith('/auth/me')) {
            return http.Response('{}', 401);
          }
          if (req.url.path.endsWith('/auth/refresh')) {
            return http.Response('{}', 404);
          }
          return http.Response('{}', 404);
        }),
      );

      final c = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          secureStorageProvider.overrideWithValue(secureStorage),
          authDatasourceProvider
              .overrideWithValue(AuthRemoteDatasource(apiClient)),
        ],
      );
      addTearDown(c.dispose);

      await c.read(authProvider.future);
      final auth = c.read(authProvider).valueOrNull;

      expect(auth?.isAuthenticated, isFalse);
      expect(auth?.isInitialized, isTrue);
      // Token must be cleared from storage
      expect(fakeStorage.storedToken, isNull);
    });

    test('network error at startup preserves session (offline mode)', () async {
      final fakeStorage =
          FakeFlutterSecureStorage()..storedToken = 'valid-token';
      final secureStorage = SecureStorage(storage: fakeStorage);
      final apiClient = ApiClient(
        httpClient: MockClient((_) async {
          throw http.ClientException('No connection');
        }),
        maxRetries: 0,
      );

      final c = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          secureStorageProvider.overrideWithValue(secureStorage),
          authDatasourceProvider
              .overrideWithValue(AuthRemoteDatasource(apiClient)),
        ],
      );
      addTearDown(c.dispose);

      await c.read(authProvider.future);
      final auth = c.read(authProvider).valueOrNull;

      expect(auth?.isInitialized, isTrue);
      // Token must NOT be cleared on network error
      expect(fakeStorage.storedToken, equals('valid-token'));
    });

    test('login success stores token in secure storage', () async {
      const loginResponse = '{"access":"new-tok","user":{"id":2,'
          '"identifier":"user2","full_name":"Bob"},'
          '"businesses":[],"permissions":[]}';

      final fakeStorage = FakeFlutterSecureStorage();
      final secureStorage = SecureStorage(storage: fakeStorage);
      final apiClient = ApiClient(
        httpClient: MockClient((req) async {
          if (req.url.path.endsWith('/auth/login')) {
            return http.Response(loginResponse, 200);
          }
          if (req.url.path.endsWith('/auth/me')) {
            return http.Response('{}', 401);
          }
          return http.Response('{}', 404);
        }),
      );

      final c = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          secureStorageProvider.overrideWithValue(secureStorage),
          authDatasourceProvider
              .overrideWithValue(AuthRemoteDatasource(apiClient)),
        ],
      );
      addTearDown(c.dispose);

      await c.read(authProvider.future);
      await c
          .read(authProvider.notifier)
          .login(identifier: 'user2', password: 'pass');

      expect(fakeStorage.storedToken, equals('new-tok'));
      expect(c.read(authProvider).valueOrNull?.isAuthenticated, isTrue);
    });
  });
}
