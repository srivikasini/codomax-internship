import 'package:material_ui/material_ui.dart';

import 'expense_controller.dart';

/// Exposes [ExpenseController] down the widget tree and rebuilds dependents.
class ExpenseScope extends InheritedNotifier<ExpenseController> {
  const ExpenseScope({
    super.key,
    required ExpenseController controller,
    required super.child,
  }) : super(notifier: controller);

  static ExpenseController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ExpenseScope>();
    assert(scope != null, 'No ExpenseScope found in widget tree.');
    return scope!.notifier!;
  }

  static ExpenseController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ExpenseScope>();
    assert(scope != null, 'No ExpenseScope found in widget tree.');
    return scope!.notifier!;
  }
}
