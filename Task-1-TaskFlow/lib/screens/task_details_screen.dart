import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../controllers/task_scope.dart';
import '../models/task_item.dart';
import '../widgets/category_badge.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/feedback_banner.dart';
import 'add_edit_task_screen.dart';

/// Displays complete details and actions for a specific task.
class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({
    super.key,
    required this.taskId,
  });

  final String taskId;

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    const months = [
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
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${months[local.month - 1]} ${local.day}, ${local.year} • $hour12:$minute $period';
  }

  Future<void> _toggleStatus(BuildContext context, TaskItem task) async {
    final controller = TaskScope.read(context);
    final result = await controller.toggleTask(task.id);
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );
  }

  Future<void> _editTask(BuildContext context, TaskItem task) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditTaskScreen(existingTask: task),
      ),
    );
  }

  Future<void> _deleteTask(BuildContext context, TaskItem task) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete Task',
      message: 'Are you sure you want to delete "${task.title}"? This action cannot be undone.',
    );
    if (!confirmed || !context.mounted) return;

    final controller = TaskScope.read(context);
    final result = await controller.deleteTask(task.id);
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );

    if (result.success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TaskScope.of(context);
    final task = controller.findById(taskId);

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off,
                  size: 48,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'This task is no longer available.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final completed = task.isCompleted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            tooltip: 'Edit task',
            onPressed: () => _editTask(context, task),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete task',
            onPressed: () => _deleteTask(context, task),
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          CategoryBadge(category: task.category),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: (completed
                                      ? AppTheme.success
                                      : AppTheme.warning)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  completed
                                      ? Icons.check_circle
                                      : Icons.schedule,
                                  size: 15,
                                  color: completed
                                      ? AppTheme.success
                                      : AppTheme.warning,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  completed ? 'Completed' : 'Pending',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: completed
                                        ? AppTheme.success
                                        : AppTheme.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: completed
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          task.notes.isEmpty
                              ? 'No additional notes added for this task.'
                              : task.notes,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: task.notes.isEmpty
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: AppTheme.border),
                      const SizedBox(height: 12),
                      _MetadataRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Created',
                        value: _formatDateTime(task.createdAt),
                      ),
                      const SizedBox(height: 8),
                      _MetadataRow(
                        icon: Icons.update_outlined,
                        label: 'Last updated',
                        value: _formatDateTime(task.updatedAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () => _toggleStatus(context, task),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          completed ? AppTheme.warning : AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(
                      completed
                          ? Icons.replay_outlined
                          : Icons.check_circle_outline,
                    ),
                    label: Text(
                      completed ? 'Reopen as Pending' : 'Mark as Completed',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editTask(context, task),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Task'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteTask(context, task),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: AppTheme.danger,
                          side: const BorderSide(color: AppTheme.danger),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
