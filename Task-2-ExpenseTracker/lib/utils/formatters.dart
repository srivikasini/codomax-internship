/// Currency and date formatting utilities with Indian (INR) grouping support.
class SpendFormatters {
  SpendFormatters._();

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Formats [amount] with [currencySymbol], using Indian lakh/crore grouping for `₹`.
  static String formatCurrency(
    double amount, {
    String currencySymbol = '₹',
    bool showDecimalsWhenZero = false,
  }) {
    final isNegative = amount < 0;
    final absVal = amount.abs();
    final hasFraction = (absVal - absVal.truncateToDouble()).abs() >= 0.005;

    final fixed = hasFraction || showDecimalsWhenZero
        ? absVal.toStringAsFixed(2)
        : absVal.round().toString();

    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';

    final formattedInt = currencySymbol == '₹'
        ? _groupIndian(intPart)
        : _groupWestern(intPart);

    final prefix = isNegative ? '-' : '';
    return '$prefix$currencySymbol$formattedInt$decPart';
  }

  static String _groupIndian(String digits) {
    if (digits.length <= 3) return digits;
    final lastThree = digits.substring(digits.length - 3);
    var remaining = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (remaining.length > 2) {
      groups.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      groups.insert(0, remaining);
    }
    return '${groups.join(',')},$lastThree';
  }

  static String _groupWestern(String digits) {
    if (digits.length <= 3) return digits;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static String formatDate(DateTime date) {
    final local = date.toLocal();
    return '${_months[local.month - 1]} ${local.day}, ${local.year}';
  }

  static String formatRelativeDate(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(local.year, local.month, local.day);

    if (target == today) return 'Today';
    if (target == yesterday) return 'Yesterday';
    return formatDate(local);
  }

  static String formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${formatDate(local)} • $hour12:$minute $period';
  }
}
