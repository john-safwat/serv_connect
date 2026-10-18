import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:serv_connect_mobile/core/utils/app_formatters.dart';
import 'package:serv_connect_mobile/core/utils/id_generator.dart';
import 'package:serv_connect_mobile/core/utils/validation.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  group('AppFormatters, LocalDateValue, LocalTimeValue & IdGenerator', () {
    test('localDateAndTimeValues_parseAndFormatRoundTrip', () {
      final date = LocalDateValue.parse('2026-10-18');
      expect(date.year, 2026);
      expect(date.month, 10);
      expect(date.day, 18);
      expect(date.toIsoString(), '2026-10-18');

      final time = LocalTimeValue.parse('18:30');
      expect(time.hour, 18);
      expect(time.minute, 30);
      expect(time.toIsoString(), '18:30');
    });

    test('utcInstant_parsesAndFormatsCorrectly', () {
      final instant = AppFormatters.parseUtcInstant('2026-10-18T15:00:00Z');
      expect(instant.isUtc, isTrue);
      expect(AppFormatters.toUtcIsoString(instant), '2026-10-18T15:00:00.000Z');
      expect(AppFormatters.formatShortDate(instant), isNotEmpty);
      expect(AppFormatters.formatTimeOfDay(instant), isNotEmpty);
    });

    test('idGenerator_generatesDistinctUuidV4Strings', () {
      final first = IdGenerator.newUuid();
      final second = IdGenerator.newUuid();
      expect(first, isNot(equals(second)));
      expect(first.length, 36);
    });
  });

  group('Validation', () {
    test('validators_acceptValidInputsAndRejectInvalidInputs', () {
      expect(Validation.validateRequiredText('value'), isNull);
      expect(Validation.validateRequiredText('   '), isNotNull);

      expect(Validation.validateEmail('servant@church.org'), isNull);
      expect(Validation.validateEmail('invalid-email'), isNotNull);

      expect(Validation.validatePhone('+201012345678'), isNull);
      expect(Validation.validatePhone('abc'), isNotNull);

      expect(Validation.validatePassword('strongPass123'), isNull);
      expect(Validation.validatePassword('short'), isNotNull);

      expect(Validation.validateOtp('123456'), isNull);
      expect(Validation.validateOtp('12a45'), isNotNull);
    });
  });
}
