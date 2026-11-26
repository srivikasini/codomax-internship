import 'package:material_ui/material_ui.dart';

import 'app/spendflow_app.dart';
import 'app/theme.dart';

export 'app/spendflow_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: SpendFlowTheme.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: SpendFlowTheme.expense,
                size: 46,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unexpected display error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SpendFlowTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: SpendFlowTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const SpendFlowApp());
}
