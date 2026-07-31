import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:laboraya_app/app/config/env_config.dart';
import 'package:laboraya_app/core/network/api_client.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';
import 'package:laboraya_app/features/jobs/presentation/providers/jobs_provider.dart';

void main() {
  group('JobsNotifier', () {
    late JobsNotifier notifier;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = SecureStorage();
      final apiClient = ApiClient(envConfig: EnvConfig.development, storage: storage);
      notifier = JobsNotifier(apiClient);
    });

    test('initial state has empty jobs', () {
      expect(notifier.state.jobs, isEmpty);
      expect(notifier.state.isLoading, false);
    });
  });
}
