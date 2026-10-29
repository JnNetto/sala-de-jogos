import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/enums/vencedor.dart';
import '../../core/theme/sala_tokens.dart';
import '../../data/models/jogador_partida.dart';
import '../../data/models/palavra.dart';
import '../navegacao.dart';
import '../providers/partida_provider.dart';
import '../widgets/sala/botao_sala.dart';
import '../widgets/sala/fim_de_jogo.dart';
import '../widgets/sala/janela.dart';
import '../widgets/sala/jogador_sala.dart';
import '../widgets/sala/selo_papel.dart';
import '../widgets/sala/tela_da_sala.dart';
import 'distribuicao_papeis_screen.dart';

/// Fim de jogo: quem venceu, quem era espião, qual era a palavra e como
/// ficou a mesa.
class ResultadoScreen extends StatefulWidget {
  const ResultadoScreen({super.key});

  @override
  State<ResultadoScreen> createState() => _ResultadoScreenState();
}

class _ResultadoScreenState extends State<ResultadoScreen>
    with SingleTickerProviderStateMixin {
  /// Título entra com escala; linhas da mesa em cascata de 60 ms.
  late final AnimationController _entrada;

  // A partida é copiada aqui: "Jogar de novo" troca a do provider.
  late final Vencedor _vencedor;
  late final Palavra _palavraSecreta;
  Palavra? _palavraRelacionada;
  late final List<JogadorPartida> _jogadores;

  @override
  void initState() {
    super.initState();
    final partida = context.read<PartidaProvider>().partida;
    _vencedor = partida?.vencedor ?? Vencedor.emAndamento;
    _palavraSecreta = partida!.palavraSecreta;
    _palavraRelacionada = partida.palavraRelacionada;
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
      context.read<PartidaProvider>().finalizarPartida();
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

  Widget _entrando(Animation<double> a, Widget filho, {double sobe = 12}) =>
      AnimatedBuilder(
        animation: a,
        builder: (_, f) => Opacity(
          opacity: a.value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, sobe * (1 - a.value)),
            child: f,
          ),
        ),
        child: filho,
      );

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final civis = _vencedor == Vencedor.civis;
    final espioes = _jogadores.where((j) => j.isEspiao).toList();
    final varios = espioes.length > 1;
    final luzVencedor = civis ? c.papelCivil : c.papelEspiao;
    final frase = civis
        ? (varios ? 'Pegaram os espiões!' : 'Pegaram o espião!')
        : (varios ? 'Os espiões escaparam!' : 'O espião escapou!');
    final titulo = _trecho(0, 320, Movimento.pulo);

    return PopScope(
      canPop: false,
      child: TelaDaSala(
        matiz: Matiz.violeta,
        corpo: SafeArea(
          top: false,
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Espaco.larguraMax),
              child: ListView(
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
                      child: Transform.scale(
                        scale: .9 + .1 * titulo.value,
                        child: f,
                      ),
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
                                        ? 'ESPIÕES VENCERAM'
                                        : 'ESPIÃO VENCEU'),
                              icone: Symbols.trophy_rounded,
                              luz: luzVencedor,
                            ),
                          ),
                          const SizedBox(height: Espaco.e4),
                          Text(
                            frase,
                            textAlign: TextAlign.center,
                            style: texto.headlineMedium,
                          ),
                          const SizedBox(height: Espaco.e6),
                          for (final e in espioes) ...[
                            FatoDoFim(
                              poco: AvatarJogador(
                                nome: e.nome,
                                indice: e.id - 1,
                                tamanho: 44,
                              ),
                              texto: TextSpan(
                                children: [
                                  TextSpan(
                                    text: e.nome,
                                    style: TextStyle(
                                      color: c.texto,
                                      fontWeight: FontWeight.w800,
                                      fontVariations: const [
                                        FontVariation.weight(800),
                                      ],
                                    ),
                                  ),
                                  const TextSpan(text: ' era espião'),
                                ],
                              ),
                              direita: SeloPapel.espiao(
                                context,
                                compacto: true,
                              ),
                            ),
                            const SizedBox(height: Espaco.e2),
                          ],
                          FatoDoFim(
                            poco: PocoIcone(
                              icone: Symbols.key_rounded,
                              luz: c.papelCivil,
                            ),
                            texto: comDestaque(
                              context,
                              'A palavra era ',
                              _palavraSecreta.texto,
                            ),
                          ),
                          if (_palavraRelacionada != null) ...[
                            const SizedBox(height: Espaco.e2),
                            FatoDoFim(
                              poco: PocoIcone(
                                icone: Symbols.visibility_off_rounded,
                                luz: c.papelEspiao,
                              ),
                              texto: comDestaque(
                                context,
                                'A pista do espião era ',
                                _palavraRelacionada!.texto,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Espaco.e8),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Na mesa', style: texto.titleMedium),
                      ),
                      Text(
                        '${_jogadores.length} JOGADORES',
                        style: texto.labelSmall?.copyWith(color: c.texto3),
                      ),
                    ],
                  ),
                  const SizedBox(height: Espaco.e3),
                  for (final (i, j) in _jogadores.indexed) ...[
                    _entrando(
                      _trecho(320 + 60 * i, 220, Movimento.entrada),
                      LinhaJogador(
                        nome: j.nome,
                        indice: j.id - 1,
                        apagado: j.foiEliminado,
                        direita: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (j.foiEliminado) ...[
                              Text(
                                'FORA',
                                style: texto.labelSmall?.copyWith(
                                  color: c.texto3,
                                ),
                              ),
                              const SizedBox(width: Espaco.e2),
                            ],
                            j.isEspiao
                                ? SeloPapel.espiao(context, compacto: true)
                                : SeloPapel.civil(context, compacto: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Espaco.e2),
                  ],
                ],
              ),
            ),
          ),
        ),
        rodape: Consumer<PartidaProvider>(
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
                    luz: c.luz(Matiz.violeta),
                    bloco: true,
                    carregando: provider.isLoading,
                    onPressed: () async {
                      final sucesso = await provider.jogarNovamente();
                      if (!context.mounted) return;
                      if (sucesso) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const DistribuicaoPapeisScreen(),
                          ),
                          ehInicioDoEspiao,
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
                      Navigator.of(context).popUntil(ehInicioDoEspiao);
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
