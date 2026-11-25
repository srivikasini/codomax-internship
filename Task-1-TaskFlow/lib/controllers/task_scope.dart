import 'package:material_ui/material_ui.dart';

import 'task_controller.dart';

/// Exposes [TaskController] down the widget tree and rebuilds dependents.
class TaskScope extends InheritedNotifier<TaskController> {
  const TaskScope({
    super.key,
    required TaskController controller,
    required super.child,
  }) : super(notifier: controller);

  static TaskController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TaskScope>();
    assert(scope != null, 'No TaskScope found in widget tree.');
    return scope!.notifier!;
  }

  static TaskController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<TaskScope>();
    assert(scope != null, 'No TaskScope found in widget tree.');
    return scope!.notifier!;
  }
}
