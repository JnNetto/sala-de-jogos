import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/so_uma_estado_remoto.dart';
import '../../../data/models/so_uma_pista_remota.dart';
import '../../../data/models/so_uma_rodada_remota.dart';
import '../../providers/so_uma_sala_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/so_uma_abort_action.dart';

class SoUmaCompararPistasRemotoScreen extends StatelessWidget {
  const SoUmaCompararPistasRemotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comparar e Anular'),
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

                  if (provider.souAdivinhador) {
                    return const _Aguardando();
                  }

                  final roundId = estado.currentRoundId;
                  if (roundId == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return StreamBuilder<SoUmaRodadaRemota?>(
                    stream: provider.observarRodadaPorId(roundId),
                    initialData: provider.rodada,
                    builder: (context, rodadaSnapshot) {
                      final rodada = rodadaSnapshot.data;
                      if (rodada == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            'Toquem para anular pistas repetidas, da mesma '
                            'família ou inválidas. As marcadas em vermelho já '
                            'foram anuladas automaticamente, mas vocês podem '
                            'corrigir.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          for (final pista in rodada.clues)
                            _PistaTile(
                              pista: pista,
                              onToggle: () => provider
                                  .alternarAnulacaoPistaRemota(pista.clueId),
                            ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            text: 'Pronto, ele pode adivinhar',
                            icon: Icons.arrow_forward,
                            isLoading: provider.isLoading,
                            onPressed: () => _finalizar(context, provider),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _finalizar(
    BuildContext context,
    SoUmaSalaProvider provider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.finalizarComparacaoRemota();
    if (!context.mounted) return;
    if (!ok && provider.erro != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
      );
    }
  }
}

class _PistaTile extends StatelessWidget {
  final SoUmaPistaRemota pista;
  final VoidCallback onToggle;

  const _PistaTile({required this.pista, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cor = pista.anulada ? Colors.red : Colors.green;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onToggle,
        leading: Icon(
          pista.anulada ? Icons.block : Icons.check_circle_outline,
          color: cor,
        ),
        title: Text(
          pista.texto,
          style: TextStyle(
            decoration: pista.anulada ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: pista.motivoAutoAnulacao != null
            ? Text(_descricaoMotivo(pista.motivoAutoAnulacao!))
            : null,
        trailing: Switch(value: !pista.anulada, onChanged: (_) => onToggle()),
      ),
    );
  }

  String _descricaoMotivo(String motivo) {
    switch (motivo) {
      case 'identica':
        return 'Idêntica a outra pista';
      case 'plural':
        return 'Mesma palavra, no plural';
      case 'genero':
        return 'Mesma palavra, outro gênero';
      case 'raiz':
        return 'Possível mesma raiz de outra pista';
      case 'palavra_alvo':
        return 'É a própria palavra-alvo';
      case 'palavra_alvo_raiz':
        return 'Possível mesma raiz da palavra-alvo';
      default:
        return 'Anulada automaticamente';
    }
  }
}

class _Aguardando extends StatelessWidget {
  const _Aguardando();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Os escritores estão comparando as pistas.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
