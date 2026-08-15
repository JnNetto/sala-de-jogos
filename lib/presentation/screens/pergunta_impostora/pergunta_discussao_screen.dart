import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/time_formatter.dart';
import '../../providers/pergunta_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'pergunta_configuracao_screen.dart';
import 'pergunta_votacao_screen.dart';

class PerguntaDiscussaoScreen extends StatefulWidget {
  const PerguntaDiscussaoScreen({super.key});

  @override
  State<PerguntaDiscussaoScreen> createState() =>
      _PerguntaDiscussaoScreenState();
}

class _PerguntaDiscussaoScreenState extends State<PerguntaDiscussaoScreen> {
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
        body: Consumer<PerguntaPartidaProvider>(
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
                      builder: (context) => const PerguntaVotacaoScreen(),
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

            final cor = Theme.of(context).colorScheme.primary;

            return SafeArea(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: cor.withValues(alpha: 0.1),
                    child: Column(
                      children: [
                        Text(
                          'A pergunta era:',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          partida.par.principal,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cor,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Icon(Icons.timer, color: getTimerColor(), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          TimeFormatter.formatarSegundos(tempoRestante),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: getTimerColor(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentualRestante.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              color: getTimerColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Respostas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: partida.jogadores.length,
                      itemBuilder: (context, index) {
                        final jogador = partida.jogadores[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${jogador.id}')),
                            title: Text(
                              jogador.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              jogador.resposta ?? '—',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: 'Pular para Votação',
                        icon: Icons.how_to_vote,
                        onPressed: () => _confirmarPular(context, provider),
                      ),
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

  void _confirmarPular(BuildContext context, PerguntaPartidaProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pular Discussão'),
        content: const Text('Ir direto para a votação?'),
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
                MaterialPageRoute(
                  builder: (context) => const PerguntaVotacaoScreen(),
                ),
              );
            },
            child: const Text('Pular'),
          ),
        ],
      ),
    );
  }

  void _mostrarMenuPausa(BuildContext context) {
    final provider = context.read<PerguntaPartidaProvider>();
    provider.pausarDiscussao();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Jogo Pausado'),
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
                  builder: (context) => const PerguntaConfiguracaoScreen(),
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
