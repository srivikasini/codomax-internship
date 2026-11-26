import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../controllers/expense_scope.dart';
import '../models/expense_entry.dart';
import '../services/local_expense_database.dart';
import '../utils/formatters.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/feedback_helper.dart';

/// Manages monthly budget, safe daily spend, currency preferences, and JSON backup/restore.
class BudgetDataScreen extends StatefulWidget {
  const BudgetDataScreen({super.key});

  @override
  State<BudgetDataScreen> createState() => _BudgetDataScreenState();
}

class _BudgetDataScreenState extends State<BudgetDataScreen> {
  final GlobalKey<FormState> _budgetFormKey = GlobalKey<FormState>();
  late final TextEditingController _budgetController;
  late String _selectedCurrency;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _budgetController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final controller = ExpenseScope.read(context);
      _budgetController.text = controller.monthlyBudget.toStringAsFixed(0);
      _selectedCurrency = controller.currency;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  double _dailySafeAllowance(double remaining) {
    if (remaining <= 0) return 0;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = (daysInMonth - now.day) + 1;
    return remaining / (daysLeft > 0 ? daysLeft : 1);
  }

  Future<void> _saveBudget() async {
    if (!(_budgetFormKey.currentState?.validate() ?? false)) return;
    final parsed = double.tryParse(
      _budgetController.text.trim().replaceAll(',', ''),
    );
    if (parsed == null) return;

    final result = await ExpenseScope.read(context).updateBudgetSettings(
      monthlyBudget: parsed,
      currencySymbol: _selectedCurrency,
    );
    if (!mounted) return;
    showSpendSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );
  }

  Future<void> _showExportDialog() async {
    final jsonBackup = ExpenseScope.read(context).exportBackupJson();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Export JSON Backup'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: SelectableText(
                jsonBackup,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: jsonBackup));
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!mounted) return;
                showSpendSnackBar(
                  context,
                  message: 'JSON backup copied to clipboard.',
                );
              },
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('Copy JSON'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImportDialog() async {
    final importController = TextEditingController();
    final rawJson = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Restore from JSON Backup'),
          content: SizedBox(
            width: 520,
            child: TextField(
              controller: importController,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Paste your SpendFlow JSON backup here...',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(importController.text),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );
    importController.dispose();

    if (rawJson == null || !mounted) return;

    final controller = ExpenseScope.read(context);
    final result = await controller.importBackupJson(rawJson);
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _budgetController.text = controller.monthlyBudget.toStringAsFixed(0);
        _selectedCurrency = controller.currency;
      });
    }
    showSpendSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );
  }

  Future<void> _clearAll() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear All Local Data',
      message:
          'Remove all stored transactions and reset your monthly budget to defaults?',
      confirmLabel: 'Clear All',
    );
    if (!confirmed || !mounted) return;

    final controller = ExpenseScope.read(context);
    final result = await controller.clearAllData();
    if (!mounted) return;
    setState(() {
      _budgetController.text = controller.monthlyBudget.toStringAsFixed(0);
      _selectedCurrency = controller.currency;
    });
    showSpendSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ExpenseScope.of(context);
    final dailySafe = _dailySafeAllowance(controller.budgetRemaining);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Budget & Data',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: SpendFlowTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Configure your monthly spending limit, currency, and local JSON backup.',
            style: TextStyle(
              fontSize: 13.5,
              color: SpendFlowTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  SpendFlowTheme.primary,
                  SpendFlowTheme.primaryDeep,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.today_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Safe-to-Spend',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${SpendFormatters.formatCurrency(dailySafe, currencySymbol: controller.currency)} / day',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: SpendFlowTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SpendFlowTheme.border),
            ),
            child: Form(
              key: _budgetFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Budget & Currency',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: SpendFlowTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _budgetController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Monthly Budget ($_selectedCurrency)',
                      prefixIcon: const Icon(
                        Icons.track_changes_outlined,
                        color: SpendFlowTheme.primary,
                      ),
                    ),
                    validator: controller.validateBudget,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Currency',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: SpendFlowTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: BudgetSettings.supportedCurrencies.map((symbol) {
                      final selected = _selectedCurrency == symbol;
                      return ChoiceChip(
                        label: Text(symbol == '₹' ? '₹ (INR)' : symbol),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: SpendFlowTheme.primary,
                        backgroundColor: SpendFlowTheme.background,
                        side: BorderSide(
                          color: selected
                              ? SpendFlowTheme.primary
                              : SpendFlowTheme.border,
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : SpendFlowTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedCurrency = symbol;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saveBudget,
                      style: FilledButton.styleFrom(
                        backgroundColor: SpendFlowTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Save Preferences'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: SpendFlowTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SpendFlowTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Local Database & JSON Schema',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SpendFlowTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _DbStatRow(
                  label: 'Schema Version',
                  value: 'v${ExpenseEntry.currentSchemaVersion}',
                ),
                const SizedBox(height: 8),
                const _DbStatRow(
                  label: 'Storage Keys',
                  value:
                      '${LocalExpenseDatabase.entriesKey}, ${LocalExpenseDatabase.settingsKey}',
                ),
                const SizedBox(height: 8),
                _DbStatRow(
                  label: 'Stored Records',
                  value: '${controller.entries.length} transactions',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showExportDialog,
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Export JSON'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showImportDialog,
                        icon: const Icon(Icons.upload_outlined, size: 18),
                        label: const Text('Import JSON'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: controller.entries.isNotEmpty ? _clearAll : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SpendFlowTheme.expense,
                      side: BorderSide(
                        color: controller.entries.isNotEmpty
                            ? SpendFlowTheme.expense
                            : SpendFlowTheme.border,
                      ),
                    ),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('Clear All Transactions'),
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

class _DbStatRow extends StatelessWidget {
  const _DbStatRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 13,
            color: SpendFlowTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: SpendFlowTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
