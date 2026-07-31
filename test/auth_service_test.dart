import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';

// Auth service tests — verifica SecureStorage directamente
void main() {
  group('SecureStorage', () {
    late SecureStorage storage;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      storage = SecureStorage();
    });

    test('hasToken should return false initially', () async {
      final result = await storage.hasToken();
      expect(result, false);
    });

    test('saveAccessToken and getAccessToken work correctly', () async {
      await storage.saveAccessToken('test_token_123');
      final token = await storage.getAccessToken();
      expect(token, 'test_token_123');
    });

    test('hasToken returns true after saving token', () async {
      await storage.saveAccessToken('test_token');
      final result = await storage.hasToken();
      expect(result, true);
    });

    test('clearAll removes token', () async {
      await storage.saveAccessToken('test_token');
      await storage.clearAll();
      final result = await storage.hasToken();
      expect(result, false);
    });

    test('saveUserId and getUserId work correctly', () async {
      await storage.saveUserId('user_123');
      final userId = await storage.getUserId();
      expect(userId, 'user_123');
    });
  });
}
