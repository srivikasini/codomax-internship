import 'dart:collection';

import 'package:material_ui/material_ui.dart';

import '../models/expense_entry.dart';
import '../services/local_expense_database.dart';

/// Aggregated total and percentage share for a single [ExpenseCategory].
class CategoryBreakdownItem {
  const CategoryBreakdownItem({
    required this.category,
    required this.totalAmount,
    required this.percentage,
    required this.transactionCount,
  });

  final ExpenseCategory category;
  final double totalAmount;
  final double percentage;
  final int transactionCount;
}

/// Aggregated total for a [PaymentMethod].
class PaymentBreakdownItem {
  const PaymentBreakdownItem({
    required this.method,
    required this.totalAmount,
    required this.percentage,
    required this.transactionCount,
  });

  final PaymentMethod method;
  final double totalAmount;
  final double percentage;
  final int transactionCount;
}

/// Result returned by controller mutations for UI feedback.
class ExpenseActionResult {
  const ExpenseActionResult({
    required this.success,
    required this.message,
    this.entry,
  });

  final bool success;
  final String message;
  final ExpenseEntry? entry;
}

/// Central state management and calculation engine for SpendFlow.
class ExpenseController extends ChangeNotifier {
  ExpenseController({LocalExpenseDatabase? database})
      : _database = database ?? LocalExpenseDatabase();

  static const int maxTitleLength = 80;
  static const int maxNotesLength = 240;
  static const double maxSingleAmount = 10000000.0;

  final LocalExpenseDatabase _database;

  final List<ExpenseEntry> _entries = [];
  BudgetSettings _settings = const BudgetSettings();

  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isSaving = false;
  String? _errorMessage;

  String _searchQuery = '';
  TransactionType? _typeFilter;
  ExpenseCategory? _categoryFilter;
  PaymentMethod? _paymentFilter;
  DateRangeFilter _dateRangeFilter = DateRangeFilter.thisMonth;
  ExpenseSortOrder _sortOrder = ExpenseSortOrder.newestFirst;

  Future<void>? _inFlightLoad;
  Future<void> _saveQueue = Future<void>.value();
  int _idCounter = 0;

  UnmodifiableListView<ExpenseEntry> get entries =>
      UnmodifiableListView(_entries);
  BudgetSettings get settings => _settings;
  String get currency => _settings.currencySymbol;
  double get monthlyBudget => _settings.monthlyBudget;

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  TransactionType? get typeFilter => _typeFilter;
  ExpenseCategory? get categoryFilter => _categoryFilter;
  PaymentMethod? get paymentFilter => _paymentFilter;
  DateRangeFilter get dateRangeFilter => _dateRangeFilter;
  ExpenseSortOrder get sortOrder => _sortOrder;

  bool get hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _typeFilter != null ||
      _categoryFilter != null ||
      _paymentFilter != null ||
      _dateRangeFilter != DateRangeFilter.thisMonth;

  // Overall totals across all stored records.
  double get totalIncome => _sumByType(_entries, TransactionType.income);
  double get totalExpenses => _sumByType(_entries, TransactionType.expense);
  double get netBalance => totalIncome - totalExpenses;

  // Current month metrics for budget tracking.
  List<ExpenseEntry> get currentMonthEntries =>
      _filterByDateRange(_entries, DateRangeFilter.thisMonth);

  double get thisMonthIncome =>
      _sumByType(currentMonthEntries, TransactionType.income);
  double get thisMonthExpenses =>
      _sumByType(currentMonthEntries, TransactionType.expense);
  double get thisMonthSavings => thisMonthIncome - thisMonthExpenses;

  double get budgetRemaining => _settings.monthlyBudget - thisMonthExpenses;
  double get budgetUsageRatio => _settings.monthlyBudget <= 0
      ? 0.0
      : thisMonthExpenses / _settings.monthlyBudget;
  bool get isOverBudget => thisMonthExpenses > _settings.monthlyBudget;

  /// Entries matching the active search, date range, type, category, and payment filters.
  List<ExpenseEntry> get filteredEntries {
    final query = _searchQuery.trim().toLowerCase();
    final dateMatched = _filterByDateRange(_entries, _dateRangeFilter);

    final result = dateMatched.where((entry) {
      if (_typeFilter != null && entry.type != _typeFilter) return false;
      if (_categoryFilter != null && entry.category != _categoryFilter) {
        return false;
      }
      if (_paymentFilter != null && entry.paymentMethod != _paymentFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final inTitle = entry.title.toLowerCase().contains(query);
        final inNotes = entry.notes.toLowerCase().contains(query);
        final inCategory = entry.category.label.toLowerCase().contains(query);
        if (!inTitle && !inNotes && !inCategory) return false;
      }
      return true;
    }).toList();

    switch (_sortOrder) {
      case ExpenseSortOrder.newestFirst:
        result.sort((a, b) {
          final cmp = b.date.compareTo(a.date);
          return cmp != 0 ? cmp : b.createdAt.compareTo(a.createdAt);
        });
      case ExpenseSortOrder.highestAmount:
        result.sort((a, b) => b.amount.compareTo(a.amount));
      case ExpenseSortOrder.lowestAmount:
        result.sort((a, b) => a.amount.compareTo(b.amount));
    }

    return List<ExpenseEntry>.unmodifiable(result);
  }

  double get filteredTotalIncome =>
      _sumByType(filteredEntries, TransactionType.income);
  double get filteredTotalExpenses =>
      _sumByType(filteredEntries, TransactionType.expense);
  double get filteredNet => filteredTotalIncome - filteredTotalExpenses;

  /// Computes category-level totals and percentages for a given [type] and [range].
  List<CategoryBreakdownItem> categoryBreakdown(
    TransactionType type, {
    DateRangeFilter range = DateRangeFilter.thisMonth,
  }) {
    final scoped = _filterByDateRange(_entries, range)
        .where((e) => e.type == type)
        .toList();
    final grandTotal = _sumByType(scoped, type);
    if (scoped.isEmpty || grandTotal <= 0) return const [];

    final totals = <ExpenseCategory, double>{};
    final counts = <ExpenseCategory, int>{};

    for (final entry in scoped) {
      totals[entry.category] = (totals[entry.category] ?? 0) + entry.amount;
      counts[entry.category] = (counts[entry.category] ?? 0) + 1;
    }

    final items = totals.entries.map((e) {
      return CategoryBreakdownItem(
        category: e.key,
        totalAmount: e.value,
        percentage: (e.value / grandTotal) * 100,
        transactionCount: counts[e.key] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return items;
  }

  /// Computes payment method distribution across expenses for [range].
  List<PaymentBreakdownItem> paymentMethodBreakdown({
    DateRangeFilter range = DateRangeFilter.thisMonth,
  }) {
    final scoped = _filterByDateRange(_entries, range)
        .where((e) => e.type == TransactionType.expense)
        .toList();
    final grandTotal = _sumByType(scoped, TransactionType.expense);
    if (scoped.isEmpty || grandTotal <= 0) return const [];

    final totals = <PaymentMethod, double>{};
    final counts = <PaymentMethod, int>{};

    for (final entry in scoped) {
      totals[entry.paymentMethod] =
          (totals[entry.paymentMethod] ?? 0) + entry.amount;
      counts[entry.paymentMethod] = (counts[entry.paymentMethod] ?? 0) + 1;
    }

    final items = totals.entries.map((e) {
      return PaymentBreakdownItem(
        method: e.key,
        totalAmount: e.value,
        percentage: (e.value / grandTotal) * 100,
        transactionCount: counts[e.key] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return items;
  }

  ExpenseEntry? findById(String id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  // Validation rules
  String? validateTitle(String? rawValue) {
    final trimmed = rawValue?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Please enter a title or merchant name.';
    }
    if (trimmed.length > maxTitleLength) {
      return 'Title must be $maxTitleLength characters or fewer.';
    }
    return null;
  }

  String? validateAmount(String? rawValue) {
    final trimmed = rawValue?.trim().replaceAll(',', '') ?? '';
    if (trimmed.isEmpty) {
      return 'Please enter an amount.';
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      return 'Enter a valid numeric amount.';
    }
    if (parsed <= 0) {
      return 'Amount must be greater than zero.';
    }
    if (parsed > maxSingleAmount) {
      return 'Amount exceeds maximum limit.';
    }
    return null;
  }

  String? validateNotes(String? rawValue) {
    final trimmed = rawValue?.trim() ?? '';
    if (trimmed.length > maxNotesLength) {
      return 'Notes must be $maxNotesLength characters or fewer.';
    }
    return null;
  }

  String? validateBudget(String? rawValue) {
    final trimmed = rawValue?.trim().replaceAll(',', '') ?? '';
    if (trimmed.isEmpty) {
      return 'Please enter a monthly budget.';
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed <= 0 || parsed > maxSingleAmount) {
      return 'Enter a valid positive budget amount.';
    }
    return null;
  }

  Future<void> loadDatabase({bool forceReload = false}) {
    if (_inFlightLoad != null) return _inFlightLoad!;
    if (_hasLoaded && !forceReload) return Future<void>.value();
    _inFlightLoad = _performLoad();
    return _inFlightLoad!;
  }

  Future<void> _performLoad() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _database.loadDatabase();
      final sorted = List<ExpenseEntry>.from(snapshot.entries)
        ..sort((a, b) => b.date.compareTo(a.date));

      _entries
        ..clear()
        ..addAll(sorted);
      _settings = snapshot.settings;
      _hasLoaded = true;
    } on DatabaseStorageException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unexpected error loading database: $e';
    } finally {
      _isLoading = false;
      _inFlightLoad = null;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void setTypeFilter(TransactionType? type) {
    if (_typeFilter == type) return;
    _typeFilter = type;
    if (type != null &&
        _categoryFilter != null &&
        !ExpenseCategory.forType(type).contains(_categoryFilter)) {
      _categoryFilter = null;
    }
    notifyListeners();
  }

  void setCategoryFilter(ExpenseCategory? category) {
    if (_categoryFilter == category) return;
    _categoryFilter = category;
    notifyListeners();
  }

  void setPaymentFilter(PaymentMethod? method) {
    if (_paymentFilter == method) return;
    _paymentFilter = method;
    notifyListeners();
  }

  void setDateRangeFilter(DateRangeFilter range) {
    if (_dateRangeFilter == range) return;
    _dateRangeFilter = range;
    notifyListeners();
  }

  void setSortOrder(ExpenseSortOrder order) {
    if (_sortOrder == order) return;
    _sortOrder = order;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _typeFilter = null;
    _categoryFilter = null;
    _paymentFilter = null;
    _dateRangeFilter = DateRangeFilter.thisMonth;
    _sortOrder = ExpenseSortOrder.newestFirst;
    notifyListeners();
  }

  String _generateId() {
    _idCounter++;
    return 'exp_${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  Future<ExpenseActionResult> addEntry({
    required String title,
    required double amount,
    required TransactionType type,
    required ExpenseCategory category,
    required PaymentMethod paymentMethod,
    required DateTime date,
    String notes = '',
  }) async {
    if (_isLoading) {
      return const ExpenseActionResult(
        success: false,
        message: 'Please wait until local data finishes loading.',
      );
    }

    final titleError = validateTitle(title);
    if (titleError != null) {
      return ExpenseActionResult(success: false, message: titleError);
    }
    if (amount <= 0 || amount > maxSingleAmount) {
      return const ExpenseActionResult(
        success: false,
        message: 'Enter a valid positive amount.',
      );
    }
    final notesError = validateNotes(notes);
    if (notesError != null) {
      return ExpenseActionResult(success: false, message: notesError);
    }

    final now = DateTime.now();
    final entry = ExpenseEntry(
      id: _generateId(),
      title: title.trim(),
      amount: double.parse(amount.toStringAsFixed(2)),
      type: type,
      category: category,
      paymentMethod: paymentMethod,
      date: date,
      notes: notes.trim(),
      createdAt: now,
      updatedAt: now,
    );

    _entries.insert(0, entry);
    _errorMessage = null;
    notifyListeners();

    final saved = await _enqueueSaveEntries();
    return ExpenseActionResult(
      success: saved,
      message: saved
          ? '${type.label} recorded successfully.'
          : (_errorMessage ?? 'Saved in memory, but local storage failed.'),
      entry: entry,
    );
  }

  Future<ExpenseActionResult> updateEntry({
    required String id,
    required String title,
    required double amount,
    required TransactionType type,
    required ExpenseCategory category,
    required PaymentMethod paymentMethod,
    required DateTime date,
    String notes = '',
  }) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) {
      return const ExpenseActionResult(
        success: false,
        message: 'Transaction could not be found.',
      );
    }

    final titleError = validateTitle(title);
    if (titleError != null) {
      return ExpenseActionResult(success: false, message: titleError);
    }
    if (amount <= 0 || amount > maxSingleAmount) {
      return const ExpenseActionResult(
        success: false,
        message: 'Enter a valid positive amount.',
      );
    }
    final notesError = validateNotes(notes);
    if (notesError != null) {
      return ExpenseActionResult(success: false, message: notesError);
    }

    final existing = _entries[index];
    final updated = existing.copyWith(
      title: title.trim(),
      amount: double.parse(amount.toStringAsFixed(2)),
      type: type,
      category: category,
      paymentMethod: paymentMethod,
      date: date,
      notes: notes.trim(),
      updatedAt: DateTime.now(),
    );

    _entries[index] = updated;
    _errorMessage = null;
    notifyListeners();

    final saved = await _enqueueSaveEntries();
    return ExpenseActionResult(
      success: saved,
      message: saved
          ? 'Transaction updated successfully.'
          : (_errorMessage ?? 'Failed to save transaction update.'),
      entry: updated,
    );
  }

  Future<ExpenseActionResult> deleteEntry(String id) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) {
      return const ExpenseActionResult(
        success: false,
        message: 'Transaction could not be found.',
      );
    }

    final removed = _entries.removeAt(index);
    _errorMessage = null;
    notifyListeners();

    final saved = await _enqueueSaveEntries();
    return ExpenseActionResult(
      success: saved,
      message: saved
          ? 'Transaction deleted.'
          : (_errorMessage ?? 'Failed to persist deletion.'),
      entry: removed,
    );
  }

  Future<ExpenseActionResult> updateBudgetSettings({
    required double monthlyBudget,
    required String currencySymbol,
  }) async {
    if (monthlyBudget <= 0 || monthlyBudget > maxSingleAmount) {
      return const ExpenseActionResult(
        success: false,
        message: 'Enter a valid positive budget amount.',
      );
    }

    final nextSettings = BudgetSettings(
      monthlyBudget: double.parse(monthlyBudget.toStringAsFixed(2)),
      currencySymbol: currencySymbol,
    );

    _settings = nextSettings;
    _errorMessage = null;
    notifyListeners();

    try {
      await _database.saveSettings(nextSettings);
      return const ExpenseActionResult(
        success: true,
        message: 'Budget & currency preferences saved.',
      );
    } on DatabaseStorageException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return ExpenseActionResult(success: false, message: e.message);
    }
  }

  String exportBackupJson() {
    return _database.exportBackupJson(
      entries: _entries,
      settings: _settings,
    );
  }

  Future<ExpenseActionResult> importBackupJson(String rawJson) async {
    try {
      final snapshot = _database.parseBackupJson(rawJson);
      final sorted = List<ExpenseEntry>.from(snapshot.entries)
        ..sort((a, b) => b.date.compareTo(a.date));

      _entries
        ..clear()
        ..addAll(sorted);
      _settings = snapshot.settings;
      _errorMessage = null;
      notifyListeners();

      await _database.saveEntries(_entries);
      await _database.saveSettings(_settings);

      return ExpenseActionResult(
        success: true,
        message: 'Restored ${_entries.length} transactions from backup.',
      );
    } on DatabaseStorageException catch (e) {
      return ExpenseActionResult(success: false, message: e.message);
    } on FormatException catch (e) {
      return ExpenseActionResult(success: false, message: e.message);
    }
  }

  Future<ExpenseActionResult> clearAllData() async {
    try {
      await _database.clearAll();
      _entries.clear();
      _settings = const BudgetSettings();
      _errorMessage = null;
      _hasLoaded = true;
      notifyListeners();
      return const ExpenseActionResult(
        success: true,
        message: 'All local transactions and settings cleared.',
      );
    } on DatabaseStorageException catch (e) {
      return ExpenseActionResult(success: false, message: e.message);
    }
  }

  Future<bool> _enqueueSaveEntries() {
    final future = _saveQueue.then((_) => _persistEntries());
    _saveQueue = future.then((_) {});
    return future;
  }

  Future<bool> _persistEntries() async {
    _isSaving = true;
    notifyListeners();
    try {
      await _database.saveEntries(List<ExpenseEntry>.unmodifiable(_entries));
      return true;
    } on DatabaseStorageException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Unexpected save error: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  static double _sumByType(
    Iterable<ExpenseEntry> list,
    TransactionType type,
  ) {
    var total = 0.0;
    for (final entry in list) {
      if (entry.type == type) {
        total += entry.amount;
      }
    }
    return total;
  }

  static List<ExpenseEntry> _filterByDateRange(
    List<ExpenseEntry> list,
    DateRangeFilter range,
  ) {
    if (range == DateRangeFilter.allTime) return list;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return list.where((entry) {
      final d = entry.date.toLocal();
      final entryDay = DateTime(d.year, d.month, d.day);

      switch (range) {
        case DateRangeFilter.today:
          return entryDay == todayStart;
        case DateRangeFilter.thisWeek:
          final weekStart =
              todayStart.subtract(Duration(days: todayStart.weekday - 1));
          return !entryDay.isBefore(weekStart);
        case DateRangeFilter.thisMonth:
          return d.year == now.year && d.month == now.month;
        case DateRangeFilter.allTime:
          return true;
      }
    }).toList(growable: false);
  }
}
