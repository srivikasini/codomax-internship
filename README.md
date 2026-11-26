# Codomax Internship

This repository contains my internship project submissions for the **Codomax Internship** program.

## Tasks

| Task | Project | Technology | Folder |
|---|---|---|---|
| **Task 1** | TaskFlow — Mobile & Web To-Do Application (UI Development & Navigation) | Flutter, Dart, Material 3, SharedPreferences | [`Task-1-TaskFlow/`](./Task-1-TaskFlow) |
| **Task 2** | SpendFlow — Expense & Budget Tracker (App Logic & Local Data) | Flutter, Dart, Material 3, Local JSON DB (`SharedPreferences`) | [`Task-2-ExpenseTracker/`](./Task-2-ExpenseTracker) |
| **Task 3** | *Upcoming* | — | — |

---

## Task 1 Overview — TaskFlow

- Multi-screen responsive Flutter UI (`Dashboard`, `My Tasks`, `Add / Edit Task`, `Task Details`, `Settings & About`)
- Category (`Personal`, `Study`, `Work`) and Status (`All`, `Pending`, `Completed`) filters + live search
- Scheduled task alarms, browser notifications, sound chime, and pre-filled `mailto:` email reminders
- Input validation, confirmation dialogs, and local persistence via `SharedPreferences`

See [`Task-1-TaskFlow/README.md`](./Task-1-TaskFlow/README.md) for setup and execution instructions.

---

## Task 2 Overview — SpendFlow

- Typed financial data schemas (`ExpenseEntry`, `BudgetSettings`, `schemaVersion: 1`) and versioned `LocalExpenseDatabase`
- INR (`₹`) Indian numbering formatting and multi-currency support (`₹`, `$`, `€`, `£`)
- Reactive `ExpenseController` calculating Net Balance, Monthly Budget %, Category Totals, and Payment Method breakdowns
- Multi-dimensional filtering (`Today`, `This Week`, `This Month`, `All Time`, Type, Category, Search, Sort) and JSON backup Export / Restore

See [`Task-2-ExpenseTracker/README.md`](./Task-2-ExpenseTracker/README.md) for setup and execution instructions.
