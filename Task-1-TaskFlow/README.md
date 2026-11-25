# TaskFlow — Mobile & Web To-Do Application

**Codomax Internship — Task 1: UI Development & Navigation**

TaskFlow is a modern, responsive Flutter productivity and to-do application designed for managing daily tasks across **Personal**, **Study**, and **Work** categories with multi-screen navigation, live search and filtering, input validation, and reliable local persistence via `SharedPreferences`.

---

## Project Overview

TaskFlow helps users organize daily goals with an intuitive dashboard, live completion progress tracking, structured category & status filters, detailed task views, and persistent local storage across app restarts and browser refreshes.

The project was upgraded from a single-screen prototype into a modular, multi-screen Flutter architecture supporting both mobile (`NavigationBar`) and wide desktop/web (`NavigationRail`) layouts.

---

## Features

### UI & Responsive Navigation
- **Responsive Multi-Screen Shell** (`MainShell`):
  - **Mobile / Narrow Layout (`< 840px`)**: Bottom `NavigationBar` + `FloatingActionButton.extended`
  - **Desktop / Web Wide Layout (`>= 840px`)**: Left `NavigationRail` + centered responsive content container
- **5 Dedicated Screens**:
  1. **Dashboard** — Welcome header, gradient daily progress banner, interactive statistics cards (`Total`, `Completed`, `Pending`), category breakdown tiles, inline Quick Add form, and recent tasks preview.
  2. **My Tasks** — Full task manager with real-time search bar, separate **Status** segmented filter (`All`, `Pending`, `Completed`), **Category** filter chips (`All`, `Personal`, `Study`, `Work`), and clear-filters control.
  3. **Add / Edit Task** — Dedicated form screen with title validation, optional notes, category selector chips, completion toggle (when editing), and double-submission protection.
  4. **Task Details** — Complete view of task title, notes, category badge, status badge, created/updated timestamps, toggle completion/reopen button, Edit shortcut, and Delete confirmation.
  5. **Settings & About** — App metadata, local `SharedPreferences` storage status, stored task summary, and a confirmation-protected **Clear Completed Tasks** action.
- **UI States**: Dedicated loading spinner, distinct empty states (no tasks vs. no filter matches), inline storage error banner with Retry/Reset recovery, and floating feedback snackbars.

### Task Management
- Add new tasks (via Dashboard Quick Add or Add/Edit screen)
- Edit existing task title, notes, category, and completion status
- Delete tasks with destructive-action confirmation dialog
- Mark pending tasks as completed and reopen completed tasks as pending
- Assign categories: `Personal`, `Study`, `Work`
- Filter independently by **Category** and **Status** (`All`, `Pending`, `Completed`)
- Search tasks in real time by title or notes
- Live statistics: Total, Completed, Pending, and completion progress percentage

### Input Validation & Error Handling
- Empty and whitespace-only title validation
- Maximum title length (`100` characters) and notes length (`300` characters)
- Case-insensitive duplicate title prevention
- Concurrent submission guard (`_isSubmitting` / `_isSaving`)
- Graceful recovery for corrupted or invalid stored JSON

### Data Persistence
- Built on `shared_preferences` (`taskflow_tasks` JSON key)
- Backward-compatible deserialization for legacy task maps (`title`, `category`, `completed`)
- Duplicate-load protection (`loadTasks()` guard)
- Sequential save queue (`_enqueueSave()`) so rapid edits/toggles do not race or lose updates

---

## Technologies Used

- **Framework**: Flutter `3.50.1` (Material 3 via `material_ui: ^1.1.0`)
- **Language**: Dart `3.14.0`
- **Local Storage**: `shared_preferences: ^2.5.6`
- **Testing**: `flutter_test` (unit tests for controller/storage + widget tests for UI & navigation)
- **Linting**: `flutter_lints: ^6.0.0`

---

## Project Structure

```text
codomax_todo_app/
├── lib/
│   ├── main.dart                         # App entry point & global ErrorWidget handler
│   ├── app/
│   │   ├── taskflow_app.dart             # Root MaterialApp & TaskScope setup
│   │   └── theme.dart                    # Centralized colors & Material 3 theme
│   ├── controllers/
│   │   ├── task_controller.dart          # State management, filters, validation & save queue
│   │   └── task_scope.dart               # InheritedNotifier scope for reactive UI updates
│   ├── models/
│   │   └── task_item.dart                # TaskItem, TaskCategory & TaskStatusFilter models
│   ├── services/
│   │   └── task_storage_service.dart     # SharedPreferences JSON persistence & error handling
│   ├── screens/
│   │   ├── main_shell.dart               # Responsive NavigationBar / NavigationRail shell
│   │   ├── dashboard_screen.dart         # Dashboard overview, stats & Quick Add
│   │   ├── my_tasks_screen.dart          # Search, category/status filters & full task list
│   │   ├── add_edit_task_screen.dart     # Create / edit task form screen
│   │   ├── task_details_screen.dart      # Detailed task view & actions
│   │   └── settings_about_screen.dart    # App info, storage summary & clear completed
│   └── widgets/
│       ├── brand_header.dart             # TaskFlow header branding
│       ├── category_badge.dart           # Category icon + colored pill badge
│       ├── confirm_delete_dialog.dart    # Confirmation dialog for destructive actions
│       ├── empty_state_card.dart         # Empty & no-results placeholder card
│       ├── feedback_banner.dart          # Floating SnackBar helper & storage error banner
│       ├── progress_banner.dart          # Gradient daily progress banner
│       ├── stat_card.dart                # Interactive summary metric card
│       └── task_card.dart                # Task list card with toggle, edit & delete actions
├── test/
│   ├── task_controller_test.dart         # Unit tests for storage, validation, filters & persistence
│   └── widget_test.dart                  # Widget tests for UI, forms, dialogs & multi-screen nav
├── web/
│   ├── index.html                        # Web entry page configured for TaskFlow
│   └── manifest.json                     # PWA manifest metadata
├── docs/
│   └── SUBMISSION_REPORT.md              # Codomax Internship Task 1 completion report
├── pubspec.yaml
└── README.md
```

---

## Installation & Setup

### Prerequisites
- Flutter SDK (`3.50.1` or compatible)
- Dart SDK (`3.14.0` or compatible)
- Google Chrome (for web execution) or Windows Desktop toolchain

### Steps
1. Clone or open the repository:
   ```bash
   cd C:\src\codomax_todo_app
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```

---

## How to Run the Application

### Run in Chrome (Development)
```bash
flutter run -d chrome
```

### Run on a Fixed Port (Recommended for Testing Web Storage Across Browser Restarts)
Using a fixed port ensures `SharedPreferences` (`localStorage`) uses the exact same origin across browser sessions:
```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8095
```
Then open `http://127.0.0.1:8095` in Chrome.

### Build Production Web Bundle
```bash
flutter build web
```

### Run on Windows Desktop
```bash
flutter run -d windows
```

---

## Testing & Quality Checks

Run static analysis and automated tests:
```bash
flutter analyze
flutter test
```

### Automated Test Coverage (`8` tests passing)
- **`test/task_controller_test.dart`** (`5` tests):
  - Legacy JSON compatibility and duplicate-load prevention
  - Corrupted JSON error handling and recovery reset
  - Empty, whitespace-only, max-length, and duplicate title validation
  - End-to-end persistence of add, edit, complete, reopen, and delete across simulated restarts
  - Combined category, status, and search filtering
- **`test/widget_test.dart`** (`3` tests):
  - Dashboard Quick Add, empty/whitespace validation, completion toggle, and live statistics updates
  - Multi-screen navigation (`Dashboard` -> `Add Task` -> `My Tasks` -> `Task Details` -> `Edit Task` -> `Delete` confirmation dialog)
  - Wide-screen `NavigationRail` layout and `Settings & About` screen rendering

---

## Screenshots

> Add screenshots of the running application in `screenshots/` (`01_dashboard.png`, `02_my_tasks.png`, `03_add_edit_task.png`, `04_task_details.png`, `05_settings_about.png`) and embed them below:

- **Dashboard** — Progress banner, task statistics, category overview, and quick add
- **My Tasks** — Search bar, status segmented filter, category chips, and task list
- **Add / Edit Task** — Validated form with category selection and notes
- **Task Details** — Complete task overview with status toggle, edit, and delete confirmation
- **Settings & About** — App details, `SharedPreferences` storage status, and completed-task cleanup
