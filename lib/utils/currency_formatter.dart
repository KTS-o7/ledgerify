import 'package:intl/intl.dart';

/// Utility class for formatting currency values.
///
/// Defaults to Indian Rupee (INR) formatting.
/// Can be extended to support multiple currencies later.
class CurrencyFormatter {
  // Indian Rupee format
  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  // Compact format for large numbers (e.g., ₹1.2L instead of ₹1,20,000)
  static final NumberFormat _compactFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Formats an amount as currency (e.g., ₹1,234.56)
  static String format(double amount) {
    return _inrFormat.format(amount);
  }

  /// Formats an amount in compact form (e.g., ₹1.2L)
  static String formatCompact(double amount) {
    return _compactFormat.format(amount);
  }

  /// Formats an amount without the currency symbol (e.g., 1,234.56)
  static String formatWithoutSymbol(double amount) {
    return NumberFormat('#,##,##0.00', 'en_IN').format(amount);
  }

  /// Parses a string to a double, handling currency symbols and commas.
  static double? parse(String value) {
    // Remove currency symbol and spaces
    final cleaned = value
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();

    return double.tryParse(cleaned);
  }
}

/// Utility class for formatting dates.
class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yy');
  static final DateFormat _dayMonthFormat = DateFormat('dd MMM');

  /// Formats a date as "25 Jan 2024"
  static String format(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Formats a date with time as "25 Jan 2024, 10:30 AM"
  static String formatWithTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Formats as "January 2024"
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Formats as "25/01/24"
  static String formatShort(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Formats as "25 Jan"
  static String formatDayMonth(DateTime date) {
    return _dayMonthFormat.format(date);
  }

  /// Returns a human-readable relative time (e.g., "Today", "Yesterday")
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat('EEEE').format(date); // e.g., "Monday"
    } else {
      return format(date);
    }
  }
}
