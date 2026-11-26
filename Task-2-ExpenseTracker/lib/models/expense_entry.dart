import 'package:material_ui/material_ui.dart';

/// Transaction polarity for entries in SpendFlow.
enum TransactionType {
  expense,
  income;

  String get label {
    switch (this) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
    }
  }

  static TransactionType fromString(String? raw) {
    return raw?.trim().toLowerCase() == 'income'
        ? TransactionType.income
        : TransactionType.expense;
  }
}

/// Supported spending and income categories.
enum ExpenseCategory {
  food,
  transport,
  bills,
  shopping,
  health,
  education,
  entertainment,
  salary,
  freelance,
  other;

  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food & Dining';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.bills:
        return 'Bills & Utilities';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.salary:
        return 'Salary';
      case ExpenseCategory.freelance:
        return 'Freelance';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFEA580C);
      case ExpenseCategory.transport:
        return const Color(0xFF0284C7);
      case ExpenseCategory.bills:
        return const Color(0xFF7C3AED);
      case ExpenseCategory.shopping:
        return const Color(0xFFDB2777);
      case ExpenseCategory.health:
        return const Color(0xFFDC2626);
      case ExpenseCategory.education:
        return const Color(0xFF2563EB);
      case ExpenseCategory.entertainment:
        return const Color(0xFFD97706);
      case ExpenseCategory.salary:
        return const Color(0xFF16A34A);
      case ExpenseCategory.freelance:
        return const Color(0xFF0D9488);
      case ExpenseCategory.other:
        return const Color(0xFF64748B);
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_outlined;
      case ExpenseCategory.transport:
        return Icons.directions_car_outlined;
      case ExpenseCategory.bills:
        return Icons.receipt_long_outlined;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_outlined;
      case ExpenseCategory.health:
        return Icons.medical_services_outlined;
      case ExpenseCategory.education:
        return Icons.school_outlined;
      case ExpenseCategory.entertainment:
        return Icons.movie_outlined;
      case ExpenseCategory.salary:
        return Icons.account_balance_wallet_outlined;
      case ExpenseCategory.freelance:
        return Icons.laptop_mac_outlined;
      case ExpenseCategory.other:
        return Icons.category_outlined;
    }
  }

  static List<ExpenseCategory> forType(TransactionType type) {
    if (type == TransactionType.income) {
      return const [
        ExpenseCategory.salary,
        ExpenseCategory.freelance,
        ExpenseCategory.other,
      ];
    }
    return const [
      ExpenseCategory.food,
      ExpenseCategory.transport,
      ExpenseCategory.bills,
      ExpenseCategory.shopping,
      ExpenseCategory.health,
      ExpenseCategory.education,
      ExpenseCategory.entertainment,
      ExpenseCategory.other,
    ];
  }

  static ExpenseCategory fromString(String? raw) {
    final normalized = raw?.trim().toLowerCase() ?? '';
    for (final value in ExpenseCategory.values) {
      if (value.name.toLowerCase() == normalized ||
          value.label.toLowerCase() == normalized) {
        return value;
      }
    }
    return ExpenseCategory.other;
  }
}

/// Payment instrument used for a transaction.
enum PaymentMethod {
  upi,
  card,
  cash,
  bankTransfer;

  String get label {
    switch (this) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.upi:
        return Icons.qr_code_2;
      case PaymentMethod.card:
        return Icons.credit_card_outlined;
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_outlined;
    }
  }

  static PaymentMethod fromString(String? raw) {
    final normalized = raw?.trim().toLowerCase() ?? '';
    for (final value in PaymentMethod.values) {
      if (value.name.toLowerCase() == normalized ||
          value.label.toLowerCase() == normalized) {
        return value;
      }
    }
    return PaymentMethod.upi;
  }
}

/// Date range presets for filtering transactions and analytics.
enum DateRangeFilter {
  today,
  thisWeek,
  thisMonth,
  allTime;

  String get label {
    switch (this) {
      case DateRangeFilter.today:
        return 'Today';
      case DateRangeFilter.thisWeek:
        return 'This Week';
      case DateRangeFilter.thisMonth:
        return 'This Month';
      case DateRangeFilter.allTime:
        return 'All Time';
    }
  }
}

/// Sort order options for the Transactions screen.
enum ExpenseSortOrder {
  newestFirst,
  highestAmount,
  lowestAmount;

  String get label {
    switch (this) {
      case ExpenseSortOrder.newestFirst:
        return 'Newest';
      case ExpenseSortOrder.highestAmount:
        return 'Highest ₹';
      case ExpenseSortOrder.lowestAmount:
        return 'Lowest ₹';
    }
  }
}

/// Immutable database record representing a single financial entry.
class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.paymentMethod,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
  });

  static const int currentSchemaVersion = 1;

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final ExpenseCategory category;
  final PaymentMethod paymentMethod;
  final DateTime date;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseEntry copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    ExpenseCategory? category,
    PaymentMethod? paymentMethod,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': currentSchemaVersion,
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category.name,
      'paymentMethod': paymentMethod.name,
      'date': date.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ExpenseEntry.fromJson(
    Map<String, dynamic> json, {
    int fallbackIndex = 0,
  }) {
    final rawTitle = json['title'];
    final title = rawTitle is String ? rawTitle.trim() : '';
    if (title.isEmpty) {
      throw const FormatException('Expense entry is missing a valid title.');
    }

    final rawAmount = json['amount'];
    final double? parsedAmount = switch (rawAmount) {
      num n => n.toDouble(),
      String s => double.tryParse(s.trim()),
      _ => null,
    };
    if (parsedAmount == null || parsedAmount <= 0 || parsedAmount.isNaN) {
      throw const FormatException('Expense entry has an invalid amount.');
    }

    final now = DateTime.now();
    final rawDate = json['date'];
    final date = rawDate is String ? (DateTime.tryParse(rawDate) ?? now) : now;

    final rawCreatedAt = json['createdAt'];
    final createdAt = rawCreatedAt is String
        ? (DateTime.tryParse(rawCreatedAt) ?? date)
        : date;

    final rawUpdatedAt = json['updatedAt'];
    final updatedAt = rawUpdatedAt is String
        ? (DateTime.tryParse(rawUpdatedAt) ?? createdAt)
        : createdAt;

    final rawId = json['id'];
    final id = (rawId is String && rawId.trim().isNotEmpty)
        ? rawId.trim()
        : 'entry_${createdAt.microsecondsSinceEpoch}_$fallbackIndex';

    final rawNotes = json['notes'];
    final notes = rawNotes is String ? rawNotes.trim() : '';

    return ExpenseEntry(
      id: id,
      title: title,
      amount: double.parse(parsedAmount.toStringAsFixed(2)),
      type: TransactionType.fromString(json['type'] as String?),
      category: ExpenseCategory.fromString(json['category'] as String?),
      paymentMethod:
          PaymentMethod.fromString(json['paymentMethod'] as String?),
      date: date,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Persisted budget and currency schema for SpendFlow.
class BudgetSettings {
  const BudgetSettings({
    this.monthlyBudget = 25000.0,
    this.currencySymbol = '₹',
  });

  static const List<String> supportedCurrencies = ['₹', '\$', '€', '£'];

  final double monthlyBudget;
  final String currencySymbol;

  BudgetSettings copyWith({
    double? monthlyBudget,
    String? currencySymbol,
  }) {
    return BudgetSettings(
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': ExpenseEntry.currentSchemaVersion,
      'monthlyBudget': monthlyBudget,
      'currencySymbol': currencySymbol,
    };
  }

  factory BudgetSettings.fromJson(Map<String, dynamic> json) {
    final rawBudget = json['monthlyBudget'];
    final parsedBudget = switch (rawBudget) {
      num n => n.toDouble(),
      String s => double.tryParse(s.trim()),
      _ => null,
    };

    final rawCurrency = json['currencySymbol'];
    final currency = (rawCurrency is String &&
            supportedCurrencies.contains(rawCurrency.trim()))
        ? rawCurrency.trim()
        : '₹';

    return BudgetSettings(
      monthlyBudget:
          (parsedBudget != null && parsedBudget > 0) ? parsedBudget : 25000.0,
      currencySymbol: currency,
    );
  }
}
