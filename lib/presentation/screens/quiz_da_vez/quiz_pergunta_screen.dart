import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/enums/estado_partida_quiz.dart';
import '../../providers/quiz_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'quiz_escolha_alvo_screen.dart';
import 'quiz_passagem_alvo_screen.dart';
import 'quiz_resumo_rodada_screen.dart';

class QuizPerguntaScreen extends StatefulWidget {
  const QuizPerguntaScreen({super.key});

  @override
  State<QuizPerguntaScreen> createState() => _QuizPerguntaScreenState();
}

class _QuizPerguntaScreenState extends State<QuizPerguntaScreen> {
  bool _navegou = false;
  int? _alternativaSelecionada;

  void _confirmar(QuizPartidaProvider provider, bool ehAlvo) {
    if (_alternativaSelecionada == null) return;
    if (ehAlvo) {
      provider.responderAlvo(_alternativaSelecionada);
    } else {
      provider.responderProprio(_alternativaSelecionada);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Consumer<QuizPartidaProvider>(
          builder: (context, provider, _) {
            final partida = provider.partida;
            if (partida == null || partida.perguntaAtual == null) {
              return const Center(child: Text('Erro'));
            }

            final ehAlvo = partida.estado == EstadoPartidaQuiz.perguntaAlvo;
            final pergunta = partida.perguntaAtual!;
            final respondente = ehAlvo
                ? (partida.alvoDoPasse?.nome ?? '')
                : partida.jogadorDaRodada.nome;
            final cor = Theme.of(context).colorScheme.primary;

            if (partida.estado == EstadoPartidaQuiz.resumoRodada && !_navegou) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _navegou) return;
                _navegou = true;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QuizResumoRodadaScreen(),
                  ),
                );
              });
            }

            if (partida.estado == EstadoPartidaQuiz.escolhaAlvo && !_navegou) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _navegou) return;
                _navegou = true;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QuizEscolhaAlvoScreen(),
                  ),
                );
              });
            }

            if (partida.estado == EstadoPartidaQuiz.passagemAlvo && !_navegou) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _navegou) return;
                _navegou = true;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QuizPassagemAlvoScreen(),
                  ),
                );
              });
            }

            final tempo = partida.tempoRestanteSegundos;
            final max = partida.configuracao.tempoPerguntaSegundos;
            final pct = (tempo / max).clamp(0.0, 1.0);
            Color timerColor() {
              if (pct > 0.5) return Colors.green;
              if (pct > 0.25) return Colors.orange;
              return Colors.red;
            }

            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${pergunta.categoria} · $respondente',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Icon(Icons.timer, color: timerColor(), size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${tempo}s',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: timerColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: LinearProgressIndicator(
                      value: pct,
                      color: timerColor(),
                      minHeight: 6,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          pergunta.pergunta,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        for (int i = 0; i < pergunta.alternativas.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: _alternativaSelecionada == i
                                  ? cor.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() => _alternativaSelecionada = i);
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _alternativaSelecionada == i
                                          ? cor
                                          : Colors.grey.shade400,
                                      width: _alternativaSelecionada == i
                                          ? 2.5
                                          : 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _alternativaSelecionada == i
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        color: _alternativaSelecionada == i
                                            ? cor
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${String.fromCharCode(65 + i)}. ${pergunta.alternativas[i]}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                _alternativaSelecionada == i
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: 'Confirmar resposta',
                            icon: Icons.check,
                            onPressed: _alternativaSelecionada != null
                                ? () => _confirmar(provider, ehAlvo)
                                : null,
                          ),
                        ),
                        if (!ehAlvo) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              text: 'Passar',
                              icon: Icons.swap_horiz,
                              backgroundColor: Colors.deepOrange,
                              onPressed: () {
                                setState(() => _alternativaSelecionada = null);
                                provider.passarPergunta();
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
