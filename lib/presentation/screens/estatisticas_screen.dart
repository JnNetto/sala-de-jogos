import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/sala_tokens.dart';
import '../../core/utils/service_locator.dart';
import '../widgets/sala/tela_estatisticas.dart';

/// Estatísticas do Quem é o Espião?.
class EstatisticasScreen extends StatelessWidget {
  const EstatisticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final servico = ServiceLocator().estatisticasService;
    return TelaEstatisticas(
      nomeDoJogo: 'Quem é o Espião?',
      matiz: Matiz.violeta,
      carregar: servico.getEstatisticas,
      apagar: servico.limparEstatisticas,
      mentirosos: 'espiões',
      iconeMentirosos: Symbols.visibility_off_rounded,
    );
  }
}
