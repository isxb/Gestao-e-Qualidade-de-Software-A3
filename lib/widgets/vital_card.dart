import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class VitalCard extends StatelessWidget {
  const VitalCard({
    super.key,
    required this.label,
    required this.unit,
    required this.reference,
    required this.value,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.hint,
  });

  final String label;
  final String unit;
  final String reference;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = scheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 11,
                  letterSpacing: 0.6,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            onChanged: onChanged,
            keyboardType: keyboardType,
            inputFormatters: keyboardType == TextInputType.number
                ? <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9,\.]'),
                    ),
                  ]
                : null,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '$unit · $reference',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
