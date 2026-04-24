import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../errors/app_exceptions.dart';

class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                // Resets storage if keystore is corrupted (e.g. after factory
                // reset or backup-restore on Android). Prevents permanent
                // lockout at the cost of forcing re-login.
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                // Keeps token in keychain even when device is locked, but
                // prevents iCloud Keychain sync across devices. Suitable for
                // enterprise apps where each device should have its own session.
                accessibility: KeychainAccessibility.first_unlock_this_device,
                synchronizable: false,
              ),
            );

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: AppConstants.tokenKey, value: token);
    } catch (e) {
      _logError('saveToken', e);
      throw const StorageException('No se pudo guardar el token.');
    }
  }

  Future<String?> readToken() async {
    try {
      return await _storage.read(key: AppConstants.tokenKey);
    } catch (e) {
      _logError('readToken', e);
      return null;
    }
  }

  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: AppConstants.refreshTokenKey, value: token);
    } catch (e) {
      _logError('saveRefreshToken', e);
    }
  }

  Future<String?> readRefreshToken() async {
    try {
      return await _storage.read(key: AppConstants.refreshTokenKey);
    } catch (e) {
      _logError('readRefreshToken', e);
      return null;
    }
  }

  Future<void> saveActiveBusinessId(String? id) async {
    try {
      if (id == null) {
        await _storage.delete(key: AppConstants.businessIdKey);
      } else {
        await _storage.write(key: AppConstants.businessIdKey, value: id);
      }
    } catch (e) {
      _logError('saveActiveBusinessId', e);
    }
  }

  Future<String?> readActiveBusinessId() async {
    try {
      return await _storage.read(key: AppConstants.businessIdKey);
    } catch (e) {
      _logError('readActiveBusinessId', e);
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      _logError('clear', e);
    }
  }

  void _logError(String operation, Object error) {
    if (kDebugMode) {
      // Safe to log in debug — never log token values, only errors.
      debugPrint('[SecureStorage] $operation failed: $error');
    }
    // TODO: report to Crashlytics when integrated:
    // FirebaseCrashlytics.instance.recordError(error, null,
    //   reason: 'SecureStorage.$operation');
  }
}
