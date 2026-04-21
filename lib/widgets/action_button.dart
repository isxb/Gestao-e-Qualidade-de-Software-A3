import 'package:flutter/material.dart';

enum ActionButtonKind { primary, secondary, success, danger, subtle }

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = ActionButtonKind.primary,
    this.icon,
    this.fullWidth = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ActionButtonKind kind;
  final IconData? icon;
  final bool fullWidth;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Widget content = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(label, overflow: TextOverflow.ellipsis),
              ),
            ],
          );

    Widget btn;
    switch (kind) {
      case ActionButtonKind.primary:
        btn = FilledButton(
          onPressed: loading ? null : onPressed,
          child: content,
        );
        break;
      case ActionButtonKind.success:
        btn = FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D52),
            foregroundColor: Colors.white,
          ),
          child: content,
        );
        break;
      case ActionButtonKind.danger:
        btn = FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: Colors.white,
          ),
          child: content,
        );
        break;
      case ActionButtonKind.secondary:
        btn = OutlinedButton(
          onPressed: loading ? null : onPressed,
          child: content,
        );
        break;
      case ActionButtonKind.subtle:
        btn = TextButton(
          onPressed: loading ? null : onPressed,
          child: content,
        );
        break;
    }

    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
