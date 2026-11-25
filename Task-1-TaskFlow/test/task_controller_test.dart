import 'dart:convert';

import 'package:codomax_todo_app/controllers/task_controller.dart';
import 'package:codomax_todo_app/models/task_item.dart';
import 'package:codomax_todo_app/services/task_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TaskController & TaskStorageService', () {
    test('loads legacy tasks and guards against duplicate loading', () async {
      SharedPreferences.setMockInitialValues({
        TaskStorageService.storageKey: jsonEncode([
          {
            'title': 'Legacy study task',
            'category': 'Study',
            'completed': true,
          },
          {
            'title': 'Legacy work task',
            'category': 'Work',
            'completed': false,
          },
        ]),
      });

      final controller = TaskController();
      await Future.wait([
        controller.loadTasks(),
        controller.loadTasks(),
      ]);
      await controller.loadTasks();

      expect(controller.tasks.length, 2);
      expect(controller.totalCount, 2);
      expect(controller.completedCount, 1);
      expect(controller.pendingCount, 1);
      expect(controller.completionPercentage, 50);
    });

    test('handles corrupted stored JSON safely and allows reset', () async {
      SharedPreferences.setMockInitialValues({
        TaskStorageService.storageKey: '{not-valid-json',
      });

      final controller = TaskController();
      await controller.loadTasks();

      expect(controller.errorMessage, isNotNull);
      expect(controller.tasks, isEmpty);

      final resetOk = await controller.resetCorruptedStorage();
      expect(resetOk, isTrue);
      expect(controller.errorMessage, isNull);
    });

    test('validates empty, whitespace, length, and duplicate titles', () async {
      final controller = TaskController();
      await controller.loadTasks();

      expect(controller.validateTitle(''), isNotNull);
      expect(controller.validateTitle('   \t\n '), isNotNull);
      expect(
        controller.validateTitle('a' * (TaskController.maxTitleLength + 1)),
        isNotNull,
      );

      final added = await controller.addTask(
        title: 'Prepare Internship Report',
        category: TaskCategory.work,
      );
      expect(added.success, isTrue);

      expect(
        controller.validateTitle('  prepare internship report  '),
        'A task with this title already exists.',
      );
      expect(
        controller.validateTitle(
          'Prepare Internship Report',
          excludeTaskId: added.task!.id,
        ),
        isNull,
      );
    });

    test('persists add, edit, toggle, reopen, and delete across restarts', () async {
      final controller1 = TaskController();
      await controller1.loadTasks();

      final add1 = await controller1.addTask(
        title: 'Revise Flutter Navigation',
        category: TaskCategory.study,
        notes: 'Check back navigation and rail',
      );
      expect(add1.success, isTrue);

      final add2 = await controller1.addTask(
        title: 'Buy groceries',
        category: TaskCategory.personal,
      );
      expect(add2.success, isTrue);

      final edit1 = await controller1.updateTask(
        id: add1.task!.id,
        title: 'Master Flutter Navigation',
        category: TaskCategory.work,
        notes: 'Verified responsive shell',
      );
      expect(edit1.success, isTrue);

      await controller1.toggleTask(add1.task!.id);
      expect(controller1.completedCount, 1);
      expect(controller1.pendingCount, 1);

      // Reopen completed task as pending.
      await controller1.toggleTask(add1.task!.id);
      expect(controller1.completedCount, 0);
      expect(controller1.pendingCount, 2);

      // Complete again and delete second task.
      await controller1.toggleTask(add1.task!.id);
      await controller1.deleteTask(add2.task!.id);

      // Simulate app restart with a fresh controller reading SharedPreferences.
      final controller2 = TaskController();
      await controller2.loadTasks();

      expect(controller2.tasks.length, 1);
      final restored = controller2.tasks.first;
      expect(restored.title, 'Master Flutter Navigation');
      expect(restored.category, TaskCategory.work);
      expect(restored.notes, 'Verified responsive shell');
      expect(restored.isCompleted, isTrue);
    });

    test('filters by category, status, and search query accurately', () async {
      final controller = TaskController();
      await controller.loadTasks();

      final t1 = await controller.addTask(
        title: 'Finish Dart unit tests',
        category: TaskCategory.study,
      );
      await controller.addTask(
        title: 'Submit Codomax PR',
        category: TaskCategory.work,
      );
      await controller.addTask(
        title: 'Evening walk',
        category: TaskCategory.personal,
      );
      await controller.toggleTask(t1.task!.id);

      controller.setStatusFilter(TaskStatusFilter.completed);
      expect(controller.filteredTasks.length, 1);
      expect(controller.filteredTasks.first.title, 'Finish Dart unit tests');

      controller.setStatusFilter(TaskStatusFilter.pending);
      expect(controller.filteredTasks.length, 2);

      controller.setCategoryFilter('Work');
      expect(controller.filteredTasks.length, 1);
      expect(controller.filteredTasks.first.title, 'Submit Codomax PR');

      controller.setSearchQuery('codomax');
      expect(controller.filteredTasks.length, 1);

      controller.setSearchQuery('nonexistent');
      expect(controller.filteredTasks, isEmpty);

      controller.clearFilters();
      expect(controller.filteredTasks.length, 3);
    });

    test('triggers due alarms, snoozes, and persists reminder settings',
        () async {
      final controller = TaskController(enableReminderTicker: false);
      await controller.loadTasks();

      final pastTime = DateTime.now().subtract(const Duration(minutes: 1));
      final added = await controller.addTask(
        title: 'Take medicine',
        category: TaskCategory.personal,
        reminderAt: pastTime,
      );
      expect(added.success, isTrue);
      expect(controller.activeAlarmTask?.id, added.task!.id);

      final snoozed = await controller.snoozeReminder(
        added.task!.id,
        duration: const Duration(minutes: 10),
      );
      expect(snoozed.success, isTrue);
      expect(controller.activeAlarmTask, isNull);
      expect(snoozed.task!.reminderAt!.isAfter(DateTime.now()), isTrue);

      expect(controller.validateEmail('invalid-email'), isNotNull);
      final savedSettings = await controller.saveAlertSettings(
        notificationEmail: 'user@example.com',
        soundEnabled: false,
      );
      expect(savedSettings.success, isTrue);

      final controller2 = TaskController(enableReminderTicker: false);
      await controller2.loadTasks();
      expect(controller2.notificationEmail, 'user@example.com');
      expect(controller2.soundEnabled, isFalse);
      expect(controller2.tasks.first.reminderAt, isNotNull);
    });
  });
}
