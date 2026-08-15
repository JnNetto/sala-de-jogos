import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pergunta_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'pergunta_coleta_respostas_screen.dart';
import 'pergunta_exibicao_screen.dart';

class PerguntaDistribuicaoScreen extends StatefulWidget {
  const PerguntaDistribuicaoScreen({super.key});

  @override
  State<PerguntaDistribuicaoScreen> createState() =>
      _PerguntaDistribuicaoScreenState();
}

class _PerguntaDistribuicaoScreenState
    extends State<PerguntaDistribuicaoScreen> {
  int _jogadorAtualIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PerguntaPartidaProvider>().iniciarDistribuicao();
    });
  }

  Future<void> _sairPartida() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da Partida?'),
        content: const Text('A partida atual será cancelada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<PerguntaPartidaProvider>().encerrarPartida();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Distribuição'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _sairPartida,
          ),
        ),
        body: Consumer<PerguntaPartidaProvider>(
          builder: (context, provider, _) {
            final partida = provider.partida;
            if (partida == null) {
              return const Center(child: Text('Erro: partida não iniciada'));
            }

            final todosViram = _jogadorAtualIndex >= partida.jogadores.length;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: _jogadorAtualIndex / partida.jogadores.length,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 16),
                    if (!todosViram)
                      Text(
                        'Jogador ${_jogadorAtualIndex + 1} de ${partida.jogadores.length}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    const Spacer(),
                    if (!todosViram) ...[
                      Center(
                        child: Icon(
                          Icons.person,
                          size: 100,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        partida.jogadores[_jogadorAtualIndex].nome,
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Toque para ver sua pergunta (só você deve olhar)',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      const Center(
                        child: Icon(
                          Icons.check_circle,
                          size: 100,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Todos viram suas perguntas!',
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: todosViram
                          ? PrimaryButton(
                              text: 'Responder',
                              icon: Icons.edit,
                              onPressed: () {
                                provider.iniciarColetaRespostas();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PerguntaColetaRespostasScreen(),
                                  ),
                                );
                              },
                            )
                          : PrimaryButton(
                              text: 'Ver Minha Pergunta',
                              icon: Icons.visibility,
                              onPressed: () async {
                                final jogador =
                                    partida.jogadores[_jogadorAtualIndex];
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PerguntaExibicaoScreen(
                                          jogador: jogador,
                                          pergunta: partida.perguntaPara(
                                            jogador,
                                          ),
                                        ),
                                  ),
                                );
                                setState(() => _jogadorAtualIndex++);
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
}
