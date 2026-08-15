import '../../core/enums/resistencia_fase.dart';
import '../../core/enums/resistencia_vencedor.dart';
import 'resistencia_jogador.dart';

class ResistenciaPartida {
  final List<ResistenciaJogador> jogadores;
  final List<int> tamanhosEquipe;
  final List<bool> resultadosMissoes;
  final List<int> fracassosPorMissao;
  final List<String> equipePropostaIds;
  final Map<String, bool> votosProposta;
  final Map<String, bool> cartasMissao;
  final bool? ultimaPropostaAprovada;
  final bool? ultimaMissaoSucesso;
  final int? ultimosFracassosMissao;
  final ResistenciaFase fase;
  final int missaoAtual;
  final int tentativaAtual;
  final int liderIndex;

  const ResistenciaPartida({
    required this.jogadores,
    required this.tamanhosEquipe,
    this.resultadosMissoes = const [],
    this.fracassosPorMissao = const [],
    this.equipePropostaIds = const [],
    this.votosProposta = const {},
    this.cartasMissao = const {},
    this.ultimaPropostaAprovada,
    this.ultimaMissaoSucesso,
    this.ultimosFracassosMissao,
    this.fase = ResistenciaFase.propondo,
    this.missaoAtual = 1,
    this.tentativaAtual = 1,
    this.liderIndex = 0,
  });

  ResistenciaJogador get liderAtual => jogadores[liderIndex];
  int get quantidadeJogadores => jogadores.length;
  int get tamanhoEquipeAtual => tamanhosEquipe[missaoAtual - 1];
  int get sucessos => resultadosMissoes.where((resultado) => resultado).length;
  int get fracassos =>
      resultadosMissoes.where((resultado) => !resultado).length;
  bool get equipeCompleta => equipePropostaIds.length == tamanhoEquipeAtual;
  bool get todosVotaram => votosProposta.length == jogadores.length;
  bool get todosJogaramMissao =>
      cartasMissao.length == equipePropostaIds.length;
  int get votosAprovacao => votosProposta.values.where((voto) => voto).length;
  int get votosRejeicao => votosProposta.values.where((voto) => !voto).length;
  bool get propostaAprovada => votosAprovacao > jogadores.length / 2;
  ResistenciaVencedor? get vencedor {
    if (sucessos >= 3) return ResistenciaVencedor.resistencia;
    if (fracassos >= 3 || fase == ResistenciaFase.finalizada) {
      return ResistenciaVencedor.espioes;
    }
    return null;
  }

  List<ResistenciaJogador> get equipeProposta {
    return jogadores
        .where((jogador) => equipePropostaIds.contains(jogador.id))
        .toList(growable: false);
  }

  bool jogadorEstaNaProposta(String jogadorId) {
    return equipePropostaIds.contains(jogadorId);
  }

  ResistenciaPartida copyWith({
    List<ResistenciaJogador>? jogadores,
    List<int>? tamanhosEquipe,
    List<bool>? resultadosMissoes,
    List<int>? fracassosPorMissao,
    List<String>? equipePropostaIds,
    Map<String, bool>? votosProposta,
    Map<String, bool>? cartasMissao,
    bool? ultimaPropostaAprovada,
    bool? ultimaMissaoSucesso,
    int? ultimosFracassosMissao,
    bool limparUltimaPropostaAprovada = false,
    bool limparUltimaMissao = false,
    ResistenciaFase? fase,
    int? missaoAtual,
    int? tentativaAtual,
    int? liderIndex,
  }) {
    return ResistenciaPartida(
      jogadores: jogadores ?? this.jogadores,
      tamanhosEquipe: tamanhosEquipe ?? this.tamanhosEquipe,
      resultadosMissoes: resultadosMissoes ?? this.resultadosMissoes,
      fracassosPorMissao: fracassosPorMissao ?? this.fracassosPorMissao,
      equipePropostaIds: equipePropostaIds ?? this.equipePropostaIds,
      votosProposta: votosProposta ?? this.votosProposta,
      cartasMissao: cartasMissao ?? this.cartasMissao,
      ultimaPropostaAprovada: limparUltimaPropostaAprovada
          ? null
          : ultimaPropostaAprovada ?? this.ultimaPropostaAprovada,
      ultimaMissaoSucesso: limparUltimaMissao
          ? null
          : ultimaMissaoSucesso ?? this.ultimaMissaoSucesso,
      ultimosFracassosMissao: limparUltimaMissao
          ? null
          : ultimosFracassosMissao ?? this.ultimosFracassosMissao,
      fase: fase ?? this.fase,
      missaoAtual: missaoAtual ?? this.missaoAtual,
      tentativaAtual: tentativaAtual ?? this.tentativaAtual,
      liderIndex: liderIndex ?? this.liderIndex,
    );
  }
}
