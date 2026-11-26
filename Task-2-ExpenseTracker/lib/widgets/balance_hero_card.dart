import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../utils/formatters.dart';

/// Hero card showing overall balance, monthly spend vs budget progress, and totals.
class BalanceHeroCard extends StatelessWidget {
  const BalanceHeroCard({
    super.key,
    required this.netBalance,
    required this.monthlyExpenses,
    required this.monthlyIncome,
    required this.monthlyBudget,
    required this.currency,
  });

  final double netBalance;
  final double monthlyExpenses;
  final double monthlyIncome;
  final double monthlyBudget;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ratio =
        monthlyBudget <= 0 ? 0.0 : (monthlyExpenses / monthlyBudget).clamp(0.0, 1.0);
    final rawPercent =
        monthlyBudget <= 0 ? 0 : ((monthlyExpenses / monthlyBudget) * 100).round();
    final isOverBudget = monthlyExpenses > monthlyBudget;
    final remaining = monthlyBudget - monthlyExpenses;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SpendFlowTheme.primary,
            SpendFlowTheme.primaryDeep,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: SpendFlowTheme.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                  'Net Balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isOverBudget
                          ? SpendFlowTheme.expense
                          : Colors.white)
                      .withValues(alpha: isOverBudget ? 0.26 : 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOverBudget
                      ? 'Over budget ($rawPercent%)'
                      : '$rawPercent% of budget used',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            SpendFormatters.formatCurrency(
              netBalance,
              currencySymbol: currency,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? const Color(0xFFFCA5A5) : SpendFlowTheme.accent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Spent: ${SpendFormatters.formatCurrency(monthlyExpenses, currencySymbol: currency)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isOverBudget
                      ? 'Exceeded by ${SpendFormatters.formatCurrency(remaining.abs(), currencySymbol: currency)}'
                      : 'Left: ${SpendFormatters.formatCurrency(remaining, currencySymbol: currency)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroPill(
                  icon: Icons.south_west,
                  iconColor: const Color(0xFF86EFAC),
                  label: 'Month Income',
                  value: SpendFormatters.formatCurrency(
                    monthlyIncome,
                    currencySymbol: currency,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  icon: Icons.north_east,
                  iconColor: const Color(0xFFFCA5A5),
                  label: 'Month Spend',
                  value: SpendFormatters.formatCurrency(
                    monthlyExpenses,
                    currencySymbol: currency,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
