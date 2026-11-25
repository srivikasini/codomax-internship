import 'package:codomax_todo_app/controllers/task_controller.dart';
import 'package:codomax_todo_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('Dashboard quick add, validation, toggle, and stats update',
      (WidgetTester tester) async {
    final controller = TaskController();
    await tester.pumpWidget(TaskFlowApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('TaskFlow'), findsOneWidget);
    expect(find.text('0% completed'), findsOneWidget);

    // Attempt empty submission -> validation error shown, no task added.
    await tapVisible(tester, find.text('Add'));
    expect(find.text('Task title cannot be empty.'), findsOneWidget);
    expect(controller.totalCount, 0);

    // Attempt whitespace-only submission -> validation error shown.
    await tester.enterText(find.byType(TextFormField).first, '   ');
    await tapVisible(tester, find.text('Add'));
    expect(find.text('Task title cannot be empty.'), findsOneWidget);
    expect(controller.totalCount, 0);

    // Add valid task.
    await tester.enterText(
      find.byType(TextFormField).first,
      'Review Flutter layout',
    );
    await tapVisible(tester, find.text('Add'));

    expect(controller.totalCount, 1);
    expect(find.text('Review Flutter layout'), findsOneWidget);
    expect(find.text('0 of 1 tasks completed'), findsOneWidget);

    // Toggle task completion via Checkbox.
    await tapVisible(tester, find.byType(Checkbox).first);

    expect(controller.completedCount, 1);
    expect(find.text('100% completed'), findsOneWidget);
  });

  testWidgets('Multi-screen navigation, filters, details, edit, and delete',
      (WidgetTester tester) async {
    final controller = TaskController();
    await tester.pumpWidget(TaskFlowApp(controller: controller));
    await tester.pumpAndSettle();

    // Navigate to Add Task screen via mobile FAB.
    await tapVisible(tester, find.text('Add Task'));
    expect(find.text('Add New Task'), findsOneWidget);

    // Create task with category Study.
    await tester.enterText(
      find.byType(TextFormField).first,
      'Study Dart streams',
    );
    await tapVisible(tester, find.text('Study'));
    await tapVisible(tester, find.text('Create Task'));

    // Switch to My Tasks tab.
    await tapVisible(tester, find.text('My Tasks').last);
    expect(find.text('Study Dart streams'), findsOneWidget);

    // Filter by Pending vs Completed.
    await tapVisible(tester, find.text('Completed'));
    expect(find.text('No matching tasks'), findsOneWidget);

    await tapVisible(tester, find.text('Pending'));
    expect(find.text('Study Dart streams'), findsOneWidget);

    // Search by title.
    await tester.enterText(find.byType(TextField).first, 'streams');
    await tester.pumpAndSettle();
    expect(find.text('Study Dart streams'), findsOneWidget);

    // Open Task Details screen.
    await tapVisible(tester, find.text('Study Dart streams'));
    expect(find.text('Task Details'), findsOneWidget);

    // Navigate to Edit Task screen.
    await tapVisible(tester, find.text('Edit Task'));
    expect(find.text('Edit Task'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'Master Dart streams',
    );
    await tapVisible(tester, find.text('Save Changes'));

    // Back on Task Details with updated title.
    expect(find.text('Master Dart streams'), findsOneWidget);

    // Delete with confirmation dialog.
    await tapVisible(tester, find.text('Delete'));
    expect(find.text('Delete Task'), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Delete'));

    expect(controller.totalCount, 0);
  });

  testWidgets('Wide screen uses NavigationRail and Settings screen renders',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TaskController();
    await tester.pumpWidget(TaskFlowApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);

    await tapVisible(tester, find.text('Settings'));

    expect(find.text('Settings & About'), findsOneWidget);
    expect(
      find.text('Saved automatically on this device'),
      findsOneWidget,
    );
  });
}
