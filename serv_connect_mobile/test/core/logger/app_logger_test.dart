import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:serv_connect_mobile/core/logger/app_logger.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('AppLogger PII Scrubbing', () {
    test('scrub_redactsSensitiveKeysFromMessages', () {
      const raw =
          'login phone=+201000000000 email=servant@example.org '
          'password: secret123 token=eyJ123 medical=asthma note=private';
      final scrubbed = AppLogger.scrub(raw);

      expect(scrubbed, isNot(contains('+201000000000')));
      expect(scrubbed, isNot(contains('servant@example.org')));
      expect(scrubbed, isNot(contains('secret123')));
      expect(scrubbed, isNot(contains('eyJ123')));
      expect(scrubbed, isNot(contains('asthma')));
      expect(scrubbed, contains('phone: [REDACTED]'));
      expect(scrubbed, contains('password: [REDACTED]'));
    });

    test('logMethods_whenEnabled_forwardScrubbedMessage', () {
      final mockLogger = _MockLogger();
      AppLogger.test(mockLogger)
        ..d('otp=654321')
        ..i('authorization: Bearerxyz')
        ..w('warning message')
        ..e('error phone=12345', error: 'token=abc');

      verify(() => mockLogger.d('otp: [REDACTED]')).called(1);
      verify(() => mockLogger.i('authorization: [REDACTED]')).called(1);
      verify(() => mockLogger.w('warning message')).called(1);
      verify(
        () =>
            mockLogger.e('error phone: [REDACTED]', error: 'token: [REDACTED]'),
      ).called(1);
    });
  });
}
