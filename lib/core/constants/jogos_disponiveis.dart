import 'package:material_symbols_icons/symbols.dart';

import '../models/jogo_disponivel.dart';
import '../theme/sala_tokens.dart';
import 'aneis_constants.dart';
import 'app_constants.dart';
import 'lobisomem_constants.dart';
import 'pergunta_impostora_constants.dart';
import 'quiz_da_vez_constants.dart';
import 'resistencia_constants.dart';
import 'so_uma_constants.dart';

class JogosDisponiveis {
  static const String idEspiao = 'espião';
  static const String idPergunta = 'pergunta_impostora';
  static const String idQuiz = 'quiz_da_vez';
  static const String idResistencia = 'resistencia';
  static const String idSoUma = 'so_uma';
  static const String idLobisomem = 'lobisomem';
  static const String idAneis = 'aneis';

  static const List<JogoDisponivel> todos = [
    JogoDisponivel(
      id: idEspiao,
      nome: AppConstants.jogoEspiaoNome,
      descricao: AppConstants.jogoEspiaoDescricao,
      icone: Symbols.visibility_off_rounded,
      matiz: Matiz.violeta,
      minJogadores: AppConstants.minJogadores,
      maxJogadores: AppConstants.maxJogadores,
      duracaoMinutos: 10,
    ),
    JogoDisponivel(
      id: idPergunta,
      nome: AppConstants.jogoPerguntaNome,
      descricao: AppConstants.jogoPerguntaDescricao,
      icone: Symbols.help_rounded,
      matiz: Matiz.rosa,
      minJogadores: PerguntaImpostoraConstants.minJogadores,
      maxJogadores: PerguntaImpostoraConstants.maxJogadores,
      duracaoMinutos: 15,
    ),
    JogoDisponivel(
      id: idQuiz,
      nome: AppConstants.jogoQuizNome,
      descricao: AppConstants.jogoQuizDescricao,
      icone: Symbols.quiz_rounded,
      matiz: Matiz.menta,
      minJogadores: QuizDaVezConstants.minJogadores,
      maxJogadores: QuizDaVezConstants.maxJogadores,
      duracaoMinutos: 10,
    ),
    JogoDisponivel(
      id: idResistencia,
      nome: AppConstants.jogoResistenciaNome,
      descricao: AppConstants.jogoResistenciaDescricao,
      icone: Symbols.shield_rounded,
      matiz: Matiz.brasa,
      minJogadores: ResistenciaConstants.minJogadores,
      maxJogadores: ResistenciaConstants.maxJogadores,
      duracaoMinutos: 30,
    ),
    JogoDisponivel(
      id: idSoUma,
      nome: AppConstants.jogoSoUmaNome,
      descricao: AppConstants.jogoSoUmaDescricao,
      icone: Symbols.lightbulb_rounded,
      matiz: Matiz.lampada,
      minJogadores: SoUmaConstants.minJogadores,
      maxJogadores: SoUmaConstants.maxJogadores,
      duracaoMinutos: 20,
    ),
    JogoDisponivel(
      id: idLobisomem,
      nome: AppConstants.jogoLobisomemNome,
      descricao: AppConstants.jogoLobisomemDescricao,
      icone: Symbols.bedtime_rounded,
      matiz: Matiz.luar,
      minJogadores: LobisomemConstants.minJogadores,
      maxJogadores: LobisomemConstants.maxJogadores,
      duracaoMinutos: 30,
    ),
    JogoDisponivel(
      id: idAneis,
      nome: AppConstants.jogoAneisNome,
      descricao: AppConstants.jogoAneisDescricao,
      icone: Symbols.join_inner_rounded,
      matiz: Matiz.ceu,
      minJogadores: AneisConstants.minJogadores,
      maxJogadores: AneisConstants.maxJogadores,
      duracaoMinutos: 20,
      novo: true,
    ),
  ];

  JogosDisponiveis._();
}
