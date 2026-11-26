import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../controllers/expense_scope.dart';
import '../models/expense_entry.dart';
import '../utils/formatters.dart';
import '../widgets/balance_hero_card.dart';
import '../widgets/category_breakdown_card.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/feedback_helper.dart';
import '../widgets/spend_donut_chart.dart';
import '../widgets/summary_stat_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_edit_entry_screen.dart';
import 'entry_details_screen.dart';

/// Main dashboard displaying balance, quick actions, donut chart, category totals, and recent entries.
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({
    super.key,
    required this.onNavigateToTransactions,
  });

  final void Function({
    TransactionType? typeFilter,
    ExpenseCategory? categoryFilter,
  }) onNavigateToTransactions;

  Future<void> _openAdd(
    BuildContext context, {
    TransactionType initialType = TransactionType.expense,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditEntryScreen(initialType: initialType),
      ),
    );
  }

  Future<void> _openDetails(BuildContext context, ExpenseEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntryDetailsScreen(entryId: entry.id),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, ExpenseEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditEntryScreen(existingEntry: entry),
      ),
    );
  }

  Future<void> _deleteEntry(BuildContext context, ExpenseEntry entry) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Transaction',
      message: 'Are you sure you want to delete "${entry.title}"?',
    );
    if (!confirmed || !context.mounted) return;

    final result = await ExpenseScope.read(context).deleteEntry(entry.id);
    if (!context.mounted) return;
    showSpendSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ExpenseScope.of(context);
    final recentEntries = controller.entries.take(5).toList(growable: false);
    final monthCategories = controller.categoryBreakdown(
      TransactionType.expense,
      range: DateRangeFilter.thisMonth,
    );
    final topCategories = monthCategories.take(4).toList(growable: false);
    final isWide = MediaQuery.sizeOf(context).width >= 840;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      SpendFlowTheme.primary,
                      SpendFlowTheme.primaryDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: SpendFlowTheme.primary.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SpendFlow',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: SpendFlowTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Smart Expense & Budget Tracker',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: SpendFlowTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _openAdd(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Entry'),
              ),
            ],
          ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 16),
            DatabaseErrorBanner(
              message: controller.errorMessage!,
              onRetry: () => controller.loadDatabase(forceReload: true),
              onReset: () async {
                await controller.clearAllData();
              },
            ),
          ],
          const SizedBox(height: 20),
          BalanceHeroCard(
            netBalance: controller.netBalance,
            monthlyExpenses: controller.thisMonthExpenses,
            monthlyIncome: controller.thisMonthIncome,
            monthlyBudget: controller.monthlyBudget,
            currency: controller.currency,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _QuickActionPill(
                  icon: Icons.north_east,
                  label: 'Add Expense',
                  color: SpendFlowTheme.expense,
                  onTap: () =>
                      _openAdd(context, initialType: TransactionType.expense),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionPill(
                  icon: Icons.south_west,
                  label: 'Add Income',
                  color: SpendFlowTheme.income,
                  onTap: () =>
                      _openAdd(context, initialType: TransactionType.income),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SummaryStatCard(
                  label: 'Total Income',
                  value: SpendFormatters.formatCurrency(
                    controller.totalIncome,
                    currencySymbol: controller.currency,
                  ),
                  icon: Icons.south_west,
                  color: SpendFlowTheme.income,
                  onTap: () => onNavigateToTransactions(
                    typeFilter: TransactionType.income,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryStatCard(
                  label: 'Total Spent',
                  value: SpendFormatters.formatCurrency(
                    controller.totalExpenses,
                    currencySymbol: controller.currency,
                  ),
                  icon: Icons.north_east,
                  color: SpendFlowTheme.expense,
                  onTap: () => onNavigateToTransactions(
                    typeFilter: TransactionType.expense,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryStatCard(
                  label: 'Month Net',
                  value: SpendFormatters.formatCurrency(
                    controller.thisMonthSavings,
                    currencySymbol: controller.currency,
                  ),
                  icon: Icons.savings_outlined,
                  color: controller.thisMonthSavings >= 0
                      ? SpendFlowTheme.primary
                      : SpendFlowTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SpendDonutChartCard(
                    title: 'This Month Split',
                    items: monthCategories,
                    currency: controller.currency,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: CategoryBreakdownCard(
                    title: 'Top Categories This Month',
                    items: topCategories,
                    currency: controller.currency,
                    emptyMessage:
                        'Record an expense to see category totals here.',
                    onCategoryTap: (item) => onNavigateToTransactions(
                      typeFilter: TransactionType.expense,
                      categoryFilter: item.category,
                    ),
                  ),
                ),
              ],
            )
          else ...[
            SpendDonutChartCard(
              title: 'This Month Split',
              items: monthCategories,
              currency: controller.currency,
            ),
            const SizedBox(height: 14),
            CategoryBreakdownCard(
              title: 'Top Categories This Month',
              items: topCategories,
              currency: controller.currency,
              emptyMessage: 'Record an expense to see category totals here.',
              onCategoryTap: (item) => onNavigateToTransactions(
                typeFilter: TransactionType.expense,
                categoryFilter: item.category,
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SpendFlowTheme.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => onNavigateToTransactions(),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (controller.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(color: SpendFlowTheme.primary),
              ),
            )
          else if (recentEntries.isEmpty)
            EmptyStateCard(
              title: 'No transactions recorded yet',
              subtitle:
                  'Track your first expense or income to unlock live budgets and charts.',
              actionLabel: 'Record first entry',
              onAction: () => _openAdd(context),
            )
          else
            ...recentEntries.map(
              (entry) => TransactionTile(
                entry: entry,
                currency: controller.currency,
                onTap: () => _openDetails(context, entry),
                onEdit: () => _openEdit(context, entry),
                onDelete: () => _deleteEntry(context, entry),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickActionPill extends StatelessWidget {
  const _QuickActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
