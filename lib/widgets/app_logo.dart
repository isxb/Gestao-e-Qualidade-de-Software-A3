import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Logo oficial da EvoluaPRO.
///
/// Quadrado arredondado com gradiente indigo→violeta→rosa e, por cima,
/// a linha de pulso cardíaco estilizada. Funciona como favicon/logo em
/// qualquer tamanho (ícone na app bar, splash, login, etc).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 44,
    this.glow = false,
  });

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: glow
            ? <BoxShadow>[
                BoxShadow(
                  color: AppColors.indigo.withValues(alpha: 0.45),
                  blurRadius: size * 0.6,
                  offset: Offset(0, size * 0.14),
                  spreadRadius: -size * 0.08,
                ),
                BoxShadow(
                  color: AppColors.pink.withValues(alpha: 0.25),
                  blurRadius: size * 0.9,
                  offset: Offset(0, size * 0.2),
                  spreadRadius: -size * 0.1,
                ),
              ]
            : null,
      ),
      child: CustomPaint(painter: _PulseLogoPainter()),
    );
  }
}

class _PulseLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Círculo interno translúcido (reforça profundidade)
    final Paint glow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(w * 0.32, h * 0.3),
        radius: w * 0.55,
      ));
    canvas.drawCircle(Offset(w * 0.32, h * 0.3), w * 0.55, glow);

    // Linha de pulso cardíaco estilizada
    final Paint pulse = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path();
    path.moveTo(w * 0.14, h * 0.55);
    path.lineTo(w * 0.32, h * 0.55);
    path.lineTo(w * 0.42, h * 0.32);
    path.lineTo(w * 0.55, h * 0.76);
    path.lineTo(w * 0.66, h * 0.46);
    path.lineTo(w * 0.86, h * 0.46);

    canvas.drawPath(path, pulse);

    // Ponto final destacado
    final Paint dot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.86, h * 0.46), w * 0.05, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Logo com wordmark — usado na tela de login e cabeçalhos amplos.
class AppLogoLockup extends StatelessWidget {
  const AppLogoLockup({
    super.key,
    this.logoSize = 56,
    this.color,
    this.subtitle,
    this.compact = false,
  });

  final double logoSize;
  final Color? color;
  final String? subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color fg = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppLogo(size: logoSize, glow: !compact),
        SizedBox(width: logoSize * 0.32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RichText(
              text: TextSpan(
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: logoSize * 0.52,
                  color: fg,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
                children: <InlineSpan>[
                  const TextSpan(text: 'Evolua'),
                  TextSpan(
                    text: 'PRO',
                    style: TextStyle(
                      color: fg == Colors.white
                          ? Colors.white
                          : AppColors.teal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (subtitle != null && !compact)
              Padding(
                padding: EdgeInsets.only(top: logoSize * 0.05),
                child: Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: fg.withValues(alpha: 0.75),
                        letterSpacing: 0.4,
                        fontSize: logoSize * 0.22,
                      ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
