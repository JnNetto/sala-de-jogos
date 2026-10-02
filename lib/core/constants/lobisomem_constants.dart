class LobisomemConstants {
  static const String jogoNome = 'Lobisomem';
  static const String jogoDescricao =
      'A aldeia discute de dia e os lobisomens atacam à noite';

  static const int minJogadores = 5;
  static const int maxJogadores = 12;
  static const int minLobisomens = 1;
  static const int timerDiscussaoMinMinutos = 3;
  static const int timerDiscussaoMaxMinutos = 10;
  static const int timerDiscussaoPadraoMinutos = 5;
  static const int segundosDefesaEmpate = 30;

  static const String prefsKeyConfiguracao = 'lobisomem_configuracao';

  static const String aberturaNoite =
      'A aldeia adormece. Todos fechem os olhos e permaneçam em silêncio.';
  static const String ponteNoite =
      'O celular vai passar de mão em mão. Cada pessoa viva olha só a própria tela, decide em silêncio e devolve o aparelho sem comentar o que viu.';
  static const String amanhecerSemVitimas =
      'A aldeia amanheceu sem vítimas.';
  static const String aberturaDiscussao =
      'O dia começa. Os vivos podem discutir, acusar e se defender. Quem já partiu assiste em silêncio.';
  static const String chamadaVotacao =
      'A discussão terminou. Cada pessoa viva vai votar, uma de cada vez, neste celular.';
  static const String desfechoAldeia =
      'A aldeia venceu. Os lobisomens foram expulsos.';
  static const String desfechoLobisomens =
      'Os lobisomens dominaram a aldeia.';
  static const String desfechoEmpate =
      'Ninguém restou. A história termina sem vencedores.';

  static int lobisomensRecomendados(int quantidadeJogadores) {
    if (quantidadeJogadores <= 6) return 1;
    if (quantidadeJogadores <= 9) return 2;
    return 3;
  }

  static bool videnteRecomendada(int quantidadeJogadores) {
    return quantidadeJogadores >= minJogadores;
  }

  static bool bruxaRecomendada(int quantidadeJogadores) {
    return quantidadeJogadores >= 10;
  }

  static bool cacadorRecomendado(int quantidadeJogadores) {
    return quantidadeJogadores >= 7;
  }

  static int maxLobisomens(int quantidadeJogadores) {
    return (quantidadeJogadores - 1) ~/ 2;
  }

  static int maxEspeciaisAleatorios(int quantidadeJogadores) {
    final peloDiferenca = quantidadeJogadores - 4;
    if (peloDiferenca < 0) return 0;
    final pool = 5; // vidente, bruxa, caçador, bobo, ancião
    return peloDiferenca < pool ? peloDiferenca : pool;
  }

  static int quantidadeAldeoes({
    required int quantidadeJogadores,
    required int quantidadeLobisomens,
    required bool temVidente,
    required bool temBruxa,
    required bool temCacador,
    required bool temBobo,
    required bool temAnciao,
  }) {
    return quantidadeJogadores -
        quantidadeLobisomens -
        (temVidente ? 1 : 0) -
        (temBruxa ? 1 : 0) -
        (temCacador ? 1 : 0) -
        (temBobo ? 1 : 0) -
        (temAnciao ? 1 : 0);
  }

  static String juntarNomes(List<String> nomes) {
    if (nomes.isEmpty) return '';
    if (nomes.length == 1) return nomes.first;
    if (nomes.length == 2) return '${nomes[0]} e ${nomes[1]}';
    return '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}';
  }

  LobisomemConstants._();
}
