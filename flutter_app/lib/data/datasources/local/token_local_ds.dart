import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/session_tokens.dart';

/// Tokens no Keychain (iOS) / Keystore (Android) via flutter_secure_storage.
class TokenLocalDataSource implements SessionTokens {
  TokenLocalDataSource([FlutterSecureStorage? storage])
      : _s = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
            );

  final FlutterSecureStorage _s;
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kBiometric = 'biometric_enabled';

  @override
  Future<String?> get accessToken => _s.read(key: _kAccess);

  @override
  Future<String?> get refreshToken => _s.read(key: _kRefresh);

  @override
  Future<void> saveSession({required String accessToken, required String refreshToken}) async {
    await _s.write(key: _kAccess, value: accessToken);
    await _s.write(key: _kRefresh, value: refreshToken);
  }

  @override
  Future<void> clearAccessToken() => _s.delete(key: _kAccess);

  @override
  Future<void> clearAll() async {
    await _s.delete(key: _kAccess);
    await _s.delete(key: _kRefresh);
    await _s.delete(key: _kBiometric);
  }

  Future<bool> get biometricEnabled async => (await _s.read(key: _kBiometric)) == '1';
  Future<void> setBiometricEnabled(bool v) =>
      v ? _s.write(key: _kBiometric, value: '1') : _s.delete(key: _kBiometric);
}
