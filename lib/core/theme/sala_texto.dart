import 'package:flutter/material.dart';

const _px = 'PixelifySans', _nu = 'Nunito';

/// As fontes são variáveis: o peso vai também em `fontVariations`.
TextStyle _t(String f, double s, double lh, int w, {double ls = 0}) =>
    TextStyle(
      fontFamily: f,
      fontSize: s,
      height: lh / s,
      letterSpacing: ls,
      fontWeight: FontWeight.values[(w ~/ 100).clamp(1, 9) - 1],
      fontVariations: [FontVariation.weight(w.toDouble())],
    );

/// Escala de texto. Rótulos em pixel (`labelMedium`, `labelSmall`) já vêm
/// em CAIXA ALTA no próprio texto: `TextStyle` não transforma caixa.
TextTheme salaTextTheme(Color cor) => TextTheme(
  displayLarge: _t(_px, 40, 44, 700),
  displayMedium: _t(_px, 32, 36, 600),
  displaySmall: _t(_px, 26, 30, 600),
  headlineLarge: _t(_nu, 28, 34, 900, ls: -.4),
  headlineMedium: _t(_nu, 24, 30, 900, ls: -.2),
  headlineSmall: _t(_nu, 20, 26, 800),
  titleLarge: _t(_nu, 18, 24, 800),
  titleMedium: _t(_nu, 16, 22, 800),
  titleSmall: _t(_nu, 14, 20, 800),
  bodyLarge: _t(_nu, 16, 24, 600),
  bodyMedium: _t(_nu, 14, 20, 600),
  bodySmall: _t(_nu, 12, 16, 700),
  labelLarge: _t(_nu, 16, 20, 900, ls: .2),
  labelMedium: _t(_px, 13, 16, 500, ls: 1),
  labelSmall: _t(_px, 11, 14, 500, ls: 1.2),
).apply(bodyColor: cor, displayColor: cor);

@immutable
class SalaTexto extends ThemeExtension<SalaTexto> {
  const SalaTexto({
    required this.revelacao,
    required this.hud,
    required this.contagem,
  });

  /// Palavra secreta: Nunito, porque a pixel confunde Z com 2 e S com 5.
  final TextStyle revelacao;

  /// Placar, tempo, contadores.
  final TextStyle hud;
  final TextStyle contagem;

  static final padrao = SalaTexto(
    revelacao: _t(_nu, 40, 46, 900, ls: .5),
    hud: _t(_px, 20, 24, 500, ls: 1),
    contagem: _t(_px, 96, 96, 700),
  );

  @override
  SalaTexto copyWith() => this;

  @override
  SalaTexto lerp(SalaTexto? o, double t) => this;
}
