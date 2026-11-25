import 'dart:collection';

import 'package:material_ui/material_ui.dart';

import '../models/task_item.dart';
import '../services/task_storage_service.dart';

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

/// Manages TaskFlow tasks, filters, search, statistics, validation, and storage.
class TaskController extends ChangeNotifier {
  TaskController({TaskStorageService? storageService})
      : _storageService = storageService ?? TaskStorageService();

  static const int maxTitleLength = 100;
  static const int maxNotesLength = 300;

  final TaskStorageService _storageService;

  final List<TaskItem> _tasks = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isSaving = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';
  TaskStatusFilter _selectedStatusFilter = TaskStatusFilter.all;

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

  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  int get pendingCount => totalCount - completedCount;
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

  /// Loads tasks from local storage once, guarding against duplicate loads.
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
      loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _tasks
        ..clear()
        ..addAll(loaded);
      _hasLoaded = true;
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
    );

    _tasks.insert(0, newTask);
    _errorMessage = null;
    notifyListeners();

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
      message: 'Task added successfully.',
      task: newTask,
    );
  }

  Future<TaskActionResult> updateTask({
    required String id,
    required String title,
    required TaskCategory category,
    String notes = '',
    bool? isCompleted,
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
    final updated = existing.copyWith(
      title: title.trim(),
      notes: notes.trim(),
      category: category,
      isCompleted: isCompleted ?? existing.isCompleted,
      updatedAt: DateTime.now(),
    );

    _tasks[index] = updated;
    _errorMessage = null;
    notifyListeners();

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
    final toggled = current.copyWith(
      isCompleted: !current.isCompleted,
      updatedAt: DateTime.now(),
    );

    _tasks[index] = toggled;
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
}
