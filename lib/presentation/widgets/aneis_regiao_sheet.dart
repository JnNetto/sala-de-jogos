import 'package:flutter/material.dart';

import '../../core/enums/aneis_regiao.dart';
import '../../data/models/aneis_anel_publico.dart';
import '../../data/models/aneis_carta_tabuleiro.dart';
import '../../data/models/aneis_regra_revelada.dart';

Future<void> mostrarCartasDaRegiao({
  required BuildContext context,
  required AneisRegiao regiao,
  required List<AneisCartaTabuleiro> cartas,
  List<AneisAnelPublico> aneis = const [],
  AneisRegraRevelada? regraSecreta,
}) {
  final daRegiao = cartas.where((carta) => carta.regiao == regiao).toList();
  AneisAnelPublico? anel;
  if (regiao.ehAnelExclusivo) {
    for (final item in aneis) {
      if (item.id == regiao.id) {
        anel = item;
        break;
      }
    }
  }

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final bottom = MediaQuery.viewPaddingOf(context).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: anel?.cor ?? regiao.cor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        anel?.nome ?? regiao.rotulo,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _descricao(regiao, anel),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (regraSecreta != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    regraSecreta.texto,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
                const SizedBox(height: 16),
                if (daRegiao.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('Nenhuma carta nesta região ainda.'),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final carta in daRegiao)
                        Chip(
                          label: Text(
                            carta.texto,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: (anel?.cor ?? regiao.cor).withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    },
  );
}

String _descricao(AneisRegiao regiao, AneisAnelPublico? anel) {
  if (regiao.ehAnelExclusivo) {
    final subtitulo = anel?.subtitulo.trim() ?? '';
    if (subtitulo.isNotEmpty) return subtitulo;
    switch (regiao) {
      case AneisRegiao.palavra:
        return 'Escrita ou som';
      case AneisRegiao.atributo:
        return 'O que a coisa é';
      case AneisRegiao.contexto:
        return 'Onde se usa';
      default:
        return 'Cumpre só esta regra.';
    }
  }

  switch (regiao) {
    case AneisRegiao.nenhum:
      return 'Não entra em nenhum dos três anéis.';
    case AneisRegiao.palavraAtributo:
      return 'Cumpre Palavra e Atributo, mas não Contexto.';
    case AneisRegiao.palavraContexto:
      return 'Cumpre Palavra e Contexto, mas não Atributo.';
    case AneisRegiao.atributoContexto:
      return 'Cumpre Atributo e Contexto, mas não Palavra.';
    case AneisRegiao.todos:
      return 'Cumpre as três regras secretas ao mesmo tempo.';
    default:
      return '';
  }
}
