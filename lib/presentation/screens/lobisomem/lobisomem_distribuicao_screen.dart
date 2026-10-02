import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/enums/lobisomem_papel.dart';
import '../../providers/lobisomem_partida_provider.dart';
import '../../widgets/lobisomem_sair_partida.dart';
import '../../widgets/primary_button.dart';
import 'lobisomem_fluxo.dart';
import 'lobisomem_revelacao_papel_screen.dart';

class LobisomemDistribuicaoScreen extends StatefulWidget {
  const LobisomemDistribuicaoScreen({super.key});

  @override
  State<LobisomemDistribuicaoScreen> createState() =>
      _LobisomemDistribuicaoScreenState();
}

class _LobisomemDistribuicaoScreenState
    extends State<LobisomemDistribuicaoScreen> {
  int _jogadorAtualIndex = 0;
  bool _viuListaEspeciais = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: lobisomemAppBar(
          context: context,
          title: 'Revelação de Papéis',
        ),
        body: Consumer<LobisomemPartidaProvider>(
          builder: (context, provider, _) {
            final partida = provider.partida;
            if (partida == null) {
              return const Center(child: Text('Partida não iniciada'));
            }

            final jogadores = partida.jogadores;
            final especiais = partida.configuracao.papeisEspeciaisAtivos;
            final precisaLista =
                partida.configuracao.papeisEspeciaisAleatorios &&
                !_viuListaEspeciais;
            final todosViram = _jogadorAtualIndex >= jogadores.length;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: precisaLista
                          ? 0
                          : jogadores.isEmpty
                          ? 0
                          : _jogadorAtualIndex / jogadores.length,
                      backgroundColor: Colors.grey[200],
                      minHeight: 8,
                    ),
                    const SizedBox(height: 16),
                    if (precisaLista) ...[
                      Expanded(child: _ListaEspeciaisPublica(especiais: especiais)),
                      PrimaryButton(
                        text: 'Começar revelação individual',
                        icon: Icons.visibility,
                        onPressed: () =>
                            setState(() => _viuListaEspeciais = true),
                      ),
                    ] else ...[
                      if (!todosViram)
                        Text(
                          'Jogador ${_jogadorAtualIndex + 1} de ${jogadores.length}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      if (partida.configuracao.papeisEspeciaisAleatorios &&
                          especiais.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Especiais na mesa: ${especiais.map((p) => p.nome).join(', ')}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const Spacer(),
                      if (!todosViram) ...[
                        Icon(
                          Icons.person,
                          size: 100,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          jogadores[_jogadorAtualIndex].nome,
                          style: Theme.of(context).textTheme.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Passe o celular para esta pessoa. Ela deve segurar para revelar.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        const Icon(
                          Icons.check_circle,
                          size: 100,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Todos viram seus papéis',
                          style: Theme.of(context).textTheme.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Passe o celular para ${partida.narrador.nome} ler a abertura da noite.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: todosViram
                            ? PrimaryButton(
                                text: 'Começar a Noite',
                                icon: Icons.nightlight_round,
                                onPressed: () {
                                  provider.iniciarPrimeiraNoite();
                                  irParaAberturaNoite(context, provider);
                                },
                              )
                            : PrimaryButton(
                                text: 'Revelar Papel',
                                icon: Icons.visibility,
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          LobisomemRevelacaoPapelScreen(
                                            jogador:
                                                jogadores[_jogadorAtualIndex],
                                            jogadores: jogadores,
                                          ),
                                    ),
                                  );
                                  if (!mounted) return;
                                  setState(() => _jogadorAtualIndex++);
                                },
                              ),
                      ),
                    ],
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

class _ListaEspeciaisPublica extends StatelessWidget {
  final List<LobisomemPapel> especiais;

  const _ListaEspeciaisPublica({required this.especiais});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 24),
        Icon(
          Icons.style,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Papéis especiais desta partida',
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Todos podem ver esta lista. Ninguém sabe quem tem cada papel.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (especiais.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Nenhum papel especial foi sorteado. Só há Lobisomens e Aldeões.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          for (final papel in especiais)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.star_outline),
                title: Text(papel.nome),
                subtitle: Text(papel.descricao),
              ),
            ),
      ],
    );
  }
}
