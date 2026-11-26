# SpendFlow — Mobile & Web Expense Tracker

A personal expense, income, and monthly budget tracking application built with **Flutter**, **Dart**, **Material 3**, and a versioned local JSON database (`SharedPreferences`).

---

## Features

- **INR (`₹`) Default & Multi-Currency Support**: Indian lakh/crore comma formatting (`₹1,25,450`) with configurable currency (`₹`, `$`, `€`, `£`).
- **4-Tab Responsive Navigation**:
  - **Overview**: Net balance hero card, monthly budget progress bar with overspend warning, income/spend/net summary cards, top categories breakdown, and recent transactions.
  - **Transactions**: Live search, date-range filters (`Today`, `This Week`, `This Month`, `All Time`), Type (`All`, `Expense`, `Income`), Category, and Sort (`Newest`, `Highest ₹`, `Lowest ₹`) with filtered totals bar.
  - **Analytics**: Period-scoped Cash Flow summary, Expense & Income category breakdowns, and Payment Method distribution (`UPI`, `Card`, `Cash`, `Bank Transfer`).
  - **Budget & Data**: Monthly budget editor, currency selector, local database schema overview, JSON backup **Export** and **Import / Restore**, and confirmation-protected reset.
- **Add / Edit & Details Screens**: Quick amount chips (`+₹100`, `+₹250`, `+₹500`, `+₹1000`), category & payment method selectors, date picker, notes, validation, and confirmation before deleting.
- **Local Data & State Architecture**:
  - Typed `ExpenseEntry` & `BudgetSettings` schemas (`schemaVersion: 1`)
  - `LocalExpenseDatabase` with sequential save queuing, corruption recovery, and JSON backup import/export
  - Reactive `ExpenseController` (`ChangeNotifier` + `ExpenseScope`)

---

## Project Structure

```text
Task-2-ExpenseTracker/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── spendflow_app.dart
│   │   └── theme.dart
│   ├── controllers/
│   │   ├── expense_controller.dart
│   │   └── expense_scope.dart
│   ├── models/
│   │   └── expense_entry.dart
│   ├── screens/
│   │   ├── add_edit_entry_screen.dart
│   │   ├── analytics_screen.dart
│   │   ├── budget_data_screen.dart
│   │   ├── entry_details_screen.dart
│   │   ├── main_shell.dart
│   │   ├── overview_screen.dart
│   │   └── transactions_screen.dart
│   ├── services/
│   │   └── local_expense_database.dart
│   ├── utils/
│   │   └── formatters.dart
│   └── widgets/
│       ├── balance_hero_card.dart
│       ├── category_breakdown_card.dart
│       ├── confirm_dialog.dart
│       ├── empty_state_card.dart
│       ├── feedback_helper.dart
│       ├── summary_stat_card.dart
│       └── transaction_tile.dart
├── test/
│   ├── expense_controller_test.dart
│   └── widget_test.dart
├── web/
│   ├── index.html
│   └── manifest.json
├── pubspec.yaml
└── README.md
```

---

## Run & Test

```powershell
cd C:\src\codomax-internship\Task-2-ExpenseTracker
flutter pub get
flutter analyze
flutter test

# Run in Chrome on a fixed origin (preserves localStorage across restarts):
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8096
```
