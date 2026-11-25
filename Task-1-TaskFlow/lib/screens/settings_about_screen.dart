import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../controllers/task_controller.dart';
import '../controllers/task_scope.dart';
import '../services/reminder_platform.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/feedback_banner.dart';

/// Settings and About screen presenting workspace utilities, alarms, email settings, and app info.
class SettingsAboutScreen extends StatefulWidget {
  const SettingsAboutScreen({super.key});

  @override
  State<SettingsAboutScreen> createState() => _SettingsAboutScreenState();
}

class _SettingsAboutScreenState extends State<SettingsAboutScreen> {
  final GlobalKey<FormState> _settingsFormKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _initialized = false;
  String _browserPermission = browserNotificationPermission;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _emailController.text = TaskScope.read(context).notificationEmail;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences(TaskController controller, bool soundEnabled) async {
    if (!(_settingsFormKey.currentState?.validate() ?? false)) return;
    final result = await controller.saveAlertSettings(
      notificationEmail: _emailController.text,
      soundEnabled: soundEnabled,
    );
    if (!mounted) return;
    showAppSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );
  }

  Future<void> _enableBrowserAlerts() async {
    final permission = await requestBrowserNotificationPermission();
    if (!mounted) return;
    setState(() {
      _browserPermission = permission;
    });
    showAppSnackBar(
      context,
      message: permission == 'granted'
          ? 'Browser notifications enabled.'
          : permission == 'denied'
              ? 'Browser notifications are blocked in browser settings.'
              : 'Notification permission status: $permission.',
      isError: permission == 'denied',
    );
  }

  Future<void> _clearCompleted(BuildContext context) async {
    final controller = TaskScope.read(context);
    final count = controller.completedCount;
    if (count == 0) return;

    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Clear Completed Tasks',
      message:
          'Remove $count completed ${count == 1 ? 'task' : 'tasks'} from your list? Pending tasks will be kept.',
      confirmLabel: 'Clear',
    );
    if (!confirmed || !context.mounted) return;

    final result = await controller.clearCompletedTasks();
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );
  }

  Future<void> _copyChecklist(BuildContext context) async {
    final controller = TaskScope.read(context);
    if (controller.tasks.isEmpty) {
      showAppSnackBar(
        context,
        message: 'No tasks available to copy yet.',
        isError: true,
      );
      return;
    }

    final buffer = StringBuffer('TaskFlow Checklist\n');
    for (final task in controller.tasks) {
      final mark = task.isCompleted ? 'x' : ' ';
      buffer.writeln('- [$mark] ${task.title} (${task.category.label})');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString().trimRight()));
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      message: 'Copied ${controller.totalCount} tasks to clipboard.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = TaskScope.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings & About',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage alarms, reminder preferences, storage, and daily utilities.',
            style: TextStyle(
              fontSize: 13.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryLight,
                  AppTheme.primaryDark,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TaskFlow',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Daily Productivity & Task Companion',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: Form(
              key: _settingsFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alarms, Alerts & Email',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Scheduled alarms trigger an in-app alert, optional sound chime, and browser notification while TaskFlow is open. Saving an email pre-fills email reminders via your mail app.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Material(
                    color: AppTheme.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SwitchListTile(
                      value: controller.soundEnabled,
                      activeThumbColor: AppTheme.primary,
                      title: const Text(
                        'Alarm Sound Chime',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Play an audible chime when a scheduled alarm fires',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      onChanged: (value) =>
                          _savePreferences(controller, value),
                    ),
                  ),
                  if (isBrowserAlertSupported) ...[
                    const SizedBox(height: 12),
                    _InfoTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Browser Alerts',
                      subtitle: _browserPermission == 'granted'
                          ? 'Enabled in this browser'
                          : _browserPermission == 'denied'
                              ? 'Blocked in browser site settings'
                              : 'Permission not requested yet',
                      trailing: _browserPermission == 'granted'
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Allowed',
                                style: TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : TextButton(
                              onPressed: _enableBrowserAlerts,
                              child: const Text('Enable'),
                            ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Reminder Email (optional)',
                      hintText: 'you@example.com',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                    validator: controller.validateEmail,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _savePreferences(
                            controller,
                            controller.soundEnabled,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Save Email'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controller.triggerTestAlarm,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.alarm_on, size: 18),
                          label: const Text('Test Alarm'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data & Storage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoTile(
                  icon: Icons.storage_outlined,
                  title: 'Local Storage',
                  subtitle: 'Saved automatically on this device',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 22, color: AppTheme.border),
                _InfoTile(
                  icon: Icons.analytics_outlined,
                  title: 'Workspace Summary',
                  subtitle:
                      '${controller.totalCount} total • ${controller.pendingCount} pending • ${controller.completedCount} completed (${controller.completionPercentage}%)',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.totalCount > 0
                            ? () => _copyChecklist(context)
                            : null,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.copy_all_outlined, size: 18),
                        label: const Text('Copy Checklist'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.completedCount > 0
                            ? () => _clearCompleted(context)
                            : null,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          foregroundColor: AppTheme.danger,
                          side: BorderSide(
                            color: controller.completedCount > 0
                                ? AppTheme.danger
                                : AppTheme.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.cleaning_services_outlined,
                          size: 18,
                        ),
                        label: Text(
                          controller.completedCount > 0
                              ? 'Clear Done (${controller.completedCount})'
                              : 'Clear Done',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About TaskFlow',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'TaskFlow is designed for focused daily task management across Personal, Study, and Work goals. Organize priorities, schedule task alarms, track completion progress in real time, and keep your tasks saved locally across sessions.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FeaturePill(
                      icon: Icons.alarm_on_outlined,
                      label: 'Scheduled Alarms',
                    ),
                    _FeaturePill(
                      icon: Icons.bolt_outlined,
                      label: 'Instant Local Sync',
                    ),
                    _FeaturePill(
                      icon: Icons.filter_alt_outlined,
                      label: 'Smart Filters & Search',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
