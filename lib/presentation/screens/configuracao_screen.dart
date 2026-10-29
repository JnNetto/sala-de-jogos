import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/sala_tokens.dart';
import '../providers/configuracao_provider.dart';
import '../widgets/sala/cartao_config.dart';
import '../widgets/sala/contador.dart';
import '../widgets/sala/tela_quem_vai_jogar.dart';
import 'espiao_ajustes_screen.dart';

/// Passo 1 do Quem é o Espião?: quem vai jogar (e em que ordem o celular
/// passa) e quantos espiões.
class ConfiguracaoScreen extends StatelessWidget {
  const ConfiguracaoScreen({super.key});

  static int _maxEspioes(int jogadores) =>
      (jogadores - 3).clamp(1, AppConstants.maxJogadores);

  static String _recomendacao(int n) {
    if (n < AppConstants.minJogadores) {
      return 'Com ${AppConstants.minJogadores} ou mais pessoas já dá para '
          'jogar.';
    }
    if (n <= 6) return 'Com $n jogadores, 1 espião funciona bem.';
    if (n <= 9) return 'Com $n jogadores, 1 ou 2 espiões funcionam bem.';
    return 'Com $n jogadores, 2 ou 3 espiões funcionam bem.';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ConfiguracaoProvider>();
    return TelaQuemVaiJogar(
      nomeDoJogo: 'Quem é o Espião?',
      matiz: Matiz.violeta,
      minimo: AppConstants.minJogadores,
      maximo: AppConstants.maxJogadores,
      nomesSalvos: () async {
        await provider.carregarConfiguracao();
        return provider.configuracao.nomesJogadores;
      },
      extras: (context, n) {
        final espioes = context.select<ConfiguracaoProvider, int>(
          (p) => p.configuracao.quantidadeEspioes,
        );
        final max = _maxEspioes(n);
        return CartaoConfig(
          icone: Symbols.person_search_rounded,
          titulo: 'Espiões',
          subtitulo: _recomendacao(n),
          luz: context.cores.luz(Matiz.violeta),
          controleNaLinha: true,
          controle: Contador(
            valor: espioes.clamp(1, max),
            minimo: 1,
            maximo: max,
            rotulo: 'espiões',
            aoMudar: provider.setQuantidadeEspioes,
          ),
        );
      },
      aoContinuar: (nomes) async {
        final max = _maxEspioes(nomes.length);
        provider
          ..setNomesJogadores(nomes)
          ..setQuantidadeJogadores(nomes.length);
        if (provider.configuracao.quantidadeEspioes > max) {
          provider.setQuantidadeEspioes(max);
        }
        await provider.salvar();
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const EspiaoAjustesScreen()),
        );
      },
    );
  }
}
