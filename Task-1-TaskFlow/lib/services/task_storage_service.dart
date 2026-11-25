import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_item.dart';

/// Persisted reminder & alert preferences for TaskFlow.
class TaskAlertSettings {
  const TaskAlertSettings({
    this.notificationEmail = '',
    this.soundEnabled = true,
  });

  final String notificationEmail;
  final bool soundEnabled;

  Map<String, dynamic> toJson() => {
        'notificationEmail': notificationEmail,
        'soundEnabled': soundEnabled,
      };

  factory TaskAlertSettings.fromJson(Map<String, dynamic> json) {
    final email = json['notificationEmail'];
    final sound = json['soundEnabled'];
    return TaskAlertSettings(
      notificationEmail: email is String ? email.trim() : '',
      soundEnabled: sound is bool ? sound : true,
    );
  }
}

/// Exception thrown when local task persistence fails or stored data is invalid.
class TaskStorageException implements Exception {
  const TaskStorageException(this.message);

  final String message;

  @override
  String toString() => 'TaskStorageException: $message';
}

/// Handles reading and writing TaskFlow tasks and preferences via [SharedPreferences].
class TaskStorageService {
  TaskStorageService({Future<SharedPreferences> Function()? prefsProvider})
      : _prefsProvider = prefsProvider ?? SharedPreferences.getInstance;

  static const String storageKey = 'taskflow_tasks';
  static const String settingsKey = 'taskflow_settings';

  final Future<SharedPreferences> Function() _prefsProvider;

  /// Loads persisted tasks from local storage.
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

  Future<TaskAlertSettings> loadSettings() async {
    try {
      final prefs = await _prefsProvider();
      final raw = prefs.getString(settingsKey);
      if (raw == null || raw.trim().isEmpty) {
        return const TaskAlertSettings();
      }
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) return const TaskAlertSettings();
      return TaskAlertSettings.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return const TaskAlertSettings();
    }
  }

  Future<void> saveSettings(TaskAlertSettings settings) async {
    try {
      final prefs = await _prefsProvider();
      await prefs.setString(settingsKey, jsonEncode(settings.toJson()));
    } catch (e) {
      throw TaskStorageException('Failed to save alert settings: $e');
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
