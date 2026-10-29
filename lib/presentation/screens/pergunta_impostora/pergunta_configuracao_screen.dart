import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/pergunta_impostora_constants.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../providers/pergunta_configuracao_provider.dart';
import '../../widgets/sala/cartao_config.dart';
import '../../widgets/sala/contador.dart';
import '../../widgets/sala/tela_quem_vai_jogar.dart';
import 'pergunta_ajustes_screen.dart';

/// Passo 1 do Pergunta Impostora: quem vai jogar (e em que ordem o celular
/// passa) e quantos impostores.
class PerguntaConfiguracaoScreen extends StatelessWidget {
  const PerguntaConfiguracaoScreen({super.key});

  static const _min = PerguntaImpostoraConstants.minJogadores;
  static const _max = PerguntaImpostoraConstants.maxJogadores;

  static int _maxImpostores(int jogadores) => (jogadores - 2).clamp(1, _max);

  static String _recomendacao(int n) {
    if (n < _min) return 'Com $_min ou mais pessoas já dá para jogar.';
    if (n <= 5) return 'Com $n jogadores, 1 impostor funciona bem.';
    if (n <= 8) return 'Com $n jogadores, 1 ou 2 impostores funcionam bem.';
    return 'Com $n jogadores, 2 ou 3 impostores funcionam bem.';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PerguntaConfiguracaoProvider>();
    return TelaQuemVaiJogar(
      nomeDoJogo: 'Pergunta Impostora',
      matiz: Matiz.rosa,
      minimo: _min,
      maximo: _max,
      nomesSalvos: () async {
        await provider.carregarConfiguracao();
        return provider.configuracao.nomesJogadores;
      },
      extras: (context, n) {
        final impostores = context.select<PerguntaConfiguracaoProvider, int>(
          (p) => p.configuracao.quantidadeImpostores,
        );
        final max = _maxImpostores(n);
        return CartaoConfig(
          icone: Symbols.theater_comedy_rounded,
          titulo: 'Impostores',
          subtitulo: _recomendacao(n),
          luz: context.cores.luz(Matiz.rosa),
          controleNaLinha: true,
          controle: Contador(
            valor: impostores.clamp(1, max),
            minimo: 1,
            maximo: max,
            rotulo: 'impostores',
            aoMudar: provider.setQuantidadeImpostores,
          ),
        );
      },
      aoContinuar: (nomes) async {
        final max = _maxImpostores(nomes.length);
        provider
          ..setNomesJogadores(nomes)
          ..setQuantidadeJogadores(nomes.length);
        if (provider.configuracao.quantidadeImpostores > max) {
          provider.setQuantidadeImpostores(max);
        }
        await provider.salvar();
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PerguntaAjustesScreen(),
          ),
        );
      },
    );
  }
}
