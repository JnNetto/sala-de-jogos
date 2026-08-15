import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quiz_partida_provider.dart';
import 'quiz_pergunta_screen.dart';

class QuizCategoriaScreen extends StatefulWidget {
  const QuizCategoriaScreen({super.key});

  @override
  State<QuizCategoriaScreen> createState() => _QuizCategoriaScreenState();
}

class _QuizCategoriaScreenState extends State<QuizCategoriaScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _revealController;
  late Animation<double> _revealScale;

  final _random = Random();
  Timer? _spinTimer;
  Timer? _navigateTimer;

  List<String> _categoriasRoleta = [];
  String _textoAtual = '...';
  String _categoriaFinal = '';
  bool _revelado = false;
  int _tick = 0;

  static const _cores = [
    Color(0xFF6C63FF),
    Color(0xFFFF6584),
    Color(0xFF2ECC71),
    Color(0xFFF39C12),
    Color(0xFF3498DB),
    Color(0xFFE74C3C),
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _revealScale = CurvedAnimation(
      parent: _revealController,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarRoleta());
  }

  void _iniciarRoleta() {
    final partida = context.read<QuizPartidaProvider>().partida;
    _categoriaFinal = partida?.perguntaAtual?.categoria ?? '';
    final ativas = partida?.configuracao.categoriasAtivas ?? [];
    _categoriasRoleta = ativas.isNotEmpty
        ? List<String>.from(ativas)
        : [_categoriaFinal];
    if (!_categoriasRoleta.contains(_categoriaFinal) &&
        _categoriaFinal.isNotEmpty) {
      _categoriasRoleta.add(_categoriaFinal);
    }

    _spinTimer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _tick++;
        _textoAtual =
            _categoriasRoleta[_random.nextInt(_categoriasRoleta.length)];
      });

      // Desacelera e para após ~2s
      if (_tick >= 22) {
        timer.cancel();
        _spinController.stop();
        setState(() {
          _textoAtual = _categoriaFinal;
          _revelado = true;
        });
        _revealController.forward();

        _navigateTimer = Timer(const Duration(milliseconds: 1600), () {
          if (!mounted) return;
          context.read<QuizPartidaProvider>().iniciarPergunta();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const QuizPerguntaScreen()),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _navigateTimer?.cancel();
    _spinController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final corFundo = _revelado
        ? _cores[_categoriaFinal.hashCode.abs() % _cores.length]
        : _cores[_tick % _cores.length];

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: corFundo,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: corFundo,
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RotationTransition(
                    turns: _revelado
                        ? const AlwaysStoppedAnimation(0)
                        : _spinController,
                    child: Icon(
                      _revelado ? Icons.check_circle : Icons.casino,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _revelado
                        ? 'Categoria sorteada!'
                        : 'Sorteando categoria...',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ScaleTransition(
                    scale: _revelado
                        ? _revealScale
                        : const AlwaysStoppedAnimation(1),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white54, width: 2),
                      ),
                      child: Text(
                        _textoAtual,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (!_revelado) ...[
                    const SizedBox(height: 40),
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
