import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../controllers/expense_controller.dart';
import '../utils/formatters.dart';

/// Custom-painted donut chart visualizing spending distribution across categories.
class SpendDonutChartCard extends StatelessWidget {
  const SpendDonutChartCard({
    super.key,
    required this.title,
    required this.items,
    required this.currency,
  });

  final String title;
  final List<CategoryBreakdownItem> items;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, e) => sum + e.totalAmount);

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: SpendFlowTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Add an expense to visualize category distribution.',
                style: TextStyle(
                  fontSize: 13,
                  color: SpendFlowTheme.textSecondary,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 400;
                final donut = SizedBox(
                  height: 148,
                  width: 148,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(148, 148),
                        painter: _DonutPainter(items: items, total: total),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 11,
                              color: SpendFlowTheme.textSecondary,
                            ),
                          ),
                          Text(
                            SpendFormatters.formatCurrency(
                              total,
                              currencySymbol: currency,
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: SpendFlowTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                final legend = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.take(5).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: item.category.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.category.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: SpendFlowTheme.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${item.percentage.round()}%',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: SpendFlowTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );

                if (isCompact) {
                  return Column(
                    children: [
                      Center(child: donut),
                      const SizedBox(height: 16),
                      legend,
                    ],
                  );
                }

                return Row(
                  children: [
                    donut,
                    const SizedBox(width: 22),
                    Expanded(child: legend),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.items,
    required this.total,
  });

  final List<CategoryBreakdownItem> items;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const strokeWidth = 18.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    var startAngle = -math.pi / 2;
    const gap = 0.04;

    for (final item in items) {
      final sweep = (item.totalAmount / total) * (2 * math.pi);
      final paint = Paint()
        ..color = item.category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final adjustedSweep = items.length > 1 ? math.max(0.05, sweep - gap) : sweep;
      canvas.drawArc(rect, startAngle, adjustedSweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.items != items;
  }
}
