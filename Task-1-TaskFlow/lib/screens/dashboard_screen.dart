import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../controllers/task_controller.dart';
import '../controllers/task_scope.dart';
import '../models/task_item.dart';
import '../services/reminder_platform.dart';
import '../utils/date_formatters.dart';
import '../widgets/brand_header.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/feedback_banner.dart';
import '../widgets/progress_banner.dart';
import '../widgets/stat_card.dart';
import '../widgets/task_card.dart';
import 'add_edit_task_screen.dart';
import 'task_details_screen.dart';

/// Main overview screen with progress summary, stats, quick add, and recent tasks.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onNavigateToTasks,
  });

  final void Function({
    String? categoryFilter,
    TaskStatusFilter? statusFilter,
  }) onNavigateToTasks;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<FormState> _quickAddFormKey = GlobalKey<FormState>();
  final TextEditingController _quickTitleController = TextEditingController();
  TaskCategory _quickCategory = TaskCategory.personal;
  DateTime? _quickReminderAt;
  bool _isAdding = false;

  @override
  void dispose() {
    _quickTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickQuickReminder() async {
    final now = DateTime.now();
    final initial = _quickReminderAt != null && _quickReminderAt!.isAfter(now)
        ? _quickReminderAt!
        : now.add(const Duration(minutes: 30));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (!combined.isAfter(DateTime.now())) {
      showAppSnackBar(
        context,
        message: 'Please choose a future time for your alarm.',
        isError: true,
      );
      return;
    }

    setState(() {
      _quickReminderAt = combined;
    });

    if (isBrowserAlertSupported &&
        browserNotificationPermission == 'default') {
      await requestBrowserNotificationPermission();
    }
  }

  Future<void> _submitQuickAdd() async {
    if (_isAdding) return;
    if (!(_quickAddFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isAdding = true;
    });

    final controller = TaskScope.read(context);
    final result = await controller.addTask(
      title: _quickTitleController.text,
      category: _quickCategory,
      reminderAt: _quickReminderAt,
    );

    if (!mounted) return;

    setState(() {
      _isAdding = false;
    });

    if (result.success) {
      _quickTitleController.clear();
      setState(() {
        _quickReminderAt = null;
      });
      FocusScope.of(context).unfocus();
    }

    showAppSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );
  }

  Future<void> _openAddScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
    );
  }

  Future<void> _openDetails(TaskItem task) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskDetailsScreen(taskId: task.id)),
    );
  }

  Future<void> _openEdit(TaskItem task) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditTaskScreen(existingTask: task)),
    );
  }

  Future<void> _handleDelete(TaskItem task) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete Task',
      message: 'Are you sure you want to delete "${task.title}"?',
    );
    if (!confirmed || !mounted) return;

    final result = await TaskScope.read(context).deleteTask(task.id);
    if (!mounted) return;
    showAppSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );
  }

  Future<void> _handleToggle(TaskItem task) async {
    final result = await TaskScope.read(context).toggleTask(task.id);
    if (!mounted) return;
    showAppSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = TaskScope.of(context);
    final recentTasks = controller.tasks.take(4).toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandHeader(
            trailing: FilledButton.tonalIcon(
              onPressed: _openAddScreen,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Task'),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hello, Welcome! 👋',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            controller.activeRemindersCount > 0
                ? 'Organize your day — ${controller.activeRemindersCount} active ${controller.activeRemindersCount == 1 ? 'alarm' : 'alarms'} scheduled.'
                : 'Organize your day and achieve your goals.',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 16),
            StorageErrorBanner(
              message: controller.errorMessage!,
              onRetry: () => controller.loadTasks(forceReload: true),
              onResetStorage: () async {
                final ok = await controller.resetCorruptedStorage();
                if (!context.mounted) return;
                showAppSnackBar(
                  context,
                  message: ok
                      ? 'Local storage reset cleanly.'
                      : 'Could not reset storage.',
                  isError: !ok,
                );
              },
            ),
          ],
          const SizedBox(height: 20),
          ProgressBanner(
            completedCount: controller.completedCount,
            totalCount: controller.totalCount,
            progress: controller.completionProgress,
            percentage: controller.completionPercentage,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total',
                  value: controller.totalCount.toString(),
                  icon: Icons.checklist_rounded,
                  color: AppTheme.primary,
                  onTap: () => widget.onNavigateToTasks(
                    categoryFilter: 'All',
                    statusFilter: TaskStatusFilter.all,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  title: 'Completed',
                  value: controller.completedCount.toString(),
                  icon: Icons.task_alt,
                  color: AppTheme.success,
                  onTap: () => widget.onNavigateToTasks(
                    categoryFilter: 'All',
                    statusFilter: TaskStatusFilter.completed,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  title: 'Pending',
                  value: controller.pendingCount.toString(),
                  icon: Icons.pending_actions,
                  color: AppTheme.warning,
                  onTap: () => widget.onNavigateToTasks(
                    categoryFilter: 'All',
                    statusFilter: TaskStatusFilter.pending,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: TaskCategory.values.map((category) {
              final count = controller.countByCategory(category);
              final done = controller.completedCountByCategory(category);
              final isLast = category == TaskCategory.values.last;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 10),
                  child: Material(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => widget.onNavigateToTasks(
                        categoryFilter: category.label,
                        statusFilter: TaskStatusFilter.all,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              category.icon,
                              color: category.color,
                              size: 20,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$done/$count done',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Quick add task',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: Form(
              key: _quickAddFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _quickTitleController,
                    maxLength: TaskController.maxTitleLength,
                    decoration: const InputDecoration(
                      hintText: 'What do you need to do?',
                      prefixIcon: Icon(
                        Icons.edit_note,
                        color: AppTheme.primary,
                      ),
                      counterText: '',
                    ),
                    validator: controller.validateTitle,
                    onFieldSubmitted: (_) => _submitQuickAdd(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<TaskCategory>(
                          initialValue: _quickCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          items: TaskCategory.values.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(
                                    category.icon,
                                    size: 16,
                                    color: category.color,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category.label),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _quickCategory = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: controller.isLoading || _isAdding
                              ? null
                              : _submitQuickAdd,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ActionChip(
                        avatar: Icon(
                          _quickReminderAt != null
                              ? Icons.alarm_on
                              : Icons.alarm_add_outlined,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                        label: Text(
                          _quickReminderAt != null
                              ? DateFormatters.formatReminderShort(
                                  _quickReminderAt!,
                                )
                              : 'Set alarm',
                        ),
                        onPressed: _pickQuickReminder,
                      ),
                      if (_quickReminderAt != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _quickReminderAt = null;
                            });
                          },
                          child: const Text('Clear alarm'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigateToTasks(),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (controller.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else if (recentTasks.isEmpty)
            EmptyStateCard(
              title: 'No tasks yet',
              subtitle: 'Add a quick task above or create one with notes.',
              actionLabel: 'Create detailed task',
              onAction: _openAddScreen,
            )
          else
            ...recentTasks.map(
              (task) => TaskCard(
                task: task,
                onToggle: () => _handleToggle(task),
                onTap: () => _openDetails(task),
                onEdit: () => _openEdit(task),
                onDelete: () => _handleDelete(task),
              ),
            ),
        ],
      ),
    );
  }
}
