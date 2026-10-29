class AppConstants {
  static const String appName = 'Sala de Jogos';
  static const String appVersion = '1.3.0';

  static const String jogoEspiaoNome = 'Quem é o Espião?';
  static const String jogoEspiaoDescricao = 'Um de vocês não sabe onde está.';

  static const String jogoPerguntaNome = 'Pergunta Impostora';
  static const String jogoPerguntaDescricao =
      'Alguém respondeu outra pergunta.';

  static const String jogoQuizNome = 'Quiz da Vez';
  static const String jogoQuizDescricao = 'Perguntas rápidas, um celular.';

  static const String jogoResistenciaNome = 'A Resistência';
  static const String jogoResistenciaDescricao = 'Missões, votos e traidores.';

  static const String jogoSoUmaNome = 'Só uma!';
  static const String jogoSoUmaDescricao = 'Uma dica cada, sem repetir.';

  static const String jogoLobisomemNome = 'Lobisomem';
  static const String jogoLobisomemDescricao =
      'A aldeia dorme, os lobos caçam.';

  static const String jogoAneisNome = 'Nos Anéis';
  static const String jogoAneisDescricao =
      'Encaixe as cartas e descubra as regras.';

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
  static const String prefsKeyNomeJogador = 'jogador_nome';

  AppConstants._();
}
