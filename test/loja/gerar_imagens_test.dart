// Gera as imagens da loja (prints com legenda e a imagem de destaque) a
// partir das telas reais do app. Não roda com o `flutter test` normal:
//
//   $env:GERAR_LOJA=1; flutter test test/loja/gerar_imagens_test.dart
//
// Saída em loja/imagens/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impostor_app/core/constants/jogos_disponiveis.dart';
import 'package:impostor_app/core/theme/app_theme.dart';
import 'package:impostor_app/core/utils/service_locator.dart';
import 'package:impostor_app/data/models/aneis_carta_publica.dart';
import 'package:impostor_app/data/models/aneis_estado_remoto.dart';
import 'package:impostor_app/data/models/aneis_jogador_remoto.dart';
import 'package:impostor_app/data/models/aneis_knower_view.dart';
import 'package:impostor_app/data/models/aneis_sala.dart';
import 'package:impostor_app/data/models/resistencia_estado_remoto.dart';
import 'package:impostor_app/data/models/resistencia_jogador_remoto.dart';
import 'package:impostor_app/data/models/resistencia_privado.dart';
import 'package:impostor_app/data/models/resistencia_proposta_remota.dart';
import 'package:impostor_app/data/models/resistencia_sala.dart';
import 'package:impostor_app/data/models/so_uma_estado_remoto.dart';
import 'package:impostor_app/data/models/so_uma_jogador_remoto.dart';
import 'package:impostor_app/data/models/so_uma_sala.dart';
import 'package:impostor_app/data/services/aneis_firebase_service.dart';
import 'package:impostor_app/data/services/resistencia_firebase_service.dart';
import 'package:impostor_app/data/services/so_uma_firebase_service.dart';
import 'package:impostor_app/presentation/providers/aneis_sala_provider.dart';
import 'package:impostor_app/presentation/providers/resistencia_sala_provider.dart';
import 'package:impostor_app/presentation/providers/so_uma_partida_provider.dart';
import 'package:impostor_app/presentation/providers/so_uma_sala_provider.dart';
import 'package:impostor_app/presentation/providers/theme_provider.dart';
import 'package:impostor_app/presentation/screens/aneis/aneis_sala_router_screen.dart';
import 'package:impostor_app/presentation/screens/expedicao/expedicao_sala_router_screen.dart';
import 'package:impostor_app/presentation/screens/jogos_screen.dart';
import 'package:impostor_app/presentation/screens/so_uma/so_uma_partida_screen.dart';
import 'package:impostor_app/presentation/screens/so_uma/so_uma_sala_router_screen.dart';
import 'package:impostor_app/presentation/screens/tela_inicial_screen.dart';
import 'package:impostor_app/presentation/widgets/sala/marca.dart';
import 'package:impostor_app/presentation/widgets/sala/palco_da_sala.dart';
import 'package:impostor_app/presentation/widgets/sala/selo_papel.dart';
import 'package:impostor_app/presentation/widgets/sala/tela_de_revelacao.dart';
import 'package:impostor_app/presentation/widgets/sala/varal.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pasta = 'loja/imagens';

// ─── Servidores de mentira para as telas online ───────────────────────────

class _Aneis implements AneisFirebaseService {
  final sala = AneisSala.fromMap('r1', {
    'code': 'KX7Q2M',
    'hostUid': 'u0',
    'status': 'playing',
  });
  @override
  String? get uid => 'u0';
  @override
  Future<AneisSala> criarSala({required String displayName}) async => sala;
  @override
  Stream<AneisSala?> observarSala(String roomId) => Stream.value(sala);
  @override
  Stream<List<AneisJogadorRemoto>> observarJogadores(String roomId) =>
      Stream.value([
        for (final (i, n) in ['Ana', 'Caio', 'Bia', 'Duda'].indexed)
          AneisJogadorRemoto.fromMap('u$i', {
            'displayName': n,
            'seat': i,
            'maoCount': 4 - i % 2,
          }),
      ]);
  @override
  Stream<AneisEstadoRemoto?> observarEstado(String roomId) => Stream.value(
    AneisEstadoRemoto.fromMap({
      'phase': 'playing',
      'currentUid': 'u0',
      'knowerMode': 'app',
      'aneis': [
        {'id': 'palavra', 'nome': 'Letra', 'subtitulo': '', 'cor': '#000000'},
        {'id': 'atributo', 'nome': 'Jeito', 'subtitulo': '', 'cor': '#000000'},
        {'id': 'contexto', 'nome': 'Lugar', 'subtitulo': '', 'cor': '#000000'},
      ],
      'tabuleiro': [
        {'coisaId': 'a', 'texto': 'Abelha', 'regiao': 'palavra_atributo'},
        {'coisaId': 'b', 'texto': 'Martelo', 'regiao': 'contexto'},
        {'coisaId': 'c', 'texto': 'Gato', 'regiao': 'nenhum'},
        {'coisaId': 'd', 'texto': 'Abacaxi', 'regiao': 'palavra'},
        {'coisaId': 'e', 'texto': 'Sol', 'regiao': 'atributo'},
      ],
      'baralhoCount': 20,
      'ultimaJogada': {
        'tipo': 'regra',
        'uid': 'u1',
        'nome': 'Caio',
        'anel': 'atributo',
        'palpite': 'É amarelo',
        'acertou': true,
        'cartasRestantes': 2,
      },
      'aneisDesvendados': [
        {'anel': 'atributo', 'nome': 'Jeito', 'texto': 'É amarelo'},
      ],
      'playerCount': 4,
    }),
  );
  @override
  Stream<List<AneisCartaPublica>> observarMao(String roomId, String uid) =>
      Stream.value([
        for (final (i, t) in ['Bicicleta', 'Limão', 'Escada', 'Pato'].indexed)
          AneisCartaPublica.fromMap({'id': 'm$i', 'texto': t}),
      ]);
  @override
  Stream<AneisKnowerView?> observarVisaoKnower(String roomId) =>
      Stream.value(null);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Eco implements SoUmaFirebaseService {
  final sala = SoUmaSala.fromMap('r1', {
    'code': 'PQ4ZTR',
    'hostUid': 'u0',
    'status': 'lobby',
  });
  @override
  String? get uid => 'u0';
  @override
  Future<SoUmaSala> criarSala({required String displayName}) async => sala;
  @override
  Stream<SoUmaSala?> observarSala(String roomId) => Stream.value(sala);
  @override
  Stream<List<SoUmaJogadorRemoto>> observarJogadores(String roomId) =>
      Stream.value([
        for (final (i, n) in ['Ana', 'Caio', 'Bia', 'Duda', 'Edu'].indexed)
          SoUmaJogadorRemoto.fromMap('u$i', {'displayName': n, 'seat': i}),
      ]);
  @override
  Stream<SoUmaEstadoRemoto?> observarEstado(String roomId) =>
      Stream.value(null);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Expedicao implements ResistenciaFirebaseService {
  ResistenciaSala get _sala => ResistenciaSala.fromMap('r1', {
    'code': 'TRL9QX',
    'hostUid': 'u0',
    'status': 'playing',
  });
  @override
  String? get uid => 'u0';
  @override
  Future<ResistenciaSala> criarSala({required String displayName}) async =>
      _sala;
  @override
  Stream<ResistenciaSala?> observarSala(String roomId) => Stream.value(_sala);
  @override
  Stream<List<ResistenciaJogadorRemoto>> observarJogadores(
    String roomId,
  ) => Stream.value([
    for (final (i, n) in ['Ana', 'Caio', 'Bia', 'Duda', 'Edu', 'Fê'].indexed)
      ResistenciaJogadorRemoto.fromMap('u$i', {'displayName': n, 'seat': i}),
  ]);
  @override
  Stream<ResistenciaPrivado?> observarMeuPrivado(String roomId) => Stream.value(
    ResistenciaPrivado.fromMap({'team': 'good', 'knowledge': []}),
  );
  @override
  Stream<ResistenciaEstadoRemoto?> observarEstado(String roomId) =>
      Stream.value(
        ResistenciaEstadoRemoto.fromMap({
          'gameId': 'g1',
          'phase': 'proposing',
          'round': 3,
          'attempt': 1,
          'leaderUid': 'u0',
          'teamSize': 4,
          'missionResults': [true, false],
          'failCounts': [0, 1],
          'lastProposalId': 'p1',
          'rejections': 1,
          'playerCount': 6,
        }),
      );
  @override
  Stream<ResistenciaPropostaRemota?> observarProposta(
    String roomId,
    String proposalId,
  ) => Stream.value(
    ResistenciaPropostaRemota.fromMap('p1', {
      'memberUids': ['u0', 'u2', 'u4'],
      'status': 'approved',
    }),
  );
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// ─── Renderização ─────────────────────────────────────────────────────────

Future<void> _fontes() async {
  Future<void> carregar(String familia, String caminho) async {
    final l = FontLoader(familia)
      ..addFont(
        Future.value(ByteData.sublistView(File(caminho).readAsBytesSync())),
      );
    await l.load();
  }

  await carregar('Nunito', 'assets/fonts/Nunito-Variable.ttf');
  await carregar('PixelifySans', 'assets/fonts/PixelifySans-Variable.ttf');
  final cache = Platform.environment['LOCALAPPDATA']!;
  await carregar(
    'packages/material_symbols_icons/MaterialSymbolsRounded',
    '$cache/Pub/Cache/hosted/pub.dev/material_symbols_icons-4.2960.0/lib/fonts/MaterialSymbolsRounded.ttf',
  );
}

var _chave = GlobalKey();

Future<void> _passos(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<ui.Image> _capturar(WidgetTester t, {double escala = 1}) async {
  late ui.Image img;
  await t.runAsync(() async {
    final ro =
        _chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    img = await ro.toImage(pixelRatio: escala);
  });
  return img;
}

Future<void> _salvar(WidgetTester t, ui.Image img, String nome) async {
  await t.runAsync(() async {
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_pasta/$nome')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// A tela do app num "celular" de 360×760 (pixels ×3).
Future<void> _montarTela(
  WidgetTester t,
  Widget tela, {
  bool dia = false,
  List<ChangeNotifierProvider> provedores = const [],
}) async {
  t.view.physicalSize = const Size(1080, 2280);
  t.view.devicePixelRatio = 3;
  _chave = GlobalKey();
  await t.pumpWidget(
    MultiProvider(
      key: UniqueKey(),
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ...provedores,
      ],
      child: RepaintBoundary(
        key: _chave,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dia ? AppTheme.dia() : AppTheme.noite(),
          navigatorObservers: [PalcoDaSala.observador],
          builder: (c, child) => PalcoDaSala(child: child!),
          home: tela,
        ),
      ),
    ),
  );
  await _passos(t, 40);
}

/// O print da loja: céu da marca, legenda em cima e a tela num celular.
Future<void> _vitrine(
  WidgetTester t,
  ui.Image tela,
  String titulo,
  String apoio,
  String nome, {
  bool dia = false,
}) async {
  t.view.physicalSize = const Size(1080, 1920);
  t.view.devicePixelRatio = 2;
  _chave = GlobalKey();
  final c = dia ? SalaCores.dia : SalaCores.noite;
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dia ? AppTheme.dia() : AppTheme.noite(),
      home: RepaintBoundary(
        key: _chave,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.ceuTopo, c.fundo, c.ceuBrilho],
                stops: const [0, .55, 1],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(36, 56, 36, 0),
            child: Column(
              children: [
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 40,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    fontVariations: const [FontVariation.weight(900)],
                    color: c.texto,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  apoio,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 21,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    fontVariations: const [FontVariation.weight(600)],
                    color: c.texto2,
                  ),
                ),
                const SizedBox(height: 36),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: dia ? c.contorno : const Color(0xFF05061A),
                          borderRadius: BorderRadius.circular(48),
                          boxShadow: [
                            BoxShadow(
                              color: (dia ? c.contorno : c.marca).withValues(
                                alpha: .35,
                              ),
                              blurRadius: 60,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(38),
                          child: SizedBox(
                            width: 360,
                            height: 760,
                            child: RawImage(image: tela, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await t.pump();
  await _salvar(t, await _capturar(t, escala: 2), nome);
}

Future<void> _print(
  WidgetTester t,
  String nome,
  String titulo,
  String apoio,
  Future<void> Function() preparar, {
  bool dia = false,
}) async {
  await preparar();
  final tela = await _capturar(t, escala: 3);
  await _vitrine(t, tela, titulo, apoio, nome, dia: dia);
}

void main() {
  final gerar = Platform.environment['GERAR_LOJA'] != null;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'aneis_tutorial_visto': true});
    await ServiceLocator().init();
    await _fontes();
    // Só os jogos que vão para a loja.
    JogosDisponiveis.mostrarEmDesenvolvimento = false;
  });

  testWidgets('prints da loja', skip: !gerar, (t) async {
    await _print(
      t,
      'prints/01-inicio.png',
      'Uma sala cheia de jogos',
      'Jogos de festa para jogar com a turma.',
      () => _montarTela(t, const TelaInicialScreen()),
    );

    await _print(
      t,
      'prints/02-jogos.png',
      'Cinco jogos para a roda',
      'De 2 a 12 pessoas, no mesmo celular ou cada um no seu.',
      () => _montarTela(t, const JogosScreen()),
    );

    await _print(
      t,
      'prints/03-espiao.png',
      'Segure para ver seu papel',
      'Só você vê a palavra. O espião vai ter que blefar.',
      () async {
        await _montarTela(
          t,
          TelaDeRevelacao(
            nomeDoJogo: 'Quem é o Espião?',
            matiz: Matiz.violeta,
            nomes: const ['Ana', 'Caio', 'Bia', 'Duda', 'Edu'],
            espiao: (i) => false,
            aoVoltar: () {},
            aoAbortar: () {},
            frente: (context, i, esconder, efeito) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SeloPapel.civil(context, texto: 'VOCÊ É CIVIL'),
                const SizedBox(height: 24),
                Icon(
                  Symbols.key_rounded,
                  size: 60,
                  fill: 1,
                  color: context.cores.papelCivil.tinta,
                ),
                const SizedBox(height: 24),
                BlocoPalavra(
                  palavra: 'Pizzaria',
                  luz: context.cores.papelCivil,
                ),
              ],
            ),
            fim: (context) => const SizedBox(),
          ),
        );
        final dedo = await t.startGesture(
          t.getCenter(find.byIcon(Symbols.fingerprint_rounded)),
        );
        await _passos(t, 20);
        await dedo.up();
        await _passos(t, 10);
      },
    );

    await _print(
      t,
      'prints/04-eco.png',
      'Uma pista, uma palavra',
      'No Eco!, pistas repetidas se anulam. Combinem sem combinar.',
      () async {
        final eco = SoUmaPartidaProvider();
        await t.runAsync(
          () => eco.iniciarNovaPartida(['Ana', 'Caio', 'Bia', 'Duda']),
        );
        eco.escolherNumero(3);
        await _montarTela(
          t,
          const SoUmaPartidaScreen(),
          provedores: [
            ChangeNotifierProvider<SoUmaPartidaProvider>.value(value: eco),
          ],
        );
        await t.tap(find.text('Sou eu'));
        await _passos(t);
        await t.enterText(find.byType(TextField), 'Trovão');
        await _passos(t, 3);
        FocusManager.instance.primaryFocus?.unfocus();
        await _passos(t, 6);
      },
    );

    await _print(
      t,
      'prints/05-cabe-aqui.png',
      'Descubra as regras secretas',
      'No Cabe Aqui?, cada carta tem seu lugar nos três anéis.',
      () async {
        final p = AneisSalaProvider(service: _Aneis());
        await t.runAsync(() => p.criarSala('x'));
        await _montarTela(
          t,
          const AneisSalaRouterScreen(),
          provedores: [
            ChangeNotifierProvider<AneisSalaProvider>.value(value: p),
          ],
        );
      },
    );

    await _print(
      t,
      'prints/06-expedicao.png',
      'Quem é o saqueador?',
      'Na Expedição, monte a equipe certa para explorar as câmaras.',
      () async {
        final p = ResistenciaSalaProvider(service: _Expedicao());
        await t.runAsync(() async {
          await p.criarSala('x');
          await p.marcarPapelRevelado('g1');
          await p.marcarResultadoPropostaVisto('g1', 'p1');
          await p.marcarResultadoMissaoVisto('g1', 2);
        });
        await _montarTela(
          t,
          const ExpedicaoSalaRouterScreen(),
          provedores: [
            ChangeNotifierProvider<ResistenciaSalaProvider>.value(value: p),
          ],
        );
        for (final nome in ['Ana', 'Caio', 'Bia', 'Duda']) {
          await t.tap(find.text(nome));
        }
        await _passos(t, 6);
      },
    );

    await _print(
      t,
      'prints/07-online.png',
      'Cada um no seu celular',
      'Crie uma sala online e passe o código para a turma.',
      () async {
        final p = SoUmaSalaProvider(service: _Eco());
        await t.runAsync(() => p.criarSala('x'));
        await _montarTela(
          t,
          const SoUmaSalaRouterScreen(),
          provedores: [
            ChangeNotifierProvider<SoUmaSalaProvider>.value(value: p),
          ],
        );
      },
    );

    await _print(
      t,
      'prints/08-tema-dia.png',
      'Tema Noite e tema Dia',
      'Escolha o clima da sua sala.',
      () => _montarTela(t, const JogosScreen(), dia: true),
      dia: true,
    );
  });

  testWidgets('imagem de destaque', skip: !gerar, (t) async {
    t.view.physicalSize = const Size(1024, 500);
    t.view.devicePixelRatio = 2;
    _chave = GlobalKey();
    const c = SalaCores.noite;
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.noite(),
        home: RepaintBoundary(
          key: _chave,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 1.4),
                  radius: 1.3,
                  colors: [
                    Color(0xFF2C2A82),
                    Color(0xFF0D0F2B),
                    Color(0xFF070822),
                  ],
                  stops: [0, .55, 1],
                ),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 4,
                    child: Varal.decorativo(),
                  ),
                  Positioned.fill(
                    top: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Marca(tamanho: 170),
                        const SizedBox(width: 18),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sala de Jogos',
                              style: TextStyle(
                                fontFamily: 'PixelifySans',
                                fontSize: 40,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                fontVariations: const [
                                  FontVariation.weight(700),
                                ],
                                color: c.texto,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Jogos de festa para jogar em grupo',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontVariations: const [
                                  FontVariation.weight(700),
                                ],
                                color: c.texto2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await _passos(t, 30);
    await _salvar(t, await _capturar(t, escala: 2), 'destaque-1024x500.png');
  });
}
