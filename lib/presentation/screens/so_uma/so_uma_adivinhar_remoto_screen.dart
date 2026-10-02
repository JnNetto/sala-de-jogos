import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/so_uma_estado_remoto.dart';
import '../../../data/models/so_uma_jogador_remoto.dart';
import '../../providers/so_uma_sala_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/so_uma_abort_action.dart';

class SoUmaAdivinharRemotoScreen extends StatefulWidget {
  const SoUmaAdivinharRemotoScreen({super.key});

  @override
  State<SoUmaAdivinharRemotoScreen> createState() =>
      _SoUmaAdivinharRemotoScreenState();
}

class _SoUmaAdivinharRemotoScreenState
    extends State<SoUmaAdivinharRemotoScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Adivinhar'),
          automaticallyImplyLeading: false,
          actions: const [SoUmaAbortAction()],
        ),
        body: SafeArea(
          child: Consumer<SoUmaSalaProvider>(
            builder: (context, provider, _) {
              return StreamBuilder<SoUmaEstadoRemoto?>(
                stream: provider.observarEstadoAtual(),
                initialData: provider.estado,
                builder: (context, estadoSnapshot) {
                  final estado = estadoSnapshot.data;
                  if (estado == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!provider.souAdivinhador) {
                    return StreamBuilder<List<SoUmaJogadorRemoto>>(
                      stream: provider.observarJogadoresAtuais(),
                      initialData: provider.jogadores,
                      builder: (context, jogadoresSnapshot) {
                        final jogadores =
                            jogadoresSnapshot.data ?? provider.jogadores;
                        final adivinhador = _buscar(
                          estado.guesserUid,
                          jogadores,
                        );
                        return _Aguardando(
                          nome: adivinhador?.displayName ?? 'o adivinhador',
                        );
                      },
                    );
                  }

                  return _Formulario(
                    pistas: estado.pistasReveladas,
                    controller: _controller,
                    isLoading: provider.isLoading,
                    erro: provider.erro,
                    onAdivinhar: () => _adivinhar(context, provider),
                    onPassar: () => _passar(context, provider),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _adivinhar(
    BuildContext context,
    SoUmaSalaProvider provider,
  ) async {
    final palpite = _controller.text.trim();
    if (palpite.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.enviarPalpiteRemoto(palpite: palpite);
    if (!context.mounted) return;
    if (!ok && provider.erro != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _passar(BuildContext context, SoUmaSalaProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.enviarPalpiteRemoto(passar: true);
    if (!context.mounted) return;
    if (!ok && provider.erro != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
      );
    }
  }

  SoUmaJogadorRemoto? _buscar(String uid, List<SoUmaJogadorRemoto> jogadores) {
    for (final jogador in jogadores) {
      if (jogador.uid == uid) return jogador;
    }
    return null;
  }
}

class _Formulario extends StatelessWidget {
  final List<String> pistas;
  final TextEditingController controller;
  final bool isLoading;
  final String? erro;
  final VoidCallback onAdivinhar;
  final VoidCallback onPassar;

  const _Formulario({
    required this.pistas,
    required this.controller,
    required this.isLoading,
    required this.erro,
    required this.onAdivinhar,
    required this.onPassar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Essas são as pistas que sobraram:',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (pistas.isEmpty)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Todas as pistas foram anuladas. Melhor passar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [for (final pista in pistas) Chip(label: Text(pista))],
            ),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            autofocus: pistas.isNotEmpty,
            decoration: const InputDecoration(
              labelText: 'Sua resposta',
              prefixIcon: Icon(Icons.lightbulb_outline),
            ),
            onSubmitted: (_) => onAdivinhar(),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Adivinhar',
            icon: Icons.check,
            isLoading: isLoading,
            onPressed: onAdivinhar,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isLoading ? null : onPassar,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Passar'),
          ),
          if (erro != null) ...[
            const SizedBox(height: 16),
            Text(
              erro!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _Aguardando extends StatelessWidget {
  final String nome;

  const _Aguardando({required this.nome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '$nome está adivinhando.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
