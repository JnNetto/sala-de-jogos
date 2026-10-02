import 'package:flutter/material.dart';

import '../../../core/enums/lobisomem_papel.dart';
import '../../../data/models/lobisomem_jogador.dart';

class LobisomemRevelacaoPapelScreen extends StatefulWidget {
  final LobisomemJogador jogador;
  final List<LobisomemJogador> jogadores;

  const LobisomemRevelacaoPapelScreen({
    super.key,
    required this.jogador,
    required this.jogadores,
  });

  @override
  State<LobisomemRevelacaoPapelScreen> createState() =>
      _LobisomemRevelacaoPapelScreenState();
}

class _LobisomemRevelacaoPapelScreenState
    extends State<LobisomemRevelacaoPapelScreen>
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
      if (value) {
        _jaRevelou = true;
      }
    });
    if (value) {
      _animationController.forward(from: 0);
    } else {
      _animationController.reverse();
    }
  }

  List<LobisomemJogador> get _alcateia {
    if (widget.jogador.papel != LobisomemPapel.lobisomem) {
      return const [];
    }
    return widget.jogadores
        .where(
          (jogador) =>
              jogador.id != widget.jogador.id &&
              jogador.papel == LobisomemPapel.lobisomem,
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _mostrarPapel
                      ? ScaleTransition(
                          key: const ValueKey('papel'),
                          scale: _scaleAnimation,
                          child: _PapelRevelado(
                            jogador: widget.jogador,
                            alcateia: _alcateia,
                          ),
                        )
                      : _PapelOculto(
                          key: const ValueKey('oculto'),
                          jogador: widget.jogador,
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
                  onPressed: _jaRevelou
                      ? () => Navigator.of(context).pop()
                      : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Já memorizei'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PapelOculto extends StatelessWidget {
  final LobisomemJogador jogador;

  const _PapelOculto({super.key, required this.jogador});

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
          jogador.nome,
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

class _PapelRevelado extends StatelessWidget {
  final LobisomemJogador jogador;
  final List<LobisomemJogador> alcateia;

  const _PapelRevelado({required this.jogador, required this.alcateia});

  @override
  Widget build(BuildContext context) {
    final cor = jogador.ehLobisomem
        ? Colors.red
        : jogador.ehBobo
        ? Colors.purple
        : Colors.blue;

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
            'Você é ${jogador.papel.nome}',
            style: TextStyle(
              color: cor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Icon(
          jogador.ehLobisomem
              ? Icons.nightlight_round
              : jogador.ehBobo
              ? Icons.theater_comedy
              : jogador.ehAnciao
              ? Icons.elderly
              : Icons.cottage_outlined,
          size: 96,
          color: cor,
        ),
        const SizedBox(height: 24),
        Text(
          jogador.papel.descricao,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        if (jogador.ehLobisomem) ...[
          const SizedBox(height: 24),
          Text(
            alcateia.isEmpty ? 'Você age sozinho' : 'Sua alcateia:',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          for (final lobo in alcateia)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                lobo.nome,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: cor),
                textAlign: TextAlign.center,
              ),
            ),
        ],
        if (jogador.ehNarrador) ...[
          const SizedBox(height: 20),
          Text(
            'Você também é o Narrador: nas fases públicas, leia a historinha em voz alta.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
