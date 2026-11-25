import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import '../controllers/task_controller.dart';
import '../controllers/task_scope.dart';
import '../models/task_item.dart';
import '../widgets/feedback_banner.dart';

/// Screen for creating a new task or editing an existing [TaskItem].
class AddEditTaskScreen extends StatefulWidget {
  const AddEditTaskScreen({
    super.key,
    this.existingTask,
  });

  final TaskItem? existingTask;

  bool get isEditing => existingTask != null;

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  late TaskCategory _selectedCategory;
  late bool _isCompleted;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _notesController = TextEditingController(text: task?.notes ?? '');
    _selectedCategory = task?.category ?? TaskCategory.personal;
    _isCompleted = task?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
    });

    final controller = TaskScope.read(context);
    final TaskActionResult result;

    if (widget.isEditing) {
      result = await controller.updateTask(
        id: widget.existingTask!.id,
        title: _titleController.text,
        notes: _notesController.text,
        category: _selectedCategory,
        isCompleted: _isCompleted,
      );
    } else {
      result = await controller.addTask(
        title: _titleController.text,
        notes: _notesController.text,
        category: _selectedCategory,
      );
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    showAppSnackBar(
      context,
      message: result.message,
      isError: !result.success,
    );

    if (result.success) {
      Navigator.of(context).pop(result.task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TaskScope.of(context);
    final isEditing = widget.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Add New Task'),
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
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing
                          ? 'Update task details'
                          : 'Create a task to stay on track',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Give your task a clear title and assign a category.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: _titleController,
                      maxLength: TaskController.maxTitleLength,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Task Title *',
                        hintText: 'e.g., Complete Flutter assignment',
                        prefixIcon: Icon(
                          Icons.edit_note,
                          color: AppTheme.primary,
                        ),
                      ),
                      validator: (value) => controller.validateTitle(
                        value,
                        excludeTaskId: widget.existingTask?.id,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLength: TaskController.maxNotesLength,
                      maxLines: 3,
                      minLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Add extra context, checklist items, or links...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Icon(
                            Icons.notes_outlined,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      validator: controller.validateNotes,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: TaskCategory.values.map((category) {
                        final selected = _selectedCategory == category;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category.icon,
                                size: 16,
                                color: selected
                                    ? Colors.white
                                    : category.color,
                              ),
                              const SizedBox(width: 6),
                              Text(category.label),
                            ],
                          ),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: category.color,
                          backgroundColor: AppTheme.background,
                          side: BorderSide(
                            color: selected ? category.color : AppTheme.border,
                          ),
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (isEditing) ...[
                      const SizedBox(height: 18),
                      Material(
                        color: AppTheme.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppTheme.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SwitchListTile(
                          value: _isCompleted,
                          activeThumbColor: AppTheme.primary,
                          title: const Text(
                            'Mark as completed',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            _isCompleted
                                ? 'This task is marked completed.'
                                : 'This task is currently pending.',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _isCompleted = value;
                            });
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
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
                              backgroundColor: AppTheme.primary,
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
                                    isEditing
                                        ? Icons.save_outlined
                                        : Icons.add_task,
                                  ),
                            label: Text(
                              isEditing ? 'Save Changes' : 'Create Task',
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
