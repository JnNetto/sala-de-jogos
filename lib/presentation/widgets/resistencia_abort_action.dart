import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/resistencia_sala_provider.dart';
import '../screens/resistencia/resistencia_sala_router_screen.dart';

class ResistenciaAbortAction extends StatelessWidget {
  const ResistenciaAbortAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ResistenciaSalaProvider>(
      builder: (context, provider, _) {
        if (!provider.souHost || provider.sala?.status != 'playing') {
          return const SizedBox.shrink();
        }

        return IconButton(
          tooltip: 'Abortar partida',
          icon: const Icon(Icons.stop_circle_outlined),
          onPressed: provider.isLoading
              ? null
              : () => _confirmarAbortar(context, provider),
        );
      },
    );
  }

  Future<void> _confirmarAbortar(
    BuildContext context,
    ResistenciaSalaProvider provider,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abortar partida?'),
        content: const Text(
          'A partida atual será encerrada e a sala voltará ao lobby.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Abortar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.abortarPartidaRemota();
    if (!context.mounted) return;

    if (ok) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const ResistenciaSalaRouterScreen()),
      );
    } else if (provider.erro != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
      );
    }
  }
}
