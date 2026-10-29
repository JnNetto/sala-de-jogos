import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/sala_tokens.dart';
import 'botao_sala.dart';

/// A barra dos fluxos: transparente sobre o céu, voltar à esquerda, uma ação
/// opcional à direita e o título no meio, com sobretítulo em pixel.
class BarraTopo extends StatelessWidget {
  const BarraTopo({
    super.key,
    required this.titulo,
    this.sobretitulo,
    this.corSobretitulo,
    this.acao,
    this.voltar = true,
    this.aoVoltar,
    this.inicio,
  });

  final String titulo;

  /// Rótulo curto em CAIXA ALTA acima do título: "RODADA 2 DE 5".
  final String? sobretitulo;
  final Color? corSobretitulo;

  /// Um [BotaoIcone] à direita.
  final Widget? acao;

  /// Sem voltar (no meio de uma rodada, por exemplo), o espaço fica vazio.
  final bool voltar;

  /// Quando a tela confirma antes de sair; o padrão é `maybePop`.
  final VoidCallback? aoVoltar;

  /// Um [BotaoIcone] no lugar do voltar (o pausar, numa rodada).
  final Widget? inicio;

  static const altura = 64.0;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    return SizedBox(
      height: altura,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Espaco.e3),
        child: Row(
          children: [
            if (inicio != null)
              inicio!
            else if (voltar)
              BotaoIcone(
                icone: Symbols.arrow_back_rounded,
                rotulo: 'Voltar',
                onPressed: aoVoltar ?? () => Navigator.of(context).maybePop(),
              )
            else
              const SizedBox(width: Espaco.alvoToque),
            Expanded(
              child: Semantics(
                header: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sobretitulo != null)
                      Text(
                        sobretitulo!,
                        style: texto.labelSmall?.copyWith(
                          color: corSobretitulo ?? c.texto3,
                        ),
                      ),
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: texto.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontVariations: const [FontVariation.weight(900)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Mantém o título no centro mesmo sem ação.
            acao ?? const SizedBox(width: Espaco.alvoToque),
          ],
        ),
      ),
    );
  }
}
