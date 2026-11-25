import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../controllers/task_scope.dart';
import '../models/task_item.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/feedback_banner.dart';
import '../widgets/task_card.dart';
import 'add_edit_task_screen.dart';
import 'task_details_screen.dart';

/// Full task management screen with search, category filter, and status filter.
class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = TaskScope.read(context).searchQuery;
    if (_searchController.text != query) {
      _searchController.text = query;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddTask() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
    );
  }

  Future<void> _openDetails(TaskItem task) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskDetailsScreen(taskId: task.id)),
    );
  }

  Future<void> _openEdit(TaskItem task) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditTaskScreen(existingTask: task)),
    );
  }

  Future<void> _handleToggle(TaskItem task) async {
    final result = await TaskScope.read(context).toggleTask(task.id);
    if (!mounted) return;
    showAppSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );
  }

  Future<void> _handleDelete(TaskItem task) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete Task',
      message: 'Are you sure you want to delete "${task.title}"?',
    );
    if (!confirmed || !mounted) return;

    final result = await TaskScope.read(context).deleteTask(task.id);
    if (!mounted) return;
    showAppSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = TaskScope.of(context);
    final filteredTasks = controller.filteredTasks;

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
                      'My Tasks',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Search, filter, and organize your tasks.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _openAddTask,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Task'),
              ),
            ],
          ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 14),
            StorageErrorBanner(
              message: controller.errorMessage!,
              onRetry: () => controller.loadTasks(forceReload: true),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: controller.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search tasks by title or notes...',
              fillColor: AppTheme.surface,
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.textSecondary,
              ),
              suffixIcon: controller.searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        controller.setSearchQuery('');
                      },
                      icon: const Icon(Icons.close),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          // Status filter segmented control (separate from category filter).
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<TaskStatusFilter>(
              segments: TaskStatusFilter.values.map((status) {
                return ButtonSegment<TaskStatusFilter>(
                  value: status,
                  label: Text(status.label),
                );
              }).toList(),
              selected: {controller.selectedStatusFilter},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  controller.setStatusFilter(selection.first);
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          // Category filter chips.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', ...TaskCategory.values.map((c) => c.label)]
                  .map((filter) {
                final isSelected = controller.selectedCategoryFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surface,
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : AppTheme.border,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => controller.setCategoryFilter(filter),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                controller.isLoading
                    ? 'Loading tasks...'
                    : '${filteredTasks.length} ${filteredTasks.length == 1 ? 'task' : 'tasks'} shown',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (controller.hasActiveFilters)
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    controller.clearFilters();
                  },
                  icon: const Icon(Icons.filter_alt_off, size: 16),
                  label: const Text('Clear filters'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : filteredTasks.isEmpty
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 12, bottom: 96),
                        child: controller.tasks.isEmpty
                            ? EmptyStateCard(
                                title: 'No tasks created yet',
                                subtitle:
                                    'Create your first task to start organizing your day.',
                                actionLabel: 'Add first task',
                                onAction: _openAddTask,
                              )
                            : EmptyStateCard(
                                title: 'No matching tasks',
                                subtitle:
                                    'Try adjusting your search query, category, or status filter.',
                                icon: Icons.filter_list_off,
                                actionLabel: 'Clear filters',
                                onAction: () {
                                  _searchController.clear();
                                  controller.clearFilters();
                                },
                              ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return TaskCard(
                            task: task,
                            onToggle: () => _handleToggle(task),
                            onTap: () => _openDetails(task),
                            onEdit: () => _openEdit(task),
                            onDelete: () => _handleDelete(task),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
