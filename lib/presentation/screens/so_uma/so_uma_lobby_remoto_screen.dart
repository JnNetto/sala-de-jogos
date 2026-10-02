import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/so_uma_constants.dart';
import '../../../data/models/so_uma_jogador_remoto.dart';
import '../../../data/models/so_uma_sala.dart';
import '../../providers/so_uma_sala_provider.dart';
import '../../widgets/primary_button.dart';
import 'so_uma_sala_router_screen.dart';

class SoUmaLobbyRemotoScreen extends StatefulWidget {
  const SoUmaLobbyRemotoScreen({super.key});

  @override
  State<SoUmaLobbyRemotoScreen> createState() => _SoUmaLobbyRemotoScreenState();
}

class _SoUmaLobbyRemotoScreenState extends State<SoUmaLobbyRemotoScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lobby Online'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _sairDaSala(context),
          ),
        ),
        body: SafeArea(
          child: Consumer<SoUmaSalaProvider>(
            builder: (context, provider, _) {
              final sala = provider.sala;
              if (sala == null) {
                return const Center(child: Text('Sala não carregada'));
              }

              return StreamBuilder<SoUmaSala?>(
                stream: provider.observarSalaAtual(),
                initialData: sala,
                builder: (context, salaSnapshot) {
                  final salaAtual = salaSnapshot.data ?? sala;
                  _navegarSePartidaIniciou(context, salaAtual);

                  return StreamBuilder<List<SoUmaJogadorRemoto>>(
                    stream: provider.observarJogadoresAtuais(),
                    initialData: provider.jogadores,
                    builder: (context, jogadoresSnapshot) {
                      final jogadores = jogadoresSnapshot.data ?? const [];
                      _navegarSeFuiRemovido(
                        context,
                        provider,
                        jogadores,
                        jogadoresSnapshot.hasData,
                      );

                      return ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Icon(
                            Icons.groups,
                            size: 84,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            salaAtual.codigo,
                            style: Theme.of(context).textTheme.displayLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.souHost
                                ? 'Compartilhe este código com os jogadores.'
                                : 'Aguarde o host iniciar a partida.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          _JogadoresCard(
                            jogadores: jogadores,
                            hostUid: salaAtual.hostUid,
                            meuUid: provider.uid,
                            souHost: provider.souHost,
                            onRemover: (uid) =>
                                _removerJogador(context, provider, uid),
                          ),
                          const SizedBox(height: 24),
                          if (provider.souHost)
                            PrimaryButton(
                              text: 'Iniciar Partida Online',
                              icon: Icons.play_arrow,
                              isLoading: provider.isLoading,
                              onPressed: provider.podeIniciar
                                  ? () => _iniciar(context, provider)
                                  : null,
                            )
                          else
                            const _AguardandoHost(),
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

  Future<void> _iniciar(
    BuildContext context,
    SoUmaSalaProvider provider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.iniciarPartidaRemota();
    if (!context.mounted) return;

    if (!ok && provider.erro != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _sairDaSala(BuildContext context) async {
    final provider = context.read<SoUmaSalaProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.sairDaSalaRemota();
    if (!context.mounted) return;
    if (ok) {
      navigator.popUntil((route) => route.isFirst);
    } else if (provider.erro != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _removerJogador(
    BuildContext context,
    SoUmaSalaProvider provider,
    String uid,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.removerJogadorRemoto(uid);
    if (!context.mounted) return;
    if (!ok && provider.erro != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
      );
    }
  }

  void _navegarSeFuiRemovido(
    BuildContext context,
    SoUmaSalaProvider provider,
    List<SoUmaJogadorRemoto> jogadores,
    bool listaCarregada,
  ) {
    final uid = provider.uid;
    if (!listaCarregada || uid == null) return;
    if (!provider.podeDetectarRemocao) return;
    if (jogadores.isEmpty) return;
    if (jogadores.any((jogador) => jogador.uid == uid)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      await provider.esquecerUltimaSala();
      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  bool _navegouParaPartida = false;

  void _navegarSePartidaIniciou(BuildContext context, SoUmaSala sala) {
    if (_navegouParaPartida || sala.status != 'playing') return;
    _navegouParaPartida = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SoUmaSalaRouterScreen()),
      );
    });
  }
}

class _JogadoresCard extends StatelessWidget {
  final List<SoUmaJogadorRemoto> jogadores;
  final String hostUid;
  final String? meuUid;
  final bool souHost;
  final ValueChanged<String> onRemover;

  const _JogadoresCard({
    required this.jogadores,
    required this.hostUid,
    required this.meuUid,
    required this.souHost,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jogadores',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('${jogadores.length}/${SoUmaConstants.maxJogadores}'),
              ],
            ),
            const SizedBox(height: 12),
            if (jogadores.isEmpty)
              const Text('Nenhum jogador conectado ainda.')
            else
              for (final jogador in jogadores)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(
                      jogador.seat != null ? '${jogador.seat! + 1}' : '?',
                    ),
                  ),
                  title: Text(jogador.displayName),
                  subtitle: jogador.uid == meuUid ? const Text('Você') : null,
                  trailing: jogador.uid == hostUid
                      ? const Chip(label: Text('Host'))
                      : souHost
                      ? IconButton(
                          tooltip: 'Remover jogador',
                          icon: const Icon(Icons.person_remove),
                          onPressed: () => onRemover(jogador.uid),
                        )
                      : null,
                ),
            if (jogadores.length < SoUmaConstants.minJogadores) ...[
              const SizedBox(height: 8),
              Text(
                'Mínimo de ${SoUmaConstants.minJogadores} jogadores para iniciar.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AguardandoHost extends StatelessWidget {
  const _AguardandoHost();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Aguardando o host iniciar.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
