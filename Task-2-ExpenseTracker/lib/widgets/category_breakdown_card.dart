import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../controllers/expense_controller.dart';
import '../utils/formatters.dart';

/// Visual horizontal bar breakdown of spending or income by category.
class CategoryBreakdownCard extends StatelessWidget {
  const CategoryBreakdownCard({
    super.key,
    required this.title,
    required this.items,
    required this.currency,
    this.emptyMessage = 'No records in this period yet.',
    this.onCategoryTap,
  });

  final String title;
  final List<CategoryBreakdownItem> items;
  final String currency;
  final String emptyMessage;
  final void Function(CategoryBreakdownItem item)? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: SpendFlowTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                emptyMessage,
                style: const TextStyle(
                  fontSize: 13,
                  color: SpendFlowTheme.textSecondary,
                ),
              ),
            )
          else
            ...items.map((item) {
              final ratio = (item.percentage / 100).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap:
                      onCategoryTap != null ? () => onCategoryTap!(item) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            item.category.icon,
                            size: 16,
                            color: item.category.color,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.category.label} (${item.transactionCount})',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: SpendFlowTheme.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${SpendFormatters.formatCurrency(item.totalAmount, currencySymbol: currency)} • ${item.percentage.round()}%',
                            style: const TextStyle(
                              fontSize: 13,
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
                          value: ratio,
                          minHeight: 7,
                          backgroundColor: SpendFlowTheme.background,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            item.category.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
