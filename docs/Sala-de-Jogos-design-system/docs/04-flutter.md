# Implementação no Flutter

Como levar o sistema para `lib/core/theme/`. A ideia é ter uma fonte só: tokens em `sala_tokens.dart`, o `ThemeData` montado a partir deles em `app_theme.dart`, e os poucos widgets de assinatura (`Pressionavel`, `BotaoSala`, `Ceu`, `Varal`) em `lib/presentation/widgets/sala/`.

## Dependências e fontes

```yaml
dependencies:
  animations: ^2.0.11            # OpenContainer, SharedAxis, FadeThrough
  material_symbols_icons: ^4.2815.0

flutter:
  fonts:
    - family: Nunito
      fonts:
        - asset: assets/fonts/Nunito-Variable.ttf
    - family: PixelifySans
      fonts:
        - asset: assets/fonts/PixelifySans-Variable.ttf
```

Pede Flutter 3.27 ou mais novo (`withValues`, `CardThemeData`, `DialogThemeData`). As fontes vão empacotadas (o app joga offline). Os arquivos estão em `fonts/` deste sistema, com licença OFL em `licencas/`. Como são variáveis, todo `TextStyle` passa o peso também em `fontVariations`.

## Tokens

```dart
// lib/core/theme/sala_tokens.dart
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class Luz {
  const Luz(this.cor, this.tinta, this.suave);
  final Color cor;   // preenchimento e brilho
  final Color tinta; // texto e ícone sobre superfícies
  final Color suave; // fundo tingido
  static Luz lerp(Luz a, Luz b, double t) => Luz(
        Color.lerp(a.cor, b.cor, t)!,
        Color.lerp(a.tinta, b.tinta, t)!,
        Color.lerp(a.suave, b.suave, t)!,
      );
}

enum Matiz { violeta, rosa, menta, brasa, lampada, luar, ceu, carmim }

enum Jogo {
  espiao('Quem é o Espião?', Symbols.visibility_off, Matiz.violeta),
  impostora('Pergunta Impostora', Symbols.help, Matiz.rosa),
  quiz('Quiz da Vez', Symbols.quiz, Matiz.menta),
  resistencia('A Resistência', Symbols.shield, Matiz.brasa),
  souma('Só uma!', Symbols.lightbulb, Matiz.lampada),
  lobisomem('Lobisomem', Symbols.bedtime, Matiz.luar),
  aneis('Nos Anéis', Symbols.join_inner, Matiz.ceu);

  const Jogo(this.nome, this.icone, this.matiz);
  final String nome;
  final IconData icone;
  final Matiz matiz;
}

@immutable
class SalaCores extends ThemeExtension<SalaCores> {
  const SalaCores({
    required this.ceuTopo, required this.ceuBrilho, required this.fundo, required this.estrela,
    required this.superficie, required this.superficieElevada, required this.superficieFunda,
    required this.linha, required this.linhaForte, required this.contorno,
    required this.texto, required this.texto2, required this.texto3,
    required this.janelaBarra, required this.janelaBarraTexto,
    required this.primaria, required this.primariaLabio, required this.primariaTinta,
    required this.sobreCor, required this.marca, required this.marcaSuave, required this.veu,
    required this.luzes, required this.ehDia,
  });

  final Color ceuTopo, ceuBrilho, fundo, estrela;
  final Color superficie, superficieElevada, superficieFunda;
  final Color linha, linhaForte, contorno;
  final Color texto, texto2, texto3;
  final Color janelaBarra, janelaBarraTexto;
  final Color primaria, primariaLabio, primariaTinta, sobreCor;
  final Color marca, marcaSuave, veu;
  final Map<Matiz, Luz> luzes;
  final bool ehDia;

  Luz luz(Matiz m) => luzes[m]!;
  Luz doJogo(Jogo j) => luz(j.matiz);
  Luz get sucesso => luz(Matiz.menta);
  Luz get erro => luz(Matiz.carmim);
  Luz get aviso => luz(Matiz.lampada);
  Luz get info => luz(Matiz.ceu);
  Luz get papelEspiao => luz(Matiz.carmim);
  Luz get papelCivil => luz(Matiz.ceu);

  static const noite = SalaCores(
    ceuTopo: Color(0xFF070822), ceuBrilho: Color(0xFF1E1D5C), fundo: Color(0xFF0D0F2B), estrela: Color(0xFFB9B6F2),
    superficie: Color(0xFF181B4A), superficieElevada: Color(0xFF222664), superficieFunda: Color(0xFF12143A),
    linha: Color(0xFF2B2F70), linhaForte: Color(0xFF6A6FC4), contorno: Color(0xFF05061A),
    texto: Color(0xFFF1EEFF), texto2: Color(0xFFB7B5E6), texto3: Color(0xFF8A8CC8),
    janelaBarra: Color(0xFF262A6E), janelaBarraTexto: Color(0xFFD9D6FF),
    primaria: Color(0xFFFFC94D), primariaLabio: Color(0xFFC9922A), primariaTinta: Color(0xFFFFC94D),
    sobreCor: Color(0xFF0D0F2B), marca: Color(0xFF8F7CFF), marcaSuave: Color(0xFF221C5A), veu: Color(0xCC070822),
    ehDia: false,
    luzes: {
      Matiz.violeta: Luz(Color(0xFF8F7CFF), Color(0xFF9A8AFF), Color(0xFF221C5A)),
      Matiz.rosa: Luz(Color(0xFFFF77B7), Color(0xFFFF77B7), Color(0xFF3D1C4F)),
      Matiz.menta: Luz(Color(0xFF4FE3A6), Color(0xFF4FE3A6), Color(0xFF123B45)),
      Matiz.brasa: Luz(Color(0xFFFF8F55), Color(0xFFFF8F55), Color(0xFF3E2340)),
      Matiz.lampada: Luz(Color(0xFFFFC94D), Color(0xFFFFC94D), Color(0xFF3A2E3E)),
      Matiz.luar: Luz(Color(0xFF67D6F0), Color(0xFF67D6F0), Color(0xFF143552)),
      Matiz.ceu: Luz(Color(0xFF5FA2FF), Color(0xFF5FA2FF), Color(0xFF1B2B66)),
      Matiz.carmim: Luz(Color(0xFFFF5D73), Color(0xFFFF5D73), Color(0xFF3F1A3C)),
    },
  );

  static const dia = SalaCores(
    ceuTopo: Color(0xFFFBF6EC), ceuBrilho: Color(0xFFEFE4F6), fundo: Color(0xFFF4EEE3), estrela: Color(0xFFD9CDB8),
    superficie: Color(0xFFFFFBF4), superficieElevada: Color(0xFFFFFFFF), superficieFunda: Color(0xFFEBE3D4),
    linha: Color(0xFFDDD2BF), linhaForte: Color(0xFF1B1D5C), contorno: Color(0xFF1B1D5C),
    texto: Color(0xFF1B1D5C), texto2: Color(0xFF4A4C86), texto3: Color(0xFF5F6196),
    janelaBarra: Color(0xFF2335C7), janelaBarraTexto: Color(0xFFFFF6E6),
    primaria: Color(0xFFFFC94D), primariaLabio: Color(0xFF1B1D5C), primariaTinta: Color(0xFF8A5A00),
    sobreCor: Color(0xFF1B1D5C), marca: Color(0xFF5B47F0), marcaSuave: Color(0xFFE9E5FF), veu: Color(0x991B1D5C),
    ehDia: true,
    luzes: {
      Matiz.violeta: Luz(Color(0xFF8F7CFF), Color(0xFF5B47F0), Color(0xFFE9E5FF)),
      Matiz.rosa: Luz(Color(0xFFFF77B7), Color(0xFFBE2A6E), Color(0xFFFFE4F0)),
      Matiz.menta: Luz(Color(0xFF4FE3A6), Color(0xFF08744A), Color(0xFFDDF7EA)),
      Matiz.brasa: Luz(Color(0xFFFF8F55), Color(0xFFB0440E), Color(0xFFFFE6D6)),
      Matiz.lampada: Luz(Color(0xFFFFC94D), Color(0xFF8A5A00), Color(0xFFFFF1CC)),
      Matiz.luar: Luz(Color(0xFF67D6F0), Color(0xFF096C88), Color(0xFFDBF4FA)),
      Matiz.ceu: Luz(Color(0xFF5FA2FF), Color(0xFF1F5FD6), Color(0xFFE0ECFF)),
      Matiz.carmim: Luz(Color(0xFFFF5D73), Color(0xFFC22440), Color(0xFFFFE1E5)),
    },
  );

  @override
  SalaCores copyWith() => this;

  @override
  SalaCores lerp(SalaCores? o, double t) {
    if (o == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SalaCores(
      ceuTopo: l(ceuTopo, o.ceuTopo), ceuBrilho: l(ceuBrilho, o.ceuBrilho), fundo: l(fundo, o.fundo), estrela: l(estrela, o.estrela),
      superficie: l(superficie, o.superficie), superficieElevada: l(superficieElevada, o.superficieElevada), superficieFunda: l(superficieFunda, o.superficieFunda),
      linha: l(linha, o.linha), linhaForte: l(linhaForte, o.linhaForte), contorno: l(contorno, o.contorno),
      texto: l(texto, o.texto), texto2: l(texto2, o.texto2), texto3: l(texto3, o.texto3),
      janelaBarra: l(janelaBarra, o.janelaBarra), janelaBarraTexto: l(janelaBarraTexto, o.janelaBarraTexto),
      primaria: l(primaria, o.primaria), primariaLabio: l(primariaLabio, o.primariaLabio), primariaTinta: l(primariaTinta, o.primariaTinta),
      sobreCor: l(sobreCor, o.sobreCor), marca: l(marca, o.marca), marcaSuave: l(marcaSuave, o.marcaSuave), veu: l(veu, o.veu),
      luzes: {for (final m in Matiz.values) m: Luz.lerp(luzes[m]!, o.luzes[m]!, t)},
      ehDia: t < .5 ? ehDia : o.ehDia,
    );
  }
}

abstract final class Espaco {
  static const e1 = 4.0, e2 = 8.0, e3 = 12.0, e4 = 16.0, e5 = 20.0, e6 = 24.0, e8 = 32.0, e12 = 48.0, e16 = 64.0;
  static const margemTela = 20.0, alvoToque = 48.0, larguraMax = 560.0;
}

abstract final class Raio {
  static const xs = 6.0, sm = 10.0, md = 14.0, lg = 18.0, xl = 24.0, xxl = 32.0, pill = 999.0;
}

abstract final class Movimento {
  static const instante = Duration(milliseconds: 80);
  static const rapida = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 220);
  static const media = Duration(milliseconds: 320);
  static const lenta = Duration(milliseconds: 450);
  static const dramatica = Duration(milliseconds: 640);
  static const ambiente = Duration(milliseconds: 3200);

  static const padrao = Cubic(0.2, 0, 0, 1);
  static const entrada = Cubic(0.05, 0.7, 0.1, 1);
  static const saida = Cubic(0.3, 0, 0.8, 0.15);
  static const pulo = Cubic(0.34, 1.56, 0.64, 1);

  /// Use em toda animação não essencial.
  static bool reduzido(BuildContext c) => MediaQuery.disableAnimationsOf(c);
  static Duration d(BuildContext c, Duration x) =>
      reduzido(c) ? const Duration(milliseconds: 120) : x;
}

extension SalaContexto on BuildContext {
  SalaCores get cores => Theme.of(this).extension<SalaCores>()!;
  SalaTexto get estilos => Theme.of(this).extension<SalaTexto>()!;
}
```

## Tipografia

```dart
// lib/core/theme/sala_texto.dart
TextStyle _t(String f, double s, double lh, int w, {double ls = 0}) => TextStyle(
      fontFamily: f, fontSize: s, height: lh / s, letterSpacing: ls,
      fontWeight: FontWeight.values[(w ~/ 100).clamp(1, 9) - 1],
      fontVariations: [FontVariation.weight(w.toDouble())],
    );
const _px = 'PixelifySans', _nu = 'Nunito';

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
  const SalaTexto({required this.revelacao, required this.hud, required this.contagem});
  final TextStyle revelacao, hud, contagem;
  static final padrao = SalaTexto(
    revelacao: _t(_nu, 40, 46, 900, ls: .5), // Nunito: legível sem erro
    hud: _t(_px, 20, 24, 500, ls: 1),
    contagem: _t(_px, 96, 96, 700),
  );
  @override
  SalaTexto copyWith() => this;
  @override
  SalaTexto lerp(SalaTexto? o, double t) => this;
}
```

Lembre de escrever rótulos em pixel já em CAIXA ALTA no texto (`'RODADA 2 DE 5'`), porque `TextStyle` não tem transformação de caixa.

## Tema

```dart
// lib/core/theme/app_theme.dart
import 'package:animations/animations.dart';

class AppTheme {
  static ThemeData noite() => _montar(SalaCores.noite, Brightness.dark);
  static ThemeData dia() => _montar(SalaCores.dia, Brightness.light);

  static ThemeData _montar(SalaCores c, Brightness b) {
    final texto = salaTextTheme(c.texto);
    final bordaControle = BorderSide(color: c.linhaForte, width: c.ehDia ? 2 : 1.5);
    final scheme = ColorScheme(
      brightness: b,
      primary: c.primaria, onPrimary: c.sobreCor,
      secondary: c.marca, onSecondary: c.ehDia ? Colors.white : c.sobreCor,
      error: c.erro.cor, onError: c.sobreCor,
      surface: c.superficie, onSurface: c.texto, onSurfaceVariant: c.texto2,
      surfaceContainerLowest: c.superficieFunda, surfaceContainerHighest: c.superficieElevada,
      outline: c.linhaForte, outlineVariant: c.linha,
      scrim: c.veu, shadow: c.contorno,
    );
    final rr = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.lg));

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.fundo, // o widget Ceu pinta o degradê por cima
      textTheme: texto,
      splashFactory: NoSplash.splashFactory, // o toque é físico, não ripple
      highlightColor: Colors.transparent,
      extensions: [c, SalaTexto.padrao],
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.horizontal),
        TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.horizontal),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent,
        elevation: 0, scrolledUnderElevation: 0, centerTitle: true, toolbarHeight: 64,
        foregroundColor: c.texto, titleTextStyle: texto.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
      // Os botões do Material ficam coerentes; a ação principal usa BotaoSala (com lábio).
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: c.primaria, foregroundColor: c.sobreCor, elevation: 0,
        minimumSize: const Size(64, 56), padding: const EdgeInsets.symmetric(horizontal: Espaco.e6),
        shape: rr, textStyle: texto.labelLarge,
      )),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: c.primaria, foregroundColor: c.sobreCor,
        minimumSize: const Size(64, 56), shape: rr, textStyle: texto.labelLarge,
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: c.texto, backgroundColor: c.superficie, side: bordaControle,
        minimumSize: const Size(64, 56), shape: rr, textStyle: texto.labelLarge,
      )),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
        foregroundColor: c.primariaTinta, minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: Espaco.e4), textStyle: texto.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.md)),
      )),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(
        minimumSize: const Size(48, 48), foregroundColor: c.texto,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.md)),
      )),
      cardTheme: CardThemeData(
        color: c.superficie, surfaceTintColor: Colors.transparent, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Raio.xl),
          side: BorderSide(color: c.ehDia ? c.contorno : c.linha, width: c.ehDia ? 2 : 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: c.ehDia ? c.superficie : c.superficieFunda,
        contentPadding: const EdgeInsets.symmetric(horizontal: Espaco.e4, vertical: 18),
        hintStyle: texto.bodyLarge?.copyWith(color: c.texto3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Raio.md), borderSide: bordaControle),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Raio.md), borderSide: bordaControle),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Raio.md), borderSide: BorderSide(color: c.marca, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Raio.md), borderSide: BorderSide(color: c.erro.cor, width: 2)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Raio.md), borderSide: BorderSide(color: c.erro.cor, width: 2)),
        errorStyle: texto.bodySmall?.copyWith(color: c.erro.tinta),
        helperStyle: texto.bodySmall?.copyWith(color: c.texto3),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primaria : c.texto3),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.luz(Matiz.lampada).suave : c.superficieFunda),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? (c.ehDia ? c.contorno : c.primaria) : c.linhaForte),
        trackOutlineWidth: WidgetStatePropertyAll(c.ehDia ? 2 : 1.5),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 10, activeTrackColor: c.primaria, inactiveTrackColor: c.superficieFunda,
        thumbColor: c.primaria, overlayColor: c.primaria.withValues(alpha: .22),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
        activeTickMarkColor: c.sobreCor.withValues(alpha: .5), inactiveTickMarkColor: c.texto3,
        valueIndicatorColor: c.janelaBarra,
        valueIndicatorTextStyle: SalaTexto.padrao.hud.copyWith(color: c.janelaBarraTexto, fontSize: 16),
        showValueIndicator: ShowValueIndicator.always,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.superficie, surfaceTintColor: Colors.transparent, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.xl)),
        titleTextStyle: texto.headlineSmall, contentTextStyle: texto.bodyMedium?.copyWith(color: c.texto2),
        barrierColor: c.veu,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating, backgroundColor: c.superficieElevada, elevation: 0,
        contentTextStyle: texto.bodyMedium?.copyWith(color: c.texto, fontWeight: FontWeight.w700),
        actionTextColor: c.primariaTinta,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.lg)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.superficie, surfaceTintColor: Colors.transparent, showDragHandle: true,
        dragHandleColor: c.linhaForte, dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Raio.xxl))),
      ),
      dividerTheme: DividerThemeData(color: c.linha, thickness: 1.5, space: 1.5),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primaria, linearTrackColor: c.superficieFunda),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.janelaBarra, borderRadius: BorderRadius.circular(Raio.xs)),
        textStyle: texto.labelMedium?.copyWith(color: c.janelaBarraTexto),
      ),
    );
  }
}
```

No `MaterialApp`, use `theme: AppTheme.dia()`, `darkTheme: AppTheme.noite()`, `themeMode` vindo do `ThemeProvider` (padrão `ThemeMode.dark`) e `themeAnimationDuration: Movimento.media`, `themeAnimationCurve: Movimento.padrao`.

Dentro de um jogo, envolva a árvore do jogo num `Theme` que troca a primária pela luz do jogo, para que interruptores, sliders e botões assumam a cor sem passar parâmetro:

```dart
Widget comLuzDoJogo(BuildContext context, Jogo jogo, Widget filho) {
  final t = Theme.of(context);
  final luz = context.cores.doJogo(jogo);
  return Theme(
    data: t.copyWith(
      colorScheme: t.colorScheme.copyWith(primary: luz.cor),
      sliderTheme: t.sliderTheme.copyWith(activeTrackColor: luz.cor, thumbColor: luz.cor),
    ),
    child: filho,
  );
}
```

## Pressionavel: a física do toque

```dart
// lib/presentation/widgets/sala/pressionavel.dart
import 'package:flutter/services.dart';

class Pressionavel extends StatefulWidget {
  const Pressionavel({super.key, required this.child, this.onTap, this.escala = .97, this.descida = 0, this.haptico = true});
  final Widget child;
  final VoidCallback? onTap;
  final double escala, descida;
  final bool haptico;
  @override
  State<Pressionavel> createState() => _PressionavelState();
}

class _PressionavelState extends State<Pressionavel> {
  bool _baixo = false;
  void _set(bool v) => setState(() => _baixo = v);

  @override
  Widget build(BuildContext context) {
    final ativo = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: ativo ? (_) { _set(true); if (widget.haptico) HapticFeedback.lightImpact(); } : null,
      onTapUp: ativo ? (_) { _set(false); widget.onTap!(); } : null,
      onTapCancel: ativo ? () => _set(false) : null,
      child: AnimatedContainer(
        duration: _baixo ? Movimento.instante : Movimento.rapida,
        curve: _baixo ? Movimento.padrao : Movimento.pulo,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..translate(0.0, _baixo ? widget.descida : 0.0)
          ..scale(_baixo ? widget.escala : 1.0),
        child: widget.child,
      ),
    );
  }
}
```

## BotaoSala: o botão com lábio

```dart
class BotaoSala extends StatelessWidget {
  const BotaoSala({super.key, required this.rotulo, this.onPressed, this.icone, this.luz, this.bloco = false, this.carregando = false});
  final String rotulo;
  final VoidCallback? onPressed;
  final IconData? icone;
  final Luz? luz; // null = primária
  final bool bloco, carregando;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final desabilitado = onPressed == null;
    final fundo = desabilitado ? (c.ehDia ? c.superficieFunda : c.superficieElevada) : (luz?.cor ?? c.primaria);
    final tinta = desabilitado ? c.texto3 : c.sobreCor;
    final labio = c.ehDia
        ? c.contorno
        : (luz == null ? c.primariaLabio : Color.lerp(fundo, const Color(0xFF05061A), .38)!);
    final ativo = !desabilitado && !carregando;
    return Semantics(
      button: true,
      enabled: !desabilitado,
      child: Pressionavel(
        onTap: ativo ? onPressed : null,
        escala: .985, descida: 3,
        child: Container(
          height: 56,
          width: bloco ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: Espaco.e6),
          decoration: BoxDecoration(
            color: fundo,
            borderRadius: BorderRadius.circular(Raio.lg),
            border: desabilitado
                ? Border.all(color: c.linha, width: c.ehDia ? 2 : 1.5)
                : (c.ehDia ? Border.all(color: c.contorno, width: 2) : null),
            boxShadow: desabilitado ? null : [
              BoxShadow(color: labio, offset: const Offset(0, 4)),
              if (!c.ehDia) BoxShadow(color: fundo.withValues(alpha: .28), blurRadius: 22, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisSize: bloco ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: carregando
                ? [BolinhasCarregando(cor: tinta)]
                : [
                    if (icone != null) ...[Icon(icone, size: 22, color: tinta), const SizedBox(width: Espaco.e2)],
                    Text(rotulo, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: tinta)),
                  ],
          ),
        ),
      ),
    );
  }
}
```

```dart
class BolinhasCarregando extends StatefulWidget {
  const BolinhasCarregando({super.key, required this.cor});
  final Color cor;
  @override
  State<BolinhasCarregando> createState() => _BolinhasState();
}

class _BolinhasState extends State<BolinhasCarregando> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++)
            Builder(builder: (_) {
              final f = ((_c.value - i * .166) % 1.0);
              final aceso = f < .35 ? Curves.easeOut.transform(f / .35) : 1 - Curves.easeIn.transform(((f - .35) / .65).clamp(0, 1));
              return Container(
                width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.cor.withValues(alpha: .25 + .75 * aceso)),
              );
            }),
        ]),
      );
}
```

O lábio que "cai" ao pressionar sai de graça: o `Pressionavel` desce 3 px e a sombra fica parada, então o lábio visível encolhe de 4 para 1 px.

## Ceu: o fundo

```dart
import 'dart:math' as math;

class Ceu extends StatelessWidget {
  const Ceu({super.key, required this.child, this.semente = 7, this.estrelas = 22});
  final Widget child;
  final int semente, estrelas;
  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [c.ceuTopo, c.fundo], stops: const [0, .55],
      )),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: RadialGradient(
          center: const Alignment(0, 1.3), radius: 1.1,
          colors: [c.ceuBrilho, c.ceuBrilho.withValues(alpha: 0)], stops: const [0, .6],
        )),
        child: CustomPaint(
          painter: _Estrelas(c, semente, c.ehDia ? 0 : estrelas),
          child: child,
        ),
      ),
    );
  }
}

class _Estrelas extends CustomPainter {
  _Estrelas(this.c, this.semente, this.n);
  final SalaCores c;
  final int semente, n;
  @override
  void paint(Canvas canvas, Size s) {
    final r = math.Random(semente);
    final p = Paint()..color = c.estrela.withValues(alpha: .55);
    for (var i = 0; i < n; i++) {
      final o = Offset(r.nextDouble() * s.width, r.nextDouble() * s.height);
      if (i % 3 == 0) { // cruz pixel 9×9
        canvas.drawRect(Rect.fromLTWH(o.dx + 3, o.dy, 3, 9), p);
        canvas.drawRect(Rect.fromLTWH(o.dx, o.dy + 3, 9, 3), p);
      } else {
        canvas.drawRect(Rect.fromLTWH(o.dx, o.dy, 3, 3), p);
      }
    }
  }
  @override
  bool shouldRepaint(_Estrelas o) => o.c != c || o.n != n;
}
```

No Dia, troque as estrelas por uma grade de pontinhos `estrela` a cada 18 px. Para o cintilar, use um `AnimationController` de `Movimento.ambiente` em repetição e module a opacidade de uma em cada quatro estrelas com fase derivada da semente; desligue quando `Movimento.reduzido(context)`.

## Transições

```dart
// Home → home do jogo
OpenContainer(
  transitionDuration: Movimento.lenta,
  transitionType: ContainerTransitionType.fadeThrough,
  closedElevation: 0, openElevation: 0,
  closedColor: c.superficie, openColor: c.fundo, middleColor: c.superficie,
  closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.xl)),
  closedBuilder: (ctx, abrir) => CartaoJogo(jogo: jogo, onTap: abrir),
  openBuilder: (ctx, _) => HomeDoJogo(jogo: jogo),
);

// Diálogo como janela (import 'dart:ui' para ImageFilter)
Future<T?> mostrarJanela<T>(BuildContext context, Widget janela) => showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: context.cores.veu,
      transitionDuration: Movimento.media,
      pageBuilder: (_, __, ___) => Center(child: janela),
      transitionBuilder: (ctx, a, __, filho) {
        final curva = CurvedAnimation(parent: a, curve: Movimento.entrada, reverseCurve: Movimento.saida);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6 * a.value, sigmaY: 6 * a.value),
          child: FadeTransition(
            opacity: curva,
            child: ScaleTransition(scale: Tween(begin: .9, end: 1.0).animate(curva), child: filho),
          ),
        );
      },
    );
```

## Dígitos de largura fixa

```dart
class DigitosHud extends StatelessWidget {
  const DigitosHud(this.texto, {super.key, this.estilo});
  final String texto;
  final TextStyle? estilo;
  @override
  Widget build(BuildContext context) {
    final s = estilo ?? context.estilos.hud;
    final fs = s.fontSize ?? 20;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (final ch in texto.characters)
        SizedBox(width: fs * (ch == ':' ? .4 : .66), child: Text(ch, style: s, textAlign: TextAlign.center)),
    ]);
  }
}
```

## Ordem sugerida de migração

1. Fontes, `sala_tokens.dart`, `sala_texto.dart` e o novo `app_theme.dart`. Só isso já troca cores, tipografia, campos, interruptores, sliders e diálogos.
2. `Ceu` como fundo de todo `Scaffold` (`extendBodyBehindAppBar: true`).
3. `Pressionavel` e `BotaoSala` no lugar do `PrimaryButton`; `CartaoJogo` com `OpenContainer`.
4. `Janela`, `Aviso` e o diálogo de abortar.
5. Componentes de jogo: `CartaRevelacao`, `Varal`, `Contagem`, `Cronometro`, `LinhaResultado`.
6. Splash nova e ícone do app (`flutter_launcher_icons` com `icone-app.svg` exportado em 1024 px; adaptativo com `icone-app-frente.svg` sobre `#0D0F2B`).
