import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/jogos_disponiveis.dart';
import '../providers/theme_provider.dart';
import '../widgets/jogo_card.dart';
import 'impostor_home_screen.dart';
import 'pergunta_impostora/pergunta_home_screen.dart';
import 'quiz_da_vez/quiz_home_screen.dart';
import 'resistencia/resistencia_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _abrirJogo(BuildContext context, String jogoId) {
    if (jogoId == JogosDisponiveis.idEspiao) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ImpostorHomeScreen()),
      );
    } else if (jogoId == JogosDisponiveis.idPergunta) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PerguntaHomeScreen()),
      );
    } else if (jogoId == JogosDisponiveis.idQuiz) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QuizHomeScreen()),
      );
    } else if (jogoId == JogosDisponiveis.idResistencia) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ResistenciaHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  Icon(
                    Icons.sports_esports,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escolha um jogo para começar',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView(
                      children: [
                        ...JogosDisponiveis.todos.map(
                          (jogo) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: JogoCard(
                              jogo: jogo,
                              onTap: jogo.disponivel
                                  ? () => _abrirJogo(context, jogo.id)
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'v${AppConstants.appVersion}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return IconButton(
                    icon: Icon(
                      themeProvider.isDarkMode
                          ? Icons.nightlight_round
                          : Icons.wb_sunny,
                      size: 28,
                    ),
                    onPressed: () {
                      themeProvider.toggleTheme();
                    },
                    tooltip: themeProvider.isDarkMode
                        ? 'Modo claro'
                        : 'Modo escuro',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
