import 'package:flutter/material.dart';

import '../../../core/theme/sala_tokens.dart';

/// Janela de sistema retrô, para momentos de foco (resultado, regras,
/// diálogo): barra de título em pixel com três luzinhas. No máximo uma
/// por tela.
class Janela extends StatelessWidget {
  const Janela({
    super.key,
    required this.titulo,
    required this.child,
    this.preenchimento = const EdgeInsets.all(Espaco.e6),
  });

  /// Até três palavras, já em CAIXA ALTA: "FIM DE JOGO".
  final String titulo;
  final Widget child;
  final EdgeInsets preenchimento;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(Raio.xl),
        border: Border.all(
          color: c.ehDia ? c.contorno : c.linha,
          width: c.bordaControle,
        ),
        boxShadow: c.sombraCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: Espaco.e4),
            decoration: BoxDecoration(
              color: c.janelaBarra,
              border: c.ehDia
                  ? Border(bottom: BorderSide(color: c.contorno, width: 2))
                  : null,
            ),
            child: Row(
              children: [
                for (final m in const [Matiz.lampada, Matiz.rosa, Matiz.menta])
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: Espaco.e1),
                    decoration: BoxDecoration(
                      color: c.luz(m).cor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                const SizedBox(width: Espaco.e2),
                Semantics(
                  header: true,
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: c.janelaBarraTexto,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: preenchimento, child: child),
        ],
      ),
    );
  }
}
