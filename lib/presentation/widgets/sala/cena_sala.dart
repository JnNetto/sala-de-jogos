import 'package:flutter/material.dart';

import '../../../core/theme/transicao_sala.dart';
import 'palco_da_sala.dart';

/// Navegação entre telas de sala, em fade-through: a tela atual some
/// primeiro e a nova surge depois, subindo um pouquinho. O varal e o céu do
/// [PalcoDaSala] ficam parados por baixo, então no meio da troca a sala
/// continua lá, só sem conteúdo.
Route<T> rotaDaSala<T>(Widget tela, {String? nome}) => PageRouteBuilder<T>(
  settings: RouteSettings(name: nome),
  transitionDuration: const Duration(milliseconds: 700),
  reverseTransitionDuration: const Duration(milliseconds: 560),
  pageBuilder: (_, _, _) => tela,
  transitionsBuilder: (_, animacao, saindo, filho) =>
      transicaoDaSala(animacao, saindo, filho),
);

/// O cenário das telas "de sala" (splash, tela inicial, lista de jogos): o
/// pedido do varal. O céu é o do [PalcoDaSala], por baixo de todas.
class CenaSala extends StatelessWidget {
  const CenaSala({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ComVaral(child: child);
  }
}
