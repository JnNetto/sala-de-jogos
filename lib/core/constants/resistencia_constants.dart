class ResistenciaConstants {
  static const String jogoNome = 'A Resistência';
  static const String jogoDescricao =
      'Proponha equipes, vote nas missões e encontre os espiões';

  static const int minJogadores = 5;
  static const int maxJogadores = 10;
  static const int totalMissoes = 5;
  static const int vitoriasNecessarias = 3;
  static const int maxRejeicoes = 5;

  static const Map<int, int> quantidadeEspioesPorJogadores = {
    5: 2,
    6: 2,
    7: 3,
    8: 3,
    9: 3,
    10: 4,
  };

  static const Map<int, List<int>> tamanhosEquipePorJogadores = {
    5: [2, 3, 2, 3, 3],
    6: [2, 3, 4, 3, 4],
    7: [2, 3, 3, 4, 4],
    8: [3, 4, 4, 5, 5],
    9: [3, 4, 4, 5, 5],
    10: [3, 4, 4, 5, 5],
  };

  static int quantidadeEspioes(int quantidadeJogadores) {
    final quantidade = quantidadeEspioesPorJogadores[quantidadeJogadores];
    if (quantidade == null) {
      throw ArgumentError('A Resistência precisa de 5 a 10 jogadores');
    }
    return quantidade;
  }

  static List<int> tamanhosEquipe(int quantidadeJogadores) {
    final tamanhos = tamanhosEquipePorJogadores[quantidadeJogadores];
    if (tamanhos == null) {
      throw ArgumentError('A Resistência precisa de 5 a 10 jogadores');
    }
    return List.unmodifiable(tamanhos);
  }

  static int fracassosNecessariosParaFalhar({
    required int missao,
    required int quantidadeJogadores,
  }) {
    if (missao == 4 && quantidadeJogadores >= 7) {
      return 2;
    }
    return 1;
  }

  ResistenciaConstants._();
}
