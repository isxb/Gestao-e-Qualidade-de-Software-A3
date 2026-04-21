import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Agrupamento label + campo, uniforme em todo o form.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.helper,
  });

  final String label;
  final Widget child;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12.5,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.72),
                  letterSpacing: 0.3,
                ),
          ),
        ),
        child,
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              helper!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

/// Texto simples.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool enabled;
  final int maxLines;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      onChanged: onChanged,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
      ),
    );
  }
}

/// Dropdown uniforme.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      borderRadius: BorderRadius.circular(10),
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      isExpanded: true,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
    );
  }
}
