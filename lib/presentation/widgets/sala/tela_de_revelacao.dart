import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/sala_tokens.dart';
import 'botao_sala.dart';
import 'carta_revelacao.dart';
import 'jogador_sala.dart';
import 'palco_da_sala.dart';
import 'tela_da_sala.dart';

/// A roda de cartas: o celular passa de mão em mão, cada um segura a carta
/// para ver a frente dela e esconde antes de passar. O varal do topo vira
/// o progresso, uma lâmpada por jogador. Quando todos passaram, entra o
/// [fim].
class TelaDeRevelacao extends StatefulWidget {
  const TelaDeRevelacao({
    super.key,
    required this.nomeDoJogo,
    required this.matiz,
    required this.nomes,
    required this.frente,
    required this.fim,
    required this.aoVoltar,
    required this.aoAbortar,
    this.espiao,
    this.sobretitulo = 'REVELAÇÃO',
    this.feito = 'JÁ VIRAM',
    this.dicaDoUltimo = 'Último da roda.',
  });

  final String nomeDoJogo;
  final Matiz matiz;

  /// Na ordem de passar o celular.
  final List<String> nomes;

  /// A frente da carta de cada jogador. [esconder] vira a carta de volta e
  /// passa a vez.
  final Widget Function(
    BuildContext context,
    int indice,
    VoidCallback esconder,
    Animation<double> efeito,
  )
  frente;

  /// O que aparece quando todo mundo já passou.
  final WidgetBuilder fim;
  final VoidCallback aoVoltar, aoAbortar;

  /// Quem é espião vibra diferente na virada. Num jogo em que ninguém sabe
  /// o próprio papel, deixe nulo: todos vibram igual.
  final bool Function(int indice)? espiao;
  final String sobretitulo;

  /// "2 DE 6 JÁ VIRAM".
  final String feito;
  final String dicaDoUltimo;

  @override
  State<TelaDeRevelacao> createState() => _TelaDeRevelacaoState();
}

class _TelaDeRevelacaoState extends State<TelaDeRevelacao> {
  int _atual = 0;
  bool _revelada = false;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final total = widget.nomes.length;
    final acabou = _atual >= total;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) widget.aoVoltar();
      },
      child: TelaDaSala(
        sobretitulo: widget.sobretitulo,
        titulo: widget.nomeDoJogo,
        matiz: widget.matiz,
        aoVoltar: widget.aoVoltar,
        acao: BotaoIcone(
          icone: Symbols.stop_circle_rounded,
          rotulo: 'Abortar partida',
          perigo: true,
          onPressed: widget.aoAbortar,
        ),
        progresso: ProgressoDoVaral(
          cores: [for (var i = 0; i < total; i++) c.luz(matizDoJogador(i)).cor],
          acesas: _atual,
        ),
        corpo: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: Espaco.e2),
              Text(
                '${_atual.clamp(0, total)} DE $total ${widget.feito}',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: c.texto3),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Espaco.margemTela,
                    vertical: Espaco.e5,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: Movimento.d(context, Movimento.media),
                      switchInCurve: Movimento.entrada,
                      switchOutCurve: Movimento.saida,
                      transitionBuilder: (filho, animacao) {
                        final entrando = filho.key == ValueKey(_atual);
                        return FadeTransition(
                          opacity: animacao,
                          child: SlideTransition(
                            position: Tween(
                              begin: Offset(entrando ? .25 : -.25, 0),
                              end: Offset.zero,
                            ).animate(animacao),
                            child: filho,
                          ),
                        );
                      },
                      child: acabou
                          ? KeyedSubtree(
                              key: ValueKey(_atual),
                              child: widget.fim(context),
                            )
                          : CartaRevelacao(
                              key: ValueKey(_atual),
                              nome: widget.nomes[_atual],
                              indice: _atual,
                              total: total,
                              espiao: widget.espiao?.call(_atual) ?? false,
                              aoMudarFace: (r) => setState(() => _revelada = r),
                              aoEsconder: () => setState(() {
                                _revelada = false;
                                _atual++;
                              }),
                              frente: (esconder, efeito) => widget.frente(
                                context,
                                _atual,
                                esconder,
                                efeito,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 72,
                child: AnimatedSwitcher(
                  duration: Movimento.base,
                  child: acabou
                      ? const SizedBox.shrink()
                      : _revelada && _atual + 1 < total
                      ? _Proximo(
                          key: const ValueKey('proximo'),
                          nome: widget.nomes[_atual + 1],
                          indice: _atual + 1,
                        )
                      : Center(
                          key: ValueKey('dica$_revelada'),
                          child: Text(
                            _revelada
                                ? widget.dicaDoUltimo
                                : 'Soltou antes da hora? Nada aparece.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: c.texto3),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Proximo extends StatelessWidget {
  const _Proximo({super.key, required this.nome, required this.indice});

  final String nome;
  final int indice;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'PRÓXIMO',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: c.texto3),
        ),
        const SizedBox(width: Espaco.e3),
        ChipJogador(nome: nome, indice: indice),
      ],
    );
  }
}

/// O fim de uma roda: um selo de "feito", título, texto e a ação seguinte.
class PainelTodosViram extends StatelessWidget {
  const PainelTodosViram({
    super.key,
    required this.titulo,
    required this.texto,
    required this.acao,
    required this.icone,
    required this.matiz,
    required this.aoContinuar,
  });

  final String titulo, texto, acao;
  final IconData icone;
  final Matiz matiz;
  final VoidCallback aoContinuar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final estilos = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: c.sucesso.suave,
            shape: BoxShape.circle,
            border: Border.all(
              color: c.ehDia ? c.contorno : c.sucesso.cor,
              width: 3,
            ),
            boxShadow: c.brilho(c.sucesso.cor, alpha: .4, blur: 40),
          ),
          child: Icon(Symbols.check_rounded, size: 52, color: c.sucesso.tinta),
        ),
        const SizedBox(height: Espaco.e6),
        Text(titulo, style: estilos.headlineLarge, textAlign: TextAlign.center),
        const SizedBox(height: Espaco.e2),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: estilos.bodyLarge?.copyWith(color: c.texto2),
        ),
        const SizedBox(height: Espaco.e8),
        BotaoSala(
          rotulo: acao,
          icone: icone,
          luz: c.luz(matiz),
          bloco: true,
          onPressed: aoContinuar,
        ),
      ],
    );
  }
}
