import '../../core/enums/resistencia_papel.dart';
import 'resistencia_jogador.dart';

class ResistenciaSorteio {
  final List<ResistenciaJogador> jogadores;
  final String liderInicialId;
  final int quantidadeEspioes;
  final List<int> tamanhosEquipe;

  const ResistenciaSorteio({
    required this.jogadores,
    required this.liderInicialId,
    required this.quantidadeEspioes,
    required this.tamanhosEquipe,
  });

  List<ResistenciaJogador> get espioes {
    return jogadores
        .where((jogador) => jogador.papel == ResistenciaPapel.espiao)
        .toList(growable: false);
  }
}
