import 'package:flutter/material.dart';

import '../../../core/theme/sala_tokens.dart';

/// Uma linha de fato no fim de jogo ("Caio era espião", "A palavra era
/// Pizzaria"): poço, frase e uma etiqueta opcional.
class FatoDoFim extends StatelessWidget {
  const FatoDoFim({
    super.key,
    required this.poco,
    required this.texto,
    this.direita,
  });

  final Widget poco;
  final InlineSpan texto;
  final Widget? direita;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      padding: const EdgeInsets.all(Espaco.e3),
      decoration: BoxDecoration(
        color: c.superficieFunda,
        borderRadius: BorderRadius.circular(Raio.lg),
      ),
      child: Row(
        children: [
          poco,
          const SizedBox(width: Espaco.e3),
          Expanded(
            child: Text.rich(
              texto,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: c.texto2),
            ),
          ),
          if (direita != null) ...[const SizedBox(width: Espaco.e2), direita!],
        ],
      ),
    );
  }
}

/// Poço pequeno (44) com um ícone preenchido na cor da luz.
class PocoIcone extends StatelessWidget {
  const PocoIcone({super.key, required this.icone, required this.luz});

  final IconData icone;
  final Luz luz;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: luz.suave,
        borderRadius: BorderRadius.circular(Raio.sm),
      ),
      child: Icon(icone, fill: 1, size: 24, color: luz.tinta),
    );
  }
}

/// Texto com um trecho em destaque: "A palavra era **Pizzaria**".
TextSpan comDestaque(
  BuildContext context,
  String antes,
  String destaque, [
  String depois = '',
]) => TextSpan(
  children: [
    TextSpan(text: antes),
    TextSpan(
      text: destaque,
      style: TextStyle(
        color: context.cores.texto,
        fontWeight: FontWeight.w900,
        fontVariations: const [FontVariation.weight(900)],
      ),
    ),
    TextSpan(text: depois),
  ],
);
