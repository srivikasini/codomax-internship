import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../controllers/expense_scope.dart';
import '../models/expense_entry.dart';
import 'add_edit_entry_screen.dart';
import 'analytics_screen.dart';
import 'budget_data_screen.dart';
import 'overview_screen.dart';
import 'transactions_screen.dart';

/// Responsive navigation shell for SpendFlow across Overview, Transactions, Analytics, and Budget.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _navigateToTransactions({
    TransactionType? typeFilter,
    ExpenseCategory? categoryFilter,
  }) {
    final controller = ExpenseScope.read(context);
    controller.setTypeFilter(typeFilter);
    controller.setCategoryFilter(categoryFilter);
    setState(() {
      _selectedIndex = 1;
    });
  }

  Future<void> _openAddEntry() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditEntryScreen()),
    );
  }

  Widget _buildActiveScreen() {
    switch (_selectedIndex) {
      case 0:
        return OverviewScreen(
          onNavigateToTransactions: _navigateToTransactions,
        );
      case 1:
        return const TransactionsScreen();
      case 2:
        return const AnalyticsScreen();
      case 3:
      default:
        return const BudgetDataScreen();
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
                backgroundColor: SpendFlowTheme.surface,
                indicatorColor: SpendFlowTheme.primary.withValues(alpha: 0.14),
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: FloatingActionButton.small(
                    heroTag: 'spendflow_rail_fab',
                    backgroundColor: SpendFlowTheme.primary,
                    foregroundColor: Colors.white,
                    tooltip: 'Add Transaction',
                    onPressed: _openAddEntry,
                    child: const Icon(Icons.add),
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(
                      Icons.dashboard,
                      color: SpendFlowTheme.primary,
                    ),
                    label: Text('Overview'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(
                      Icons.receipt_long,
                      color: SpendFlowTheme.primary,
                    ),
                    label: Text('Transactions'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(
                      Icons.bar_chart,
                      color: SpendFlowTheme.primary,
                    ),
                    label: Text('Analytics'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.tune_outlined),
                    selectedIcon: Icon(
                      Icons.tune,
                      color: SpendFlowTheme.primary,
                    ),
                    label: Text('Budget'),
                  ),
                ],
              ),
            if (isWide)
              const VerticalDivider(width: 1, color: SpendFlowTheme.border),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: _buildActiveScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: (!isWide && _selectedIndex < 2)
          ? FloatingActionButton.extended(
              heroTag: 'spendflow_mobile_fab',
              backgroundColor: SpendFlowTheme.primary,
              foregroundColor: Colors.white,
              onPressed: _openAddEntry,
              icon: const Icon(Icons.add),
              label: const Text('Add Entry'),
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
                  label: 'Overview',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Transactions',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Analytics',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: 'Budget',
                ),
              ],
            ),
    );
  }
}
