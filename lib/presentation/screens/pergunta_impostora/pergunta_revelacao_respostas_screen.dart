import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/sala_tokens.dart';
import '../../providers/pergunta_partida_provider.dart';
import '../../widgets/sala/botao_sala.dart';
import '../../widgets/sala/jogador_sala.dart';
import '../../widgets/sala/tela_da_sala.dart';
import 'pergunta_cartas.dart';
import 'pergunta_discussao_screen.dart';

/// As respostas na mesa, com a pergunta ainda em segredo: a hora de ler em
/// voz alta e já ir desconfiando.
class PerguntaRevelacaoRespostasScreen extends StatefulWidget {
  const PerguntaRevelacaoRespostasScreen({super.key});

  @override
  State<PerguntaRevelacaoRespostasScreen> createState() =>
      _PerguntaRevelacaoRespostasScreenState();
}

class _PerguntaRevelacaoRespostasScreenState
    extends State<PerguntaRevelacaoRespostasScreen>
    with SingleTickerProviderStateMixin {
  /// As respostas entram em cascata, 60 ms entre elas.
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entrada.isDismissed) {
      Movimento.reduzido(context) ? _entrada.value = 1 : _entrada.forward();
    }
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  void _abortar() => abortarPerguntaImpostora(
    context,
    corpo:
        'As respostas se perdem e a partida não conta nas estatísticas. '
        'Vocês voltam para a escolha de jogadores.',
  );

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final partida = context.watch<PerguntaPartidaProvider>().partida;
    if (partida == null) {
      return const TelaDaSala(
        corpo: Center(child: Text('A partida terminou.')),
      );
    }
    final jogadores = partida.jogadores;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) _abortar();
      },
      child: TelaDaSala(
        sobretitulo: 'AS RESPOSTAS',
        titulo: 'Pergunta Impostora',
        matiz: Matiz.rosa,
        voltar: false,
        acao: BotaoIcone(
          icone: Symbols.stop_circle_rounded,
          rotulo: 'Abortar partida',
          perigo: true,
          onPressed: _abortar,
        ),
        corpo: ListView(
          padding: const EdgeInsets.fromLTRB(
            Espaco.margemTela,
            Espaco.e4,
            Espaco.margemTela,
            Espaco.e6,
          ),
          children: [
            Text('Quem destoou?', style: texto.headlineLarge),
            const SizedBox(height: Espaco.e2),
            Text(
              'A pergunta ainda é segredo. Leiam as respostas em voz alta.',
              style: texto.bodyLarge?.copyWith(color: c.texto2),
            ),
            const SizedBox(height: Espaco.e6),
            for (final (i, j) in jogadores.indexed) ...[
              _entrando(
                i,
                LinhaJogador(
                  nome: j.nome,
                  indice: j.id - 1,
                  apoio: '“${j.resposta ?? '...'}”',
                ),
              ),
              const SizedBox(height: Espaco.e3),
            ],
          ],
        ),
        rodape: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Espaco.margemTela,
              Espaco.e3,
              Espaco.margemTela,
              Espaco.e4,
            ),
            child: BotaoSala(
              rotulo: 'Revelar a pergunta',
              icone: Symbols.visibility_rounded,
              luz: c.luz(Matiz.rosa),
              bloco: true,
              onPressed: () {
                context.read<PerguntaPartidaProvider>().iniciarDiscussao();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PerguntaDiscussaoScreen(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _entrando(int i, Widget filho) {
    final total = _entrada.duration!.inMilliseconds;
    final fatia = CurvedAnimation(
      parent: _entrada,
      curve: Interval(
        (60 * i / total).clamp(0, 1),
        ((60 * i + 220) / total).clamp(0, 1),
        curve: Movimento.entrada,
      ),
    );
    return AnimatedBuilder(
      animation: fatia,
      builder: (_, f) => Opacity(
        opacity: fatia.value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - fatia.value)),
          child: f,
        ),
      ),
      child: filho,
    );
  }
}
