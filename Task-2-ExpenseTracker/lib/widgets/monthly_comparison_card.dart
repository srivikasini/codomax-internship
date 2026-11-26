import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../controllers/expense_controller.dart';
import '../utils/formatters.dart';

/// Multi-month bar comparison card for comparing monthly income vs. spending.
class MonthlyComparisonCard extends StatelessWidget {
  const MonthlyComparisonCard({
    super.key,
    required this.months,
    required this.currency,
  });

  final List<MonthlySummary> months;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final maxValue = months.fold<double>(0.0, (peak, m) {
      return math.max(peak, math.max(m.income, m.expense));
    });
    final hasAnyData = maxValue > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SpendFlowTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SpendFlowTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '6-Month Comparison',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SpendFlowTheme.textPrimary,
                  ),
                ),
              ),
              const _LegendDot(color: SpendFlowTheme.income, label: 'In'),
              const SizedBox(width: 10),
              const _LegendDot(color: SpendFlowTheme.expense, label: 'Out'),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Compare past months to spot high-expense periods.',
            style: TextStyle(
              fontSize: 12.5,
              color: SpendFlowTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          if (!hasAnyData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Monthly bars will appear once you record transactions.',
                style: TextStyle(
                  fontSize: 13,
                  color: SpendFlowTheme.textSecondary,
                ),
              ),
            )
          else
            SizedBox(
              height: 156,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: months.map((m) {
                  final incHeight =
                      maxValue <= 0 ? 0.0 : (m.income / maxValue) * 105;
                  final expHeight =
                      maxValue <= 0 ? 0.0 : (m.expense / maxValue) * 105;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (m.expense > 0)
                          Text(
                            SpendFormatters.formatCurrency(
                              m.expense,
                              currencySymbol: currency,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: SpendFlowTheme.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _BarColumn(
                              height: incHeight,
                              color: SpendFlowTheme.income,
                            ),
                            const SizedBox(width: 4),
                            _BarColumn(
                              height: expHeight,
                              color: SpendFlowTheme.expense,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          m.label,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: SpendFlowTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.height,
    required this.color,
  });

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final displayHeight = height > 0 ? math.max(6.0, height) : 4.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 11,
      height: displayHeight,
      decoration: BoxDecoration(
        color: height > 0 ? color : SpendFlowTheme.border,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: SpendFlowTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
