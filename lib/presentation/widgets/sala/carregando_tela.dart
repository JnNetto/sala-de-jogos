import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/sala_tokens.dart';
import 'varal.dart';

/// Roda [acao] com a tela travada por um véu e uma janelinha com o varal
/// correndo e o que está acontecendo ("Saindo da sala…"). Para esperas do
/// servidor que mudam de tela no fim, quando não há um botão para girar.
Future<T> comCarregando<T>(
  BuildContext context,
  String texto,
  Future<T> Function() acao,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final c = context.cores;
  showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Movimento.d(context, Movimento.media),
    pageBuilder: (_, _, _) =>
        PopScope(canPop: false, child: _Carregando(texto: texto)),
    transitionBuilder: (_, animacao, _, filho) => Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: animacao,
            builder: (_, _) => BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 6 * animacao.value,
                sigmaY: 6 * animacao.value,
              ),
              child: ColoredBox(
                color: c.veu.withValues(alpha: c.veu.a * animacao.value),
              ),
            ),
          ),
        ),
        FadeTransition(
          opacity: CurvedAnimation(parent: animacao, curve: Movimento.entrada),
          child: filho,
        ),
      ],
    ),
  );
  try {
    return await acao();
  } finally {
    navigator.pop();
  }
}

class _Carregando extends StatelessWidget {
  const _Carregando({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Center(
      child: Semantics(
        liveRegion: true,
        label: texto,
        excludeSemantics: true,
        child: Container(
          width: 240,
          padding: const EdgeInsets.fromLTRB(
            Espaco.e5,
            Espaco.e4,
            Espaco.e5,
            Espaco.e5,
          ),
          decoration: BoxDecoration(
            color: c.superficie,
            borderRadius: BorderRadius.circular(Raio.xl),
            border: Border.all(
              color: c.ehDia ? c.contorno : c.linha,
              width: c.bordaControle,
            ),
            boxShadow: c.sombraFlutuante,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Varal.carregando(),
              const SizedBox(height: Espaco.e3),
              Material(
                type: MaterialType.transparency,
                child: Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
