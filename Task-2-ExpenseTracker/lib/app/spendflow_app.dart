import 'package:material_ui/material_ui.dart';

import '../controllers/expense_controller.dart';
import '../controllers/expense_scope.dart';
import '../screens/main_shell.dart';
import 'theme.dart';

/// Root SpendFlow widget initializing state scope and Material 3 theme.
class SpendFlowApp extends StatefulWidget {
  const SpendFlowApp({
    super.key,
    this.controller,
  });

  final ExpenseController? controller;

  @override
  State<SpendFlowApp> createState() => _SpendFlowAppState();
}

class _SpendFlowAppState extends State<SpendFlowApp> {
  late final ExpenseController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? ExpenseController();
    _controller.loadDatabase();
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
    return ExpenseScope(
      controller: _controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SpendFlow',
        theme: SpendFlowTheme.light(),
        home: const MainShell(),
      ),
    );
  }
}
