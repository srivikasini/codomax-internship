import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../controllers/expense_scope.dart';
import '../models/expense_entry.dart';
import '../utils/formatters.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/feedback_helper.dart';
import 'add_edit_entry_screen.dart';

/// Displays complete details and edit/delete actions for an [ExpenseEntry].
class EntryDetailsScreen extends StatelessWidget {
  const EntryDetailsScreen({
    super.key,
    required this.entryId,
  });

  final String entryId;

  Future<void> _edit(BuildContext context, ExpenseEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditEntryScreen(existingEntry: entry),
      ),
    );
  }

  Future<void> _delete(BuildContext context, ExpenseEntry entry) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Transaction',
      message:
          'Delete "${entry.title}"? This will update all totals immediately.',
    );
    if (!confirmed || !context.mounted) return;

    final result = await ExpenseScope.read(context).deleteEntry(entry.id);
    if (!context.mounted) return;
    showSpendSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );
    if (result.success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ExpenseScope.of(context);
    final entry = controller.findById(entryId);

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Details')),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ),
      );
    }

    final isIncome = entry.type == TransactionType.income;
    final amountColor =
        isIncome ? SpendFlowTheme.income : SpendFlowTheme.expense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () => _edit(context, entry),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _delete(context, entry),
            icon: const Icon(Icons.delete_outline, color: SpendFlowTheme.expense),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: SpendFlowTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SpendFlowTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: entry.category.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              entry.category.icon,
                              color: entry.category.color,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: SpendFlowTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${entry.type.label} • ${entry.category.label}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: entry.category.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: amountColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isIncome ? 'Amount Received' : 'Amount Spent',
                              style: const TextStyle(
                                fontSize: 12,
                                color: SpendFlowTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${isIncome ? '+' : '-'} ${SpendFormatters.formatCurrency(entry.amount, currencySymbol: controller.currency)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: amountColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _DetailRow(
                        icon: entry.paymentMethod.icon,
                        label: 'Payment Method',
                        value: entry.paymentMethod.label,
                      ),
                      const SizedBox(height: 10),
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Transaction Date',
                        value: SpendFormatters.formatDate(entry.date),
                      ),
                      const SizedBox(height: 10),
                      _DetailRow(
                        icon: Icons.update_outlined,
                        label: 'Last Updated',
                        value: SpendFormatters.formatDateTime(entry.updatedAt),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: SpendFlowTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: SpendFlowTheme.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.notes.isEmpty
                              ? 'No notes added.'
                              : entry.notes,
                          style: TextStyle(
                            fontSize: 14,
                            color: entry.notes.isEmpty
                                ? SpendFlowTheme.textSecondary
                                : SpendFlowTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _edit(context, entry),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _delete(context, entry),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: SpendFlowTheme.expense,
                          side: const BorderSide(color: SpendFlowTheme.expense),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: SpendFlowTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 13.5,
            color: SpendFlowTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: SpendFlowTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
