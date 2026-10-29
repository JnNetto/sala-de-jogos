import 'package:flutter/material.dart';

import 'sala_texto.dart';
import 'sala_tokens.dart';
import 'transicao_sala.dart';

export 'sala_texto.dart';
export 'sala_tokens.dart';

class AppTheme {
  // Montados uma vez: o MaterialApp reconstrói a cada troca de tema.
  static final _noite = _montar(SalaCores.noite, Brightness.dark);
  static final _dia = _montar(SalaCores.dia, Brightness.light);

  static ThemeData noite() => _noite;
  static ThemeData dia() => _dia;

  // Cores do sistema antigo, apontando para a paleta nova. Ficam até as telas
  // migrarem para `context.cores` (ver docs/.../05-migracao.md).
  static const Color primaryColor = Color(0xFF8F7CFF); // marca
  static const Color secondaryColor = Color(0xFF67D6F0); // luar
  static const Color accentColor = Color(0xFFFF77B7); // rosa
  static const Color errorColor = Color(0xFFFF5D73); // carmim
  static const Color successColor = Color(0xFF4FE3A6); // menta
  static const Color warningColor = Color(0xFFFFC94D); // lâmpada
  static const Color espiaoColor = Color(0xFFFF5D73); // papel-espiao
  static const Color civilColor = Color(0xFF5FA2FF); // papel-civil

  static ThemeData _montar(SalaCores c, Brightness b) {
    final texto = salaTextTheme(c.texto);
    final bordaControle = BorderSide(
      color: c.linhaForte,
      width: c.bordaControle,
    );
    final scheme = ColorScheme(
      brightness: b,
      primary: c.primaria,
      onPrimary: c.sobreCor,
      secondary: c.marca,
      onSecondary: c.ehDia ? Colors.white : c.sobreCor,
      error: c.erro.cor,
      onError: c.sobreCor,
      surface: c.superficie,
      onSurface: c.texto,
      onSurfaceVariant: c.texto2,
      surfaceContainerLowest: c.superficieFunda,
      surfaceContainerHighest: c.superficieElevada,
      outline: c.linhaForte,
      outlineVariant: c.linha,
      scrim: c.veu,
      shadow: c.contorno,
    );
    final rr = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Raio.lg),
    );
    OutlineInputBorder borda(BorderSide lado) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Raio.md),
      borderSide: lado,
    );
    // Fade-through: as telas são transparentes sobre o céu do palco, então
    // a que sai some antes de a nova aparecer.
    const transicao = TransicaoDaSala();

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      // Transparente: o céu do PalcoDaSala aparece por trás de toda tela.
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: 'Nunito',
      textTheme: texto,
      splashFactory: NoSplash.splashFactory, // o toque é físico, não ripple
      highlightColor: Colors.transparent,
      iconTheme: IconThemeData(color: c.texto, size: 24, weight: 500, grade: 0),
      extensions: [c, SalaTexto.padrao],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: transicao,
          TargetPlatform.iOS: transicao,
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 64,
        foregroundColor: c.texto,
        titleTextStyle: texto.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          fontVariations: const [FontVariation.weight(900)],
        ),
      ),
      // Os botões do Material ficam coerentes; a ação principal usa BotaoSala.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primaria,
          foregroundColor: c.sobreCor,
          elevation: 0,
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: Espaco.e6),
          shape: rr,
          textStyle: texto.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primaria,
          foregroundColor: c.sobreCor,
          minimumSize: const Size(64, 56),
          shape: rr,
          textStyle: texto.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.texto,
          backgroundColor: c.superficie,
          side: bordaControle,
          minimumSize: const Size(64, 56),
          shape: rr,
          textStyle: texto.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primariaTinta,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: Espaco.e4),
          textStyle: texto.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Raio.md),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: c.texto,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Raio.md),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Raio.xl),
          side: BorderSide(
            color: c.ehDia ? c.contorno : c.linha,
            width: c.bordaControle,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.ehDia ? c.superficie : c.superficieFunda,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Espaco.e4,
          vertical: 18,
        ),
        hintStyle: texto.bodyLarge?.copyWith(color: c.texto3),
        border: borda(bordaControle),
        enabledBorder: borda(bordaControle),
        focusedBorder: borda(BorderSide(color: c.marca, width: 2)),
        errorBorder: borda(BorderSide(color: c.erro.cor, width: 2)),
        focusedErrorBorder: borda(BorderSide(color: c.erro.cor, width: 2)),
        errorStyle: texto.bodySmall?.copyWith(color: c.erro.tinta),
        helperStyle: texto.bodySmall?.copyWith(color: c.texto3),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primaria : c.texto3,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? c.luz(Matiz.lampada).suave
              : c.superficieFunda,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? (c.ehDia ? c.contorno : c.primaria)
              : c.linhaForte,
        ),
        trackOutlineWidth: WidgetStatePropertyAll(c.bordaControle),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 10,
        activeTrackColor: c.primaria,
        inactiveTrackColor: c.superficieFunda,
        thumbColor: c.primaria,
        overlayColor: c.primaria.withValues(alpha: .22),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
        activeTickMarkColor: c.sobreCor.withValues(alpha: .5),
        inactiveTickMarkColor: c.texto3,
        valueIndicatorColor: c.janelaBarra,
        valueIndicatorTextStyle: SalaTexto.padrao.hud.copyWith(
          color: c.janelaBarraTexto,
          fontSize: 16,
        ),
        showValueIndicator: ShowValueIndicator.onDrag,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Raio.xl),
        ),
        titleTextStyle: texto.headlineSmall,
        contentTextStyle: texto.bodyMedium?.copyWith(color: c.texto2),
        barrierColor: c.veu,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.superficieElevada,
        elevation: 0,
        contentTextStyle: texto.bodyMedium?.copyWith(
          color: c.texto,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation.weight(700)],
        ),
        actionTextColor: c.primariaTinta,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Raio.lg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.superficie,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.linhaForte,
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Raio.xxl)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: c.linha,
        thickness: 1.5,
        space: 1.5,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primaria,
        linearTrackColor: c.superficieFunda,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.janelaBarra,
          borderRadius: BorderRadius.circular(Raio.xs),
        ),
        textStyle: texto.labelMedium?.copyWith(color: c.janelaBarraTexto),
      ),
    );
  }

  AppTheme._();
}
