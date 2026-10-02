import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/so_uma_estado_remoto.dart';
import '../../../data/models/so_uma_rodada_remota.dart';
import '../../providers/so_uma_sala_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/so_uma_abort_action.dart';

class SoUmaEscreverPistaRemotaScreen extends StatefulWidget {
  const SoUmaEscreverPistaRemotaScreen({super.key});

  @override
  State<SoUmaEscreverPistaRemotaScreen> createState() =>
      _SoUmaEscreverPistaRemotaScreenState();
}

class _SoUmaEscreverPistaRemotaScreenState
    extends State<SoUmaEscreverPistaRemotaScreen> {
  String? _roundId;
  bool _enviei = false;
  final _controller1 = TextEditingController();
  final _controller2 = TextEditingController();

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Escreva sua pista'),
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

                  final roundId = estado.currentRoundId;
                  if (roundId != null && roundId != _roundId) {
                    _roundId = roundId;
                    _enviei = false;
                  }

                  if (provider.souAdivinhador) {
                    return _Aguardando(estado: estado);
                  }

                  if (_enviei || roundId == null) {
                    return _Aguardando(estado: estado);
                  }

                  return StreamBuilder<SoUmaRodadaRemota?>(
                    stream: provider.observarRodadaPorId(roundId),
                    initialData: provider.rodada,
                    builder: (context, rodadaSnapshot) {
                      final rodada = rodadaSnapshot.data;
                      if (rodada == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return _FormularioPista(
                        rodada: rodada,
                        duasPistas: estado.playerCount == 3,
                        controller1: _controller1,
                        controller2: _controller2,
                        isLoading: provider.isLoading,
                        erro: provider.erro,
                        onEnviar: () => _enviar(context, provider, estado),
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

  Future<void> _enviar(
    BuildContext context,
    SoUmaSalaProvider provider,
    SoUmaEstadoRemoto estado,
  ) async {
    final texto1 = _controller1.text.trim();
    if (texto1.isEmpty) return;
    final duasPistas = estado.playerCount == 3;
    final texto2 = _controller2.text.trim();
    if (duasPistas && texto2.isEmpty) return;

    final palavras = duasPistas ? [texto1, texto2] : [texto1];
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.enviarPistasRemoto(palavras);
    if (!context.mounted) return;

    if (ok) {
      setState(() => _enviei = true);
    } else if (provider.erro != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
      );
    }
  }
}

class _FormularioPista extends StatelessWidget {
  final SoUmaRodadaRemota rodada;
  final bool duasPistas;
  final TextEditingController controller1;
  final TextEditingController controller2;
  final bool isLoading;
  final String? erro;
  final VoidCallback onEnviar;

  const _FormularioPista({
    required this.rodada,
    required this.duasPistas,
    required this.controller1,
    required this.controller2,
    required this.isLoading,
    required this.erro,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _CartaCompleta(
          palavras: rodada.palavras,
          indiceAlvo: rodada.mysteryIndex,
        ),
        const SizedBox(height: 24),
        Text(
          duasPistas
              ? 'Vocês são só 2 escritores: cada um escreve 2 pistas diferentes.'
              : 'Escreva uma única palavra que leve até a palavra em destaque.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller1,
          autofocus: true,
          decoration: InputDecoration(
            labelText: duasPistas ? 'Primeira pista' : 'Sua pista',
            prefixIcon: const Icon(Icons.edit),
          ),
        ),
        if (duasPistas) ...[
          const SizedBox(height: 12),
          TextField(
            controller: controller2,
            decoration: const InputDecoration(
              labelText: 'Segunda pista',
              prefixIcon: Icon(Icons.edit),
            ),
          ),
        ],
        const SizedBox(height: 16),
        PrimaryButton(
          text: 'Confirmar Pista',
          icon: Icons.check,
          isLoading: isLoading,
          onPressed: onEnviar,
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
    );
  }
}

class _CartaCompleta extends StatelessWidget {
  final List<String> palavras;
  final int indiceAlvo;

  const _CartaCompleta({required this.palavras, required this.indiceAlvo});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < palavras.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: i == indiceAlvo
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.14)
                        : null,
                    border: i == indiceAlvo
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: i == indiceAlvo
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.3),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          palavras[i],
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: i == indiceAlvo
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Aguardando extends StatelessWidget {
  final SoUmaEstadoRemoto estado;

  const _Aguardando({required this.estado});

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
              'Aguardando as pistas. ${estado.submittedCount}/${estado.expectedCount}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
