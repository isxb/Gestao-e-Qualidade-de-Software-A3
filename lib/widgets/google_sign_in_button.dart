import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Botão "Continuar com Google" com a aparência clássica do guideline
/// oficial: superfície branca, borda neutra, logotipo G colorido à
/// esquerda. Funciona em fundos claros e escuros.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.label = 'Continuar com Google',
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool disabled = onPressed == null || loading;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: const Color(0xFFDADCE0)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Color(0xFF4285F4),
                    ),
                  )
                else
                  const _GoogleGLogo(size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF3C4043),
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logotipo "G" do Google desenhado a mão — quatro arcos coloridos
/// no anel exterior + barra horizontal interior em azul. Não depende
/// de assets externos.
class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo({this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  static const Color _blue = Color(0xFF4285F4);
  static const Color _red = Color(0xFFEA4335);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double stroke = w * 0.22;
    final Offset center = Offset(w / 2, h / 2);
    final double radius = (w / 2) - (stroke / 2);
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    Paint arcPaint(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Azul: arco do topo até a direita (-90° → ~ -10°)
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 0.42,
      false,
      arcPaint(_blue),
    );

    // Verde: direita até base direita (~ -10° → ~ 90°)
    canvas.drawArc(
      arcRect,
      -math.pi / 2 + math.pi * 0.42,
      math.pi * 0.5,
      false,
      arcPaint(_green),
    );

    // Amarelo: base esquerda
    canvas.drawArc(
      arcRect,
      math.pi / 2,
      math.pi * 0.5,
      false,
      arcPaint(_yellow),
    );

    // Vermelho: lateral esquerda até topo
    canvas.drawArc(
      arcRect,
      math.pi,
      math.pi * 0.5,
      false,
      arcPaint(_red),
    );

    // Barra horizontal interna do "G" (corte azul à direita do centro).
    final Paint bar = Paint()
      ..color = _blue
      ..style = PaintingStyle.fill;
    final double barH = h * 0.16;
    final Rect barRect = Rect.fromLTWH(
      w * 0.50,
      (h - barH) / 2,
      w * 0.46,
      barH,
    );
    canvas.drawRect(barRect, bar);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
