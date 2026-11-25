import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../models/task_item.dart';
import '../utils/date_formatters.dart';
import 'category_badge.dart';

/// Action returned when the user responds to an in-app task reminder alarm.
enum AlarmDialogAction {
  complete,
  snooze,
  email,
  dismiss,
}

/// Modal alert dialog shown when a scheduled task reminder time arrives.
class AlarmAlertDialog extends StatelessWidget {
  const AlarmAlertDialog({
    super.key,
    required this.task,
    required this.hasEmailConfigured,
  });

  final TaskItem task;
  final bool hasEmailConfigured;

  @override
  Widget build(BuildContext context) {
    final isPreview = task.id == 'test_alarm_preview';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.alarm_on,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Reminder Alarm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Time to work on your scheduled task',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (task.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    task.notes,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    CategoryBadge(category: task.category, compact: true),
                    if (task.reminderAt != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          DateFormatters.formatReminderShort(task.reminderAt!),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (hasEmailConfigured) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop(AlarmDialogAction.email),
                icon: const Icon(Icons.email_outlined, size: 18),
                label: const Text('Send Email Reminder'),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(AlarmDialogAction.dismiss),
          child: const Text('Dismiss'),
        ),
        if (!isPreview)
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(AlarmDialogAction.snooze),
            icon: const Icon(Icons.snooze, size: 17),
            label: const Text('Snooze 10m'),
          ),
        if (!isPreview)
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(AlarmDialogAction.complete),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check, size: 17),
            label: const Text('Mark Done'),
          ),
      ],
    );
  }
}
