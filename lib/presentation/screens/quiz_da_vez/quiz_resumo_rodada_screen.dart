import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/enums/estado_partida_quiz.dart';
import '../../providers/quiz_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'quiz_passagem_screen.dart';
import 'quiz_resultado_screen.dart';

class QuizResumoRodadaScreen extends StatefulWidget {
  const QuizResumoRodadaScreen({super.key});

  @override
  State<QuizResumoRodadaScreen> createState() => _QuizResumoRodadaScreenState();
}

class _QuizResumoRodadaScreenState extends State<QuizResumoRodadaScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _shakeController;
  late Animation<double> _iconScale;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _iconScale = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shake =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resultado = context
          .read<QuizPartidaProvider>()
          .partida
          ?.ultimoResultado;
      if (resultado?.acertou == true) {
        HapticFeedback.mediumImpact();
        _iconController.forward();
      } else {
        HapticFeedback.heavyImpact();
        _shakeController.forward();
        _iconController.forward();
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Consumer<QuizPartidaProvider>(
        builder: (context, provider, _) {
          final partida = provider.partida;
          final resultado = partida?.ultimoResultado;
          if (partida == null || resultado == null) {
            return const Scaffold(body: Center(child: Text('Erro')));
          }

          final acertou = resultado.acertou;
          final cor = acertou
              ? const Color(0xFF2ECC71)
              : const Color(0xFFE74C3C);
          final mostrarPlacar = partida.configuracao.mostrarPlacarAposRodada;

          return Scaffold(
            backgroundColor: cor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: Listenable.merge([_iconScale, _shake]),
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(acertou ? 0 : _shake.value, 0),
                          child: Transform.scale(
                            scale: _iconScale.value,
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        acertou
                            ? Icons.celebration
                            : Icons.sentiment_dissatisfied,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      acertou ? 'Acertou!' : 'Errou!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      resultado.mensagem,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resposta correta',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            resultado.respostaCorreta,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cor,
                            ),
                          ),
                          if (resultado.explicacao != null) ...[
                            const SizedBox(height: 12),
                            Text(resultado.explicacao!),
                          ],
                          if (resultado.mudancas.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            ...resultado.mudancas.map(
                              (m) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${m.nome}: ${m.delta > 0 ? '+' : ''}${m.delta}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: m.delta >= 0
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (mostrarPlacar) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Placar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            children: partida.ranking.map((j) {
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    '${j.id}',
                                    style: TextStyle(color: cor),
                                  ),
                                ),
                                title: Text(
                                  j.nome,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                trailing: Text(
                                  '${j.pontos} pts',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      text: 'Continuar',
                      icon: Icons.arrow_forward,
                      backgroundColor: Colors.white,
                      textColor: cor,
                      onPressed: () {
                        provider.avancarAposResumo();
                        final depois = provider.partida;
                        if (depois?.estado == EstadoPartidaQuiz.resultado) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QuizResultadoScreen(),
                            ),
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QuizPassagemScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
