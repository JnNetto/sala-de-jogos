class AppConstants {
  static const String appName = 'Sala de Jogos';
  static const String appVersion = '1.3.0';

  static const String jogoEspiaoNome = 'Quem é o Espião?';
  static const String jogoEspiaoDescricao =
      'Descubra quem está mentindo na rodada';

  static const String jogoPerguntaNome = 'Pergunta Impostora';
  static const String jogoPerguntaDescricao =
      'Todos respondem a mesma pergunta... exceto um';

  static const String jogoQuizNome = 'Quiz da Vez';
  static const String jogoQuizDescricao =
      'Responda ou passe — quem erra perde pontos';

  static const String jogoResistenciaNome = 'A Resistência';
  static const String jogoResistenciaDescricao =
      'Monte equipes secretas e sabote missões';

  static const int minJogadores = 4;
  static const int maxJogadores = 12;
  static const int minEspioes = 1;

  static const int duracaoExibicaoPapelSegundos = 3;
  static const int duracaoAnuncioJogadorInicialSegundos = 3;
  static const int duracaoDiscussaoDefaultSegundos = 300;
  static const int duracaoDiscussaoMinSegundos = 30;
  static const int duracaoDiscussaoMaxSegundos = 600;

  static const String prefsKeyConfiguracao = 'configuracao_partida';
  static const String prefsKeyEstatisticas = 'estatisticas';
  static const String prefsKeyPalavrasUsadas = 'palavras_usadas';
  static const String prefsKeyCategorias = 'categorias';

  AppConstants._();
}
