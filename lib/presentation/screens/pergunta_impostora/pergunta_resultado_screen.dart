import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/enums/vencedor.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../../data/models/jogador_pergunta.dart';
import '../../../data/models/par_perguntas.dart';
import '../../navegacao.dart';
import '../../providers/pergunta_partida_provider.dart';
import '../../widgets/sala/botao_sala.dart';
import '../../widgets/sala/fim_de_jogo.dart';
import '../../widgets/sala/janela.dart';
import '../../widgets/sala/jogador_sala.dart';
import '../../widgets/sala/selo_papel.dart';
import '../../widgets/sala/tela_da_sala.dart';
import 'pergunta_distribuicao_screen.dart';

/// Fim de jogo: quem venceu, quem tinha a outra pergunta, as duas
/// perguntas e o que cada um respondeu.
class PerguntaResultadoScreen extends StatefulWidget {
  const PerguntaResultadoScreen({super.key});

  @override
  State<PerguntaResultadoScreen> createState() =>
      _PerguntaResultadoScreenState();
}

class _PerguntaResultadoScreenState extends State<PerguntaResultadoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrada;

  // A partida é copiada aqui: "Jogar de novo" troca a do provider.
  late final Vencedor _vencedor;
  late final ParPerguntas _par;
  late final List<JogadorPergunta> _jogadores;

  @override
  void initState() {
    super.initState();
    final partida = context.read<PerguntaPartidaProvider>().partida!;
    _vencedor = partida.vencedor;
    _par = partida.par;
    _jogadores = List.of(partida.jogadores);
    _entrada = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 320 + 60 * _jogadores.length + 220),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Movimento.reduzido(context)) {
        _entrada.value = 1;
      } else {
        _entrada.forward();
      }
      context.read<PerguntaPartidaProvider>().finalizarPartida();
    });
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  Animation<double> _trecho(int inicioMs, int duracaoMs, Curve curva) {
    final total = _entrada.duration!.inMilliseconds;
    return CurvedAnimation(
      parent: _entrada,
      curve: Interval(
        inicioMs / total,
        ((inicioMs + duracaoMs) / total).clamp(0, 1),
        curve: curva,
      ),
    );
  }

  SeloPapel _selo(JogadorPergunta j) => j.isEspiao
      ? SeloPapel(
          texto: 'IMPOSTOR',
          icone: Symbols.theater_comedy_rounded,
          luz: context.cores.papelEspiao,
          compacto: true,
        )
      : SeloPapel.civil(context, compacto: true);

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final civis = _vencedor == Vencedor.civis;
    final impostores = _jogadores.where((j) => j.isEspiao).toList();
    final varios = impostores.length > 1;
    final titulo = _trecho(0, 320, Movimento.pulo);

    return PopScope(
      canPop: false,
      child: TelaDaSala(
        matiz: Matiz.rosa,
        corpo: ListView(
          padding: const EdgeInsets.fromLTRB(
            Espaco.margemTela,
            Espaco.e2,
            Espaco.margemTela,
            Espaco.e6,
          ),
          children: [
            AnimatedBuilder(
              animation: titulo,
              builder: (_, f) => Opacity(
                opacity: titulo.value.clamp(0, 1),
                child: Transform.scale(scale: .9 + .1 * titulo.value, child: f),
              ),
              child: Janela(
                titulo: 'FIM DE JOGO',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SeloPapel(
                        texto: civis
                            ? 'CIVIS VENCERAM'
                            : (varios
                                  ? 'IMPOSTORES VENCERAM'
                                  : 'IMPOSTOR VENCEU'),
                        icone: Symbols.trophy_rounded,
                        luz: civis ? c.papelCivil : c.papelEspiao,
                      ),
                    ),
                    const SizedBox(height: Espaco.e4),
                    Text(
                      civis
                          ? (varios
                                ? 'Pegaram os impostores!'
                                : 'Pegaram o impostor!')
                          : (varios
                                ? 'Os impostores escaparam!'
                                : 'O impostor escapou!'),
                      textAlign: TextAlign.center,
                      style: texto.headlineMedium,
                    ),
                    const SizedBox(height: Espaco.e6),
                    for (final i in impostores) ...[
                      FatoDoFim(
                        poco: AvatarJogador(
                          nome: i.nome,
                          indice: i.id - 1,
                          tamanho: 44,
                        ),
                        texto: comDestaque(
                          context,
                          '',
                          i.nome,
                          ' tinha a outra pergunta',
                        ),
                        direita: _selo(i),
                      ),
                      const SizedBox(height: Espaco.e2),
                    ],
                    FatoDoFim(
                      poco: PocoIcone(
                        icone: Symbols.group_rounded,
                        luz: c.papelCivil,
                      ),
                      texto: comDestaque(
                        context,
                        'A pergunta de todos era:\n',
                        _par.principal,
                      ),
                    ),
                    const SizedBox(height: Espaco.e2),
                    FatoDoFim(
                      poco: PocoIcone(
                        icone: Symbols.theater_comedy_rounded,
                        luz: c.papelEspiao,
                      ),
                      texto: comDestaque(
                        context,
                        varios
                            ? 'A pergunta dos impostores era:\n'
                            : 'A pergunta do impostor era:\n',
                        _par.impostor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Espaco.e8),
            Row(
              children: [
                Expanded(child: Text('Na mesa', style: texto.titleMedium)),
                Text(
                  '${_jogadores.length} JOGADORES',
                  style: texto.labelSmall?.copyWith(color: c.texto3),
                ),
              ],
            ),
            const SizedBox(height: Espaco.e3),
            for (final (i, j) in _jogadores.indexed) ...[
              AnimatedBuilder(
                animation: _entrada,
                builder: (_, f) {
                  final a = _trecho(320 + 60 * i, 220, Movimento.entrada);
                  return Opacity(
                    opacity: a.value.clamp(0, 1),
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - a.value)),
                      child: f,
                    ),
                  );
                },
                child: LinhaJogador(
                  nome: j.nome,
                  indice: j.id - 1,
                  apagado: j.foiEliminado,
                  apoio: '“${j.resposta ?? '...'}”',
                  direita: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _selo(j),
                      if (j.foiEliminado) ...[
                        const SizedBox(height: Espaco.e1),
                        Text(
                          'FORA',
                          style: texto.labelSmall?.copyWith(color: c.texto3),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Espaco.e2),
            ],
          ],
        ),
        rodape: Consumer<PerguntaPartidaProvider>(
          builder: (context, provider, _) => SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Espaco.margemTela,
                Espaco.e3,
                Espaco.margemTela,
                Espaco.e3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BotaoSala(
                    rotulo: 'Jogar de novo',
                    icone: Symbols.replay_rounded,
                    luz: c.luz(Matiz.rosa),
                    bloco: true,
                    carregando: provider.isLoading,
                    onPressed: () async {
                      final sucesso = await provider.jogarNovamente();
                      if (!context.mounted) return;
                      if (sucesso) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const PerguntaDistribuicaoScreen(),
                          ),
                          ehInicioDaImpostora,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.erro ??
                                  'Não deu para começar outra partida. '
                                      'Tente de novo.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: Espaco.e1),
                  BotaoSala(
                    rotulo: 'Voltar ao início',
                    variante: VarianteBotao.fantasma,
                    luz: Luz(c.texto2, c.texto2, c.superficieFunda),
                    bloco: true,
                    onPressed: () {
                      provider.encerrarPartida();
                      Navigator.of(context).popUntil(ehInicioDaImpostora);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
