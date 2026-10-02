import '../../core/constants/lobisomem_constants.dart';
import '../../core/enums/lobisomem_consenso.dart';
import '../../core/enums/lobisomem_empate.dart';
import '../../core/enums/lobisomem_papel.dart';
import '../../core/enums/lobisomem_revelacao.dart';

class LobisomemConfiguracao {
  final int quantidadeJogadores;
  final List<String> nomesJogadores;
  final int narradorIndex;
  final int quantidadeLobisomens;
  final bool temVidente;
  final bool temBruxa;
  final bool temCacador;
  final bool temBobo;
  final bool temAnciao;
  final bool papeisEspeciaisAleatorios;
  final String narradorId;
  final LobisomemRevelacao revelacao;
  final LobisomemEmpate empate;
  final bool permitirAbstencao;
  final bool permitirVotoEmSi;
  final int? timerDiscussaoMinutos;
  final LobisomemConsenso consenso;

  const LobisomemConfiguracao({
    this.quantidadeJogadores = LobisomemConstants.minJogadores,
    this.nomesJogadores = const [],
    this.narradorIndex = 0,
    this.quantidadeLobisomens = 1,
    this.temVidente = true,
    this.temBruxa = false,
    this.temCacador = false,
    this.temBobo = false,
    this.temAnciao = false,
    this.papeisEspeciaisAleatorios = false,
    this.narradorId = '',
    this.revelacao = LobisomemRevelacao.total,
    this.empate = LobisomemEmpate.defesaRevoto,
    this.permitirAbstencao = false,
    this.permitirVotoEmSi = true,
    this.timerDiscussaoMinutos = LobisomemConstants.timerDiscussaoPadraoMinutos,
    this.consenso = LobisomemConsenso.semAtaqueSeDivergirem,
  });

  int get quantidadeEspeciais =>
      (temVidente ? 1 : 0) +
      (temBruxa ? 1 : 0) +
      (temCacador ? 1 : 0) +
      (temBobo ? 1 : 0) +
      (temAnciao ? 1 : 0);

  List<LobisomemPapel> get papeisEspeciaisAtivos {
    return [
      if (temVidente) LobisomemPapel.vidente,
      if (temBruxa) LobisomemPapel.bruxa,
      if (temCacador) LobisomemPapel.cacador,
      if (temBobo) LobisomemPapel.bobo,
      if (temAnciao) LobisomemPapel.anciao,
    ];
  }

  int quantidadeAldeoes(int quantidadeJogadores) {
    return LobisomemConstants.quantidadeAldeoes(
      quantidadeJogadores: quantidadeJogadores,
      quantidadeLobisomens: quantidadeLobisomens,
      temVidente: temVidente,
      temBruxa: temBruxa,
      temCacador: temCacador,
      temBobo: temBobo,
      temAnciao: temAnciao,
    );
  }

  bool composicaoValida(int quantidadeJogadores) {
    if (quantidadeJogadores < LobisomemConstants.minJogadores ||
        quantidadeJogadores > LobisomemConstants.maxJogadores) {
      return false;
    }
    if (quantidadeLobisomens < LobisomemConstants.minLobisomens) {
      return false;
    }
    if (quantidadeLobisomens >= quantidadeJogadores / 2) {
      return false;
    }
    if (papeisEspeciaisAleatorios) {
      final maxEspeciais = LobisomemConstants.maxEspeciaisAleatorios(
        quantidadeJogadores,
      );
      return quantidadeLobisomens + maxEspeciais <= quantidadeJogadores;
    }
    return quantidadeAldeoes(quantidadeJogadores) >= 0;
  }

  LobisomemConfiguracao copyWith({
    int? quantidadeJogadores,
    List<String>? nomesJogadores,
    int? narradorIndex,
    int? quantidadeLobisomens,
    bool? temVidente,
    bool? temBruxa,
    bool? temCacador,
    bool? temBobo,
    bool? temAnciao,
    bool? papeisEspeciaisAleatorios,
    String? narradorId,
    LobisomemRevelacao? revelacao,
    LobisomemEmpate? empate,
    bool? permitirAbstencao,
    bool? permitirVotoEmSi,
    int? timerDiscussaoMinutos,
    bool desligarTimer = false,
    LobisomemConsenso? consenso,
  }) {
    return LobisomemConfiguracao(
      quantidadeJogadores: quantidadeJogadores ?? this.quantidadeJogadores,
      nomesJogadores: nomesJogadores ?? this.nomesJogadores,
      narradorIndex: narradorIndex ?? this.narradorIndex,
      quantidadeLobisomens: quantidadeLobisomens ?? this.quantidadeLobisomens,
      temVidente: temVidente ?? this.temVidente,
      temBruxa: temBruxa ?? this.temBruxa,
      temCacador: temCacador ?? this.temCacador,
      temBobo: temBobo ?? this.temBobo,
      temAnciao: temAnciao ?? this.temAnciao,
      papeisEspeciaisAleatorios:
          papeisEspeciaisAleatorios ?? this.papeisEspeciaisAleatorios,
      narradorId: narradorId ?? this.narradorId,
      revelacao: revelacao ?? this.revelacao,
      empate: empate ?? this.empate,
      permitirAbstencao: permitirAbstencao ?? this.permitirAbstencao,
      permitirVotoEmSi: permitirVotoEmSi ?? this.permitirVotoEmSi,
      timerDiscussaoMinutos: desligarTimer
          ? null
          : (timerDiscussaoMinutos ?? this.timerDiscussaoMinutos),
      consenso: consenso ?? this.consenso,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantidadeJogadores': quantidadeJogadores,
      'nomesJogadores': nomesJogadores,
      'narradorIndex': narradorIndex,
      'quantidadeLobisomens': quantidadeLobisomens,
      'temVidente': temVidente,
      'temBruxa': temBruxa,
      'temCacador': temCacador,
      'temBobo': temBobo,
      'temAnciao': temAnciao,
      'papeisEspeciaisAleatorios': papeisEspeciaisAleatorios,
      'narradorId': narradorId,
      'revelacao': revelacao.name,
      'empate': empate.name,
      'permitirAbstencao': permitirAbstencao,
      'permitirVotoEmSi': permitirVotoEmSi,
      'timerDiscussaoMinutos': timerDiscussaoMinutos,
      'consenso': consenso.name,
    };
  }

  factory LobisomemConfiguracao.fromJson(Map<String, dynamic> json) {
    try {
      final quantidadeJogadores = _lerInt(
        json['quantidadeJogadores'],
      ).clamp(LobisomemConstants.minJogadores, LobisomemConstants.maxJogadores);

      var narradorIndex = _lerInt(json['narradorIndex'], padrao: -1);
      if (narradorIndex < 0) {
        final narradorId = json['narradorId'];
        if (narradorId is String && narradorId.startsWith('jogador_')) {
          narradorIndex = int.tryParse(narradorId.substring(8)) ?? 0;
        } else {
          narradorIndex = 0;
        }
      }
      if (narradorIndex >= quantidadeJogadores) {
        narradorIndex = 0;
      }

      final nomes =
          (json['nomesJogadores'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];

      final timer = _lerTimer(json);

      final config = LobisomemConfiguracao(
        quantidadeJogadores: quantidadeJogadores,
        nomesJogadores: nomes,
        narradorIndex: narradorIndex,
        quantidadeLobisomens: _lerInt(
          json['quantidadeLobisomens'],
          padrao: LobisomemConstants.lobisomensRecomendados(quantidadeJogadores),
        ),
        temVidente: json['temVidente'] as bool? ?? true,
        temBruxa: json['temBruxa'] as bool? ?? false,
        temCacador: json['temCacador'] as bool? ?? false,
        temBobo: json['temBobo'] as bool? ?? false,
        temAnciao: json['temAnciao'] as bool? ?? false,
        papeisEspeciaisAleatorios:
            json['papeisEspeciaisAleatorios'] as bool? ?? false,
        narradorId: json['narradorId'] as String? ?? 'jogador_$narradorIndex',
        revelacao: _lerEnum(
          LobisomemRevelacao.values,
          json['revelacao'],
          LobisomemRevelacao.total,
        ),
        empate: _lerEnum(
          LobisomemEmpate.values,
          json['empate'],
          LobisomemEmpate.defesaRevoto,
        ),
        permitirAbstencao: json['permitirAbstencao'] as bool? ?? false,
        permitirVotoEmSi: json['permitirVotoEmSi'] as bool? ?? true,
        timerDiscussaoMinutos: timer,
        consenso: _lerEnum(
          LobisomemConsenso.values,
          json['consenso'],
          LobisomemConsenso.semAtaqueSeDivergirem,
        ),
      );
      return config._sanitizada();
    } catch (_) {
      return const LobisomemConfiguracao();
    }
  }

  LobisomemConfiguracao _sanitizada() {
    final quantidadeJogadores = this.quantidadeJogadores.clamp(
      LobisomemConstants.minJogadores,
      LobisomemConstants.maxJogadores,
    );
    final narradorIndex = this.narradorIndex.clamp(0, quantidadeJogadores - 1);
    final maxLobisomens = LobisomemConstants.maxLobisomens(quantidadeJogadores);
    var quantidadeLobisomens = this.quantidadeLobisomens.clamp(
      LobisomemConstants.minLobisomens,
      maxLobisomens,
    );
    var temVidente = this.temVidente;
    var temBruxa = this.temBruxa;
    var temCacador = this.temCacador;
    var temBobo = this.temBobo;
    var temAnciao = this.temAnciao;
    final aleatorio = papeisEspeciaisAleatorios;

    var atual = copyWith(
      quantidadeJogadores: quantidadeJogadores,
      narradorIndex: narradorIndex,
      quantidadeLobisomens: quantidadeLobisomens,
      temVidente: aleatorio ? false : temVidente,
      temBruxa: aleatorio ? false : temBruxa,
      temCacador: aleatorio ? false : temCacador,
      temBobo: aleatorio ? false : temBobo,
      temAnciao: aleatorio ? false : temAnciao,
      papeisEspeciaisAleatorios: aleatorio,
      narradorId: narradorId.isEmpty ? 'jogador_$narradorIndex' : narradorId,
    );
    if (atual.composicaoValida(quantidadeJogadores)) return atual;

    if (!aleatorio) {
      if (temAnciao) {
        temAnciao = false;
        atual = atual.copyWith(temAnciao: false);
        if (atual.composicaoValida(quantidadeJogadores)) return atual;
      }
      if (temBobo) {
        temBobo = false;
        atual = atual.copyWith(temBobo: false);
        if (atual.composicaoValida(quantidadeJogadores)) return atual;
      }
      if (temCacador) {
        temCacador = false;
        atual = atual.copyWith(temCacador: false);
        if (atual.composicaoValida(quantidadeJogadores)) return atual;
      }
      if (temBruxa) {
        temBruxa = false;
        atual = atual.copyWith(temBruxa: false);
        if (atual.composicaoValida(quantidadeJogadores)) return atual;
      }
      if (temVidente) {
        temVidente = false;
        atual = atual.copyWith(temVidente: false);
        if (atual.composicaoValida(quantidadeJogadores)) return atual;
      }
    }

    quantidadeLobisomens = LobisomemConstants.lobisomensRecomendados(
      quantidadeJogadores,
    );
    return atual.copyWith(
      quantidadeLobisomens: quantidadeLobisomens,
      temVidente: aleatorio
          ? false
          : LobisomemConstants.videnteRecomendada(quantidadeJogadores),
      temBruxa: aleatorio
          ? false
          : LobisomemConstants.bruxaRecomendada(quantidadeJogadores),
      temCacador: aleatorio
          ? false
          : LobisomemConstants.cacadorRecomendado(quantidadeJogadores),
      temBobo: false,
      temAnciao: false,
    );
  }

  static int _lerInt(dynamic value, {int padrao = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return padrao;
  }

  static int? _lerTimer(Map<String, dynamic> json) {
    if (!json.containsKey('timerDiscussaoMinutos')) {
      return LobisomemConstants.timerDiscussaoPadraoMinutos;
    }
    final raw = json['timerDiscussaoMinutos'];
    if (raw == null) return null;
    final minutos = _lerInt(raw, padrao: -1);
    if (minutos < LobisomemConstants.timerDiscussaoMinMinutos ||
        minutos > LobisomemConstants.timerDiscussaoMaxMinutos) {
      return LobisomemConstants.timerDiscussaoPadraoMinutos;
    }
    return minutos;
  }

  static T _lerEnum<T extends Enum>(List<T> values, dynamic raw, T fallback) {
    if (raw is! String) return fallback;
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return fallback;
  }
}
