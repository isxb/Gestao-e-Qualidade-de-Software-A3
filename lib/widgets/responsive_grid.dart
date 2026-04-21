import 'package:flutter/material.dart';

/// Grid responsivo — 1 coluna no mobile, 2 colunas no tablet, 3 no desktop
/// conforme o [minItemWidth]. Calcula automaticamente as linhas e mantém
/// espaçamento consistente.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.minItemWidth = 260,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        int columns = (width / minItemWidth).floor();
        if (columns < 1) columns = 1;
        if (columns > children.length) columns = children.length;
        if (columns < 1) columns = 1;

        final double totalSpacing = spacing * (columns - 1);
        final double itemWidth = (width - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map((Widget c) => SizedBox(width: itemWidth, child: c))
              .toList(),
        );
      },
    );
  }
}
