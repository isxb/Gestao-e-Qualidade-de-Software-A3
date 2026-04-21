import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Cartão numérico de destaque para dashboards (total de usuários,
/// evoluções no dia, logins na semana, etc).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.gradient,
    this.accent,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;
  final LinearGradient? gradient;
  final Color? accent;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool hasGradient = gradient != null;
    final Color fgSoft = hasGradient
        ? Colors.white.withValues(alpha: 0.88)
        : theme.colorScheme.onSurface.withValues(alpha: 0.72);
    final Color fgStrong =
        hasGradient ? Colors.white : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: gradient,
            color: hasGradient ? null : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: hasGradient
                  ? Colors.white.withValues(alpha: 0.12)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            boxShadow: hasGradient
                ? <BoxShadow>[
                    BoxShadow(
                      color: (accent ?? AppColors.indigo)
                          .withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: -6,
                    ),
                  ]
                : AppColors.softShadow(opacity: isDark ? 0.25 : 0.06),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hasGradient
                          ? Colors.white.withValues(alpha: 0.18)
                          : (accent ?? theme.colorScheme.primary)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 20,
                      color: hasGradient
                          ? Colors.white
                          : (accent ?? theme.colorScheme.primary),
                    ),
                  ),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: fgStrong,
                  fontSize: 28,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: fgSoft,
                  letterSpacing: 0.3,
                ),
              ),
              if (hint != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  hint!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: fgSoft,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
