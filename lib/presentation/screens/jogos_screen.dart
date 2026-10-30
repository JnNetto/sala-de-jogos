import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';

import '../../core/constants/jogos_disponiveis.dart';
import '../../core/theme/sala_tokens.dart';
import '../widgets/sala/botao_sala.dart';
import '../widgets/sala/cartao_jogo.dart';
import '../widgets/sala/cena_sala.dart';
import '../widgets/sala/varal.dart';
import 'aneis/aneis_home_screen.dart';
import 'impostor_home_screen.dart';
import 'lobisomem/lobisomem_home_screen.dart';
import 'pergunta_impostora/pergunta_home_screen.dart';
import 'quiz_da_vez/quiz_home_screen.dart';
import 'expedicao/expedicao_home_screen.dart';
import 'so_uma/so_uma_home_screen.dart';

/// A estante: todos os jogos, com o mais novo em destaque. Chega-se aqui
/// pelo "Jogar" da tela inicial.
class JogosScreen extends StatefulWidget {
  const JogosScreen({super.key});

  static const titulo = 'Escolha o jogo';

  @override
  State<JogosScreen> createState() => _JogosScreenState();
}

class _JogosScreenState extends State<JogosScreen>
    with SingleTickerProviderStateMixin {
  final _rolagem = ScrollController();

  /// A barra compacta aparece quando o título grande sai de cena.
  final _compacto = ValueNotifier(false);
  static const _limiteCompacto = 110.0;

  /// O jogo que acabou de chegar ganha a janela; o resto vai para a grade.
  static final _destaque = JogosDisponiveis.visiveis
      .where((j) => j.novo)
      .firstOrNull;
  static final _grade = JogosDisponiveis.visiveis
      .where((j) => j != _destaque)
      .toList();

  /// Entrada em cascata: cada card sobe 12 px com fade, 40 ms entre eles.
  /// A fatia 0 é do destaque; a grade começa na 1.
  late final AnimationController _entrada;
  late final List<Animation<double>> _fatias;
  static const _atrasoCascata = Duration(milliseconds: 40);

  @override
  void initState() {
    super.initState();
    _rolagem.addListener(() {
      _compacto.value = _rolagem.offset > _limiteCompacto;
    });
    final quantos = _grade.length + 1;
    _entrada = AnimationController(
      vsync: this,
      duration: Movimento.base + _atrasoCascata * (quantos - 1),
    );
    final total = _entrada.duration!.inMilliseconds;
    _fatias = [
      for (var i = 0; i < quantos; i++)
        CurvedAnimation(
          parent: _entrada,
          curve: Interval(
            (_atrasoCascata * i).inMilliseconds / total,
            ((_atrasoCascata * i + Movimento.base).inMilliseconds / total)
                .clamp(0, 1),
            curve: Movimento.entrada,
          ),
        ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entrada.isDismissed) {
      Movimento.reduzido(context) ? _entrada.value = 1 : _entrada.forward();
    }
  }

  @override
  void dispose() {
    _rolagem.dispose();
    _compacto.dispose();
    _entrada.dispose();
    super.dispose();
  }

  Widget _telaDoJogo(String jogoId) {
    return switch (jogoId) {
      JogosDisponiveis.idEspiao => const ImpostorHomeScreen(),
      JogosDisponiveis.idPergunta => const PerguntaHomeScreen(),
      JogosDisponiveis.idQuiz => const QuizHomeScreen(),
      JogosDisponiveis.idResistencia => const ExpedicaoHomeScreen(),
      JogosDisponiveis.idSoUma => const SoUmaHomeScreen(),
      JogosDisponiveis.idLobisomem => const LobisomemHomeScreen(),
      JogosDisponiveis.idAneis => const AneisHomeScreen(),
      _ => throw ArgumentError.value(jogoId, 'jogoId', 'Jogo desconhecido'),
    };
  }

  void _avisarEmBreve() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Esse jogo chega em breve. Fique de olho!'),
        ),
      );
  }

  /// Card [i] da cascata de entrada.
  Widget _entrando(int i, Widget card) {
    final fatia = _fatias[i];
    return FadeTransition(
      opacity: fatia,
      child: AnimatedBuilder(
        animation: fatia,
        builder: (_, filho) => Transform.translate(
          offset: Offset(0, 12 * (1 - fatia.value)),
          child: filho,
        ),
        child: card,
      ),
    );
  }

  Widget _ladrilho(int i) {
    final jogo = _grade[i];
    return _entrando(
      i + 1,
      CartaoJogo.ladrilho(
        jogo: jogo,
        telaDoJogo: (_) => _telaDoJogo(jogo.id),
        aoIndisponivel: _avisarEmBreve,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final topo = MediaQuery.paddingOf(context).top;
    final base = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: CenaSala(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Espaco.larguraMax),
                child: CustomScrollView(
                  controller: _rolagem,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        Espaco.margemTela,
                        topo + Varal.altura + Espaco.e1,
                        Espaco.margemTela,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(child: _cabecalho(context, c)),
                    ),
                    if (_destaque case final jogo?)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          Espaco.margemTela,
                          0,
                          Espaco.margemTela,
                          Espaco.e8,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _entrando(
                            0,
                            CartaoJogo.destaque(
                              jogo: jogo,
                              telaDoJogo: (_) => _telaDoJogo(jogo.id),
                              aoIndisponivel: _avisarEmBreve,
                            ),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        Espaco.margemTela,
                        0,
                        Espaco.margemTela,
                        Espaco.e3,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Semantics(
                          header: true,
                          child: Text(
                            'TODOS OS JOGOS',
                            style: Theme.of(
                              context,
                            ).textTheme.labelMedium?.copyWith(color: c.texto3),
                          ),
                        ),
                      ),
                    ),
                    // Grade de duas colunas; cada linha tem a altura do
                    // ladrilho mais alto dela.
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Espaco.margemTela,
                      ),
                      sliver: SliverList.separated(
                        itemCount: (_grade.length + 1) ~/ 2,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: Espaco.e3),
                        itemBuilder: (context, linha) {
                          final i = linha * 2;
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _ladrilho(i)),
                                const SizedBox(width: Espaco.e3),
                                Expanded(
                                  child: i + 1 < _grade.length
                                      ? _ladrilho(i + 1)
                                      : const SizedBox(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: base + Espaco.e12),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _BarraCompacta(visivel: _compacto, topo: topo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho(BuildContext context, SalaCores c) {
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BotaoIcone(
          icone: Symbols.arrow_back_rounded,
          rotulo: 'Voltar',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: Espaco.e6),
        // Títulos display param de crescer acima de 1,3× de escala de texto.
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Semantics(
            header: true,
            child: Text(JogosScreen.titulo, style: texto.displayMedium),
          ),
        ),
        const SizedBox(height: Espaco.e2),
        Text(
          'A galera chegou. Qual vai ser hoje?',
          style: texto.bodyLarge?.copyWith(color: c.texto2),
        ),
        const SizedBox(height: Espaco.e8),
      ],
    );
  }
}

/// Ao rolar, o título encolhe numa barra com fundo a 92% e desfoque, com o
/// voltar à mão. Ela começa no topo da tela, então o varal fica sobre ela.
class _BarraCompacta extends StatelessWidget {
  const _BarraCompacta({required this.visivel, required this.topo});

  final ValueListenable<bool> visivel;
  final double topo;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return ValueListenableBuilder<bool>(
      valueListenable: visivel,
      builder: (context, mostrar, barra) => IgnorePointer(
        ignoring: !mostrar,
        child: AnimatedOpacity(
          opacity: mostrar ? 1 : 0,
          duration: Movimento.base,
          curve: Movimento.padrao,
          child: barra,
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            // O varal do palco fica pendurado por cima da barra.
            height: topo + Varal.altura + 56,
            padding: EdgeInsets.only(top: topo + Varal.altura),
            decoration: BoxDecoration(
              color: c.fundo.withValues(alpha: .92),
              border: Border(
                bottom: BorderSide(
                  color: c.ehDia ? c.contorno : c.linha,
                  width: c.bordaControle,
                ),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: Espaco.margemTela,
                  child: BotaoIcone(
                    icone: Symbols.arrow_back_rounded,
                    rotulo: 'Voltar',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Text(
                  JogosScreen.titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontVariations: const [FontVariation.weight(900)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
