import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';

/// Displays a floating feedback snackbar for task actions and errors.
void showAppSnackBar(
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
        backgroundColor: isError ? AppTheme.danger : AppTheme.textPrimary,
      ),
    );
}

/// Inline banner shown when local storage fails to load or save.
class StorageErrorBanner extends StatelessWidget {
  const StorageErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
    this.onResetStorage,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onResetStorage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Storage Notice',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.danger,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
              if (onResetStorage != null)
                TextButton(
                  onPressed: onResetStorage,
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: AppTheme.danger),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
