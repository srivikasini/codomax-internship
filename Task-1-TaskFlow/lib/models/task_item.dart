import 'package:material_ui/material_ui.dart';

/// Supported task categories in TaskFlow.
enum TaskCategory {
  personal,
  study,
  work;

  String get label {
    switch (this) {
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.study:
        return 'Study';
      case TaskCategory.work:
        return 'Work';
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.personal:
        return const Color(0xFF8E5CE6);
      case TaskCategory.study:
        return const Color(0xFF2196F3);
      case TaskCategory.work:
        return const Color(0xFFFF9800);
    }
  }

  IconData get icon {
    switch (this) {
      case TaskCategory.personal:
        return Icons.person_outline;
      case TaskCategory.study:
        return Icons.school_outlined;
      case TaskCategory.work:
        return Icons.work_outline;
    }
  }

  static TaskCategory fromString(String? raw) {
    final normalized = raw?.trim().toLowerCase() ?? '';
    switch (normalized) {
      case 'study':
        return TaskCategory.study;
      case 'work':
        return TaskCategory.work;
      case 'personal':
      default:
        return TaskCategory.personal;
    }
  }
}

/// Separate status filter options for viewing tasks.
enum TaskStatusFilter {
  all,
  pending,
  completed;

  String get label {
    switch (this) {
      case TaskStatusFilter.all:
        return 'All';
      case TaskStatusFilter.pending:
        return 'Pending';
      case TaskStatusFilter.completed:
        return 'Completed';
    }
  }
}

/// Immutable representation of a TaskFlow to-do item.
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.category,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
  });

  final String id;
  final String title;
  final String notes;
  final TaskCategory category;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskItem copyWith({
    String? id,
    String? title,
    String? notes,
    TaskCategory? category,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'category': category.label,
      'completed': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Parses a task map, supporting both current schema and legacy TaskFlow maps
  /// that only stored `title`, `category`, and `completed`.
  factory TaskItem.fromJson(Map<String, dynamic> json, {int fallbackIndex = 0}) {
    final now = DateTime.now();
    final rawTitle = json['title'];
    final title = rawTitle is String ? rawTitle.trim() : '';
    if (title.isEmpty) {
      throw const FormatException('Task item is missing a valid title.');
    }

    final rawCreatedAt = json['createdAt'];
    final parsedCreatedAt = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt) ?? now
        : now;

    final rawUpdatedAt = json['updatedAt'];
    final parsedUpdatedAt = rawUpdatedAt is String
        ? DateTime.tryParse(rawUpdatedAt) ?? parsedCreatedAt
        : parsedCreatedAt;

    final rawId = json['id'];
    final id = (rawId is String && rawId.trim().isNotEmpty)
        ? rawId.trim()
        : 'legacy_${parsedCreatedAt.microsecondsSinceEpoch}_$fallbackIndex';

    final rawNotes = json['notes'];
    final notes = rawNotes is String ? rawNotes.trim() : '';

    final rawCompleted = json['completed'];
    final isCompleted = rawCompleted is bool ? rawCompleted : false;

    final rawCategory = json['category'];
    final category = TaskCategory.fromString(
      rawCategory is String ? rawCategory : null,
    );

    return TaskItem(
      id: id,
      title: title,
      notes: notes,
      category: category,
      isCompleted: isCompleted,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }
}
