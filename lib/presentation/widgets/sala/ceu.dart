import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/sala_tokens.dart';
import 'palco_da_sala.dart';
import 'relogio_ambiente.dart';
import 'vento.dart';

/// O fundo de toda tela: degradê de `ceu-topo` até `fundo`, brilho no rodapé
/// e estrelas pixel. No Dia o céu vira papel com uma grade de pontinhos.
///
/// As estrelas ficam numa camada própria: o cintilar e o parallax repintam
/// só elas, nunca o conteúdo da tela.
class Ceu extends StatefulWidget {
  const Ceu({
    super.key,
    required this.child,
    this.semente = 7,
    this.estrelas = 22,
    this.rolagem,
    this.vento,
  });

  final Widget child;

  /// Posições fixas por tela, para as estrelas não "dançarem" ao navegar.
  final int semente;
  final int estrelas;

  /// Quando passado, as estrelas andam a 30% da velocidade do conteúdo.
  final ScrollController? rolagem;

  /// O vento que leva as estrelas; sem ele, vale o do [PalcoDaSala].
  final Vento? vento;

  @override
  State<Ceu> createState() => _CeuState();
}

class _CeuState extends State<Ceu> with SingleTickerProviderStateMixin {
  late final _relogio = RelogioAmbiente(this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _relogio.ligado = !Movimento.reduzido(context) && !context.cores.ehDia;
  }

  @override
  void dispose() {
    _relogio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.ceuTopo, c.fundo],
          stops: const [0, .55],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, 1.3),
            radius: 1.1,
            colors: [c.ceuBrilho, c.ceuBrilho.withValues(alpha: 0)],
            stops: const [0, .6],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: _Estrelas(
                  c: c,
                  semente: widget.semente,
                  n: widget.estrelas,
                  relogio: _relogio,
                  rolagem: widget.rolagem,
                  vento: widget.vento ?? PalcoDaSala.ventoDe(context),
                ),
              ),
            ),
            RepaintBoundary(child: widget.child),
          ],
        ),
      ),
    );
  }
}

class _Estrelas extends CustomPainter {
  _Estrelas({
    required this.c,
    required this.semente,
    required this.n,
    required this.relogio,
    this.rolagem,
    this.vento,
  }) : super(repaint: Listenable.merge([relogio, ?rolagem, ?vento]));

  final SalaCores c;
  final int semente, n;
  final RelogioAmbiente relogio;
  final ScrollController? rolagem;
  final Vento? vento;

  double get _deslocamento {
    final r = rolagem;
    if (r == null || !r.hasClients) return 0;
    return r.offset * .3;
  }

  @override
  void paint(Canvas canvas, Size s) {
    if (c.ehDia) {
      _grade(canvas, s);
      return;
    }
    final r = math.Random(semente);
    final p = Paint();
    final dy = _deslocamento;
    final ciclo =
        relogio.value.inMilliseconds / Movimento.ambiente.inMilliseconds;
    for (var i = 0; i < n; i++) {
      var x = r.nextDouble() * s.width;
      final y = (r.nextDouble() * s.height - dy) % s.height;
      final fase = r.nextDouble();
      final v = vento;
      if (v != null) {
        // Cruzes parecem mais perto: o vento as leva mais que os pontinhos.
        final perto = i % 3 == 0 ? 1.0 : .5;
        final dx = (v.deriva + v.empurrao(x / s.width)) * perto;
        x = (x + dx) % (s.width + 12) - 6;
      }
      var alpha = .55;
      if (i % 4 == 1) {
        // Uma em cada quatro cintila entre 20% e 90%, com fase própria.
        final onda = .5 - .5 * math.cos(2 * math.pi * (ciclo + fase));
        alpha = .2 + .7 * onda;
      }
      p.color = c.estrela.withValues(alpha: alpha);
      if (i % 3 == 0) {
        // Cruz pixel 9 × 9.
        canvas.drawRect(Rect.fromLTWH(x + 3, y, 3, 9), p);
        canvas.drawRect(Rect.fromLTWH(x, y + 3, 9, 3), p);
      } else {
        canvas.drawRect(Rect.fromLTWH(x, y, 3, 3), p);
      }
    }
  }

  void _grade(Canvas canvas, Size s) {
    const passo = 18.0;
    final p = Paint()..color = c.estrela;
    final dy = _deslocamento % passo;
    for (var y = passo / 2 - dy; y < s.height; y += passo) {
      for (var x = passo / 2; x < s.width; x += passo) {
        canvas.drawRect(Rect.fromLTWH(x - 1, y - 1, 2.5, 2.5), p);
      }
    }
  }

  @override
  bool shouldRepaint(_Estrelas o) =>
      o.c != c ||
      o.n != n ||
      o.semente != semente ||
      o.rolagem != rolagem ||
      o.vento != vento;
}
