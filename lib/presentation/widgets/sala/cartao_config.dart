import 'package:flutter/material.dart';

import '../../../core/theme/sala_tokens.dart';

/// Card de uma opção: ícone, título, subtítulo e o controle. Controles
/// compactos (interruptor, alternar tema) vão na linha do título com
/// [controleNaLinha]; os largos (slider, campo) vão embaixo.
class CartaoConfig extends StatelessWidget {
  const CartaoConfig({
    super.key,
    required this.icone,
    required this.titulo,
    this.subtitulo,
    this.valor,
    this.controle,
    this.controleNaLinha = false,
    this.luz,
  });

  final IconData icone;
  final String titulo;
  final String? subtitulo;

  /// Valor atual à direita do título, em `hud`.
  final String? valor;
  final Widget? controle;
  final bool controleNaLinha;

  /// Dentro de um jogo, a luz dele; fora, a primária.
  final Luz? luz;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final tinta = luz?.tinta ?? c.primariaTinta;
    final emLinha = controleNaLinha && controle != null;

    return Container(
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
        boxShadow: c.sombraCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icone, color: tinta),
              const SizedBox(width: Espaco.e3),
              Expanded(child: Text(titulo, style: texto.titleLarge)),
              if (valor != null)
                Text(valor!, style: context.estilos.hud.copyWith(color: tinta)),
              if (emLinha) ...[const SizedBox(width: Espaco.e3), controle!],
            ],
          ),
          // O texto de apoio ocupa a largura toda, embaixo da linha.
          if (subtitulo != null) ...[
            const SizedBox(height: Espaco.e2),
            Text(
              subtitulo!,
              style: texto.bodyMedium?.copyWith(color: c.texto2),
            ),
          ],
          if (controle != null && !emLinha) ...[
            const SizedBox(height: Espaco.e4),
            controle!,
          ],
        ],
      ),
    );
  }
}
