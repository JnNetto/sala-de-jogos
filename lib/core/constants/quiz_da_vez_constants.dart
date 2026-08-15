class QuizDaVezConstants {
  static const String jogoNome = 'Quiz da Vez';
  static const String jogoDescricao =
      'Responda ou passe — quem erra perde pontos';

  static const int minJogadores = 2;
  static const int maxJogadores = 8;
  static const int minPerguntasPorJogador = 1;
  static const int maxPerguntasPorJogador = 20;
  static const int defaultPerguntasPorJogador = 5;

  static const int tempoPerguntaDefaultSegundos = 20;
  static const int tempoPerguntaMinSegundos = 10;
  static const int tempoPerguntaMaxSegundos = 60;

  static const int pontosAcertoProprio = 2;
  static const int pontosErroProprio = -1;
  static const int pontosAcertoAlvo = 2;
  static const int pontosErroRemetenteNoAcertoAlvo = -1;
  static const int pontosErroAlvo = -1;
  static const int pontosAcertoRemetenteNoErroAlvo = 1;

  static const String prefsKeyConfiguracao = 'quiz_configuracao';
  static const String prefsKeyPerguntasUsadas = 'quiz_perguntas_usadas';
  static const String assetBanco = 'assets/quiz_da_vez_banco.json';

  QuizDaVezConstants._();
}
