import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:laboraya_app/app/config/env_config.dart';
import 'package:laboraya_app/core/network/api_client.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';
import 'package:laboraya_app/features/chat/presentation/providers/chat_provider.dart';

void main() {
  group('ChatNotifier', () {
    late ChatNotifier notifier;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = SecureStorage();
      final apiClient = ApiClient(envConfig: EnvConfig.development, storage: storage);
      notifier = ChatNotifier(apiClient);
    });

    test('initial state is empty', () {
      expect(notifier.state, isEmpty);
    });
  });
}
