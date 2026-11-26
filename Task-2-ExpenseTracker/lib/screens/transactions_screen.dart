import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../controllers/expense_scope.dart';
import '../models/expense_entry.dart';
import '../utils/formatters.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/feedback_helper.dart';
import '../widgets/transaction_tile.dart';
import 'add_edit_entry_screen.dart';
import 'entry_details_screen.dart';

/// Filterable, searchable transaction ledger with live filtered totals.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = ExpenseScope.read(context).searchQuery;
    if (_searchController.text != query) {
      _searchController.text = query;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditEntryScreen()),
    );
  }

  Future<void> _openDetails(ExpenseEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EntryDetailsScreen(entryId: entry.id)),
    );
  }

  Future<void> _openEdit(ExpenseEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditEntryScreen(existingEntry: entry),
      ),
    );
  }

  Future<void> _deleteEntry(ExpenseEntry entry) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Transaction',
      message: 'Delete "${entry.title}"?',
    );
    if (!confirmed || !mounted) return;

    final result = await ExpenseScope.read(context).deleteEntry(entry.id);
    if (!mounted) return;
    showSpendSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ExpenseScope.of(context);
    final entries = controller.filteredEntries;

    if (_searchController.text != controller.searchQuery) {
      _searchController.text = controller.searchQuery;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: SpendFlowTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Search, filter by date or category, and inspect totals.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: SpendFlowTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _openAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: SpendFlowTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: controller.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search by title, category, or notes...',
              fillColor: SpendFlowTheme.surface,
              prefixIcon: const Icon(
                Icons.search,
                color: SpendFlowTheme.textSecondary,
              ),
              suffixIcon: controller.searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        controller.setSearchQuery('');
                      },
                      icon: const Icon(Icons.close),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DateRangeFilter.values.map((range) {
                final selected = controller.dateRangeFilter == range;
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
                    onSelected: (_) => controller.setDateRangeFilter(range),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<TransactionType?>(
                  initialValue: controller.typeFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    fillColor: SpendFlowTheme.surface,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('All Types', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: TransactionType.expense,
                      child: Text('Expense', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: TransactionType.income,
                      child: Text('Income', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: controller.setTypeFilter,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<ExpenseSortOrder>(
                  initialValue: controller.sortOrder,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sort',
                    fillColor: SpendFlowTheme.surface,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                  items: ExpenseSortOrder.values
                      .map(
                        (order) => DropdownMenuItem(
                          value: order,
                          child: Text(
                            order.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) controller.setSortOrder(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ExpenseCategory?>(
            initialValue: controller.categoryFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Category',
              fillColor: SpendFlowTheme.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Categories', overflow: TextOverflow.ellipsis),
              ),
              ...ExpenseCategory.values.map(
                (cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat.label, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: controller.setCategoryFilter,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: SpendFlowTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SpendFlowTheme.border),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: SpendFlowTheme.textPrimary,
                  ),
                ),
                Text(
                  'In: ${SpendFormatters.formatCurrency(controller.filteredTotalIncome, currencySymbol: controller.currency)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: SpendFlowTheme.income,
                  ),
                ),
                Text(
                  'Out: ${SpendFormatters.formatCurrency(controller.filteredTotalExpenses, currencySymbol: controller.currency)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: SpendFlowTheme.expense,
                  ),
                ),
                if (controller.hasActiveFilters)
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      controller.clearFilters();
                    },
                    child: const Text('Reset'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: SpendFlowTheme.primary,
                    ),
                  )
                : entries.isEmpty
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 10, bottom: 96),
                        child: controller.entries.isEmpty
                            ? EmptyStateCard(
                                title: 'No transactions yet',
                                subtitle:
                                    'Add an expense or income entry to start tracking.',
                                actionLabel: 'Add entry',
                                onAction: _openAdd,
                              )
                            : EmptyStateCard(
                                title: 'No matching entries',
                                subtitle:
                                    'Adjust your date range, category, or search filters.',
                                icon: Icons.filter_alt_off,
                                actionLabel: 'Reset filters',
                                onAction: () {
                                  _searchController.clear();
                                  controller.clearFilters();
                                },
                              ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return TransactionTile(
                            entry: entry,
                            currency: controller.currency,
                            onTap: () => _openDetails(entry),
                            onEdit: () => _openEdit(entry),
                            onDelete: () => _deleteEntry(entry),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
