import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../controllers/task_scope.dart';
import '../models/task_item.dart';
import 'add_edit_task_screen.dart';
import 'dashboard_screen.dart';
import 'my_tasks_screen.dart';
import 'settings_about_screen.dart';

/// Responsive top-level navigation shell hosting Dashboard, My Tasks, and Settings.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _navigateToTasks({
    String? categoryFilter,
    TaskStatusFilter? statusFilter,
  }) {
    final controller = TaskScope.read(context);
    if (categoryFilter != null) {
      controller.setCategoryFilter(categoryFilter);
    }
    if (statusFilter != null) {
      controller.setStatusFilter(statusFilter);
    }
    setState(() {
      _selectedIndex = 1;
    });
  }

  Future<void> _openAddTaskScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
    );
  }

  Widget _buildActiveScreen() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(onNavigateToTasks: _navigateToTasks);
      case 1:
        return const MyTasksScreen();
      case 2:
      default:
        return const SettingsAboutScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 840;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (isWide)
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                extended: MediaQuery.sizeOf(context).width >= 1100,
                backgroundColor: AppTheme.surface,
                indicatorColor: AppTheme.primary.withValues(alpha: 0.14),
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: FloatingActionButton.small(
                    heroTag: 'rail_add_task_fab',
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    tooltip: 'Add New Task',
                    onPressed: _openAddTaskScreen,
                    child: const Icon(Icons.add),
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard, color: AppTheme.primary),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.checklist_outlined),
                    selectedIcon: Icon(Icons.checklist, color: AppTheme.primary),
                    label: Text('My Tasks'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings, color: AppTheme.primary),
                    label: Text('Settings'),
                  ),
                ],
              ),
            if (isWide) const VerticalDivider(width: 1, color: AppTheme.border),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: _buildActiveScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: (!isWide && _selectedIndex != 2)
          ? FloatingActionButton.extended(
              heroTag: 'mobile_add_task_fab',
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              onPressed: _openAddTaskScreen,
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            )
          : null,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.checklist_outlined),
                  selectedIcon: Icon(Icons.checklist),
                  label: 'My Tasks',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
    );
  }
}
