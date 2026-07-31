import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:laboraya_app/app/config/env_config.dart';
import 'package:laboraya_app/core/network/api_client.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';
import 'package:laboraya_app/features/favorites/presentation/providers/favorites_provider.dart';

void main() {
  group('FavoritesNotifier', () {
    late FavoritesNotifier notifier;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = SecureStorage();
      final apiClient = ApiClient(envConfig: EnvConfig.development, storage: storage);
      notifier = FavoritesNotifier(apiClient);
    });

    test('initial state is empty', () {
      expect(notifier.state, isEmpty);
    });

    test('isFavorite returns false initially', () {
      expect(notifier.isFavorite('job_1'), false);
    });
  });
}
