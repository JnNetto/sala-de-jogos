import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/time_formatter.dart';
import '../../providers/lobisomem_partida_provider.dart';
import '../../widgets/lobisomem_sair_partida.dart';
import '../../widgets/primary_button.dart';
import 'lobisomem_fluxo.dart';

class LobisomemDiscussaoScreen extends StatefulWidget {
  const LobisomemDiscussaoScreen({super.key});

  @override
  State<LobisomemDiscussaoScreen> createState() =>
      _LobisomemDiscussaoScreenState();
}

class _LobisomemDiscussaoScreenState extends State<LobisomemDiscussaoScreen> {
  bool _navegou = false;

  void _irParaVotacao(LobisomemPartidaProvider provider) {
    if (_navegou) return;
    _navegou = true;
    provider.encerrarDiscussao();
    irParaChamadaVotacao(context, provider);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: lobisomemAppBar(context: context, title: 'Discussão'),
        body: Consumer<LobisomemPartidaProvider>(
          builder: (context, provider, _) {
            final partida = provider.partida;
            if (partida == null) {
              return const Center(child: Text('Partida não iniciada'));
            }

            final temTimer =
                partida.configuracao.timerDiscussaoMinutos != null;
            final tempoRestante = partida.discussaoSegundosRestantes;

            if (temTimer && tempoRestante <= 0 && !_navegou) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_navegou) {
                  _irParaVotacao(provider);
                }
              });
            }

            final totalSegundos =
                (partida.configuracao.timerDiscussaoMinutos ?? 0) * 60;
            final percentual = !temTimer || totalSegundos == 0
                ? 1.0
                : tempoRestante / totalSegundos;
            final tempoPercentual = (percentual * 100).round();

            Color timerColor() {
              if (tempoPercentual > 50) return Colors.green;
              if (tempoPercentual > 25) return Colors.orange;
              return Colors.red;
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Os vivos discutem. Mortos assistem em silêncio.',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Vivos: ${partida.vivos.map((jogador) => jogador.nome).join(', ')}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    if (temTimer)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 280,
                            height: 280,
                            child: CircularProgressIndicator(
                              value: percentual,
                              strokeWidth: 20,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                timerColor(),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Icon(Icons.timer, size: 64, color: timerColor()),
                              const SizedBox(height: 16),
                              Text(
                                TimeFormatter.formatarSegundos(tempoRestante),
                                style: TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  color: timerColor(),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              if (partida.discussaoPausada)
                                Text(
                                  'Pausado',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                            ],
                          ),
                        ],
                      )
                    else
                      Icon(
                        Icons.forum,
                        size: 96,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    const Spacer(),
                    if (temTimer)
                      OutlinedButton.icon(
                        onPressed: partida.discussaoPausada
                            ? provider.retomarDiscussao
                            : provider.pausarDiscussao,
                        icon: Icon(
                          partida.discussaoPausada
                              ? Icons.play_arrow
                              : Icons.pause,
                        ),
                        label: Text(
                          partida.discussaoPausada ? 'Retomar' : 'Pausar',
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: 'Encerrar discussão',
                        icon: Icons.how_to_vote,
                        onPressed: () => _irParaVotacao(provider),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
