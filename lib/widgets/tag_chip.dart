import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.onRemove,
  });

  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = scheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.4,
                  ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
              splashRadius: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 30,
                minHeight: 30,
              ),
              onPressed: onRemove,
              tooltip: 'Remover',
            ),
        ],
      ),
    );
  }
}
