class QuizPergunta {
  final String id;
  final String categoria;
  final String subcategoria;
  final int dificuldade;
  final String pergunta;
  final List<String> alternativas;
  final int respostaCorreta;
  final String? explicacao;

  const QuizPergunta({
    required this.id,
    required this.categoria,
    required this.subcategoria,
    required this.dificuldade,
    required this.pergunta,
    required this.alternativas,
    required this.respostaCorreta,
    this.explicacao,
  });

  factory QuizPergunta.fromJson(Map<String, dynamic> json) {
    return QuizPergunta(
      id: json['id'] as String,
      categoria: json['categoria'] as String,
      subcategoria: json['subcategoria'] as String? ?? '',
      dificuldade: _parseDificuldade(json['dificuldade'] ?? json['nivel']),
      pergunta: json['pergunta'] as String,
      alternativas: (json['alternativas'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      respostaCorreta: json['resposta_correta'] as int,
      explicacao: json['explicacao'] as String?,
    );
  }

  static int _parseDificuldade(dynamic value) {
    if (value is int) return value.clamp(1, 3);
    final texto = value?.toString().toLowerCase().trim() ?? '';
    switch (texto) {
      case '1':
      case 'facil':
      case 'fácil':
        return 1;
      case '3':
      case 'dificil':
      case 'difícil':
        return 3;
      case '2':
      case 'medio':
      case 'méMédio':
      default:
        return 2;
    }
  }

  bool isCorreta(int indice) => indice == respostaCorreta;

  String get textoRespostaCorreta =>
      (respostaCorreta >= 0 && respostaCorreta < alternativas.length)
      ? alternativas[respostaCorreta]
      : '';
}
