// Gera o ícone do app a partir da Marca (a mesma janela da splash e da
// home). Não roda com o `flutter test` normal; para gerar:
//
//   $env:GERAR_ICONE=1; flutter test test/loja/gerar_icone_test.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impostor_app/core/theme/app_theme.dart';
import 'package:impostor_app/presentation/widgets/sala/marca.dart';

const _tamanho = 1024.0;

/// O céu do ícone: o mesmo de `icone-app.svg` (gradientes, estrelas e
/// varal), com espaço para a janela grande.
class _Ceu extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final tudo = Offset.zero & s;
    canvas.drawRect(
      tudo,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF070822), Color(0xFF0D0F2B)],
          stops: [0, .6],
        ).createShader(tudo),
    );
    canvas.drawRect(
      tudo,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 1.16),
          radius: .99,
          colors: [Color(0xFF2C2A82), Color(0x000D0F2B)],
        ).createShader(tudo),
    );

    // Estrelas em cruz, nos cantos.
    final estrela = Paint()..color = const Color(0xFFB9B6F2);
    for (final (x, y, t, o) in const [
      (136.0, 378.0, 36.0, .7),
      (882.0, 348.0, 36.0, .8),
      (855.0, 875.0, 30.0, .5),
      (162.0, 852.0, 24.0, .5),
    ]) {
      estrela.color = const Color(0xFFB9B6F2).withValues(alpha: o);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: t / 3, height: t),
        estrela,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: t, height: t / 3),
        estrela,
      );
    }

    // O varal com seis lâmpadas acesas.
    final fio = Path()
      ..moveTo(-20, 150)
      ..quadraticBezierTo(512, 270, 1044, 150);
    canvas.drawPath(
      fio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = const Color(0xFF6A6FC4),
    );
    const cores = [
      Color(0xFFFFC94D),
      Color(0xFFFF77B7),
      Color(0xFF4FE3A6),
      Color(0xFF8F7CFF),
      Color(0xFFFF8F55),
      Color(0xFF67D6F0),
    ];
    final metrica = fio.computeMetrics().first;
    for (final (i, cor) in cores.indexed) {
      final ponto = metrica
          .getTangentForOffset(metrica.length * (i + .5) / cores.length)!
          .position;
      final centro = ponto + const Offset(0, 30);
      canvas.drawCircle(
        centro,
        44,
        Paint()
          ..shader = RadialGradient(
            colors: [cor.withValues(alpha: .55), cor.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: centro, radius: 44)),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: ponto + const Offset(0, 8),
            width: 18,
            height: 14,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF6A6FC4),
      );
      canvas.drawOval(
        Rect.fromCenter(center: centro, width: 28, height: 38),
        Paint()..color = cor,
      );
    }
  }

  @override
  bool shouldRepaint(_Ceu old) => false;
}

final _chave = GlobalKey();

Future<void> _salvar(WidgetTester t, Widget conteudo, String arquivo) async {
  t.view.physicalSize = const Size(_tamanho, _tamanho);
  t.view.devicePixelRatio = 1;
  await t.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
        data: AppTheme.noite(),
        child: RepaintBoundary(
          key: _chave,
          child: SizedBox.square(dimension: _tamanho, child: conteudo),
        ),
      ),
    ),
  );
  await t.runAsync(() async {
    final ro =
        _chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await ro.toImage(pixelRatio: 1);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File(arquivo)
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void main() {
  final gerar = Platform.environment['GERAR_ICONE'] != null;

  testWidgets('ícone completo e frente do adaptativo', skip: !gerar, (t) async {
    // Completo: céu, varal e a janela grande (a moldura ocupa ~44% da
    // largura). A Marca é desenhada num quadro de 240: moldura de 45 a 195,
    // peitoril até 208,5.
    const marca = 720.0;
    await _salvar(
      t,
      Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _Ceu())),
          Positioned(
            left: (_tamanho - marca) / 2,
            top: 268,
            child: const Marca(tamanho: marca),
          ),
        ],
      ),
      'assets/icone/icone-app-1024.png',
    );

    // Frente do adaptativo: o Android mostra um círculo de 2/3 da camada.
    // A janela fica no maior tamanho em que moldura e peitoril não são
    // cortados, centrada pela altura (moldura + peitoril).
    const frente = 680.0;
    const centroDaMarca = (45 + 208.5) / 2 / 240 * frente;
    await _salvar(
      t,
      Stack(
        children: [
          Positioned(
            left: (_tamanho - frente) / 2,
            top: _tamanho / 2 - centroDaMarca,
            child: const Marca(tamanho: frente),
          ),
        ],
      ),
      'assets/icone/icone-app-frente-1024.png',
    );
  });
}
