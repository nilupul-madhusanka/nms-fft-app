import 'package:intl/intl.dart';

class Helpers {
  static final DateFormat dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat dayFormat = DateFormat('EEE, MMM dd');
  static final DateFormat monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat shortDate = DateFormat('dd/MM');
  static final NumberFormat currencyFormat = NumberFormat.currency(
    symbol: 'Rs. ',
    decimalDigits: 2,
  );

  /// Get start of day
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  /// Get this week's Monday
  static DateTime startOfWeek(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    return addDays(date, -diff);
  }

  static DateTime startOfNextWeek(DateTime date) =>
      addDays(startOfWeek(date), 7);

  /// Get first day of month
  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static DateTime startOfNextMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 1);

  static bool isInRange(DateTime date, DateTime start, DateTime end) =>
      !date.isBefore(start) && date.isBefore(end);

  static String displayName(String? name) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? 'Unknown' : trimmed;
  }

  /// Format amount with color awareness (for display)
  static String formatAmount(double amount) => currencyFormat.format(amount);
}
