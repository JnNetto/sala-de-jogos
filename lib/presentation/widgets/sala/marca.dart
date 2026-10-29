import 'package:flutter/material.dart';

import '../../../core/theme/sala_tokens.dart';

/// A marca: uma janela acesa com quatro vidros nas cores de quatro jogos.
/// Desenhada a partir de `marca-noite.svg` / `marca-dia.svg` (viewBox 240).
class Marca extends StatelessWidget {
  const Marca({super.key, this.tamanho = 48, this.vidrosAcesos = 4});

  final double tamanho;

  /// Na splash os vidros acendem um a um; apagado, o vidro é só vão escuro.
  /// Fracionário: 1,5 é o primeiro aceso e o segundo pela metade.
  final double vidrosAcesos;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Sala de Jogos',
      child: CustomPaint(
        size: Size.square(tamanho),
        painter: _MarcaPintor(context.cores, vidrosAcesos),
      ),
    );
  }
}

class _MarcaPintor extends CustomPainter {
  _MarcaPintor(this.c, this.acesos);

  final SalaCores c;
  final double acesos;

  // Os vidros não se recolorem: são as luzes de quatro jogos.
  static const _vidros = [
    (Offset(57.8, 57.8), Color(0xFFFFC94D)),
    (Offset(124.1, 57.8), Color(0xFFFF77B7)),
    (Offset(57.8, 124.1), Color(0xFF4FE3A6)),
    (Offset(124.1, 124.1), Color(0xFF8F7CFF)),
  ];

  @override
  void paint(Canvas canvas, Size s) {
    canvas.scale(s.width / 240);

    if (!c.ehDia && acesos > 0) {
      final halo = Rect.fromCenter(
        center: const Offset(120, 120),
        width: 285,
        height: 285,
      );
      canvas.drawOval(
        halo,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFC94D).withValues(alpha: .38 * acesos / 4),
              const Color(0xFFFF77B7).withValues(alpha: .12 * acesos / 4),
              const Color(0xFF8F7CFF).withValues(alpha: 0),
            ],
            stops: const [0, .55, 1],
          ).createShader(halo),
      );
    }

    RRect rr(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

    final moldura = c.ehDia ? c.contorno : c.janelaBarra;
    final peitoril = c.ehDia ? c.contorno : const Color(0xFF3A3F96);
    canvas.drawRRect(rr(45, 45, 150, 150, 18), Paint()..color = moldura);

    final reflexo = Paint()..color = Colors.white.withValues(alpha: .6);
    for (final (i, (o, cor)) in _vidros.indexed) {
      final luz = (acesos - i).clamp(0.0, 1.0);
      canvas.drawRRect(
        rr(o.dx, o.dy, 58.1, 58.1, 7.2),
        Paint()..color = Color.lerp(c.superficieFunda, cor, luz)!,
      );
      if (luz == 0) continue;
      reflexo.color = Colors.white.withValues(alpha: .6 * luz);
      canvas.drawRect(
        Rect.fromLTWH(o.dx + 8.1, o.dy + 8.2, 11.6, 4.4),
        reflexo,
      );
      canvas.drawRect(
        Rect.fromLTWH(o.dx + 8.1, o.dy + 15.7, 4.4, 4.4),
        reflexo,
      );
    }

    canvas.drawRRect(rr(30, 192, 180, 16.5, 6), Paint()..color = peitoril);
  }

  @override
  bool shouldRepaint(_MarcaPintor o) => o.c != c || o.acesos != acesos;
}
