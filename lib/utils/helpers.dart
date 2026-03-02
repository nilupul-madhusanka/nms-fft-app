import 'package:intl/intl.dart';

class Helpers {
  static final DateFormat dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat dayFormat = DateFormat('EEE, MMM dd');
  static final DateFormat monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat shortDate = DateFormat('dd/MM');
  static final NumberFormat currencyFormat =
      NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);

  /// Get start of day
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Get end of day
  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);

  /// Get this week's Monday
  static DateTime startOfWeek(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    return startOfDay(date.subtract(Duration(days: diff)));
  }

  /// Get this week's Sunday
  static DateTime endOfWeek(DateTime date) {
    final start = startOfWeek(date);
    return endOfDay(start.add(const Duration(days: 6)));
  }

  /// Get first day of month
  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  /// Get last day of month
  static DateTime endOfMonth(DateTime date) =>
      endOfDay(DateTime(date.year, date.month + 1, 0));

  /// Format amount with color awareness (for display)
  static String formatAmount(double amount) => currencyFormat.format(amount);
}
