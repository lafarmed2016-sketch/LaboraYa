import 'package:flutter_test/flutter_test.dart';
import 'package:laboraya_app/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('email', () {
      test('returns error for empty', () {
        expect(Validators.email(''), isNotNull);
        expect(Validators.email(null), isNotNull);
      });

      test('returns error for invalid email', () {
        expect(Validators.email('test'), isNotNull);
        expect(Validators.email('test@'), isNotNull);
        expect(Validators.email('@test.com'), isNotNull);
      });

      test('returns null for valid email', () {
        expect(Validators.email('test@test.com'), isNull);
        expect(Validators.email('user.name@domain.co'), isNull);
      });
    });

    group('required', () {
      test('returns error for empty', () {
        expect(Validators.required(''), isNotNull);
        expect(Validators.required(null), isNotNull);
        expect(Validators.required('   '), isNotNull);
      });

      test('returns null for non-empty', () {
        expect(Validators.required('hello'), isNull);
      });
    });

    group('password', () {
      test('returns error for short password', () {
        expect(Validators.password('1234567'), isNotNull);
      });

      test('returns null for valid password', () {
        expect(Validators.password('12345678'), isNull);
      });

      test('returns error for empty', () {
        expect(Validators.password(''), isNotNull);
      });
    });

    group('phone', () {
      test('returns error for short number', () {
        expect(Validators.phone('1234'), isNotNull);
      });

      test('returns null for valid phone', () {
        expect(Validators.phone('987654321'), isNull);
      });
    });

    group('budget', () {
      test('returns null for empty (optional)', () {
        expect(Validators.budget(''), isNull);
        expect(Validators.budget(null), isNull);
      });

      test('returns error for negative', () {
        expect(Validators.budget('-10'), isNotNull);
      });

      test('returns null for valid amount', () {
        expect(Validators.budget('100'), isNull);
        expect(Validators.budget('0'), isNull);
      });
    });
  });
}
