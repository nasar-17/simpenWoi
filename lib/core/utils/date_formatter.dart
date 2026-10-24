import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Pola tanggal yang dipakai aplikasi.
abstract final class DatePatterns {
  static const String clock = 'HH:mm';
  static const String dateTimeShort = 'd MMM yyyy, HH:mm';
  static const String dateLong = 'd MMMM yyyy';
  static const String weekdayDate = 'EEEE, d MMMM yyyy';
  static const String dayMonth = 'd MMM';
  static const String dayMonthYear = 'd MMM yyyy';
  static const String monthYear = 'MMMM yyyy';
}

final DateFormat _clockFormat = DateFormat(
  DatePatterns.clock,
  AppConstants.localeId,
);
final DateFormat _dateTimeShortFormat = DateFormat(
  DatePatterns.dateTimeShort,
  AppConstants.localeId,
);
final DateFormat _dateLongFormat = DateFormat(
  DatePatterns.dateLong,
  AppConstants.localeId,
);
final DateFormat _weekdayDateFormat = DateFormat(
  DatePatterns.weekdayDate,
  AppConstants.localeId,
);
final DateFormat _dayMonthFormat = DateFormat(
  DatePatterns.dayMonth,
  AppConstants.localeId,
);
final DateFormat _dayMonthYearFormat = DateFormat(
  DatePatterns.dayMonthYear,
  AppConstants.localeId,
);
final DateFormat _monthYearFormat = DateFormat(
  DatePatterns.monthYear,
  AppConstants.localeId,
);

String formatClockTime(DateTime date) => _clockFormat.format(date);

String formatDateTimeShort(DateTime date) => _dateTimeShortFormat.format(date);

String formatDateLong(DateTime date) => _dateLongFormat.format(date);

String formatWeekdayDate(DateTime date) => _weekdayDateFormat.format(date);

String formatDayMonth(DateTime date) => _dayMonthFormat.format(date);

String formatDayMonthYear(DateTime date) => _dayMonthYearFormat.format(date);

String formatMonthYear(DateTime date) => _monthYearFormat.format(date);
