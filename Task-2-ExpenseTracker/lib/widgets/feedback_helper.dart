import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';

/// Displays a floating feedback snackbar for SpendFlow actions and errors.
void showSpendSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? SpendFlowTheme.expense : SpendFlowTheme.textPrimary,
      ),
    );
}

/// Inline banner shown when local database load/save fails.
class DatabaseErrorBanner extends StatelessWidget {
  const DatabaseErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
    this.onReset,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SpendFlowTheme.expense.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SpendFlowTheme.expense.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: SpendFlowTheme.expense,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Database Notice',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: SpendFlowTheme.expense,
                  ),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
              if (onReset != null)
                TextButton(
                  onPressed: onReset,
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: SpendFlowTheme.expense),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: SpendFlowTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
