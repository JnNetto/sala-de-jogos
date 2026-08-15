import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/time_formatter.dart';
import '../providers/partida_provider.dart';
import '../widgets/primary_button.dart';
import 'configuracao_screen.dart';
import 'votacao_screen.dart';

class DiscussaoScreen extends StatefulWidget {
  const DiscussaoScreen({super.key});

  @override
  State<DiscussaoScreen> createState() => _DiscussaoScreenState();
}

class _DiscussaoScreenState extends State<DiscussaoScreen> {
  bool _navegouParaVotacao = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Discussão'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () => _mostrarMenuPausa(context),
            ),
          ],
        ),
        body: Consumer<PartidaProvider>(
          builder: (context, provider, _) {
            final partida = provider.partida;
            if (partida == null) {
              return const Center(child: Text('Erro: partida não encontrada'));
            }

            final tempoRestante = partida.tempoRestanteSegundos;

            if (tempoRestante <= 0 && !_navegouParaVotacao) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_navegouParaVotacao) {
                  _navegouParaVotacao = true;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VotacaoScreen(),
                    ),
                  );
                }
              });
            }
            final percentualRestante =
                tempoRestante / partida.configuracao.duracaoDiscussaoSegundos;
            final tempoPercentual = (percentualRestante * 100).round();

            Color getTimerColor() {
              if (tempoPercentual > 50) return Colors.green;
              if (tempoPercentual > 25) return Colors.orange;
              return Colors.red;
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      'Discutam e descubram quem é o espião',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (partida.jogadorInicial != null)
                      Text(
                        'Começa: ${partida.jogadorInicial!.nome}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const Spacer(),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 320,
                          height: 320,
                          child: CircularProgressIndicator(
                            value: percentualRestante,
                            strokeWidth: 24,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              getTimerColor(),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Icon(Icons.timer, size: 80, color: getTimerColor()),
                            const SizedBox(height: 24),
                            Text(
                              TimeFormatter.formatarSegundos(tempoRestante),
                              style: TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: getTimerColor(),
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: 'Pular para Votação',
                        icon: Icons.how_to_vote,
                        onPressed: () {
                          _confirmarPular(context, provider);
                        },
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

  void _confirmarPular(BuildContext context, PartidaProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pular Discussão'),
        content: const Text(
          'Tem certeza que deseja pular o tempo de discussão e ir direto para a votação?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.pularDiscussao();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const VotacaoScreen()),
              );
            },
            child: const Text('Pular'),
          ),
        ],
      ),
    );
  }

  void _mostrarMenuPausa(BuildContext context) {
    final provider = context.read<PartidaProvider>();
    provider.pausarDiscussao();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.pause_circle),
            const SizedBox(width: 12),
            const Text('Jogo Pausado'),
          ],
        ),
        content: const Text('O timer foi pausado. O que deseja fazer?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.retomarDiscussao();
            },
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.encerrarPartida();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const ConfiguracaoScreen(),
                ),
                (route) => route.isFirst,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
