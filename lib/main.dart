import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/service_locator.dart';
import 'firebase_options.dart';
import 'firebase_options_env.dart';
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
import 'presentation/providers/lobisomem_partida_provider.dart';
import 'presentation/providers/so_uma_partida_provider.dart';
import 'presentation/providers/so_uma_sala_provider.dart';
import 'presentation/providers/aneis_sala_provider.dart';
import 'presentation/providers/conta_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/widgets/sala/palco_da_sala.dart';
import 'presentation/widgets/sala/troca_de_tema.dart';

FirebaseOptions _firebaseOptions() {
  try {
    return EnvFirebaseOptions.currentPlatform;
  } on StateError {
    return DefaultFirebaseOptions.currentPlatform;
  }
}

/// O App Check prova para o Firebase que a chamada vem do app de verdade,
/// num aparelho de verdade (e não de um script com a chave de API). Em
/// debug, usa o provedor de depuração: o token aparece no log e precisa ser
/// cadastrado no console. Na web, ficaria a cargo do reCAPTCHA.
Future<void> _ativarAppCheck() async {
  if (kIsWeb) return;
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (_) {
    // Sem App Check o app segue; o servidor decide se aceita a chamada.
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: _firebaseOptions());
  await _ativarAppCheck();

  // Configurar app para funcionar apenas em modo retrato
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await ServiceLocator().init();

  // O tema salvo carrega antes do primeiro quadro: a splash já nasce nele.
  final tema = ThemeProvider();
  await tema.carregarPreferencias();

  runApp(MyApp(tema: tema));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.tema});

  final ThemeProvider tema;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: tema),
        ChangeNotifierProvider(create: (_) => ContaProvider()),
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
        ChangeNotifierProvider(create: (_) => SoUmaPartidaProvider()),
        ChangeNotifierProvider(create: (_) => SoUmaSalaProvider()),
        ChangeNotifierProvider(create: (_) => LobisomemPartidaProvider()),
        ChangeNotifierProvider(create: (_) => AneisSalaProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Sala de Jogos',
            theme: AppTheme.dia(),
            darkTheme: AppTheme.noite(),
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            // A troca é feita pela TrocaDeTema; interpolar o ThemeData do
            // app inteiro a cada quadro é o que travava.
            themeAnimationDuration: Duration.zero,
            navigatorObservers: [PalcoDaSala.observador],
            builder: (context, child) =>
                TrocaDeTema(child: PalcoDaSala(child: child!)),
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
