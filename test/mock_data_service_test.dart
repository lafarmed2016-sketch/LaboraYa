import 'package:flutter_test/flutter_test.dart';
import 'package:laboraya_app/core/services/mock_data_service.dart';

void main() {
  group('MockDataService', () {
    late MockDataService service;

    setUp(() {
      service = MockDataService();
    });

    test('currentUser has valid data', () {
      expect(service.currentUser.id, 'user_current');
      expect(service.currentUser.fullName, 'Juan Pérez');
      expect(service.currentUser.profession, 'Plomero');
      expect(service.currentUser.rating, 4.8);
    });

    test('users list is not empty', () {
      expect(service.users.isNotEmpty, true);
      expect(service.users.length, 5);
    });

    test('conversations list is not empty', () {
      expect(service.conversations.isNotEmpty, true);
    });

    test('notifications list is not empty', () {
      expect(service.notifications.isNotEmpty, true);
    });

    test('toggleFavorite adds and removes', () {
      expect(service.isFavorite('job_1'), false);
      service.toggleFavorite('job_1');
      expect(service.isFavorite('job_1'), true);
      service.toggleFavorite('job_1');
      expect(service.isFavorite('job_1'), false);
    });

    test('verifications have correct initial state', () {
      expect(service.verifications['email'], true);
      expect(service.verifications['phone'], true);
      expect(service.verifications['identity'], false);
      expect(service.verifications['selfie'], false);
      expect(service.verifications['address'], false);
    });
  });
}
