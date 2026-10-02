import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/aneis_estado_remoto.dart';
import '../../../data/models/aneis_sala.dart';
import '../../providers/aneis_sala_provider.dart';
import 'aneis_fim_remoto_screen.dart';
import 'aneis_lobby_remoto_screen.dart';
import 'aneis_mesa_remota_screen.dart';

class AneisSalaRouterScreen extends StatefulWidget {
  final bool restaurarUltimaSala;

  const AneisSalaRouterScreen({super.key, this.restaurarUltimaSala = false});

  @override
  State<AneisSalaRouterScreen> createState() => _AneisSalaRouterScreenState();
}

class _AneisSalaRouterScreenState extends State<AneisSalaRouterScreen> {
  late final Future<bool> _restauracaoFuture;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AneisSalaProvider>();
    _restauracaoFuture = widget.restaurarUltimaSala
        ? provider.restaurarUltimaSala()
        : Future.value(provider.sala != null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _restauracaoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final provider = context.watch<AneisSalaProvider>();
        if (provider.sala == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sala Online')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhuma sala online encontrada.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Voltar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return StreamBuilder<AneisSala?>(
          stream: provider.observarSalaAtual(),
          initialData: provider.sala,
          builder: (context, salaSnapshot) {
            final sala = salaSnapshot.data ?? provider.sala;
            if (sala == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (sala.status == 'lobby') {
              return const AneisLobbyRemotoScreen();
            }

            return StreamBuilder<AneisEstadoRemoto?>(
              stream: provider.observarEstadoAtual(),
              initialData: provider.estado,
              builder: (context, estadoSnapshot) {
                final estado = estadoSnapshot.data ?? provider.estado;
                if (estado == null) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (estado.terminou || sala.status == 'finished') {
                  return const AneisFimRemotoScreen();
                }

                return const AneisMesaRemotaScreen();
              },
            );
          },
        );
      },
    );
  }
}
