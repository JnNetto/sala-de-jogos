import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/so_uma_estado_remoto.dart';
import '../../../data/models/so_uma_sala.dart';
import '../../providers/so_uma_sala_provider.dart';
import 'so_uma_adivinhar_remoto_screen.dart';
import 'so_uma_comparar_pistas_remoto_screen.dart';
import 'so_uma_escolha_numero_remoto_screen.dart';
import 'so_uma_escrever_pista_remota_screen.dart';
import 'so_uma_fim_remoto_screen.dart';
import 'so_uma_lobby_remoto_screen.dart';
import 'so_uma_resultado_rodada_remoto_screen.dart';

class SoUmaSalaRouterScreen extends StatefulWidget {
  final bool restaurarUltimaSala;

  const SoUmaSalaRouterScreen({super.key, this.restaurarUltimaSala = false});

  @override
  State<SoUmaSalaRouterScreen> createState() => _SoUmaSalaRouterScreenState();
}

class _SoUmaSalaRouterScreenState extends State<SoUmaSalaRouterScreen> {
  late final Future<bool> _restauracaoFuture;
  final Map<String, bool> _resultadoRodadaCache = {};

  @override
  void initState() {
    super.initState();
    final provider = context.read<SoUmaSalaProvider>();
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

        final provider = context.watch<SoUmaSalaProvider>();
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

        return StreamBuilder<SoUmaSala?>(
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
              _resultadoRodadaCache.clear();
              provider.resetarMarcadoresResultadoRodada();
              return const SoUmaLobbyRemotoScreen();
            }

            return StreamBuilder<SoUmaEstadoRemoto?>(
              stream: provider.observarEstadoAtual(),
              initialData: provider.estado,
              builder: (context, estadoSnapshot) {
                final estado = estadoSnapshot.data ?? provider.estado;
                if (estado == null) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                return _telaComResultadosPendentes(provider, sala.id, estado);
              },
            );
          },
        );
      },
    );
  }

  Widget _telaComResultadosPendentes(
    SoUmaSalaProvider provider,
    String roomId,
    SoUmaEstadoRemoto estado,
  ) {
    final quantidade = estado.historico.length;
    if (quantidade == 0) {
      _resultadoRodadaCache.clear();
      provider.resetarMarcadoresResultadoRodada();
      return _telaDaFase(estado.phase);
    }

    final chave = _chaveResultado(estado.gameId, quantidade);
    final visto = _resultadoRodadaCache[chave];
    if (visto == null) {
      _carregarResultadoRodadaVisto(
        provider,
        roomId,
        estado.gameId,
        quantidade,
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!visto) {
      return const SoUmaResultadoRodadaRemotoScreen();
    }

    return _telaDaFase(estado.phase);
  }

  String _chaveResultado(String gameId, int quantidade) =>
      '$gameId:$quantidade';

  Future<void> _carregarResultadoRodadaVisto(
    SoUmaSalaProvider provider,
    String roomId,
    String gameId,
    int quantidade,
  ) async {
    final chave = _chaveResultado(gameId, quantidade);
    if (_resultadoRodadaCache.containsKey(chave)) return;
    final visto = await provider.resultadoRodadaVisto(
      roomId: roomId,
      gameId: gameId,
      quantidadeHistorico: quantidade,
    );
    if (!mounted) return;
    setState(() => _resultadoRodadaCache[chave] = visto);
  }

  Widget _telaDaFase(String phase) {
    switch (phase) {
      case 'drawing':
        return const SoUmaEscolhaNumeroRemotoScreen();
      case 'writing':
        return const SoUmaEscreverPistaRemotaScreen();
      case 'comparing':
        return const SoUmaCompararPistasRemotoScreen();
      case 'guessing':
        return const SoUmaAdivinharRemotoScreen();
      case 'over':
        return const SoUmaFimRemotoScreen();
      default:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
