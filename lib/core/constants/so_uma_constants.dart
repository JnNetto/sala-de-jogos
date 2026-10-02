class SoUmaConstants {
  static const String jogoNome = 'Só uma!';
  static const String jogoDescricao =
      'Dê uma pista de uma única palavra para a palavra certa da carta';

  static const int minJogadores = 3;
  static const int maxJogadores = 7;
  static const int totalCartasPartida = 13;
  static const int palavrasPorCarta = 5;
  static const int jogadoresParaDuasPistas = 3;

  static const String prefsKeyUltimaSalaId = 'so_uma_ultima_sala_id';

  static String faixaDesempenho(int cartasGanhas) {
    if (cartasGanhas >= 13) return 'Perfeito';
    if (cartasGanhas >= 11) return 'Excelente';
    if (cartasGanhas >= 9) return 'Bom';
    if (cartasGanhas >= 7) return 'Na média';
    return 'Fraco';
  }

  SoUmaConstants._();
}
