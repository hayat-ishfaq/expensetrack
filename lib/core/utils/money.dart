import 'package:intl/intl.dart';

/// Currency helpers.
///
/// Every monetary value in FlatSplit is an [int] of paisa (Rs. 1 = 100 paisa).
/// Keeping money as integers avoids floating-point drift in splits, balances
/// and settlement math; values are only converted to numbers for display.
abstract final class Money {
  static const String symbol = 'Rs.';

  static final NumberFormat _wholeFormat = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _decimalFormat = NumberFormat('#,##0.00', 'en_US');
  static final RegExp _amountPattern = RegExp(r'^\d{1,12}(\.\d{1,2})?$');

  /// Parses user input into paisa.
  ///
  /// Accepts `1500`, `1,500`, `Rs. 1,500`, `1500.50`. Returns `null` for
  /// anything that is not a valid non-negative amount: signs, letters,
  /// `NaN`, `Infinity`, more than two decimals, or empty input.
  static int? tryParsePaisa(String? input) {
    if (input == null) return null;
    var text = input.trim();
    if (text.isEmpty || text.startsWith('-')) return null;

    final lower = text.toLowerCase();
    if (lower.startsWith('rs.')) {
      text = text.substring(3);
    } else if (lower.startsWith('rs')) {
      text = text.substring(2);
    }

    text = text.trim().replaceAll(',', '');
    if (!_amountPattern.hasMatch(text)) return null;

    final dotIndex = text.indexOf('.');
    final rupees =
        int.parse(dotIndex == -1 ? text : text.substring(0, dotIndex));
    final paisa = dotIndex == -1
        ? 0
        : int.parse(text.substring(dotIndex + 1).padRight(2, '0'));
    return rupees * 100 + paisa;
  }

  /// Formats paisa as `Rs. 1,450` / `Rs. 1,450.50`
  /// (decimals only shown when they exist).
  static String format(int paisa) {
    final isNegative = paisa < 0;
    final abs = paisa.abs();
    final body = abs % 100 == 0
        ? _wholeFormat.format(abs ~/ 100)
        : _decimalFormat.format(abs / 100);
    return '${isNegative ? '-' : ''}$symbol $body';
  }

  /// Formats with an explicit sign for balances: `+Rs. 4,500`, `-Rs. 2,000`.
  /// Zero is unsigned: `Rs. 0`.
  static String formatSigned(int paisa) {
    if (paisa > 0) return '+${format(paisa)}';
    return format(paisa);
  }
}
