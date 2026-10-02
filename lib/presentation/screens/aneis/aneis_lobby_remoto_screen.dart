import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/aneis_constants.dart';
import '../../../data/models/aneis_jogador_remoto.dart';
import '../../../data/models/aneis_sala.dart';
import '../../providers/aneis_sala_provider.dart';
import '../../widgets/primary_button.dart';
import 'aneis_sala_router_screen.dart';

class AneisLobbyRemotoScreen extends StatefulWidget {
  const AneisLobbyRemotoScreen({super.key});

  @override
  State<AneisLobbyRemotoScreen> createState() => _AneisLobbyRemotoScreenState();
}

class _AneisLobbyRemotoScreenState extends State<AneisLobbyRemotoScreen> {
  bool _navegouParaPartida = false;

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
          child: Consumer<AneisSalaProvider>(
            builder: (context, provider, _) {
              final sala = provider.sala;
              if (sala == null) {
                return const Center(child: Text('Sala não carregada'));
              }

              return StreamBuilder<AneisSala?>(
                stream: provider.observarSalaAtual(),
                initialData: sala,
                builder: (context, salaSnapshot) {
                  final salaAtual = salaSnapshot.data ?? sala;
                  _navegarSePartidaIniciou(context, salaAtual);

                  return StreamBuilder<List<AneisJogadorRemoto>>(
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
                            Icons.filter_tilt_shift,
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
                          _ComoJogarCard(knowerMode: provider.knowerMode),
                          const SizedBox(height: 16),
                          _JogadoresCard(
                            jogadores: jogadores,
                            hostUid: salaAtual.hostUid,
                            meuUid: provider.uid,
                            souHost: provider.souHost,
                            onRemover: (uid) =>
                                _removerJogador(context, provider, uid),
                          ),
                          if (provider.souHost) ...[
                            const SizedBox(height: 16),
                            _KnowerModeCard(
                              valor: provider.knowerMode,
                              knowerUid: provider.knowerUidEscolhido,
                              jogadores: jogadores,
                              onChanged: provider.definirKnowerMode,
                              onKnowerUid: provider.definirKnowerUid,
                            ),
                            const SizedBox(height: 16),
                            _DificuldadeCard(
                              valor: provider.dificuldade,
                              onChanged: provider.definirDificuldade,
                            ),
                          ],
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
    AneisSalaProvider provider,
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
    final provider = context.read<AneisSalaProvider>();
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
    AneisSalaProvider provider,
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
    AneisSalaProvider provider,
    List<AneisJogadorRemoto> jogadores,
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

  void _navegarSePartidaIniciou(BuildContext context, AneisSala sala) {
    if (_navegouParaPartida || sala.status != 'playing') return;
    _navegouParaPartida = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AneisSalaRouterScreen()),
      );
    });
  }
}

class _ComoJogarCard extends StatelessWidget {
  final String knowerMode;

  const _ComoJogarCard({required this.knowerMode});

  @override
  Widget build(BuildContext context) {
    final knowerHumano = knowerMode != AneisConstants.knowerApp;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Como jogar', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              knowerHumano
                  ? 'Uma pessoa é sorteada como Knower: vê as regras, recebe cartas aleatórias, coloca 3 pistas e decide onde cada palavra dos outros vai. Os Finders tentam esvaziar a mão acertando a região.'
                  : 'O próprio jogo é o Knower: ninguém vê as regras. Encaixe uma carta da mão na região certa. Acerte e jogue de novo; erre e a carta vai sozinha para o lugar certo.',
            ),
          ],
        ),
      ),
    );
  }
}

class _KnowerModeCard extends StatelessWidget {
  final String valor;
  final String? knowerUid;
  final List<AneisJogadorRemoto> jogadores;
  final ValueChanged<String> onChanged;
  final ValueChanged<String?> onKnowerUid;

  const _KnowerModeCard({
    required this.valor,
    required this.knowerUid,
    required this.jogadores,
    required this.onChanged,
    required this.onKnowerUid,
  });

  @override
  Widget build(BuildContext context) {
    final uidsValidos = jogadores.map((jogador) => jogador.uid).toSet();
    final selecionado =
        knowerUid != null && uidsValidos.contains(knowerUid) ? knowerUid : null;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quem é o Knower',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: AneisConstants.knowerJogador,
                  label: Text('Jogador'),
                ),
                ButtonSegment(
                  value: AneisConstants.knowerApp,
                  label: Text('O jogo'),
                ),
              ],
              selected: {valor},
              onSelectionChanged: (selecao) => onChanged(selecao.first),
            ),
            if (valor == AneisConstants.knowerJogador) ...[
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Pessoa',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: selecionado,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Aleatório'),
                      ),
                      for (final jogador in jogadores)
                        DropdownMenuItem<String?>(
                          value: jogador.uid,
                          child: Text(jogador.displayName),
                        ),
                    ],
                    onChanged: onKnowerUid,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              AneisConstants.descricaoKnowerMode(valor),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}

class _DificuldadeCard extends StatelessWidget {
  final String valor;
  final ValueChanged<String> onChanged;

  const _DificuldadeCard({required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dificuldade', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                for (final item in AneisConstants.dificuldades)
                  ButtonSegment(
                    value: item,
                    label: Text(AneisConstants.rotuloDificuldade(item)),
                  ),
              ],
              selected: {valor},
              onSelectionChanged: (selecao) => onChanged(selecao.first),
            ),
          ],
        ),
      ),
    );
  }
}

class _JogadoresCard extends StatelessWidget {
  final List<AneisJogadorRemoto> jogadores;
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
                Text('${jogadores.length}/${AneisConstants.maxJogadores}'),
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
            if (jogadores.length < AneisConstants.minJogadores) ...[
              const SizedBox(height: 8),
              Text(
                'Mínimo de ${AneisConstants.minJogadores} jogadores para iniciar.',
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
