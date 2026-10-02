import 'aneis_anel_publico.dart';
import 'aneis_carta_tabuleiro.dart';
import 'aneis_pending_jogada.dart';
import 'aneis_regra_revelada.dart';
import 'aneis_ultima_jogada.dart';

class AneisEstadoRemoto {
  final String gameId;
  final String phase;
  final String currentUid;
  final String dificuldade;
  final String knowerMode;
  final String? knowerUid;
  final String? knowerNome;
  final List<AneisAnelPublico> aneis;
  final List<AneisCartaTabuleiro> tabuleiro;
  final int baralhoCount;
  final AneisUltimaJogada? ultimaJogada;
  final AneisPendingJogada? pendingJogada;
  final bool reversivel;
  final String? vencedorUid;
  final String? vencedorNome;
  final List<AneisRegraRevelada> regrasReveladas;
  final int playerCount;

  const AneisEstadoRemoto({
    required this.gameId,
    required this.phase,
    required this.currentUid,
    required this.dificuldade,
    this.knowerMode = 'jogador',
    this.knowerUid,
    this.knowerNome,
    required this.aneis,
    required this.tabuleiro,
    required this.baralhoCount,
    this.ultimaJogada,
    this.pendingJogada,
    this.reversivel = false,
    this.vencedorUid,
    this.vencedorNome,
    this.regrasReveladas = const [],
    required this.playerCount,
  });

  bool get terminou => phase == 'over';
  bool get knowerHumano => knowerMode == 'jogador' && knowerUid != null;
  bool get emSetup => phase == 'setup';
  bool get emJulgamento => phase == 'judging';
  bool get podeDesfazer => reversivel;

  factory AneisEstadoRemoto.fromMap(Map<String, dynamic> data) {
    return AneisEstadoRemoto(
      gameId: data['gameId'] as String? ?? '',
      phase: data['phase'] as String? ?? 'playing',
      currentUid: data['currentUid'] as String? ?? '',
      dificuldade: data['dificuldade'] as String? ?? 'facil',
      knowerMode: data['knowerMode'] as String? ?? 'app',
      knowerUid: data['knowerUid'] as String?,
      knowerNome: data['knowerNome'] as String?,
      aneis: (data['aneis'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => AneisAnelPublico.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      tabuleiro: (data['tabuleiro'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                AneisCartaTabuleiro.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      baralhoCount: data['baralhoCount'] as int? ?? 0,
      ultimaJogada: data['ultimaJogada'] is Map
          ? AneisUltimaJogada.fromMap(
              Map<String, dynamic>.from(data['ultimaJogada'] as Map),
            )
          : null,
      pendingJogada: data['pendingJogada'] is Map
          ? AneisPendingJogada.fromMap(
              Map<String, dynamic>.from(data['pendingJogada'] as Map),
            )
          : null,
      reversivel: data['reversivel'] is Map,
      vencedorUid: data['vencedorUid'] as String?,
      vencedorNome: data['vencedorNome'] as String?,
      regrasReveladas: (data['regrasReveladas'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                AneisRegraRevelada.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      playerCount: data['playerCount'] as int? ?? 0,
    );
  }
}
