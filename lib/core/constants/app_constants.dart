class AppConstants {
  static const String appName = 'Sala de Jogos';
  /// Igual ao `version` do pubspec.yaml (sem o número do build).
  static const String appVersion = '2.1.9';

  static const String jogoEspiaoNome = 'Quem é o Espião?';
  static const String jogoEspiaoDescricao = 'Um de vocês não sabe onde está.';

  static const String jogoPerguntaNome = 'Pergunta Impostora';
  static const String jogoPerguntaDescricao =
      'Alguém respondeu outra pergunta.';

  static const String jogoQuizNome = 'Quiz da Vez';
  static const String jogoQuizDescricao = 'Perguntas rápidas, um celular.';

  static const String jogoResistenciaNome = 'Expedição';
  static const String jogoResistenciaDescricao =
      'Câmaras, votos e saqueadores.';

  static const String jogoSoUmaNome = 'Eco!';
  static const String jogoSoUmaDescricao = 'Uma dica cada, sem repetir.';

  static const String jogoLobisomemNome = 'Lobisomem';
  static const String jogoLobisomemDescricao =
      'A aldeia dorme, os lobos caçam.';

  static const String jogoAneisNome = 'Cabe Aqui?';
  static const String jogoAneisDescricao =
      'Encaixe as cartas e descubra as regras.';

  /// As páginas públicas do app (Firebase Hosting).
  static const String urlSite = 'https://sala-de-jogos-7298f.web.app';
  static const String urlPrivacidade = '$urlSite/privacidade.html';
  static const String urlExcluirConta = '$urlSite/excluir-conta.html';

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
