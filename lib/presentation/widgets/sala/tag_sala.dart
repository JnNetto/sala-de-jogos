import 'package:flutter/material.dart';

import '../../../core/theme/sala_tokens.dart';

/// Tag em pixel, até três palavras em CAIXA ALTA: "3–12", "10 MIN", "NOVO".
class TagSala extends StatelessWidget {
  const TagSala(this.texto, {super.key, this.icone, this.luz, this.destaque});

  final String texto;
  final IconData? icone;

  /// Tingida na cor do jogo (fundo `-suave`, texto `-tinta`).
  final Luz? luz;

  /// Preenchida na cor viva com texto `sobre-cor`, como o "NOVO".
  final Color? destaque;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final fundo = destaque ?? luz?.suave ?? c.superficieFunda;
    final tinta = destaque != null ? c.sobreCor : (luz?.tinta ?? c.texto2);
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: Espaco.e2),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(Raio.xs),
        border: c.ehDia ? Border.all(color: c.contorno, width: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 14, color: tinta),
            const SizedBox(width: Espaco.e1),
          ],
          Text(
            texto,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: tinta, height: 1),
          ),
        ],
      ),
    );
  }
}
