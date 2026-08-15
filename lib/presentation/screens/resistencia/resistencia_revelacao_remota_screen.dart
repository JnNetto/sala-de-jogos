import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/resistencia_jogador_remoto.dart';
import '../../../data/models/resistencia_privado.dart';
import '../../providers/resistencia_sala_provider.dart';
import '../../widgets/resistencia_abort_action.dart';
import 'resistencia_sala_router_screen.dart';

class ResistenciaRevelacaoRemotaScreen extends StatelessWidget {
  final String gameId;

  const ResistenciaRevelacaoRemotaScreen({super.key, this.gameId = ''});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Seu Papel'),
          automaticallyImplyLeading: false,
          actions: const [ResistenciaAbortAction()],
        ),
        body: SafeArea(
          child: Consumer<ResistenciaSalaProvider>(
            builder: (context, provider, _) {
              final sala = provider.sala;
              if (sala == null) {
                return const Center(child: Text('Sala não carregada'));
              }

              return StreamBuilder<List<ResistenciaJogadorRemoto>>(
                stream: provider.observarJogadoresAtuais(),
                initialData: provider.jogadores,
                builder: (context, jogadoresSnapshot) {
                  final jogadores =
                      jogadoresSnapshot.data ?? provider.jogadores;

                  return StreamBuilder<ResistenciaPrivado?>(
                    stream: provider.observarMeuPrivadoAtual(),
                    initialData: provider.privado,
                    builder: (context, privadoSnapshot) {
                      final privado = privadoSnapshot.data;
                      if (privado == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final meuJogador = _meuJogador(provider.uid, jogadores);
                      return _RevelacaoRemotaConteudo(
                        displayName: meuJogador?.displayName ?? 'Jogador',
                        privado: privado,
                        jogadores: jogadores,
                        gameId: gameId,
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

  ResistenciaJogadorRemoto? _meuJogador(
    String? uid,
    List<ResistenciaJogadorRemoto> jogadores,
  ) {
    if (uid == null) return null;
    for (final jogador in jogadores) {
      if (jogador.uid == uid) return jogador;
    }
    return null;
  }
}

class _RevelacaoRemotaConteudo extends StatefulWidget {
  final String displayName;
  final ResistenciaPrivado privado;
  final List<ResistenciaJogadorRemoto> jogadores;
  final String gameId;

  const _RevelacaoRemotaConteudo({
    required this.displayName,
    required this.privado,
    required this.jogadores,
    required this.gameId,
  });

  @override
  State<_RevelacaoRemotaConteudo> createState() =>
      _RevelacaoRemotaConteudoState();
}

class _RevelacaoRemotaConteudoState extends State<_RevelacaoRemotaConteudo>
    with SingleTickerProviderStateMixin {
  bool _mostrarPapel = false;
  bool _jaRevelou = false;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setMostrarPapel(bool value) {
    if (_mostrarPapel == value) return;
    setState(() {
      _mostrarPapel = value;
      if (value) _jaRevelou = true;
    });
    if (value) {
      _animationController.forward(from: 0);
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _mostrarPapel
                ? ScaleTransition(
                    key: const ValueKey('papel_remoto'),
                    scale: _scaleAnimation,
                    child: _PapelRemotoRevelado(
                      privado: widget.privado,
                      jogadores: widget.jogadores,
                    ),
                  )
                : _PapelRemotoOculto(
                    key: const ValueKey('papel_remoto_oculto'),
                    displayName: widget.displayName,
                  ),
          ),
          const Spacer(),
          GestureDetector(
            onLongPressStart: (_) => _setMostrarPapel(true),
            onLongPressEnd: (_) => _setMostrarPapel(false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Segure para ver',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _jaRevelou ? () => _mostrarProximoPasso(context) : null,
            icon: const Icon(Icons.check),
            label: const Text('Já memorizei'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarProximoPasso(BuildContext context) async {
    await context.read<ResistenciaSalaProvider>().marcarPapelRevelado(
      widget.gameId,
    );
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ResistenciaSalaRouterScreen()),
    );
  }
}

class _PapelRemotoOculto extends StatelessWidget {
  final String displayName;

  const _PapelRemotoOculto({super.key, required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.visibility_off,
          size: 96,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 32),
        Text(
          displayName,
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'O papel está escondido',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PapelRemotoRevelado extends StatelessWidget {
  final ResistenciaPrivado privado;
  final List<ResistenciaJogadorRemoto> jogadores;

  const _PapelRemotoRevelado({required this.privado, required this.jogadores});

  @override
  Widget build(BuildContext context) {
    final isEspiao = privado.role == 'spy' || privado.team == 'evil';
    final cor = isEspiao ? Colors.red : Colors.blue;
    final conhecidos = _conhecidos();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: cor, width: 2),
          ),
          child: Text(
            isEspiao ? 'Você é Espião' : 'Você é da Resistência',
            style: TextStyle(
              color: cor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),
        Icon(
          isEspiao ? Icons.visibility_off : Icons.shield_outlined,
          size: 104,
          color: cor,
        ),
        const SizedBox(height: 40),
        if (isEspiao) ...[
          Text(
            conhecidos.isEmpty ? 'Você age sozinho' : 'Outros espiões:',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          for (final nome in conhecidos)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                nome,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: cor),
                textAlign: TextAlign.center,
              ),
            ),
        ] else ...[
          Text(
            'Encontre os espiões e aprove as equipes certas.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  List<String> _conhecidos() {
    return privado.knowledge
        .map((item) => item['uid'] as String?)
        .whereType<String>()
        .map((uid) {
          for (final jogador in jogadores) {
            if (jogador.uid == uid) return jogador.displayName;
          }
          return 'Jogador desconhecido';
        })
        .toList(growable: false);
  }
}
