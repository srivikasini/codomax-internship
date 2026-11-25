import 'package:material_ui/material_ui.dart';

import '../controllers/task_controller.dart';
import '../controllers/task_scope.dart';
import '../screens/main_shell.dart';
import 'theme.dart';

/// Root application widget configuring theme, error boundary, and [TaskController].
class TaskFlowApp extends StatefulWidget {
  const TaskFlowApp({
    super.key,
    this.controller,
  });

  final TaskController? controller;

  @override
  State<TaskFlowApp> createState() => _TaskFlowAppState();
}

class _TaskFlowAppState extends State<TaskFlowApp> {
  late final TaskController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TaskController();
    _controller.loadTasks();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TaskScope(
      controller: _controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TaskFlow',
        theme: AppTheme.light(),
        home: const MainShell(),
      ),
    );
  }
}
