import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../controllers/expense_scope.dart';
import '../models/expense_entry.dart';
import '../utils/formatters.dart';
import '../widgets/category_breakdown_card.dart';

/// Analytics screen showing category totals, income vs expense ratio, and payment methods.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateRangeFilter _period = DateRangeFilter.thisMonth;

  @override
  Widget build(BuildContext context) {
    final controller = ExpenseScope.of(context);
    final expenseCategories = controller.categoryBreakdown(
      TransactionType.expense,
      range: _period,
    );
    final incomeCategories = controller.categoryBreakdown(
      TransactionType.income,
      range: _period,
    );
    final paymentBreakdown =
        controller.paymentMethodBreakdown(range: _period);

    final totalExp = expenseCategories.fold<double>(
      0,
      (sum, e) => sum + e.totalAmount,
    );
    final totalInc = incomeCategories.fold<double>(
      0,
      (sum, e) => sum + e.totalAmount,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: SpendFlowTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Visual breakdown of your spending, income, and payment channels.',
            style: TextStyle(
              fontSize: 13.5,
              color: SpendFlowTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DateRangeFilter.values.map((range) {
                final selected = _period == range;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(range.label),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: SpendFlowTheme.primary,
                    backgroundColor: SpendFlowTheme.surface,
                    side: BorderSide(
                      color: selected
                          ? SpendFlowTheme.primary
                          : SpendFlowTheme.border,
                    ),
                    labelStyle: TextStyle(
                      color:
                          selected ? Colors.white : SpendFlowTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _period = range;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: SpendFlowTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SpendFlowTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cash Flow (${_period.label})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SpendFlowTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _CashFlowTile(
                        label: 'Income',
                        amount: SpendFormatters.formatCurrency(
                          totalInc,
                          currencySymbol: controller.currency,
                        ),
                        color: SpendFlowTheme.income,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CashFlowTile(
                        label: 'Expenses',
                        amount: SpendFormatters.formatCurrency(
                          totalExp,
                          currencySymbol: controller.currency,
                        ),
                        color: SpendFlowTheme.expense,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CashFlowTile(
                        label: 'Net',
                        amount: SpendFormatters.formatCurrency(
                          totalInc - totalExp,
                          currencySymbol: controller.currency,
                        ),
                        color: (totalInc - totalExp) >= 0
                            ? SpendFlowTheme.primary
                            : SpendFlowTheme.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CategoryBreakdownCard(
            title: 'Expenses by Category',
            items: expenseCategories,
            currency: controller.currency,
            emptyMessage: 'No expenses found for ${_period.label}.',
          ),
          const SizedBox(height: 16),
          CategoryBreakdownCard(
            title: 'Income Sources',
            items: incomeCategories,
            currency: controller.currency,
            emptyMessage: 'No income recorded for ${_period.label}.',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: SpendFlowTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SpendFlowTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Spending by Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SpendFlowTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (paymentBreakdown.isEmpty)
                  Text(
                    'No payment activity in ${_period.label}.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: SpendFlowTheme.textSecondary,
                    ),
                  )
                else
                  ...paymentBreakdown.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                item.method.icon,
                                size: 17,
                                color: SpendFlowTheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${item.method.label} (${item.transactionCount})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: SpendFlowTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '${SpendFormatters.formatCurrency(item.totalAmount, currencySymbol: controller.currency)} • ${item.percentage.round()}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: SpendFlowTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (item.percentage / 100).clamp(0.0, 1.0),
                              minHeight: 7,
                              backgroundColor: SpendFlowTheme.background,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                SpendFlowTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CashFlowTile extends StatelessWidget {
  const _CashFlowTile({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: SpendFlowTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
