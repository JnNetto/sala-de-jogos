import 'package:flutter/material.dart';
import '../models/jogo_disponivel.dart';
import '../theme/app_theme.dart';
import 'app_constants.dart';

class JogosDisponiveis {
  static const String idEspiao = 'espião';
  static const String idPergunta = 'pergunta_impostora';
  static const String idQuiz = 'quiz_da_vez';
  static const String idResistencia = 'resistencia';

  static const List<JogoDisponivel> todos = [
    JogoDisponivel(
      id: idEspiao,
      nome: AppConstants.jogoEspiaoNome,
      descricao: AppConstants.jogoEspiaoDescricao,
      icone: Icons.visibility_off,
      cor: AppTheme.primaryColor,
      disponivel: true,
    ),
    JogoDisponivel(
      id: idPergunta,
      nome: AppConstants.jogoPerguntaNome,
      descricao: AppConstants.jogoPerguntaDescricao,
      icone: Icons.help_outline,
      cor: AppTheme.accentColor,
      disponivel: true,
    ),
    JogoDisponivel(
      id: idQuiz,
      nome: AppConstants.jogoQuizNome,
      descricao: AppConstants.jogoQuizDescricao,
      icone: Icons.quiz,
      cor: AppTheme.successColor,
      disponivel: true,
    ),
    JogoDisponivel(
      id: idResistencia,
      nome: AppConstants.jogoResistenciaNome,
      descricao: AppConstants.jogoResistenciaDescricao,
      icone: Icons.shield_outlined,
      cor: AppTheme.warningColor,
      disponivel: true,
    ),
  ];

  JogosDisponiveis._();
}
