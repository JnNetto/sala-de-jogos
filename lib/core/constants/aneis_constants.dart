import 'package:flutter/material.dart';

class AneisConstants {
  static const String jogoNome = 'Nos Anéis';
  static const String jogoDescricao =
      'Encaixe as cartas no diagrama e descubra as regras secretas';

  static const int minJogadores = 2;
  static const int maxJogadores = 6;
  static const int cartasPorMao = 5;
  static const int pistasIniciais = 3;
  static const int cartasSetupKnower = 5;

  static const String knowerJogador = 'jogador';
  static const String knowerApp = 'app';

  static const String prefsKeyUltimaSalaId = 'aneis_ultima_sala_id';
  static const String prefsKeyTutorialVisto = 'aneis_tutorial_visto';

  static const Color corPalavra = Color(0xFF3B82F6);
  static const Color corAtributo = Color(0xFFF59E0B);
  static const Color corContexto = Color(0xFFEC4899);
  static const Color corNenhum = Color(0xFF94A3B8);

  static const List<String> dificuldades = ['facil', 'medio', 'dificil'];

  static String rotuloDificuldade(String valor) {
    switch (valor) {
      case 'medio':
        return 'Médio';
      case 'dificil':
        return 'Difícil';
      default:
        return 'Fácil';
    }
  }

  static String rotuloKnowerMode(String valor) {
    return valor == knowerApp ? 'O próprio jogo' : 'Um jogador';
  }

  static String descricaoKnowerMode(String valor) {
    if (valor == knowerApp) {
      return 'O app conhece as regras, coloca as pistas e posiciona cada carta automaticamente.';
    }
    return 'Uma pessoa da sala é sorteada. Ela vê as regras, recebe cartas aleatórias para as 3 pistas e decide onde cada palavra dos outros vai.';
  }

  AneisConstants._();
}
