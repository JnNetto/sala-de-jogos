import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/sala_tokens.dart';
import 'botao_sala.dart';
import 'janela.dart';
import 'tela_da_sala.dart';

/// Abre um diálogo de confirmação sobre uma [Janela]: véu com desfoque, a
/// janela crescendo de 0,9 e subindo 8 px.
///
/// Devolve `true` na ação principal, `false` na de escape e `null` se for
/// dispensado (toque fora ou voltar do Android, que valem como escape).
Future<bool?> mostrarDialogo(
  BuildContext context, {
  required String barra,
  required String titulo,
  required String corpo,
  required String acao,
  String? escape,
  IconData? icone,
  bool perigo = false,
  bool dispensavel = true,
  Matiz? matiz,
}) {
  final c = context.cores;
  if (perigo) HapticFeedback.mediumImpact();
  // Dentro de um jogo, a janela toma a luz dele; fora, a primária.
  final luz = matiz == null
      ? Luz(c.primaria, c.primariaTinta, c.luz(Matiz.lampada).suave)
      : c.luz(matiz);
  final tema = temaComLuz(Theme.of(context), luz);
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: dispensavel,
    barrierLabel: escape ?? 'Fechar',
    barrierColor: Colors.transparent,
    transitionDuration: Movimento.d(context, Movimento.media),
    pageBuilder: (contexto, _, _) => Theme(
      data: tema,
      child: _Dialogo(
        barra: barra,
        titulo: titulo,
        corpo: corpo,
        acao: acao,
        escape: escape,
        icone: icone,
        perigo: perigo,
        luz: luz,
      ),
    ),
    transitionBuilder: (contexto, animacao, _, filho) {
      final curva = CurvedAnimation(
        parent: animacao,
        curve: Movimento.entrada,
        reverseCurve: Movimento.saida,
      );
      return Stack(
        children: [
          // O véu entra em fade e desfoca o que está atrás.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: animacao,
                builder: (_, _) => BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 6 * animacao.value,
                    sigmaY: 6 * animacao.value,
                  ),
                  child: ColoredBox(
                    color: c.veu.withValues(alpha: c.veu.a * animacao.value),
                  ),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: curva,
            child: AnimatedBuilder(
              animation: curva,
              builder: (_, f) => Transform.translate(
                offset: Offset(0, 8 * (1 - curva.value)),
                child: Transform.scale(scale: .9 + .1 * curva.value, child: f),
              ),
              child: filho,
            ),
          ),
        ],
      );
    },
  );
}

class _Dialogo extends StatelessWidget {
  const _Dialogo({
    required this.barra,
    required this.titulo,
    required this.corpo,
    required this.acao,
    this.escape,
    this.icone,
    this.perigo = false,
    required this.luz,
  });

  final String barra, titulo, corpo, acao;
  final Luz luz;
  final String? escape;
  final IconData? icone;
  final bool perigo;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luzIcone = perigo ? c.erro : luz;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Espaco.margemTela),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Material(
            type: MaterialType.transparency,
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: titulo,
              child: Janela(
                titulo: barra,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (icone != null) ...[
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: luzIcone.suave,
                              borderRadius: BorderRadius.circular(Raio.md),
                              border: c.ehDia
                                  ? Border.all(color: c.contorno, width: 2)
                                  : null,
                            ),
                            child: Icon(
                              icone,
                              fill: 1,
                              size: 28,
                              color: luzIcone.tinta,
                            ),
                          ),
                          const SizedBox(width: Espaco.e4),
                        ],
                        Expanded(
                          child: Text(titulo, style: texto.headlineSmall),
                        ),
                      ],
                    ),
                    const SizedBox(height: Espaco.e3),
                    Text(
                      corpo,
                      style: texto.bodyMedium?.copyWith(color: c.texto2),
                    ),
                    const SizedBox(height: Espaco.e6),
                    BotaoSala(
                      rotulo: acao,
                      variante: perigo
                          ? VarianteBotao.perigo
                          : VarianteBotao.primario,
                      luz: perigo ? null : luz,
                      bloco: true,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                    if (escape != null) ...[
                      const SizedBox(height: Espaco.e2),
                      BotaoSala(
                        rotulo: escape!,
                        variante: VarianteBotao.fantasma,
                        luz: Luz(c.texto, c.texto, c.superficieFunda),
                        bloco: true,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
