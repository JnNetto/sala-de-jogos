import 'dart:math';

import '../../core/constants/lobisomem_constants.dart';
import '../../core/enums/lobisomem_papel.dart';
import '../models/lobisomem_configuracao.dart';
import '../models/lobisomem_jogador.dart';

class LobisomemSorteioService {
  final Random _random;

  LobisomemSorteioService({Random? random}) : _random = random ?? Random();

  ({List<LobisomemJogador> jogadores, LobisomemConfiguracao configuracao})
  sortear({
    required List<String> nomes,
    required int narradorIndex,
    required LobisomemConfiguracao configuracao,
  }) {
    final quantidade = nomes.length;
    if (!configuracao.composicaoValida(quantidade)) {
      throw ArgumentError('Composição inválida para $quantidade jogadores');
    }
    if (narradorIndex < 0 || narradorIndex >= quantidade) {
      throw ArgumentError('Escolha quem será o Narrador');
    }

    final configFinal = configuracao.papeisEspeciaisAleatorios
        ? _sortearEspeciais(quantidade, configuracao)
        : configuracao;

    final papeis = _montarPapeis(quantidade, configFinal);
    papeis.shuffle(_random);

    final jogadores = [
      for (var i = 0; i < quantidade; i++)
        LobisomemJogador(
          id: 'jogador_$i',
          nome: nomes[i].trim().isEmpty ? 'Jogador ${i + 1}' : nomes[i].trim(),
          assento: i,
          papel: papeis[i],
          ehNarrador: i == narradorIndex,
        ),
    ];

    return (jogadores: jogadores, configuracao: configFinal);
  }

  LobisomemConfiguracao _sortearEspeciais(
    int quantidadeJogadores,
    LobisomemConfiguracao configuracao,
  ) {
    final maxEspeciais = LobisomemConstants.maxEspeciaisAleatorios(
      quantidadeJogadores,
    );
    final disponivelParaEspeciais =
        quantidadeJogadores - configuracao.quantidadeLobisomens;
    final teto = maxEspeciais < disponivelParaEspeciais
        ? maxEspeciais
        : disponivelParaEspeciais;
    if (teto <= 0) {
      return configuracao.copyWith(
        temVidente: false,
        temBruxa: false,
        temCacador: false,
        temBobo: false,
        temAnciao: false,
        papeisEspeciaisAleatorios: true,
      );
    }

    final pool = [...LobisomemPapel.especiaisDisponiveis]..shuffle(_random);
    final quantidade = _random.nextInt(teto + 1);
    final escolhidos = pool.take(quantidade).toSet();

    return configuracao.copyWith(
      temVidente: escolhidos.contains(LobisomemPapel.vidente),
      temBruxa: escolhidos.contains(LobisomemPapel.bruxa),
      temCacador: escolhidos.contains(LobisomemPapel.cacador),
      temBobo: escolhidos.contains(LobisomemPapel.bobo),
      temAnciao: escolhidos.contains(LobisomemPapel.anciao),
      papeisEspeciaisAleatorios: true,
    );
  }

  List<LobisomemPapel> _montarPapeis(
    int quantidadeJogadores,
    LobisomemConfiguracao configuracao,
  ) {
    final papeis = <LobisomemPapel>[
      for (var i = 0; i < configuracao.quantidadeLobisomens; i++)
        LobisomemPapel.lobisomem,
      ...configuracao.papeisEspeciaisAtivos,
    ];
    final aldeoes = configuracao.quantidadeAldeoes(quantidadeJogadores);
    if (aldeoes < 0) {
      throw ArgumentError('Há mais papéis especiais do que jogadores');
    }
    papeis.addAll(List.filled(aldeoes, LobisomemPapel.aldeao));
    if (papeis.length != quantidadeJogadores) {
      throw ArgumentError(
        'A composição precisa somar $quantidadeJogadores papéis',
      );
    }
    if (quantidadeJogadores < LobisomemConstants.minJogadores ||
        quantidadeJogadores > LobisomemConstants.maxJogadores) {
      throw ArgumentError(
        'O Lobisomem precisa de ${LobisomemConstants.minJogadores} a ${LobisomemConstants.maxJogadores} jogadores',
      );
    }
    return papeis;
  }
}
