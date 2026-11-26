import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendflow_expense_tracker/controllers/expense_controller.dart';
import 'package:spendflow_expense_tracker/models/expense_entry.dart';
import 'package:spendflow_expense_tracker/services/local_expense_database.dart';
import 'package:spendflow_expense_tracker/utils/formatters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SpendFormatters', () {
    test('formats INR amounts using Indian numbering commas', () {
      expect(SpendFormatters.formatCurrency(450), '₹450');
      expect(SpendFormatters.formatCurrency(25000), '₹25,000');
      expect(SpendFormatters.formatCurrency(125450), '₹1,25,450');
      expect(SpendFormatters.formatCurrency(-1500.5), '-₹1,500.50');
      expect(
        SpendFormatters.formatCurrency(12500, currencySymbol: '\$'),
        '\$12,500',
      );
    });
  });

  group('ExpenseController & LocalExpenseDatabase', () {
    test('handles corrupted stored JSON safely', () async {
      SharedPreferences.setMockInitialValues({
        LocalExpenseDatabase.entriesKey: '{invalid-json',
      });

      final controller = ExpenseController();
      await controller.loadDatabase();

      expect(controller.errorMessage, isNotNull);
      expect(controller.entries, isEmpty);

      final cleared = await controller.clearAllData();
      expect(cleared.success, isTrue);
      expect(controller.errorMessage, isNull);
    });

    test('validates title, amount, and budget inputs', () async {
      final controller = ExpenseController();
      await controller.loadDatabase();

      expect(controller.validateTitle('   '), isNotNull);
      expect(controller.validateAmount('0'), isNotNull);
      expect(controller.validateAmount('-50'), isNotNull);
      expect(controller.validateAmount('abc'), isNotNull);
      expect(controller.validateAmount('450.50'), isNull);
      expect(controller.validateBudget('0'), isNotNull);
      expect(controller.validateBudget('30000'), isNull);
    });

    test('persists add, edit, budget, totals, and delete across restarts',
        () async {
      final controller1 = ExpenseController();
      await controller1.loadDatabase();

      final now = DateTime.now();
      final inc = await controller1.addEntry(
        title: 'Monthly Salary',
        amount: 50000,
        type: TransactionType.income,
        category: ExpenseCategory.salary,
        paymentMethod: PaymentMethod.bankTransfer,
        date: now,
      );
      expect(inc.success, isTrue);

      final exp1 = await controller1.addEntry(
        title: 'Groceries',
        amount: 1850,
        type: TransactionType.expense,
        category: ExpenseCategory.food,
        paymentMethod: PaymentMethod.upi,
        date: now,
      );
      expect(exp1.success, isTrue);

      final exp2 = await controller1.addEntry(
        title: 'Metro Card',
        amount: 600,
        type: TransactionType.expense,
        category: ExpenseCategory.transport,
        paymentMethod: PaymentMethod.card,
        date: now,
      );
      expect(exp2.success, isTrue);

      expect(controller1.totalIncome, 50000);
      expect(controller1.totalExpenses, 2450);
      expect(controller1.netBalance, 47550);
      expect(controller1.budgetRemaining, 25000 - 2450);

      // Update expense and budget.
      await controller1.updateEntry(
        id: exp1.entry!.id,
        title: 'Supermarket Groceries',
        amount: 2000,
        type: TransactionType.expense,
        category: ExpenseCategory.food,
        paymentMethod: PaymentMethod.upi,
        date: now,
      );
      await controller1.updateBudgetSettings(
        monthlyBudget: 15000,
        currencySymbol: '₹',
      );
      await controller1.deleteEntry(exp2.entry!.id);

      // Simulate restart with fresh controller.
      final controller2 = ExpenseController();
      await controller2.loadDatabase();

      expect(controller2.entries.length, 2);
      expect(controller2.monthlyBudget, 15000);
      expect(controller2.totalIncome, 50000);
      expect(controller2.totalExpenses, 2000);
      expect(controller2.netBalance, 48000);
    });

    test('computes category breakdowns, filters, and JSON backup roundtrip',
        () async {
      final controller = ExpenseController();
      await controller.loadDatabase();

      final now = DateTime.now();
      await controller.addEntry(
        title: 'Dinner',
        amount: 800,
        type: TransactionType.expense,
        category: ExpenseCategory.food,
        paymentMethod: PaymentMethod.upi,
        date: now,
      );
      await controller.addEntry(
        title: 'Electricity Bill',
        amount: 1200,
        type: TransactionType.expense,
        category: ExpenseCategory.bills,
        paymentMethod: PaymentMethod.bankTransfer,
        date: now,
      );
      await controller.addEntry(
        title: 'Freelance Design',
        amount: 5000,
        type: TransactionType.income,
        category: ExpenseCategory.freelance,
        paymentMethod: PaymentMethod.bankTransfer,
        date: now,
      );

      final breakdown = controller.categoryBreakdown(TransactionType.expense);
      expect(breakdown.length, 2);
      expect(breakdown.first.category, ExpenseCategory.bills);
      expect(breakdown.first.totalAmount, 1200);
      expect(breakdown.first.percentage.round(), 60);

      controller.setTypeFilter(TransactionType.expense);
      controller.setCategoryFilter(ExpenseCategory.food);
      expect(controller.filteredEntries.length, 1);
      expect(controller.filteredTotalExpenses, 800);

      controller.clearFilters();
      controller.setSearchQuery('electricity');
      expect(controller.filteredEntries.length, 1);

      final backupJson = controller.exportBackupJson();
      await controller.clearAllData();
      expect(controller.entries, isEmpty);

      final restored = await controller.importBackupJson(backupJson);
      expect(restored.success, isTrue);
      expect(controller.entries.length, 3);

      final invalid = await controller.importBackupJson('not json');
      expect(invalid.success, isFalse);
    });

    test('computes multi-month comparison across old and current months',
        () async {
      final controller = ExpenseController();
      await controller.loadDatabase();

      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 15);
      await controller.addEntry(
        title: 'Last month rent',
        amount: 9000,
        type: TransactionType.expense,
        category: ExpenseCategory.bills,
        paymentMethod: PaymentMethod.bankTransfer,
        date: lastMonth,
      );
      await controller.addEntry(
        title: 'This month groceries',
        amount: 1500,
        type: TransactionType.expense,
        category: ExpenseCategory.food,
        paymentMethod: PaymentMethod.upi,
        date: now,
      );

      final months = controller.recentMonthsComparison(monthCount: 6);
      expect(months.length, 6);
      expect(months[4].expense, 9000);
      expect(months[5].expense, 1500);
    });
  });
}
