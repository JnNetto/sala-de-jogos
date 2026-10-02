import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/so_uma_estado_remoto.dart';
import '../../../data/models/so_uma_jogador_remoto.dart';
import '../../providers/so_uma_sala_provider.dart';
import '../../widgets/so_uma_abort_action.dart';

class SoUmaEscolhaNumeroRemotoScreen extends StatelessWidget {
  const SoUmaEscolhaNumeroRemotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nova Carta'),
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

                  return StreamBuilder<List<SoUmaJogadorRemoto>>(
                    stream: provider.observarJogadoresAtuais(),
                    initialData: provider.jogadores,
                    builder: (context, jogadoresSnapshot) {
                      final jogadores =
                          jogadoresSnapshot.data ?? provider.jogadores;
                      final adivinhador = _buscar(estado.guesserUid, jogadores);

                      if (provider.souAdivinhador) {
                        return _EscolhaNumero(
                          isLoading: provider.isLoading,
                          erro: provider.erro,
                          onEscolher: (numero) =>
                              _escolher(context, provider, numero),
                        );
                      }

                      return _AguardandoAdivinhador(
                        nome: adivinhador?.displayName ?? 'o adivinhador',
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

  Future<void> _escolher(
    BuildContext context,
    SoUmaSalaProvider provider,
    int numero,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.escolherNumeroRemoto(numero);
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

class _EscolhaNumero extends StatelessWidget {
  final bool isLoading;
  final String? erro;
  final ValueChanged<int> onEscolher;

  const _EscolhaNumero({
    required this.isLoading,
    required this.erro,
    required this.onEscolher,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(
            Icons.style,
            size: 96,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Escolha um número de 1 a 5.',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Você não sabe o que vai encontrar. É às cegas mesmo.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              for (var numero = 1; numero <= 5; numero++)
                _BotaoNumero(
                  numero: numero,
                  disabled: isLoading,
                  onTap: () => onEscolher(numero),
                ),
            ],
          ),
          if (erro != null) ...[
            const SizedBox(height: 16),
            Text(
              erro!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _BotaoNumero extends StatelessWidget {
  final int numero;
  final bool disabled;
  final VoidCallback onTap;

  const _BotaoNumero({
    required this.numero,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$numero',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _AguardandoAdivinhador extends StatelessWidget {
  final String nome;

  const _AguardandoAdivinhador({required this.nome});

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
              'Aguardando $nome escolher um número.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
