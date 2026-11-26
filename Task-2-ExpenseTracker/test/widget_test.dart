import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendflow_expense_tracker/controllers/expense_controller.dart';
import 'package:spendflow_expense_tracker/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    final center = tester.getCenter(finder);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    if (center.dy >= size.height - 20) {
      final pageScroll = find.byType(SingleChildScrollView);
      if (pageScroll.evaluate().isNotEmpty) {
        await tester.drag(pageScroll.last, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
    }
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('Overview, add entry validation, calculation, edit, and delete',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = ExpenseController();
    await tester.pumpWidget(SpendFlowApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('SpendFlow'), findsOneWidget);
    expect(find.text('₹0'), findsWidgets);

    // Open Add Entry screen via Overview CTA.
    await tapVisible(tester, find.text('Add Entry').first);
    expect(find.text('Add Transaction'), findsOneWidget);

    // Empty validation check.
    await tapVisible(tester, find.text('Save Entry'));
    expect(find.text('Please enter an amount.'), findsOneWidget);
    expect(find.text('Please enter a title or merchant name.'), findsOneWidget);

    // Enter valid INR expense.
    await tester.enterText(find.byType(TextFormField).at(0), '450');
    await tester.enterText(find.byType(TextFormField).at(1), 'Lunch Cafe');
    await tapVisible(tester, find.text('Save Entry'));

    // Let floating SnackBar auto-dismiss so it does not obscure bottom buttons.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(controller.entries.length, 1);
    expect(controller.totalExpenses, 450);
    expect(find.text('Lunch Cafe'), findsOneWidget);

    // Navigate to Transactions tab and inspect entry details.
    await tapVisible(tester, find.text('Transactions'));
    expect(find.text('Out: ₹450'), findsOneWidget);

    await tapVisible(tester, find.text('Lunch Cafe'));
    expect(find.text('Transaction Details'), findsOneWidget);

    // Edit entry amount.
    await tapVisible(tester, find.text('Edit'));
    expect(find.text('Edit Transaction'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '600');
    await tapVisible(tester, find.text('Save Changes'));

    expect(controller.totalExpenses, 600);
    expect(find.text('- ₹600'), findsOneWidget);

    // Wait for floating SnackBar before tapping Delete.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Delete'));
    expect(find.text('Delete Transaction'), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Delete'));

    expect(controller.entries, isEmpty);
  });

  testWidgets('Wide layout uses NavigationRail and Analytics/Budget render',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = ExpenseController();
    await tester.pumpWidget(SpendFlowApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);

    await tapVisible(tester, find.text('Analytics'));
    expect(find.text('Expenses by Category'), findsOneWidget);

    await tapVisible(tester, find.text('Budget'));
    expect(find.text('Monthly Budget & Currency'), findsOneWidget);
    expect(find.text('Export JSON'), findsOneWidget);
  });
}
