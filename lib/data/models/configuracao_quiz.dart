import '../../core/constants/quiz_da_vez_constants.dart';
import '../../core/enums/modo_passe_quiz.dart';

class ConfiguracaoQuiz {
  final int quantidadeJogadores;
  final int perguntasPorJogador;
  final int tempoPerguntaSegundos;
  final ModoPasseQuiz modoPasse;
  final bool mostrarPlacarAposRodada;
  final List<String> categoriasAtivas;
  final List<int> dificuldadesAtivas;
  final List<String> nomesJogadores;

  ConfiguracaoQuiz({
    this.quantidadeJogadores = 4,
    this.perguntasPorJogador = QuizDaVezConstants.defaultPerguntasPorJogador,
    this.tempoPerguntaSegundos =
        QuizDaVezConstants.tempoPerguntaDefaultSegundos,
    this.modoPasse = ModoPasseQuiz.alvoLivre,
    this.mostrarPlacarAposRodada = true,
    this.categoriasAtivas = const [],
    this.dificuldadesAtivas = const [1, 2, 3],
    this.nomesJogadores = const [],
  });

  int get totalRodadas => quantidadeJogadores * perguntasPorJogador;

  ConfiguracaoQuiz copyWith({
    int? quantidadeJogadores,
    int? perguntasPorJogador,
    int? tempoPerguntaSegundos,
    ModoPasseQuiz? modoPasse,
    bool? mostrarPlacarAposRodada,
    List<String>? categoriasAtivas,
    List<int>? dificuldadesAtivas,
    List<String>? nomesJogadores,
  }) {
    return ConfiguracaoQuiz(
      quantidadeJogadores: quantidadeJogadores ?? this.quantidadeJogadores,
      perguntasPorJogador: perguntasPorJogador ?? this.perguntasPorJogador,
      tempoPerguntaSegundos:
          tempoPerguntaSegundos ?? this.tempoPerguntaSegundos,
      modoPasse: modoPasse ?? this.modoPasse,
      mostrarPlacarAposRodada:
          mostrarPlacarAposRodada ?? this.mostrarPlacarAposRodada,
      categoriasAtivas: categoriasAtivas ?? this.categoriasAtivas,
      dificuldadesAtivas: dificuldadesAtivas ?? this.dificuldadesAtivas,
      nomesJogadores: nomesJogadores ?? this.nomesJogadores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantidadeJogadores': quantidadeJogadores,
      'perguntasPorJogador': perguntasPorJogador,
      'tempoPerguntaSegundos': tempoPerguntaSegundos,
      'modoPasse': modoPasse.name,
      'mostrarPlacarAposRodada': mostrarPlacarAposRodada,
      'categoriasAtivas': categoriasAtivas,
      'dificuldadesAtivas': dificuldadesAtivas,
      'nomesJogadores': nomesJogadores,
    };
  }

  factory ConfiguracaoQuiz.fromJson(Map<String, dynamic> json) {
    return ConfiguracaoQuiz(
      quantidadeJogadores: json['quantidadeJogadores'] as int? ?? 4,
      perguntasPorJogador:
          json['perguntasPorJogador'] as int? ??
          QuizDaVezConstants.defaultPerguntasPorJogador,
      tempoPerguntaSegundos:
          json['tempoPerguntaSegundos'] as int? ??
          QuizDaVezConstants.tempoPerguntaDefaultSegundos,
      modoPasse: ModoPasseQuiz.values.firstWhere(
        (m) => m.name == json['modoPasse'],
        orElse: () => ModoPasseQuiz.alvoLivre,
      ),
      mostrarPlacarAposRodada: json['mostrarPlacarAposRodada'] as bool? ?? true,
      categoriasAtivas:
          (json['categoriasAtivas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      dificuldadesAtivas:
          (json['dificuldadesAtivas'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [1, 2, 3],
      nomesJogadores:
          (json['nomesJogadores'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  String? getValidationError() {
    if (quantidadeJogadores < QuizDaVezConstants.minJogadores ||
        quantidadeJogadores > QuizDaVezConstants.maxJogadores) {
      return 'Jogadores devem estar entre ${QuizDaVezConstants.minJogadores} e ${QuizDaVezConstants.maxJogadores}';
    }
    if (perguntasPorJogador < QuizDaVezConstants.minPerguntasPorJogador ||
        perguntasPorJogador > QuizDaVezConstants.maxPerguntasPorJogador) {
      return 'Perguntas por jogador inválidas';
    }
    if (tempoPerguntaSegundos < QuizDaVezConstants.tempoPerguntaMinSegundos) {
      return 'Tempo por pergunta muito curto';
    }
    if (dificuldadesAtivas.isEmpty) {
      return 'Selecione pelo menos uma dificuldade';
    }
    return null;
  }
}
