import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/sala_tokens.dart';
import '../../../core/utils/service_locator.dart';
import '../../../data/models/estatisticas.dart';
import '../../widgets/sala/tela_estatisticas.dart';

/// Estatísticas do Pergunta Impostora.
class PerguntaEstatisticasScreen extends StatelessWidget {
  const PerguntaEstatisticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = ServiceLocator().storageService;
    return TelaEstatisticas(
      nomeDoJogo: 'Pergunta Impostora',
      matiz: Matiz.rosa,
      carregar: storage.getEstatisticasPergunta,
      apagar: () => storage.saveEstatisticasPergunta(Estatisticas()),
      mentirosos: 'impostores',
      iconeMentirosos: Symbols.theater_comedy_rounded,
    );
  }
}
