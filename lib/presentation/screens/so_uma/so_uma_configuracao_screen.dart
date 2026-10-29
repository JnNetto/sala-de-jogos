import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/so_uma_constants.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../providers/so_uma_partida_provider.dart';
import '../../widgets/sala/aviso.dart';
import '../../widgets/sala/cartao_config.dart';
import '../../widgets/sala/tela_quem_vai_jogar.dart';
import '../../widgets/so_uma/pecas_so_uma.dart';
import 'so_uma_partida_screen.dart';

const _chaveNomes = 'so_uma_nomes';

/// "Quem vai jogar?" do modo num celular só. Os nomes ficam salvos para a
/// próxima vez.
class SoUmaConfiguracaoScreen extends StatelessWidget {
  const SoUmaConfiguracaoScreen({super.key});

  Future<void> _comecar(BuildContext context, List<String> nomes) async {
    final provider = context.read<SoUmaPartidaProvider>();
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_chaveNomes, nomes);
    final ok = await provider.iniciarNovaPartida(nomes);
    if (!context.mounted) return;
    if (ok) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const SoUmaPartidaScreen()),
      );
    } else if (provider.erro != null) {
      mostrarAviso(context, provider.erro!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TelaQuemVaiJogar(
      nomeDoJogo: SoUmaConstants.jogoNome,
      matiz: matizSoUma,
      minimo: SoUmaConstants.minJogadores,
      maximo: SoUmaConstants.maxJogadores,
      sobretitulo: 'NUM CELULAR SÓ',
      nomesSalvos: () async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getStringList(_chaveNomes) ?? const [];
      },
      extras: (context, n) => n == SoUmaConstants.jogadoresParaDuasPistas
          ? CartaoConfig(
              icone: Symbols.edit_note_rounded,
              titulo: 'Duas pistas cada',
              subtitulo:
                  'Com 3 pessoas, quem escreve dá duas pistas por rodada, '
                  'para sobrar o que adivinhar.',
              luz: context.cores.luz(matizSoUma),
            )
          : const SizedBox.shrink(),
      aoContinuar: (nomes) => _comecar(context, nomes),
    );
  }
}
