import 'dart:async';
import 'dart:collection';

import 'package:material_ui/material_ui.dart';

import '../models/task_item.dart';
import '../services/reminder_platform.dart';
import '../services/task_storage_service.dart';
import '../utils/date_formatters.dart';

/// Result returned by task mutations so the UI can show accurate feedback.
class TaskActionResult {
  const TaskActionResult({
    required this.success,
    required this.message,
    this.task,
  });

  final bool success;
  final String message;
  final TaskItem? task;
}

/// Manages TaskFlow tasks, filters, search, statistics, validation, alarms, and storage.
class TaskController extends ChangeNotifier {
  TaskController({
    TaskStorageService? storageService,
    this.enableReminderTicker = true,
  }) : _storageService = storageService ?? TaskStorageService();

  static const int maxTitleLength = 100;
  static const int maxNotesLength = 300;
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final TaskStorageService _storageService;
  final bool enableReminderTicker;

  final List<TaskItem> _tasks = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isSaving = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';
  TaskStatusFilter _selectedStatusFilter = TaskStatusFilter.all;

  String _notificationEmail = '';
  bool _soundEnabled = true;

  TaskItem? _activeAlarmTask;
  final Set<String> _triggeredAlarmKeys = <String>{};
  Timer? _reminderTimer;

  Future<void>? _inFlightLoad;
  Future<void> _saveQueue = Future<void>.value();
  int _idCounter = 0;

  UnmodifiableListView<TaskItem> get tasks => UnmodifiableListView(_tasks);
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String get selectedCategoryFilter => _selectedCategoryFilter;
  TaskStatusFilter get selectedStatusFilter => _selectedStatusFilter;

  String get notificationEmail => _notificationEmail;
  bool get soundEnabled => _soundEnabled;
  TaskItem? get activeAlarmTask => _activeAlarmTask;

  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  int get pendingCount => totalCount - completedCount;
  int get activeRemindersCount =>
      _tasks.where((t) => t.hasReminder && !t.isCompleted).length;
  double get completionProgress =>
      totalCount == 0 ? 0.0 : completedCount / totalCount;
  int get completionPercentage => (completionProgress * 100).round();

  bool get hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _selectedCategoryFilter != 'All' ||
      _selectedStatusFilter != TaskStatusFilter.all;

  int countByCategory(TaskCategory category) {
    return _tasks.where((t) => t.category == category).length;
  }

  int completedCountByCategory(TaskCategory category) {
    return _tasks
        .where((t) => t.category == category && t.isCompleted)
        .length;
  }

  /// Tasks filtered by category, completion status, and search query.
  List<TaskItem> get filteredTasks {
    final query = _searchQuery.trim().toLowerCase();

    return _tasks.where((task) {
      if (_selectedCategoryFilter != 'All' &&
          task.category.label != _selectedCategoryFilter) {
        return false;
      }

      switch (_selectedStatusFilter) {
        case TaskStatusFilter.all:
          break;
        case TaskStatusFilter.pending:
          if (task.isCompleted) return false;
        case TaskStatusFilter.completed:
          if (!task.isCompleted) return false;
      }

      if (query.isNotEmpty) {
        final inTitle = task.title.toLowerCase().contains(query);
        final inNotes = task.notes.toLowerCase().contains(query);
        if (!inTitle && !inNotes) return false;
      }

      return true;
    }).toList(growable: false);
  }

  TaskItem? findById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  /// Validates a task title for emptiness, whitespace, length, and duplicates.
  String? validateTitle(String? rawValue, {String? excludeTaskId}) {
    final trimmed = rawValue?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Task title cannot be empty.';
    }
    if (trimmed.length > maxTitleLength) {
      return 'Task title must be $maxTitleLength characters or fewer.';
    }

    final normalized = trimmed.toLowerCase();
    final duplicateExists = _tasks.any(
      (task) =>
          task.id != excludeTaskId &&
          task.title.trim().toLowerCase() == normalized,
    );
    if (duplicateExists) {
      return 'A task with this title already exists.';
    }
    return null;
  }

  String? validateNotes(String? rawValue) {
    final trimmed = rawValue?.trim() ?? '';
    if (trimmed.length > maxNotesLength) {
      return 'Notes must be $maxNotesLength characters or fewer.';
    }
    return null;
  }

  String? validateEmail(String? rawValue) {
    final trimmed = rawValue?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Enter a valid email address (e.g., name@example.com).';
    }
    return null;
  }

  /// Loads tasks and reminder settings from local storage once.
  Future<void> loadTasks({bool forceReload = false}) {
    if (_inFlightLoad != null) {
      return _inFlightLoad!;
    }
    if (_hasLoaded && !forceReload) {
      return Future<void>.value();
    }

    _inFlightLoad = _performLoad();
    return _inFlightLoad!;
  }

  Future<void> _performLoad() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _storageService.loadTasks();
      final settings = await _storageService.loadSettings();
      loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _tasks
        ..clear()
        ..addAll(loaded);
      _notificationEmail = settings.notificationEmail;
      _soundEnabled = settings.soundEnabled;
      _hasLoaded = true;
      _startReminderTicker();
      _checkDueReminders();
    } on TaskStorageException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unexpected error loading tasks: $e';
    } finally {
      _isLoading = false;
      _inFlightLoad = null;
      notifyListeners();
    }
  }

  void _startReminderTicker() {
    if (!enableReminderTicker) return;
    _reminderTimer ??= Timer.periodic(
      const Duration(seconds: 5),
      (_) => checkDueRemindersNow(),
    );
  }

  /// Scans pending tasks with active alarms and fires the next due reminder.
  void checkDueRemindersNow() {
    _checkDueReminders();
  }

  void _checkDueReminders() {
    if (_activeAlarmTask != null) return;

    final now = DateTime.now();
    TaskItem? nextDue;
    for (final task in _tasks) {
      if (task.reminderAt == null || task.isCompleted || task.reminderDismissed) {
        continue;
      }
      if (task.reminderAt!.isAfter(now)) continue;

      final triggerKey =
          '${task.id}_${task.reminderAt!.millisecondsSinceEpoch}';
      if (_triggeredAlarmKeys.contains(triggerKey)) continue;

      if (nextDue == null ||
          task.reminderAt!.isBefore(nextDue.reminderAt!)) {
        nextDue = task;
      }
    }

    if (nextDue == null) return;

    final key =
        '${nextDue.id}_${nextDue.reminderAt!.millisecondsSinceEpoch}';
    _triggeredAlarmKeys.add(key);
    _activeAlarmTask = nextDue;
    notifyListeners();

    unawaited(
      triggerBrowserAlert(
        title: 'TaskFlow Alarm • ${nextDue.category.label}',
        body: 'Time to complete: ${nextDue.title}',
        playSound: _soundEnabled,
      ),
    );
  }

  Future<void> triggerTestAlarm() async {
    final now = DateTime.now();
    final sampleTask = _tasks.isNotEmpty
        ? _tasks.first
        : TaskItem(
            id: 'test_alarm_preview',
            title: 'Sample Task Reminder Alarm',
            category: TaskCategory.personal,
            isCompleted: false,
            createdAt: now,
            updatedAt: now,
            reminderAt: now,
          );

    _activeAlarmTask = sampleTask;
    notifyListeners();

    await triggerBrowserAlert(
      title: 'TaskFlow Alarm Test',
      body: 'Alerts and sound chimes are working for "${sampleTask.title}".',
      playSound: _soundEnabled,
    );
  }

  Future<void> dismissActiveAlarm({bool markReminderDismissed = true}) async {
    final alarmTask = _activeAlarmTask;
    _activeAlarmTask = null;

    if (alarmTask != null &&
        markReminderDismissed &&
        alarmTask.id != 'test_alarm_preview') {
      final index = _tasks.indexWhere((t) => t.id == alarmTask.id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          reminderDismissed: true,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
        await _enqueueSave();
        _checkDueReminders();
        return;
      }
    }

    notifyListeners();
    _checkDueReminders();
  }

  Future<TaskActionResult> snoozeReminder(
    String id, {
    Duration duration = const Duration(minutes: 10),
  }) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) {
      _activeAlarmTask = null;
      notifyListeners();
      return const TaskActionResult(
        success: false,
        message: 'Task could not be found.',
      );
    }

    final snoozedAt = DateTime.now().add(duration);
    final updated = _tasks[index].copyWith(
      reminderAt: snoozedAt,
      reminderDismissed: false,
      updatedAt: DateTime.now(),
    );
    _tasks[index] = updated;
    if (_activeAlarmTask?.id == id) {
      _activeAlarmTask = null;
    }
    notifyListeners();

    final saved = await _enqueueSave();
    return TaskActionResult(
      success: saved,
      message: saved
          ? 'Alarm snoozed until ${DateFormatters.formatReminderShort(snoozedAt)}.'
          : (_errorMessage ?? 'Failed to snooze alarm.'),
      task: updated,
    );
  }

  Future<TaskActionResult> saveAlertSettings({
    required String notificationEmail,
    required bool soundEnabled,
  }) async {
    final emailError = validateEmail(notificationEmail);
    if (emailError != null) {
      return TaskActionResult(success: false, message: emailError);
    }

    _notificationEmail = notificationEmail.trim();
    _soundEnabled = soundEnabled;
    notifyListeners();

    try {
      await _storageService.saveSettings(
        TaskAlertSettings(
          notificationEmail: _notificationEmail,
          soundEnabled: _soundEnabled,
        ),
      );
      return const TaskActionResult(
        success: true,
        message: 'Reminder & alert preferences saved.',
      );
    } on TaskStorageException catch (e) {
      return TaskActionResult(success: false, message: e.message);
    }
  }

  Future<bool> sendEmailReminderForTask(
    TaskItem task, {
    String? overrideEmail,
  }) {
    final recipient = (overrideEmail ?? _notificationEmail).trim();
    final reminderText = task.reminderAt != null
        ? DateFormatters.formatDateTime(task.reminderAt!)
        : 'Not scheduled';
    final notesLine =
        task.notes.isNotEmpty ? '\nNotes: ${task.notes}' : '';

    return openEmailDraft(
      toEmail: recipient,
      subject: 'TaskFlow Reminder: ${task.title}',
      body: 'Reminder to complete your task:\n\n'
          'Task: ${task.title}\n'
          'Category: ${task.category.label}\n'
          'Scheduled Time: $reminderText\n'
          'Status: ${task.isCompleted ? 'Completed' : 'Pending'}'
          '$notesLine\n\n'
          '— Sent from TaskFlow',
    );
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String categoryFilter) {
    if (_selectedCategoryFilter == categoryFilter) return;
    _selectedCategoryFilter = categoryFilter;
    notifyListeners();
  }

  void setStatusFilter(TaskStatusFilter statusFilter) {
    if (_selectedStatusFilter == statusFilter) return;
    _selectedStatusFilter = statusFilter;
    notifyListeners();
  }

  void clearFilters() {
    if (!hasActiveFilters) return;
    _searchQuery = '';
    _selectedCategoryFilter = 'All';
    _selectedStatusFilter = TaskStatusFilter.all;
    notifyListeners();
  }

  String _generateId() {
    _idCounter++;
    return 'task_${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  Future<TaskActionResult> addTask({
    required String title,
    required TaskCategory category,
    String notes = '',
    DateTime? reminderAt,
  }) async {
    if (_isLoading) {
      return const TaskActionResult(
        success: false,
        message: 'Please wait until tasks finish loading.',
      );
    }

    final titleError = validateTitle(title);
    if (titleError != null) {
      return TaskActionResult(success: false, message: titleError);
    }

    final notesError = validateNotes(notes);
    if (notesError != null) {
      return TaskActionResult(success: false, message: notesError);
    }

    final now = DateTime.now();
    final newTask = TaskItem(
      id: _generateId(),
      title: title.trim(),
      notes: notes.trim(),
      category: category,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      reminderAt: reminderAt,
      reminderDismissed: false,
    );

    _tasks.insert(0, newTask);
    _errorMessage = null;
    notifyListeners();
    _checkDueReminders();

    final saved = await _enqueueSave();
    if (!saved) {
      return TaskActionResult(
        success: false,
        message: _errorMessage ?? 'Task added in memory, but failed to save.',
        task: newTask,
      );
    }

    return TaskActionResult(
      success: true,
      message: reminderAt != null
          ? 'Task added with alarm for ${DateFormatters.formatReminderShort(reminderAt)}.'
          : 'Task added successfully.',
      task: newTask,
    );
  }

  Future<TaskActionResult> updateTask({
    required String id,
    required String title,
    required TaskCategory category,
    String notes = '',
    bool? isCompleted,
    DateTime? reminderAt,
    bool clearReminder = false,
  }) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) {
      return const TaskActionResult(
        success: false,
        message: 'Task could not be found.',
      );
    }

    final titleError = validateTitle(title, excludeTaskId: id);
    if (titleError != null) {
      return TaskActionResult(success: false, message: titleError);
    }

    final notesError = validateNotes(notes);
    if (notesError != null) {
      return TaskActionResult(success: false, message: notesError);
    }

    final existing = _tasks[index];
    final reminderChanged = clearReminder || reminderAt != existing.reminderAt;
    final updated = existing.copyWith(
      title: title.trim(),
      notes: notes.trim(),
      category: category,
      isCompleted: isCompleted ?? existing.isCompleted,
      updatedAt: DateTime.now(),
      reminderAt: reminderAt,
      clearReminder: clearReminder,
      reminderDismissed: reminderChanged ? false : existing.reminderDismissed,
    );

    _tasks[index] = updated;
    if (_activeAlarmTask?.id == id && (updated.isCompleted || clearReminder)) {
      _activeAlarmTask = null;
    }
    _errorMessage = null;
    notifyListeners();
    _checkDueReminders();

    final saved = await _enqueueSave();
    if (!saved) {
      return TaskActionResult(
        success: false,
        message: _errorMessage ?? 'Failed to save task updates.',
        task: updated,
      );
    }

    return TaskActionResult(
      success: true,
      message: 'Task updated successfully.',
      task: updated,
    );
  }

  Future<TaskActionResult> toggleTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) {
      return const TaskActionResult(
        success: false,
        message: 'Task could not be found.',
      );
    }

    final current = _tasks[index];
    final nextCompleted = !current.isCompleted;
    final toggled = current.copyWith(
      isCompleted: nextCompleted,
      reminderDismissed: nextCompleted ? true : false,
      updatedAt: DateTime.now(),
    );

    _tasks[index] = toggled;
    if (_activeAlarmTask?.id == id && nextCompleted) {
      _activeAlarmTask = null;
    }
    _errorMessage = null;
    notifyListeners();

    final saved = await _enqueueSave();
    if (!saved) {
      return TaskActionResult(
        success: false,
        message: _errorMessage ?? 'Failed to save task status.',
        task: toggled,
      );
    }

    return TaskActionResult(
      success: true,
      message: toggled.isCompleted
          ? 'Task marked as completed.'
          : 'Task reopened as pending.',
      task: toggled,
    );
  }

  Future<TaskActionResult> deleteTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) {
      return const TaskActionResult(
        success: false,
        message: 'Task could not be found.',
      );
    }

    final removed = _tasks.removeAt(index);
    if (_activeAlarmTask?.id == id) {
      _activeAlarmTask = null;
    }
    _errorMessage = null;
    notifyListeners();

    final saved = await _enqueueSave();
    if (!saved) {
      return TaskActionResult(
        success: false,
        message: _errorMessage ?? 'Failed to persist task deletion.',
        task: removed,
      );
    }

    return TaskActionResult(
      success: true,
      message: 'Task deleted successfully.',
      task: removed,
    );
  }

  Future<TaskActionResult> clearCompletedTasks() async {
    final completed = _tasks.where((t) => t.isCompleted).length;
    if (completed == 0) {
      return const TaskActionResult(
        success: false,
        message: 'There are no completed tasks to clear.',
      );
    }

    _tasks.removeWhere((t) => t.isCompleted);
    _errorMessage = null;
    notifyListeners();

    final saved = await _enqueueSave();
    if (!saved) {
      return TaskActionResult(
        success: false,
        message: _errorMessage ?? 'Failed to save after clearing tasks.',
      );
    }

    return TaskActionResult(
      success: true,
      message: 'Cleared $completed completed ${completed == 1 ? 'task' : 'tasks'}.',
    );
  }

  Future<bool> resetCorruptedStorage() async {
    try {
      await _storageService.clearTasks();
      _tasks.clear();
      _activeAlarmTask = null;
      _errorMessage = null;
      _hasLoaded = true;
      notifyListeners();
      return true;
    } on TaskStorageException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Chains save calls sequentially so rapid user actions never race or lose data.
  Future<bool> _enqueueSave() {
    final completer = _saveQueue.then((_) => _persistSnapshot());
    _saveQueue = completer.then((_) {});
    return completer;
  }

  Future<bool> _persistSnapshot() async {
    _isSaving = true;
    notifyListeners();

    try {
      final snapshot = List<TaskItem>.unmodifiable(_tasks);
      await _storageService.saveTasks(snapshot);
      return true;
    } on TaskStorageException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Unexpected error saving tasks: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    _reminderTimer = null;
    super.dispose();
  }
}
