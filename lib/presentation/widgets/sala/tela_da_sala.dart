import 'package:flutter/material.dart';

import '../../../core/theme/sala_tokens.dart';
import 'barra_topo.dart';
import 'palco_da_sala.dart';
import 'varal.dart';

/// O tema de dentro de um jogo: a luz dele toma o lugar da primária em
/// botões, interruptores, sliders e indicadores.
ThemeData temaComLuz(ThemeData t, Luz luz) {
  final c = t.extension<SalaCores>()!;
  WidgetStateProperty<Color?> naLuz(
    WidgetStateProperty<Color?>? original,
    Color cor,
  ) => WidgetStateProperty.resolveWith(
    (s) => s.contains(WidgetState.disabled) ? original?.resolve(s) : cor,
  );
  ButtonStyle? cheio(ButtonStyle? s) =>
      s?.copyWith(backgroundColor: naLuz(s.backgroundColor, luz.cor));

  return t.copyWith(
    colorScheme: t.colorScheme.copyWith(primary: luz.cor),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: cheio(t.elevatedButtonTheme.style),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: cheio(t.filledButtonTheme.style),
    ),
    textButtonTheme: TextButtonThemeData(
      style: t.textButtonTheme.style?.copyWith(
        foregroundColor: naLuz(
          t.textButtonTheme.style?.foregroundColor,
          luz.tinta,
        ),
      ),
    ),
    sliderTheme: t.sliderTheme.copyWith(
      activeTrackColor: luz.cor,
      thumbColor: luz.cor,
      overlayColor: luz.cor.withValues(alpha: .22),
    ),
    switchTheme: t.switchTheme.copyWith(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? luz.cor : c.texto3,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? luz.suave : c.superficieFunda,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? (c.ehDia ? c.contorno : luz.cor)
            : c.linhaForte,
      ),
    ),
    checkboxTheme: t.checkboxTheme.copyWith(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? luz.cor : null,
      ),
      checkColor: WidgetStatePropertyAll(c.sobreCor),
    ),
    progressIndicatorTheme: t.progressIndicatorTheme.copyWith(color: luz.cor),
  );
}

/// A moldura das telas de fluxo: céu, o espaço do varal do [PalcoDaSala],
/// a [BarraTopo] e o corpo. Com [matiz], é uma tela de jogo: o tema toma a
/// luz dele (o varal continua colorido).
///
/// O [corpo] recebe a altura que sobra, já sem o recuo do topo (o da base
/// continua, para quem usa `SafeArea`).
class TelaDaSala extends StatelessWidget {
  const TelaDaSala({
    super.key,
    required this.corpo,
    this.titulo,
    this.sobretitulo,
    this.acao,
    this.voltar = true,
    this.aoVoltar,
    this.matiz,
    this.rodape,
    this.progresso,
    this.inicio,
  });

  final Widget corpo;

  /// Sem título, a tela não tem barra (revelação, contagem).
  final String? titulo;
  final String? sobretitulo;
  final Widget? acao;
  final bool voltar;
  final VoidCallback? aoVoltar;
  final Matiz? matiz;

  /// A ação principal fixa embaixo, fora da rolagem do corpo.
  final Widget? rodape;

  /// Pede o varal no modo de progresso (revelação, votação).
  final ProgressoDoVaral? progresso;

  /// Botão no lugar do voltar da barra.
  final Widget? inicio;

  @override
  Widget build(BuildContext context) {
    final topo = MediaQuery.paddingOf(context).top;
    final tema = Theme.of(context);
    final luz = matiz == null ? null : context.cores.luz(matiz!);

    // Sem céu próprio: a tela é transparente sobre o céu do PalcoDaSala,
    // o único do app. Numa transição, assim, só um céu é desenhado.
    Widget tela = Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topo + Varal.altura),
          if (titulo != null)
            BarraTopo(
              titulo: titulo!,
              sobretitulo: sobretitulo,
              corSobretitulo: luz?.tinta,
              acao: acao,
              voltar: voltar,
              aoVoltar: aoVoltar,
              inicio: inicio,
            ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: corpo,
            ),
          ),
          ?rodape,
        ],
      ),
    );
    if (luz != null) tela = Theme(data: temaComLuz(tema, luz), child: tela);
    return ComVaral(progresso: progresso, child: tela);
  }
}
