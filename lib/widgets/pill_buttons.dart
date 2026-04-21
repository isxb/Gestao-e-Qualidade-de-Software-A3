import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Botão pílula — reutilizado para checkboxes e radios com a mesma estética.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = scheme.brightness == Brightness.dark;

    final Color borderColor = selected
        ? scheme.primary
        : Theme.of(context).dividerColor;
    final Color bgColor = selected
        ? (isDark
            ? scheme.primary.withValues(alpha: 0.18)
            : AppColors.indigoLight)
        : Theme.of(context).colorScheme.surface;
    final Color fgColor = selected
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: enabled ? 1 : 0.4);

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.18),
                ),
              ),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fgColor,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrap que alinha Pills com espaçamento consistente.
class PillGroup extends StatelessWidget {
  const PillGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }
}
