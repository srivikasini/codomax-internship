import 'package:material_ui/material_ui.dart';

import '../models/task_item.dart';

/// Styled pill badge representing a [TaskCategory].
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.category,
    this.compact = false,
  });

  final TaskCategory category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            category.icon,
            size: compact ? 13 : 15,
            color: category.color,
          ),
          const SizedBox(width: 5),
          Text(
            category.label,
            style: TextStyle(
              fontSize: compact ? 11.5 : 12.5,
              color: category.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
