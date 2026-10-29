import 'package:flutter/material.dart';

import '../../../core/theme/sala_tokens.dart';
import 'pressionavel.dart';

/// Um botão de uma escolha em grupo (nível, modo): poço fundo quando
/// desligado, tingido na luz do jogo quando ligado. Vão lado a lado, em
/// `Expanded`.
class BotaoOpcao extends StatelessWidget {
  const BotaoOpcao({
    super.key,
    required this.rotulo,
    required this.selecionado,
    required this.luz,
    required this.aoTocar,
    this.icone,
    this.semantica,
  });

  final String rotulo;
  final bool selecionado;
  final Luz luz;
  final VoidCallback? aoTocar;
  final IconData? icone;

  /// O que o leitor de tela diz no lugar do rótulo ("Nível Fácil").
  final String? semantica;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final tinta = selecionado ? luz.tinta : c.texto2;
    return Semantics(
      button: true,
      selected: selecionado,
      label: semantica ?? rotulo,
      excludeSemantics: true,
      child: Pressionavel(
        onTap: aoTocar,
        escala: .96,
        child: AnimatedContainer(
          duration: Movimento.base,
          curve: Movimento.padrao,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: Espaco.e2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selecionado ? luz.suave : c.superficieFunda,
            borderRadius: BorderRadius.circular(Raio.md),
            border: Border.all(
              color: selecionado
                  ? (c.ehDia ? c.contorno : luz.cor)
                  : (c.ehDia ? c.contorno : c.linha),
              width: selecionado ? 2 : c.bordaControle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icone != null) ...[
                Icon(icone, size: 20, fill: selecionado ? 1 : 0, color: tinta),
                const SizedBox(width: Espaco.e2),
              ],
              Flexible(
                child: Text(
                  rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: tinta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
