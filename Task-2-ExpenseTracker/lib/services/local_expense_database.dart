import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense_entry.dart';

/// Exception thrown when local database operations fail or encounter invalid data.
class DatabaseStorageException implements Exception {
  const DatabaseStorageException(this.message);

  final String message;

  @override
  String toString() => 'DatabaseStorageException: $message';
}

/// Snapshot returned when loading or importing the local SpendFlow database.
class ExpenseDatabaseSnapshot {
  const ExpenseDatabaseSnapshot({
    required this.entries,
    required this.settings,
  });

  final List<ExpenseEntry> entries;
  final BudgetSettings settings;
}

/// Versioned local JSON database abstraction backed by [SharedPreferences].
class LocalExpenseDatabase {
  LocalExpenseDatabase({Future<SharedPreferences> Function()? prefsProvider})
      : _prefsProvider = prefsProvider ?? SharedPreferences.getInstance;

  static const String entriesKey = 'spendflow_entries_v1';
  static const String settingsKey = 'spendflow_budget_v1';

  final Future<SharedPreferences> Function() _prefsProvider;

  Future<ExpenseDatabaseSnapshot> loadDatabase() async {
    try {
      final prefs = await _prefsProvider();
      final entries = _decodeEntries(prefs.getString(entriesKey));
      final settings = _decodeSettings(prefs.getString(settingsKey));
      return ExpenseDatabaseSnapshot(entries: entries, settings: settings);
    } on DatabaseStorageException {
      rethrow;
    } catch (e) {
      throw DatabaseStorageException('Failed to read local database: $e');
    }
  }

  List<ExpenseEntry> _decodeEntries(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const DatabaseStorageException(
        'Stored expense records are corrupted and could not be parsed.',
      );
    }

    if (decoded is! List) {
      throw const DatabaseStorageException(
        'Stored expense database has an unexpected schema format.',
      );
    }

    final items = <ExpenseEntry>[];
    final seenIds = <String>{};
    for (var i = 0; i < decoded.length; i++) {
      final rawEntry = decoded[i];
      if (rawEntry is! Map) continue;
      try {
        final parsed = ExpenseEntry.fromJson(
          Map<String, dynamic>.from(rawEntry),
          fallbackIndex: i,
        );
        if (seenIds.add(parsed.id)) {
          items.add(parsed);
        }
      } on FormatException {
        continue;
      }
    }
    return items;
  }

  BudgetSettings _decodeSettings(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const BudgetSettings();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return BudgetSettings.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Fall back to default budget settings if preferences payload is invalid.
    }
    return const BudgetSettings();
  }

  Future<void> saveEntries(List<ExpenseEntry> entries) async {
    try {
      final prefs = await _prefsProvider();
      final payload = jsonEncode(
        entries.map((e) => e.toJson()).toList(growable: false),
      );
      final ok = await prefs.setString(entriesKey, payload);
      if (!ok) {
        throw const DatabaseStorageException(
          'Device storage declined saving expense changes.',
        );
      }
    } on DatabaseStorageException {
      rethrow;
    } catch (e) {
      throw DatabaseStorageException('Failed to save expenses: $e');
    }
  }

  Future<void> saveSettings(BudgetSettings settings) async {
    try {
      final prefs = await _prefsProvider();
      final ok = await prefs.setString(
        settingsKey,
        jsonEncode(settings.toJson()),
      );
      if (!ok) {
        throw const DatabaseStorageException(
          'Device storage declined saving budget settings.',
        );
      }
    } on DatabaseStorageException {
      rethrow;
    } catch (e) {
      throw DatabaseStorageException('Failed to save budget settings: $e');
    }
  }

  /// Exports the full local database as a formatted JSON backup string.
  String exportBackupJson({
    required List<ExpenseEntry> entries,
    required BudgetSettings settings,
  }) {
    final payload = {
      'app': 'SpendFlow',
      'schemaVersion': ExpenseEntry.currentSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': settings.toJson(),
      'entries': entries.map((e) => e.toJson()).toList(growable: false),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Parses and validates a JSON backup payload before restoring it.
  ExpenseDatabaseSnapshot parseBackupJson(String rawJson) {
    final trimmed = rawJson.trim();
    if (trimmed.isEmpty) {
      throw const DatabaseStorageException('Backup JSON cannot be empty.');
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException {
      throw const DatabaseStorageException(
        'Invalid JSON syntax. Please paste a valid SpendFlow JSON backup.',
      );
    }

    if (decoded is! Map) {
      throw const DatabaseStorageException(
        'Backup JSON root must be a JSON object.',
      );
    }

    final rawEntries = decoded['entries'];
    if (rawEntries is! List) {
      throw const DatabaseStorageException(
        'Backup JSON is missing the "entries" list.',
      );
    }

    final parsedEntries = <ExpenseEntry>[];
    final seenIds = <String>{};
    for (var i = 0; i < rawEntries.length; i++) {
      final item = rawEntries[i];
      if (item is! Map) continue;
      final entry = ExpenseEntry.fromJson(
        Map<String, dynamic>.from(item),
        fallbackIndex: i,
      );
      if (seenIds.add(entry.id)) {
        parsedEntries.add(entry);
      }
    }

    final rawSettings = decoded['settings'];
    final settings = rawSettings is Map
        ? BudgetSettings.fromJson(Map<String, dynamic>.from(rawSettings))
        : const BudgetSettings();

    return ExpenseDatabaseSnapshot(entries: parsedEntries, settings: settings);
  }

  Future<void> clearAll() async {
    try {
      final prefs = await _prefsProvider();
      await prefs.remove(entriesKey);
      await prefs.remove(settingsKey);
    } catch (e) {
      throw DatabaseStorageException('Failed to clear local database: $e');
    }
  }
}
