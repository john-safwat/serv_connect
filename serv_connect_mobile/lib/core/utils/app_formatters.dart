import 'package:intl/intl.dart';

/// Value object for genuine date-only values (`YYYY-MM-DD`, e.g. birthdates)
/// that must never be shifted through UTC midnight (`CLAUDE.md §6`).
class LocalDateValue {
  const LocalDateValue({
    required this.year,
    required this.month,
    required this.day,
  });

  factory LocalDateValue.parse(String isoDate) {
    final parts = isoDate.trim().split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid ISO local date: $isoDate');
    }
    return LocalDateValue(
      year: int.parse(parts[0]),
      month: int.parse(parts[1]),
      day: int.parse(parts[2]),
    );
  }

  final int year;
  final int month;
  final int day;

  String toIsoString() {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// Value object for time-of-day values (`HH:mm`, e.g. recurring meetings).
class LocalTimeValue {
  const LocalTimeValue({required this.hour, required this.minute});

  factory LocalTimeValue.parse(String isoTime) {
    final parts = isoTime.trim().split(':');
    if (parts.length < 2) {
      throw FormatException('Invalid ISO local time: $isoTime');
    }
    return LocalTimeValue(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  final int hour;
  final int minute;

  String toIsoString() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Centralised date, time, and UTC instant formatting (`CLAUDE.md §6`).
abstract final class AppFormatters {
  static DateTime parseUtcInstant(String isoUtc) =>
      DateTime.parse(isoUtc).toUtc();

  static String toUtcIsoString(DateTime instant) =>
      instant.toUtc().toIso8601String();

  static String formatShortDate(DateTime instant, {String locale = 'en'}) {
    return DateFormat.yMMMd(locale).format(instant.toLocal());
  }

  static String formatTimeOfDay(DateTime instant, {String locale = 'en'}) {
    return DateFormat.jm(locale).format(instant.toLocal());
  }

  static String formatLocalDate(LocalDateValue date, {String locale = 'en'}) {
    final local = DateTime(date.year, date.month, date.day);
    return DateFormat.yMMMd(locale).format(local);
  }
}
