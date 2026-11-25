/// Formats dates and times consistently across TaskFlow screens and alerts.
class DateFormatters {
  DateFormatters._();

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

  static String formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${_months[local.month - 1]} ${local.day}, ${local.year} • $hour12:$minute $period';
  }

  static String formatReminderShort(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final targetDay = DateTime(local.year, local.month, local.day);

    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final timeText = '$hour12:$minute $period';

    if (targetDay == today) {
      return 'Today, $timeText';
    }
    if (targetDay == tomorrow) {
      return 'Tomorrow, $timeText';
    }
    return '${_months[local.month - 1]} ${local.day}, $timeText';
  }
}
