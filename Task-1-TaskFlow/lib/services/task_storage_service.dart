import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_item.dart';

/// Exception thrown when local task persistence fails or stored data is invalid.
class TaskStorageException implements Exception {
  const TaskStorageException(this.message);

  final String message;

  @override
  String toString() => 'TaskStorageException: $message';
}

/// Handles reading and writing TaskFlow tasks via [SharedPreferences].
class TaskStorageService {
  TaskStorageService({Future<SharedPreferences> Function()? prefsProvider})
      : _prefsProvider = prefsProvider ?? SharedPreferences.getInstance;

  static const String storageKey = 'taskflow_tasks';

  final Future<SharedPreferences> Function() _prefsProvider;

  /// Loads persisted tasks from local storage.
  ///
  /// Throws [TaskStorageException] if the underlying preference read fails or
  /// if the stored payload cannot be parsed as a JSON list.
  Future<List<TaskItem>> loadTasks() async {
    try {
      final prefs = await _prefsProvider();
      final raw = prefs.getString(storageKey);

      if (raw == null || raw.trim().isEmpty) {
        return const [];
      }

      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const TaskStorageException(
          'Saved task data has an unexpected format.',
        );
      }

      final loaded = <TaskItem>[];
      final seenIds = <String>{};

      for (var i = 0; i < decoded.length; i++) {
        final entry = decoded[i];
        if (entry is! Map) continue;

        try {
          final item = TaskItem.fromJson(
            Map<String, dynamic>.from(entry),
            fallbackIndex: i,
          );
          if (seenIds.add(item.id)) {
            loaded.add(item);
          }
        } on FormatException {
          // Skip malformed individual records without discarding valid tasks.
          continue;
        }
      }

      return loaded;
    } on TaskStorageException {
      rethrow;
    } on FormatException {
      throw const TaskStorageException(
        'Saved task data is corrupted and could not be read.',
      );
    } catch (e) {
      throw TaskStorageException('Failed to load saved tasks: $e');
    }
  }

  /// Persists the complete [tasks] list to local storage.
  Future<void> saveTasks(List<TaskItem> tasks) async {
    try {
      final prefs = await _prefsProvider();
      final encoded = jsonEncode(
        tasks.map((task) => task.toJson()).toList(growable: false),
      );
      final saved = await prefs.setString(storageKey, encoded);
      if (!saved) {
        throw const TaskStorageException(
          'Local storage refused to save task changes.',
        );
      }
    } on TaskStorageException {
      rethrow;
    } catch (e) {
      throw TaskStorageException('Failed to save tasks: $e');
    }
  }

  /// Removes all persisted task records from local storage.
  Future<void> clearTasks() async {
    try {
      final prefs = await _prefsProvider();
      await prefs.remove(storageKey);
    } catch (e) {
      throw TaskStorageException('Failed to clear saved tasks: $e');
    }
  }
}
