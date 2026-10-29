import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/sala_tokens.dart';
import '../../providers/theme_provider.dart';

/// Troca o tema como quem acende (ou apaga) a luz da sala: tira uma foto da
/// tela no tema antigo, troca o tema de uma vez por baixo e abre um círculo
/// na foto a partir do interruptor.
///
/// Custa um quadro de reconstrução, em vez de interpolar o `ThemeData` do
/// app inteiro a cada quadro. Vai no `builder` do `MaterialApp`.
class TrocaDeTema extends StatefulWidget {
  const TrocaDeTema({super.key, required this.child});

  final Widget child;

  /// Alterna Noite/Dia. [origem] é o ponto, em coordenadas globais, de onde
  /// o círculo se abre (o centro do interruptor).
  static Future<void> alternar(BuildContext context, {Offset? origem}) {
    final estado = context.findAncestorStateOfType<_TrocaDeTemaState>();
    if (estado == null) return context.read<ThemeProvider>().toggleTheme();
    return estado._alternar(origem);
  }

  @override
  State<TrocaDeTema> createState() => _TrocaDeTemaState();
}

class _TrocaDeTemaState extends State<TrocaDeTema>
    with SingleTickerProviderStateMixin {
  final _palco = GlobalKey();
  late final AnimationController _abrir;
  late final CurvedAnimation _curva;
  ui.Image? _foto;
  Offset _origem = Offset.zero;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _abrir = AnimationController(vsync: this);
    _curva = CurvedAnimation(parent: _abrir, curve: Movimento.padrao);
  }

  @override
  void dispose() {
    _curva.dispose();
    _abrir.dispose();
    _foto?.dispose();
    super.dispose();
  }

  Future<void> _alternar(Offset? origem) async {
    if (_ocupado) return;
    _ocupado = true;
    final tema = context.read<ThemeProvider>();
    final reduzido = Movimento.reduzido(context);
    // A foto não precisa da resolução cheia: some em menos de meio segundo.
    final escala = math.min(MediaQuery.devicePixelRatioOf(context), 2.0);

    try {
      final palco =
          _palco.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      _foto = await palco?.toImage(pixelRatio: escala);
    } catch (_) {
      _foto = null; // sem foto, troca seca
    }
    if (!mounted) return;

    setState(() => _origem = origem ?? Offset.zero);
    unawaited(tema.toggleTheme());

    if (_foto != null) {
      _abrir.duration = reduzido
          ? const Duration(milliseconds: 120)
          : Movimento.lenta;
      await _abrir.forward(from: 0);
    }
    if (!mounted) return;
    setState(() {
      _foto?.dispose();
      _foto = null;
    });
    _ocupado = false;
  }

  @override
  Widget build(BuildContext context) {
    final foto = _foto;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        RepaintBoundary(key: _palco, child: widget.child),
        if (foto != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _Revelacao(
                  foto: foto,
                  origem: _origem,
                  progresso: _curva,
                  soFade: Movimento.reduzido(context),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Revelacao extends CustomPainter {
  _Revelacao({
    required this.foto,
    required this.origem,
    required this.progresso,
    required this.soFade,
  }) : super(repaint: progresso);

  final ui.Image foto;
  final Offset origem;
  final Animation<double> progresso;
  final bool soFade;

  @override
  void paint(Canvas canvas, Size s) {
    final t = progresso.value;
    final destino = Offset.zero & s;
    final pincel = Paint()..filterQuality = FilterQuality.low;

    if (soFade) {
      pincel.color = Color.fromRGBO(0, 0, 0, 1 - t);
    } else {
      // O círculo cresce até cobrir o canto mais distante do interruptor.
      final raioMax = [
        destino.topLeft,
        destino.topRight,
        destino.bottomLeft,
        destino.bottomRight,
      ].map((p) => (p - origem).distance).reduce(math.max);
      canvas.clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(destino)
          ..addOval(Rect.fromCircle(center: origem, radius: raioMax * t)),
      );
    }
    canvas.drawImageRect(
      foto,
      Offset.zero & Size(foto.width.toDouble(), foto.height.toDouble()),
      destino,
      pincel,
    );
  }

  @override
  bool shouldRepaint(_Revelacao o) => o.foto != foto || o.origem != origem;
}
