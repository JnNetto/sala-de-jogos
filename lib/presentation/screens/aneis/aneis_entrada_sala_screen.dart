import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/aneis_constants.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../providers/aneis_sala_provider.dart';
import '../../widgets/sala/sala_online.dart';
import 'aneis_sala_router_screen.dart';

class AneisEntradaSalaScreen extends StatelessWidget {
  const AneisEntradaSalaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EntradaSalaOnline(
      nomeDoJogo: AneisConstants.jogoNome,
      matiz: Matiz.ceu,
      sala: context.read<AneisSalaProvider>(),
      chaveUltimaSala: AneisConstants.prefsKeyUltimaSalaId,
      abrirSala: (restaurar) =>
          AneisSalaRouterScreen(restaurarUltimaSala: restaurar),
    );
  }
}
