import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/sala_tokens.dart';
import 'botao_sala.dart';
import 'pressionavel.dart';
import 'tela_da_sala.dart';

/// Uma categoria na folha: o nome e quantos itens (palavras, perguntas)
/// ela tem.
typedef OpcaoCategoria = ({String id, String nome, int quantidade});

/// O que a folha precisa saber de um jogo: as categorias, a seleção (que
/// vive no provider do jogo) e as ações. [ouvir] avisa quando a seleção
/// muda.
class FonteDeCategorias {
  const FonteDeCategorias({
    required this.ouvir,
    required this.opcoes,
    required this.selecionada,
    required this.alternar,
    required this.todas,
    required this.nenhuma,
    required this.sortear,
    required this.total,
    required this.singular,
    required this.plural,
  });

  final Listenable ouvir;
  final List<OpcaoCategoria> Function() opcoes;
  final bool Function(String id) selecionada;
  final void Function(String id) alternar;
  final VoidCallback todas, nenhuma, sortear;

  /// Quantos itens entram no sorteio com a seleção atual.
  final int Function() total;

  /// "palavra" / "palavras", "pergunta" / "perguntas".
  final String singular, plural;

  int get escolhidas => opcoes().where((o) => selecionada(o.id)).length;

  /// "Todas as 15 categorias · 400 palavras."
  String get resumo {
    final todasAs = opcoes().length;
    final n = escolhidas;
    final itens = total();
    final unidade = itens == 1 ? singular : plural;
    if (n == 0) return 'Nenhuma escolhida. Escolha pelo menos uma.';
    if (n == todasAs) return 'Todas as $todasAs categorias · $itens $unidade.';
    return '$n de $todasAs categorias · $itens $unidade.';
  }
}

/// Abre a folha de categorias: de onde sai o sorteio. Fecha em "Pronto".
Future<void> mostrarFolhaDeCategorias(
  BuildContext context, {
  required FonteDeCategorias fonte,
  required Matiz matiz,
  String descricao = 'De onde sai o sorteio.',
}) {
  final tema = temaComLuz(Theme.of(context), context.cores.luz(matiz));
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => Theme(
      data: tema,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .82,
        minChildSize: .5,
        maxChildSize: .92,
        builder: (_, rolagem) => ListenableBuilder(
          listenable: fonte.ouvir,
          builder: (context, _) => _Folha(
            fonte: fonte,
            matiz: matiz,
            descricao: descricao,
            rolagem: rolagem,
          ),
        ),
      ),
    ),
  );
}

class _Folha extends StatelessWidget {
  const _Folha({
    required this.fonte,
    required this.matiz,
    required this.descricao,
    required this.rolagem,
  });

  final FonteDeCategorias fonte;
  final Matiz matiz;
  final String descricao;
  final ScrollController rolagem;

  static final _atalho = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: Espaco.e2),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luz(matiz);
    final opcoes = fonte.opcoes();
    final escolhidas = fonte.escolhidas;
    final total = fonte.total();

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: rolagem,
            padding: const EdgeInsets.fromLTRB(
              Espaco.margemTela,
              0,
              Espaco.margemTela,
              Espaco.e4,
            ),
            children: [
              Text('Categorias', style: texto.headlineMedium),
              const SizedBox(height: Espaco.e1),
              Text(
                descricao,
                style: texto.bodyMedium?.copyWith(color: c.texto2),
              ),
              const SizedBox(height: Espaco.e2),
              Wrap(
                children: [
                  TextButton.icon(
                    style: _atalho,
                    onPressed: escolhidas == opcoes.length ? null : fonte.todas,
                    icon: const Icon(Symbols.done_all_rounded),
                    label: const Text('Todas'),
                  ),
                  TextButton.icon(
                    style: _atalho,
                    onPressed: escolhidas == 0 ? null : fonte.nenhuma,
                    icon: const Icon(Symbols.remove_done_rounded),
                    label: const Text('Nenhuma'),
                  ),
                  TextButton.icon(
                    style: _atalho,
                    onPressed: opcoes.length > 3
                        ? () {
                            HapticFeedback.lightImpact();
                            fonte.sortear();
                          }
                        : null,
                    icon: const Icon(Symbols.casino_rounded),
                    label: const Text('Sortear 3'),
                  ),
                ],
              ),
              const SizedBox(height: Espaco.e3),
              for (var i = 0; i < opcoes.length; i += 2) ...[
                if (i > 0) const SizedBox(height: Espaco.e3),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _ladrilho(opcoes[i], luz)),
                      const SizedBox(width: Espaco.e3),
                      Expanded(
                        child: i + 1 < opcoes.length
                            ? _ladrilho(opcoes[i + 1], luz)
                            : const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Espaco.margemTela,
              Espaco.e3,
              Espaco.margemTela,
              Espaco.e4,
            ),
            child: BotaoSala(
              rotulo: escolhidas == 0
                  ? 'Escolha pelo menos uma'
                  : 'Pronto · $total ${total == 1 ? fonte.singular : fonte.plural}',
              icone: Symbols.check_rounded,
              luz: luz,
              bloco: true,
              onPressed: escolhidas == 0
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _ladrilho(OpcaoCategoria opcao, Luz luz) => _Ladrilho(
    opcao: opcao,
    selecionada: fonte.selecionada(opcao.id),
    unidade: (opcao.quantidade == 1 ? fonte.singular : fonte.plural)
        .toUpperCase(),
    luz: luz,
    aoTocar: () {
      HapticFeedback.selectionClick();
      fonte.alternar(opcao.id);
    },
  );
}

class _Ladrilho extends StatelessWidget {
  const _Ladrilho({
    required this.opcao,
    required this.selecionada,
    required this.unidade,
    required this.luz,
    required this.aoTocar,
  });

  final OpcaoCategoria opcao;
  final bool selecionada;
  final String unidade;
  final Luz luz;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selecionada,
      label: '${opcao.nome}, ${opcao.quantidade} $unidade',
      excludeSemantics: true,
      child: Pressionavel(
        onTap: aoTocar,
        child: AnimatedContainer(
          duration: Movimento.base,
          curve: Movimento.padrao,
          padding: const EdgeInsets.all(Espaco.e4),
          decoration: BoxDecoration(
            color: selecionada
                ? Color.lerp(c.superficie, luz.cor, c.ehDia ? .14 : .16)
                : c.superficieElevada,
            borderRadius: BorderRadius.circular(Raio.lg),
            border: Border.all(
              color: selecionada
                  ? (c.ehDia ? c.contorno : luz.cor)
                  : (c.ehDia ? c.contorno : c.linha),
              width: selecionada ? 2 : c.bordaControle,
            ),
            boxShadow: selecionada
                ? c.brilho(luz.cor, alpha: .25, blur: 18)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(opcao.nome, style: texto.titleMedium)),
                  const SizedBox(width: Espaco.e2),
                  AnimatedSwitcher(
                    duration: Movimento.base,
                    switchInCurve: Movimento.pulo,
                    transitionBuilder: (f, a) =>
                        ScaleTransition(scale: a, child: f),
                    child: Icon(
                      selecionada
                          ? Symbols.check_circle_rounded
                          : Symbols.radio_button_unchecked_rounded,
                      key: ValueKey(selecionada),
                      fill: selecionada ? 1 : 0,
                      size: 22,
                      color: selecionada ? luz.tinta : c.texto3,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const SizedBox(height: Espaco.e3),
              Text(
                '${opcao.quantidade} $unidade',
                style: texto.labelSmall?.copyWith(
                  color: selecionada ? luz.tinta : c.texto3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
