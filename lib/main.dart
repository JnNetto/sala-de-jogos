import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/service_locator.dart';
import 'firebase_options.dart';
import 'presentation/providers/categoria_provider.dart';
import 'presentation/providers/configuracao_provider.dart';
import 'presentation/providers/partida_provider.dart';
import 'presentation/providers/pergunta_categoria_provider.dart';
import 'presentation/providers/pergunta_configuracao_provider.dart';
import 'presentation/providers/pergunta_partida_provider.dart';
import 'presentation/providers/quiz_categoria_provider.dart';
import 'presentation/providers/quiz_configuracao_provider.dart';
import 'presentation/providers/quiz_partida_provider.dart';
import 'presentation/providers/resistencia_partida_provider.dart';
import 'presentation/providers/resistencia_sala_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configurar app para funcionar apenas em modo retrato
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await ServiceLocator().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..carregarPreferencias(),
        ),
        ChangeNotifierProvider(create: (_) => ConfiguracaoProvider()),
        ChangeNotifierProvider(create: (_) => PartidaProvider()),
        ChangeNotifierProvider(create: (_) => CategoriaProvider()),
        ChangeNotifierProvider(create: (_) => PerguntaConfiguracaoProvider()),
        ChangeNotifierProvider(create: (_) => PerguntaPartidaProvider()),
        ChangeNotifierProvider(create: (_) => PerguntaCategoriaProvider()),
        ChangeNotifierProvider(create: (_) => QuizConfiguracaoProvider()),
        ChangeNotifierProvider(create: (_) => QuizPartidaProvider()),
        ChangeNotifierProvider(create: (_) => QuizCategoriaProvider()),
        ChangeNotifierProvider(create: (_) => ResistenciaPartidaProvider()),
        ChangeNotifierProvider(create: (_) => ResistenciaSalaProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Sala de Jogos',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
