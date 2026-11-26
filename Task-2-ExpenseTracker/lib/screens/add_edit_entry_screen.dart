import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../controllers/expense_controller.dart';
import '../controllers/expense_scope.dart';
import '../models/expense_entry.dart';
import '../utils/formatters.dart';
import '../widgets/feedback_helper.dart';

/// Form screen for adding a new transaction or editing an existing [ExpenseEntry].
class AddEditEntryScreen extends StatefulWidget {
  const AddEditEntryScreen({
    super.key,
    this.existingEntry,
    this.initialType = TransactionType.expense,
  });

  final ExpenseEntry? existingEntry;
  final TransactionType initialType;

  bool get isEditing => existingEntry != null;

  @override
  State<AddEditEntryScreen> createState() => _AddEditEntryScreenState();
}

class _AddEditEntryScreenState extends State<AddEditEntryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  late TransactionType _type;
  late ExpenseCategory _category;
  late PaymentMethod _paymentMethod;
  late DateTime _selectedDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEntry;
    _type = existing?.type ?? widget.initialType;
    _category = existing?.category ??
        (_type == TransactionType.income
            ? ExpenseCategory.salary
            : ExpenseCategory.food);
    _paymentMethod = existing?.paymentMethod ?? PaymentMethod.upi;
    _selectedDate = existing?.date ?? DateTime.now();

    _amountController = TextEditingController(
      text: existing != null
          ? (existing.amount == existing.amount.truncateToDouble()
              ? existing.amount.toStringAsFixed(0)
              : existing.amount.toStringAsFixed(2))
          : '',
    );
    _titleController = TextEditingController(text: existing?.title ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType nextType) {
    if (_type == nextType) return;
    final allowed = ExpenseCategory.forType(nextType);
    setState(() {
      _type = nextType;
      if (!allowed.contains(_category)) {
        _category = allowed.first;
      }
    });
  }

  void _addQuickAmount(double delta) {
    final current =
        double.tryParse(_amountController.text.trim().replaceAll(',', '')) ?? 0;
    final next = current + delta;
    _amountController.text = next == next.truncateToDouble()
        ? next.toStringAsFixed(0)
        : next.toStringAsFixed(2);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final parsedAmount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    if (parsedAmount == null) return;

    setState(() {
      _isSubmitting = true;
    });

    final controller = ExpenseScope.read(context);
    final ExpenseActionResult result;

    if (widget.isEditing) {
      result = await controller.updateEntry(
        id: widget.existingEntry!.id,
        title: _titleController.text,
        amount: parsedAmount,
        type: _type,
        category: _category,
        paymentMethod: _paymentMethod,
        date: _selectedDate,
        notes: _notesController.text,
      );
    } else {
      result = await controller.addEntry(
        title: _titleController.text,
        amount: parsedAmount,
        type: _type,
        category: _category,
        paymentMethod: _paymentMethod,
        date: _selectedDate,
        notes: _notesController.text,
      );
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    showSpendSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );

    if (result.success) {
      Navigator.of(context).pop(result.entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ExpenseScope.of(context);
    final categories = ExpenseCategory.forType(_type);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SpendFlowTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SpendFlowTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<TransactionType>(
                        segments: const [
                          ButtonSegment(
                            value: TransactionType.expense,
                            icon: Icon(Icons.north_east, size: 16),
                            label: Text('Expense'),
                          ),
                          ButtonSegment(
                            value: TransactionType.income,
                            icon: Icon(Icons.south_west, size: 16),
                            label: Text('Income'),
                          ),
                        ],
                        selected: {_type},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          if (selection.isNotEmpty) {
                            _onTypeChanged(selection.first);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: SpendFlowTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount (${controller.currency}) *',
                        hintText: '0',
                        prefixText: '${controller.currency} ',
                        prefixStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: SpendFlowTheme.primary,
                        ),
                      ),
                      validator: controller.validateAmount,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [100, 250, 500, 1000].map((val) {
                        return ActionChip(
                          label: Text('+${controller.currency}$val'),
                          onPressed: () => _addQuickAmount(val.toDouble()),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      maxLength: ExpenseController.maxTitleLength,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Title / Merchant *',
                        hintText: _type == TransactionType.expense
                            ? 'e.g., Lunch at cafe, Metro pass'
                            : 'e.g., Monthly salary, Freelance project',
                        prefixIcon: const Icon(
                          Icons.description_outlined,
                          color: SpendFlowTheme.primary,
                        ),
                      ),
                      validator: controller.validateTitle,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: SpendFlowTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final selected = _category == cat;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat.icon,
                                size: 16,
                                color: selected ? Colors.white : cat.color,
                              ),
                              const SizedBox(width: 6),
                              Text(cat.label),
                            ],
                          ),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: cat.color,
                          backgroundColor: SpendFlowTheme.background,
                          side: BorderSide(
                            color: selected ? cat.color : SpendFlowTheme.border,
                          ),
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : SpendFlowTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _category = cat;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: SpendFlowTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PaymentMethod.values.map((method) {
                        final selected = _paymentMethod == method;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                method.icon,
                                size: 16,
                                color: selected
                                    ? Colors.white
                                    : SpendFlowTheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(method.label),
                            ],
                          ),
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
                              _paymentMethod = method;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: SpendFlowTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: SpendFlowTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: SpendFlowTheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Date: ${SpendFormatters.formatDate(_selectedDate)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: SpendFlowTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _pickDate,
                                  child: const Text('Change'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLength: ExpenseController.maxNotesLength,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Any extra receipt or reference note...',
                        prefixIcon: Icon(
                          Icons.notes_outlined,
                          color: SpendFlowTheme.primary,
                        ),
                      ),
                      validator: controller.validateNotes,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: SpendFlowTheme.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    widget.isEditing
                                        ? Icons.save_outlined
                                        : Icons.check,
                                  ),
                            label: Text(
                              widget.isEditing ? 'Save Changes' : 'Save Entry',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
