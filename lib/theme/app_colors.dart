import 'package:flutter/material.dart';

/// Paleta moderna da EvoluaPRO — vibrante, profissional e multi-tonal.
/// Inspirada em design systems atuais (Material 3, Vercel, Linear) e em
/// dashboards clínicos premium. Mantém acessibilidade WCAG AA.
class AppColors {
  AppColors._();

  // ============================================================
  // Marca — gradiente indigo → violeta → rosa
  // ============================================================
  static const Color indigo = Color(0xFF4F46E5);
  static const Color indigoDark = Color(0xFF3730A3);
  static const Color indigoLight = Color(0xFFEEF2FF);

  static const Color violet = Color(0xFF7C3AED);
  static const Color violetLight = Color(0xFFF3E8FF);

  static const Color pink = Color(0xFFEC4899);
  static const Color pinkLight = Color(0xFFFCE7F3);

  // Secundárias (categorias do dashboard / gráficos)
  static const Color teal = Color(0xFF14B8A6);
  static const Color tealLight = Color(0xFFCCFBF1);
  static const Color sky = Color(0xFF0EA5E9);
  static const Color skyLight = Color(0xFFE0F2FE);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFEF3C7);
  static const Color rose = Color(0xFFF43F5E);
  static const Color roseLight = Color(0xFFFFE4E6);
  static const Color lime = Color(0xFF84CC16);
  static const Color limeLight = Color(0xFFECFCCB);

  // ============================================================
  // Superfícies claras — cinza-azulado frio e clean
  // ============================================================
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF1F5F9);
  static const Color lightSurfaceMuted = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderStrong = Color(0xFFCBD5E1);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextMuted = Color(0xFF64748B);
  static const Color lightTextSoft = Color(0xFF94A3B8);

  // ============================================================
  // Superfícies escuras — azul-marinho profundo e elegante
  // ============================================================
  static const Color darkBackground = Color(0xFF0B0F1A);
  static const Color darkSurface = Color(0xFF141A2B);
  static const Color darkSurfaceAlt = Color(0xFF1C2338);
  static const Color darkSurfaceMuted = Color(0xFF252D47);
  static const Color darkBorder = Color(0xFF2B3350);
  static const Color darkBorderStrong = Color(0xFF3D4668);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkTextSoft = Color(0xFF64748B);

  // ============================================================
  // Estados semânticos
  // ============================================================
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF047857);
  static const Color successLight = Color(0xFFD1FAE5);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFB45309);
  static const Color warningLight = Color(0xFFFEF3C7);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerDark = Color(0xFFB91C1C);
  static const Color dangerLight = Color(0xFFFEE2E2);

  static const Color info = Color(0xFF0EA5E9);
  static const Color infoDark = Color(0xFF0369A1);
  static const Color infoLight = Color(0xFFE0F2FE);

  // ============================================================
  // Gradientes assinados
  // ============================================================
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[indigo, violet, pink],
    stops: <double>[0.0, 0.55, 1.0],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF3730A3), Color(0xFF6D28D9), Color(0xFFDB2777)],
    stops: <double>[0.0, 0.55, 1.0],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF059669), Color(0xFF0EA5E9)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFF59E0B), Color(0xFFEF4444)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFEF4444), Color(0xFFEC4899)],
  );

  static const LinearGradient subtleLightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFAFBFF), Color(0xFFF1F5F9)],
  );

  static const LinearGradient subtleDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF141A2B), Color(0xFF1C2338)],
  );

  // ============================================================
  // Sombras padrão (Material 3 refinado)
  // ============================================================
  static List<BoxShadow> softShadow({double opacity = 0.08}) {
    return <BoxShadow>[
      BoxShadow(
        color: Color.fromRGBO(15, 23, 42, opacity),
        offset: const Offset(0, 4),
        blurRadius: 20,
        spreadRadius: -4,
      ),
    ];
  }

  static List<BoxShadow> elevatedShadow({double opacity = 0.14}) {
    return <BoxShadow>[
      BoxShadow(
        color: Color.fromRGBO(15, 23, 42, opacity),
        offset: const Offset(0, 10),
        blurRadius: 32,
        spreadRadius: -8,
      ),
    ];
  }

  /// Retorna a cor correspondente a uma categoria de dashboard, mantendo
  /// coerência entre gráficos e cartões.
  static List<Color> get chartPalette => <Color>[
        indigo,
        teal,
        amber,
        pink,
        sky,
        violet,
        lime,
        rose,
      ];
}
