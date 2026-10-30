import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/resistencia_constants.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../providers/resistencia_partida_provider.dart';
import '../../widgets/expedicao/pecas_expedicao.dart';
import '../../widgets/sala/aviso.dart';
import '../../widgets/sala/cartao_config.dart';
import '../../widgets/sala/tela_quem_vai_jogar.dart';
import 'expedicao_distribuicao_screen.dart';

const _chaveNomes = 'expedicao_nomes';

/// "Quem vai jogar?" da Expedição num celular só: os nomes ficam salvos, e
/// o cartão embaixo mostra quantos saqueadores e o tamanho das equipes.
class ExpedicaoConfiguracaoScreen extends StatelessWidget {
  const ExpedicaoConfiguracaoScreen({super.key});

  Future<void> _comecar(BuildContext context, List<String> nomes) async {
    final provider = context.read<ResistenciaPartidaProvider>();
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_chaveNomes, nomes);
    final ok = await provider.iniciarNovaPartida(nomes);
    if (!context.mounted) return;
    if (ok) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const ExpedicaoDistribuicaoScreen()),
      );
    } else if (provider.erro != null) {
      mostrarAviso(context, provider.erro!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TelaQuemVaiJogar(
      nomeDoJogo: ResistenciaConstants.jogoNome,
      matiz: matizExpedicao,
      minimo: ResistenciaConstants.minJogadores,
      maximo: ResistenciaConstants.maxJogadores,
      sobretitulo: 'NUM CELULAR SÓ',
      nomesSalvos: () async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getStringList(_chaveNomes) ?? const [];
      },
      extras: (context, n) {
        if (n < ResistenciaConstants.minJogadores) {
          return const SizedBox.shrink();
        }
        final saqueadores = ResistenciaConstants.quantidadeEspioes(n);
        return CartaoConfig(
          icone: Symbols.skull_rounded,
          titulo: '$saqueadores saqueadores',
          subtitulo: 'O número em cada câmara é quantas pessoas entram nela.',
          luz: context.cores.luz(matizExpedicao),
          controle: TrilhaDasCamaras(
            resultados: const [],
            tamanhos: ResistenciaConstants.tamanhosEquipe(n),
            atual: 1,
            jogadores: n,
          ),
        );
      },
      aoContinuar: (nomes) => _comecar(context, nomes),
    );
  }
}
