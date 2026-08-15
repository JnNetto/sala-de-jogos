import '../../core/enums/estado_partida_quiz.dart';
import 'configuracao_quiz.dart';
import 'quiz_jogador.dart';
import 'quiz_pergunta.dart';
import 'resultado_rodada_quiz.dart';

class PartidaQuiz {
  final List<QuizJogador> jogadores;
  final ConfiguracaoQuiz configuracao;
  final EstadoPartidaQuiz estado;
  final int
  rodadaAtual; // 0-based index of completed+current; current is rodadaAtual
  final int indiceJogadorRodada; // index in jogadores for round owner
  final QuizPergunta? perguntaAtual;
  final int? alvoPasseId;
  final int tempoRestanteSegundos;
  final ResultadoRodadaQuiz? ultimoResultado;
  final List<String> perguntasUsadasNaPartida;
  final String? ultimaCategoria;

  PartidaQuiz({
    required this.jogadores,
    required this.configuracao,
    this.estado = EstadoPartidaQuiz.configuracao,
    this.rodadaAtual = 0,
    this.indiceJogadorRodada = 0,
    this.perguntaAtual,
    this.alvoPasseId,
    int? tempoRestanteSegundos,
    this.ultimoResultado,
    this.perguntasUsadasNaPartida = const [],
    this.ultimaCategoria,
  }) : tempoRestanteSegundos =
           tempoRestanteSegundos ?? configuracao.tempoPerguntaSegundos;

  int get totalRodadas => configuracao.totalRodadas;

  int get rodadaExibicao => rodadaAtual + 1;

  bool get partidaFinalizada => rodadaAtual >= totalRodadas;

  QuizJogador get jogadorDaRodada => jogadores[indiceJogadorRodada];

  QuizJogador? get alvoDoPasse {
    if (alvoPasseId == null) return null;
    try {
      return jogadores.firstWhere((j) => j.id == alvoPasseId);
    } catch (_) {
      return null;
    }
  }

  List<QuizJogador> get ranking {
    final lista = List<QuizJogador>.from(jogadores);
    lista.sort((a, b) => b.pontos.compareTo(a.pontos));
    return lista;
  }

  bool get fimDeVoltaCompleta {
    // After completing a round, if next owner would wrap: (indice+1) % n == 0
    // Called after advancing: rodadaAtual already incremented.
    // Volta completa when rodadaAtual % quantidadeJogadores == 0 && rodadaAtual > 0
    return rodadaAtual > 0 &&
        rodadaAtual % configuracao.quantidadeJogadores == 0;
  }

  PartidaQuiz copyWith({
    List<QuizJogador>? jogadores,
    ConfiguracaoQuiz? configuracao,
    EstadoPartidaQuiz? estado,
    int? rodadaAtual,
    int? indiceJogadorRodada,
    QuizPergunta? perguntaAtual,
    int? alvoPasseId,
    bool limparAlvo = false,
    int? tempoRestanteSegundos,
    ResultadoRodadaQuiz? ultimoResultado,
    bool limparResultado = false,
    List<String>? perguntasUsadasNaPartida,
    String? ultimaCategoria,
    bool limparPergunta = false,
  }) {
    return PartidaQuiz(
      jogadores: jogadores ?? this.jogadores,
      configuracao: configuracao ?? this.configuracao,
      estado: estado ?? this.estado,
      rodadaAtual: rodadaAtual ?? this.rodadaAtual,
      indiceJogadorRodada: indiceJogadorRodada ?? this.indiceJogadorRodada,
      perguntaAtual: limparPergunta
          ? null
          : (perguntaAtual ?? this.perguntaAtual),
      alvoPasseId: limparAlvo ? null : (alvoPasseId ?? this.alvoPasseId),
      tempoRestanteSegundos:
          tempoRestanteSegundos ?? this.tempoRestanteSegundos,
      ultimoResultado: limparResultado
          ? null
          : (ultimoResultado ?? this.ultimoResultado),
      perguntasUsadasNaPartida:
          perguntasUsadasNaPartida ?? this.perguntasUsadasNaPartida,
      ultimaCategoria: ultimaCategoria ?? this.ultimaCategoria,
    );
  }
}
