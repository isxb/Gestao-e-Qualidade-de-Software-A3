import 'package:flutter/material.dart';

/// Paleta da EvoluaPRO — viva, clínica e elegante.
///
/// Construída em torno de um azul-real médio (steel blue saturado) que
/// remete a precisão médica, complementado por um teal vivo que entrega
/// vitalidade sem chamar atenção. Os acentos quentes (dourado, terracota,
/// oliva) trazem calor à interface sem caírem no festivo. Mantém WCAG AA.
class AppColors {
  AppColors._();

  // ============================================================
  // Marca — azul real (primary) + teal vivo (secundário)
  // Os nomes "indigo / violet / pink" são preservados como tokens
  // lógicos; os valores foram redefinidos para uma família com vida.
  // ============================================================
  static const Color indigo = Color(0xFF1F5F9C);
  static const Color indigoDark = Color(0xFF143E66);
  static const Color indigoLight = Color(0xFFE3EEF8);

  static const Color violet = Color(0xFF3B82B5);
  static const Color violetLight = Color(0xFFE0ECF4);

  static const Color pink = Color(0xFFC97A47);
  static const Color pinkLight = Color(0xFFF6E4D2);

  // Secundárias (categorias do dashboard / gráficos)
  static const Color teal = Color(0xFF0E9B91);
  static const Color tealLight = Color(0xFFD4F0EC);
  static const Color sky = Color(0xFF3FA5C7);
  static const Color skyLight = Color(0xFFDBEEF6);
  static const Color amber = Color(0xFFD89343);
  static const Color amberLight = Color(0xFFF8E8CD);
  static const Color rose = Color(0xFFC76A6A);
  static const Color roseLight = Color(0xFFF4DCDC);
  static const Color lime = Color(0xFF7DA53F);
  static const Color limeLight = Color(0xFFE7EFD3);

  // ============================================================
  // Superfícies claras — branco limpo com fundo levemente azulado
  // para dar contraste aos accents sem ficar frio.
  // ============================================================
  static const Color lightBackground = Color(0xFFF6F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEDF3F8);
  static const Color lightSurfaceMuted = Color(0xFFDCE5EE);
  static const Color lightBorder = Color(0xFFDFE7EF);
  static const Color lightBorderStrong = Color(0xFFC0CCD9);
  static const Color lightText = Color(0xFF14253A);
  static const Color lightTextMuted = Color(0xFF57667A);
  static const Color lightTextSoft = Color(0xFF8593A4);

  // ============================================================
  // Superfícies escuras — azul-marinho profundo com leve calor.
  // ============================================================
  static const Color darkBackground = Color(0xFF0B1422);
  static const Color darkSurface = Color(0xFF152133);
  static const Color darkSurfaceAlt = Color(0xFF1D2C42);
  static const Color darkSurfaceMuted = Color(0xFF263650);
  static const Color darkBorder = Color(0xFF2D3D58);
  static const Color darkBorderStrong = Color(0xFF425777);
  static const Color darkText = Color(0xFFEDF2F7);
  static const Color darkTextMuted = Color(0xFF94A4B8);
  static const Color darkTextSoft = Color(0xFF647389);

  // ============================================================
  // Estados semânticos — vivos mas comportados.
  // ============================================================
  static const Color success = Color(0xFF14A37C);
  static const Color successDark = Color(0xFF0C7558);
  static const Color successLight = Color(0xFFD4EFE5);

  static const Color warning = Color(0xFFE89A2F);
  static const Color warningDark = Color(0xFFAC6E15);
  static const Color warningLight = Color(0xFFFAEACA);

  static const Color danger = Color(0xFFC74545);
  static const Color dangerDark = Color(0xFF8F2A2A);
  static const Color dangerLight = Color(0xFFF4D6D6);

  static const Color info = Color(0xFF2A8FB8);
  static const Color infoDark = Color(0xFF15668A);
  static const Color infoLight = Color(0xFFD7ECF5);

  // ============================================================
  // Gradientes — transição viva azul-real → teal, com variações
  // calmas mas perceptíveis. Sem "salto de matiz".
  // ============================================================
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1F5F9C), Color(0xFF267DA6), Color(0xFF0E9B91)],
    stops: <double>[0.0, 0.55, 1.0],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF143E66), Color(0xFF1F5F9C), Color(0xFF267DA6)],
    stops: <double>[0.0, 0.55, 1.0],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF14A37C), Color(0xFF0E9B91)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFE89A2F), Color(0xFFC97A47)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFC74545), Color(0xFFC76A6A)],
  );

  static const LinearGradient subtleLightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFF6F9FC), Color(0xFFEDF3F8)],
  );

  static const LinearGradient subtleDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF152133), Color(0xFF1D2C42)],
  );

  // ============================================================
  // Sombras padrão (Material 3 refinado)
  // ============================================================
  static List<BoxShadow> softShadow({double opacity = 0.08}) {
    return <BoxShadow>[
      BoxShadow(
        color: Color.fromRGBO(20, 37, 58, opacity),
        offset: const Offset(0, 4),
        blurRadius: 20,
        spreadRadius: -4,
      ),
    ];
  }

  static List<BoxShadow> elevatedShadow({double opacity = 0.14}) {
    return <BoxShadow>[
      BoxShadow(
        color: Color.fromRGBO(20, 37, 58, opacity),
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
