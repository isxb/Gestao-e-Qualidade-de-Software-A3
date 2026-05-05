import 'package:flutter/material.dart';

/// Converte `**texto**` em [TextSpan] com peso bold, mantendo as quebras de
/// linha. Usado para exibir o texto gerado pelo template — marcadores simples
/// de negrito em cima de texto plano.
class BoldMarkdown extends StatelessWidget {
  const BoldMarkdown(
    this.text, {
    super.key,
    this.baseStyle,
    this.selectable = true,
  });

  final String text;
  final TextStyle? baseStyle;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = (baseStyle ??
            Theme.of(context).textTheme.bodyLarge ?? const TextStyle())
        .copyWith(height: 1.75);
    final List<TextSpan> spans = _parse(text, style);
    final TextSpan root = TextSpan(children: spans);
    if (selectable) {
      return SelectableText.rich(root, style: style);
    }
    return RichText(text: root);
  }

  List<TextSpan> _parse(String raw, TextStyle base) {
    final List<TextSpan> out = <TextSpan>[];
    final RegExp re = RegExp(r'\*\*(.+?)\*\*');
    int cursor = 0;
    for (final RegExpMatch m in re.allMatches(raw)) {
      if (m.start > cursor) {
        out.add(TextSpan(text: raw.substring(cursor, m.start), style: base));
      }
      out.add(
        TextSpan(
          text: m.group(1),
          style: base.copyWith(fontWeight: FontWeight.w800),
        ),
      );
      cursor = m.end;
    }
    if (cursor < raw.length) {
      out.add(TextSpan(text: raw.substring(cursor), style: base));
    }
    return out;
  }
}
