import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/jogador_partida.dart';
import '../../data/models/palavra.dart';

class ExibicaoPapelScreen extends StatefulWidget {
  final JogadorPartida jogador;
  final Palavra palavraSecreta;
  final Palavra? palavraRelacionada;

  const ExibicaoPapelScreen({
    super.key,
    required this.jogador,
    required this.palavraSecreta,
    this.palavraRelacionada,
  });

  @override
  State<ExibicaoPapelScreen> createState() => _ExibicaoPapelScreenState();
}

class _ExibicaoPapelScreenState extends State<ExibicaoPapelScreen>
    with SingleTickerProviderStateMixin {
  bool _mostrarPapel = false;
  int _tempoRestante = AppConstants.duracaoExibicaoPapelSegundos;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _revelarPapel() {
    setState(() {
      _mostrarPapel = true;
    });
    _animationController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _tempoRestante--;
      });

      if (_tempoRestante <= 0) {
        timer.cancel();
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _mostrarPapel
                  ? _buildPapelRevelado()
                  : _buildBotaoRevelar(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoRevelar() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.touch_app,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 32),
        Text(
          widget.jogador.nome,
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Toque no botão para revelar seu papel',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: _revelarPapel,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility, size: 28),
              SizedBox(width: 12),
              Text(
                'Revelar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPapelRevelado() {
    final isEspiao = widget.jogador.isEspiao;
    final palavra = isEspiao
        ? widget.palavraRelacionada?.texto ?? '???'
        : widget.palavraSecreta.texto;
    final corPapel = isEspiao ? AppTheme.espiaoColor : AppTheme.civilColor;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: corPapel.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: corPapel, width: 2),
            ),
            child: Text(
              'Você é ${isEspiao ? 'o' : 'um'} ${widget.jogador.papel.displayName}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: corPapel,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Icon(
            isEspiao ? Icons.visibility_off : Icons.group,
            size: 100,
            color: corPapel,
          ),
          const SizedBox(height: 48),
          if (isEspiao && widget.palavraRelacionada == null) ...[
            Text(
              'Você não sabe a palavra',
              style: TextStyle(
                fontSize: 28,
                color: corPapel,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Tente descobrir ouvindo os outros',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Text(
              isEspiao ? 'Palavra relacionada:' : 'Sua palavra:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: corPapel.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: corPapel, width: 3),
              ),
              child: Text(
                palavra,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: corPapel,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Text(
              '$_tempoRestante',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
