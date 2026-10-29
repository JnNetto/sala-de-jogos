import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/sala_tokens.dart';

enum TipoAviso { erro, sucesso, info, aviso }

/// O toast da sala, em janelinha: poço com o ícone do estado e a mensagem.
/// Substitui o `SnackBar` vermelho.
void mostrarAviso(
  BuildContext context,
  String mensagem, {
  TipoAviso tipo = TipoAviso.erro,
}) {
  final c = context.cores;
  final (luz, icone) = switch (tipo) {
    TipoAviso.erro => (c.erro, Symbols.error_rounded),
    TipoAviso.sucesso => (c.sucesso, Symbols.check_circle_rounded),
    TipoAviso.info => (c.info, Symbols.info_rounded),
    TipoAviso.aviso => (c.aviso, Symbols.warning_rounded),
  };
  if (tipo == TipoAviso.erro) HapticFeedback.lightImpact();

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        padding: const EdgeInsets.fromLTRB(
          Espaco.e3,
          Espaco.e3,
          Espaco.e2,
          Espaco.e3,
        ),
        showCloseIcon: true,
        closeIconColor: c.texto3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Raio.lg),
          side: c.ehDia
              ? BorderSide(color: c.contorno, width: 2)
              : BorderSide(color: c.linha, width: 1.5),
        ),
        content: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: luz.suave,
                borderRadius: BorderRadius.circular(Raio.sm),
              ),
              child: Icon(icone, fill: 1, size: 24, color: luz.tinta),
            ),
            const SizedBox(width: Espaco.e3),
            Expanded(
              child: Text(
                mensagem,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
}
