import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/so_uma_constants.dart';
import '../../providers/so_uma_sala_provider.dart';
import '../../widgets/sala/sala_online.dart';
import '../../widgets/so_uma/pecas_so_uma.dart';
import 'so_uma_sala_router_screen.dart';

class SoUmaEntradaSalaScreen extends StatelessWidget {
  const SoUmaEntradaSalaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EntradaSalaOnline(
      nomeDoJogo: SoUmaConstants.jogoNome,
      matiz: matizSoUma,
      sala: context.read<SoUmaSalaProvider>(),
      chaveUltimaSala: SoUmaConstants.prefsKeyUltimaSalaId,
      abrirSala: (restaurar) =>
          SoUmaSalaRouterScreen(restaurarUltimaSala: restaurar),
    );
  }
}
