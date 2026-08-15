import '../../core/constants/pergunta_impostora_constants.dart';

class ConfiguracaoPerguntaImpostora {
  final int quantidadeJogadores;
  final int quantidadeImpostores;
  final int jogadoresRestantesParaVitoriaImpostor;
  final int duracaoDiscussaoSegundos;
  final List<String> categoriasAtivasIds;
  final List<int> niveisAtivos;
  final List<String> nomesJogadores;

  ConfiguracaoPerguntaImpostora({
    this.quantidadeJogadores = 4,
    this.quantidadeImpostores = 1,
    int? jogadoresRestantesParaVitoriaImpostor,
    this.duracaoDiscussaoSegundos =
        PerguntaImpostoraConstants.duracaoDiscussaoDefaultSegundos,
    this.categoriasAtivasIds = const [],
    this.niveisAtivos = const [1, 2, 3],
    this.nomesJogadores = const [],
  }) : jogadoresRestantesParaVitoriaImpostor =
           jogadoresRestantesParaVitoriaImpostor ??
           defaultLimiarVitoriaImpostor(quantidadeJogadores);

  int get maxImpostores =>
      (quantidadeJogadores - 2).clamp(1, quantidadeJogadores);

  int get minLimiarVitoriaImpostor => quantidadeImpostores + 1;

  int get maxLimiarVitoriaImpostor => quantidadeJogadores - 1;

  static int defaultLimiarVitoriaImpostor(int quantidadeJogadores) =>
      quantidadeJogadores - 1;

  int get limiarVitoriaImpostorClamped => jogadoresRestantesParaVitoriaImpostor
      .clamp(minLimiarVitoriaImpostor, maxLimiarVitoriaImpostor);

  ConfiguracaoPerguntaImpostora copyWith({
    int? quantidadeJogadores,
    int? quantidadeImpostores,
    int? jogadoresRestantesParaVitoriaImpostor,
    int? duracaoDiscussaoSegundos,
    List<String>? categoriasAtivasIds,
    List<int>? niveisAtivos,
    List<String>? nomesJogadores,
  }) {
    return ConfiguracaoPerguntaImpostora(
      quantidadeJogadores: quantidadeJogadores ?? this.quantidadeJogadores,
      quantidadeImpostores: quantidadeImpostores ?? this.quantidadeImpostores,
      jogadoresRestantesParaVitoriaImpostor:
          jogadoresRestantesParaVitoriaImpostor ??
          this.jogadoresRestantesParaVitoriaImpostor,
      duracaoDiscussaoSegundos:
          duracaoDiscussaoSegundos ?? this.duracaoDiscussaoSegundos,
      categoriasAtivasIds: categoriasAtivasIds ?? this.categoriasAtivasIds,
      niveisAtivos: niveisAtivos ?? this.niveisAtivos,
      nomesJogadores: nomesJogadores ?? this.nomesJogadores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantidadeJogadores': quantidadeJogadores,
      'quantidadeImpostores': quantidadeImpostores,
      'jogadoresRestantesParaVitoriaImpostor':
          jogadoresRestantesParaVitoriaImpostor,
      'duracaoDiscussaoSegundos': duracaoDiscussaoSegundos,
      'categoriasAtivasIds': categoriasAtivasIds,
      'niveisAtivos': niveisAtivos,
      'nomesJogadores': nomesJogadores,
    };
  }

  factory ConfiguracaoPerguntaImpostora.fromJson(Map<String, dynamic> json) {
    final jogadores = json['quantidadeJogadores'] as int? ?? 4;
    return ConfiguracaoPerguntaImpostora(
      quantidadeJogadores: jogadores,
      quantidadeImpostores: json['quantidadeImpostores'] as int? ?? 1,
      jogadoresRestantesParaVitoriaImpostor:
          json['jogadoresRestantesParaVitoriaImpostor'] as int? ??
          defaultLimiarVitoriaImpostor(jogadores),
      duracaoDiscussaoSegundos:
          json['duracaoDiscussaoSegundos'] as int? ??
          PerguntaImpostoraConstants.duracaoDiscussaoDefaultSegundos,
      categoriasAtivasIds:
          (json['categoriasAtivasIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      niveisAtivos:
          (json['niveisAtivos'] as List<dynamic>?)
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

  bool isValid() => getValidationError() == null;

  String? getValidationError() {
    if (quantidadeJogadores < PerguntaImpostoraConstants.minJogadores ||
        quantidadeJogadores > PerguntaImpostoraConstants.maxJogadores) {
      return 'Quantidade de jogadores deve estar entre '
          '${PerguntaImpostoraConstants.minJogadores} e '
          '${PerguntaImpostoraConstants.maxJogadores}';
    }
    if (quantidadeImpostores < PerguntaImpostoraConstants.minImpostores) {
      return 'Deve haver pelo menos 1 impostor';
    }
    if (quantidadeImpostores > quantidadeJogadores - 2) {
      return 'Quantidade de impostores não pode exceder jogadores - 2';
    }
    if (jogadoresRestantesParaVitoriaImpostor < minLimiarVitoriaImpostor ||
        jogadoresRestantesParaVitoriaImpostor > maxLimiarVitoriaImpostor) {
      return 'Limiar de vitória do impostor inválido';
    }
    if (duracaoDiscussaoSegundos <
        PerguntaImpostoraConstants.duracaoDiscussaoMinSegundos) {
      return 'Duração da discussão deve ser de pelo menos 30 segundos';
    }
    if (niveisAtivos.isEmpty) {
      return 'Selecione pelo menos um nível de dificuldade';
    }
    return null;
  }
}
