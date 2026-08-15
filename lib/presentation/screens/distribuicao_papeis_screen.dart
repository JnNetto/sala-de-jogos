import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/partida_provider.dart';
import '../widgets/primary_button.dart';
import 'exibicao_papel_screen.dart';
import 'inicio_discussao_screen.dart';

class DistribuicaoPapeisScreen extends StatefulWidget {
  const DistribuicaoPapeisScreen({super.key});

  @override
  State<DistribuicaoPapeisScreen> createState() =>
      _DistribuicaoPapeisScreenState();
}

class _DistribuicaoPapeisScreenState extends State<DistribuicaoPapeisScreen> {
  int _jogadorAtualIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PartidaProvider>().iniciarDistribuicaoPapeis();
    });
  }

  Future<void> _mostrarDialogoSairPartida(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sair da Partida?'),
          content: const Text(
            'Você tem certeza que deseja sair? A partida atual será cancelada e você voltará para as configurações.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<PartidaProvider>().encerrarPartida();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Distribuição de Papéis'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _mostrarDialogoSairPartida(context),
            tooltip: 'Voltar para configurações',
          ),
        ),
        body: Consumer<PartidaProvider>(
          builder: (context, provider, _) {
            final partida = provider.partida;
            if (partida == null) {
              return const Center(child: Text('Erro: partida não iniciada'));
            }

            final todosViram = _jogadorAtualIndex >= partida.jogadores.length;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _jogadorAtualIndex / partida.jogadores.length,
                      backgroundColor: Colors.grey[200],
                      minHeight: 8,
                    ),
                    const SizedBox(height: 16),
                    if (!todosViram)
                      Text(
                        'Jogador ${_jogadorAtualIndex + 1} de ${partida.jogadores.length}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    const Spacer(),
                    if (!todosViram) ...[
                      Icon(
                        Icons.person,
                        size: 100,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        partida.jogadores[_jogadorAtualIndex].nome,
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Toque no botão abaixo para ver seu papel',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      Icon(Icons.check_circle, size: 100, color: Colors.green),
                      const SizedBox(height: 32),
                      Text(
                        'Todos viram seus papéis!',
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: todosViram
                          ? PrimaryButton(
                              text: 'Iniciar Discussão',
                              icon: Icons.play_arrow,
                              onPressed: () {
                                provider.iniciarDiscussao();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const InicioDiscussaoScreen(),
                                  ),
                                );
                              },
                            )
                          : PrimaryButton(
                              text: 'Ver Meu Papel',
                              icon: Icons.visibility,
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExibicaoPapelScreen(
                                      jogador:
                                          partida.jogadores[_jogadorAtualIndex],
                                      palavraSecreta: partida.palavraSecreta,
                                      palavraRelacionada:
                                          partida.palavraRelacionada,
                                    ),
                                  ),
                                );
                                setState(() {
                                  _jogadorAtualIndex++;
                                });
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
