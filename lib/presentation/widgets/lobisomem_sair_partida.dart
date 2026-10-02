import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/lobisomem_partida_provider.dart';

Future<void> confirmarSaidaLobisomem(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Sair da partida?'),
        content: const Text('A partida atual de Lobisomem será cancelada.'),
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
    context.read<LobisomemPartidaProvider>().limparPartida();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

PreferredSizeWidget lobisomemAppBar({
  required BuildContext context,
  required String title,
}) {
  return AppBar(
    title: Text(title),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => confirmarSaidaLobisomem(context),
      tooltip: 'Cancelar partida',
    ),
  );
}
