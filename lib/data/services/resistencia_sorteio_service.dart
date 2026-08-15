import 'dart:math';

import '../../core/constants/resistencia_constants.dart';
import '../../core/enums/resistencia_papel.dart';
import '../models/resistencia_jogador.dart';
import '../models/resistencia_sorteio.dart';

class ResistenciaSorteioService {
  final Random _random;

  ResistenciaSorteioService({Random? random}) : _random = random ?? Random();

  ResistenciaSorteio sortear(List<ResistenciaJogador> jogadores) {
    final quantidadeJogadores = jogadores.length;
    if (quantidadeJogadores < ResistenciaConstants.minJogadores ||
        quantidadeJogadores > ResistenciaConstants.maxJogadores) {
      throw ArgumentError('A Resistência precisa de 5 a 10 jogadores');
    }

    final jogadoresEmbaralhados = _embaralhar(jogadores);
    final papeis = _sortearPapeis(quantidadeJogadores);
    final jogadoresComPapeis = <ResistenciaJogador>[];

    for (var i = 0; i < jogadoresEmbaralhados.length; i++) {
      jogadoresComPapeis.add(
        jogadoresEmbaralhados[i].copyWith(assento: i, papel: papeis[i]),
      );
    }

    return ResistenciaSorteio(
      jogadores: List.unmodifiable(jogadoresComPapeis),
      liderInicialId: jogadoresComPapeis.first.id,
      quantidadeEspioes: ResistenciaConstants.quantidadeEspioes(
        quantidadeJogadores,
      ),
      tamanhosEquipe: ResistenciaConstants.tamanhosEquipe(quantidadeJogadores),
    );
  }

  List<ResistenciaPapel> _sortearPapeis(int quantidadeJogadores) {
    final quantidadeEspioes = ResistenciaConstants.quantidadeEspioes(
      quantidadeJogadores,
    );
    final papeis = <ResistenciaPapel>[
      for (var i = 0; i < quantidadeEspioes; i++) ResistenciaPapel.espiao,
      for (var i = 0; i < quantidadeJogadores - quantidadeEspioes; i++)
        ResistenciaPapel.resistencia,
    ];
    return _embaralhar(papeis);
  }

  List<T> _embaralhar<T>(List<T> itens) {
    final embaralhados = List<T>.from(itens);
    embaralhados.shuffle(_random);
    return embaralhados;
  }
}
