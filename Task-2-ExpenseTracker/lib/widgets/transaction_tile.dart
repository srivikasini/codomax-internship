import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../models/expense_entry.dart';
import '../utils/formatters.dart';

/// Card representing a single financial entry with amount, category, and actions.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.entry,
    required this.currency,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ExpenseEntry entry;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.type == TransactionType.income;
    final amountColor =
        isIncome ? SpendFlowTheme.income : SpendFlowTheme.expense;
    final signedAmount =
        '${isIncome ? '+' : '-'} ${SpendFormatters.formatCurrency(entry.amount, currencySymbol: currency)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: SpendFlowTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SpendFlowTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: entry.category.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    entry.category.icon,
                    color: entry.category.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: SpendFlowTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            entry.category.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: entry.category.color,
                            ),
                          ),
                          Text(
                            '• ${entry.paymentMethod.label}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: SpendFlowTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '• ${SpendFormatters.formatRelativeDate(entry.date)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: SpendFlowTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      signedAmount,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: onEdit,
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: SpendFlowTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: SpendFlowTheme.expense,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
