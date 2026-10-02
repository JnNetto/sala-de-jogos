import '../../core/enums/lobisomem_equipe.dart';
import '../../core/enums/lobisomem_fase.dart';
import '../../core/enums/lobisomem_papel.dart';
import '../../core/enums/lobisomem_vencedor.dart';
import 'lobisomem_configuracao.dart';
import 'lobisomem_jogador.dart';

enum LobisomemOrigemResolucao { noite, voto }

class LobisomemPartida {
  final LobisomemConfiguracao configuracao;
  final List<LobisomemJogador> jogadores;
  final LobisomemFase fase;
  final int noiteAtual;
  final bool bruxaTemCura;
  final bool bruxaTemVeneno;
  final Map<String, String?> votosLobisomens;
  final String? investigacaoAlvoId;
  final bool? investigacaoEhLobisomem;
  final bool bruxaUsouCuraNestaNoite;
  final String? bruxaVenenoAlvoId;
  final String? vitimaAtaqueId;
  final List<String> filaMortesIds;
  final List<String> mortesResolucaoIds;
  final List<String> mortesCacadorIds;
  final LobisomemOrigemResolucao? origemResolucao;
  final Map<String, String?> votosDia;
  final bool emRevoto;
  final List<String> candidatosVotoIds;
  final List<String> empatadosIds;
  final bool votoNaoEliminou;
  final bool aguardandoRevoto;
  final int discussaoSegundosRestantes;
  final bool discussaoPausada;
  final LobisomemVencedor? vencedor;
  final bool boboVenceu;

  const LobisomemPartida({
    required this.configuracao,
    required this.jogadores,
    this.fase = LobisomemFase.distribuindo,
    this.noiteAtual = 1,
    this.bruxaTemCura = true,
    this.bruxaTemVeneno = true,
    this.votosLobisomens = const {},
    this.investigacaoAlvoId,
    this.investigacaoEhLobisomem,
    this.bruxaUsouCuraNestaNoite = false,
    this.bruxaVenenoAlvoId,
    this.vitimaAtaqueId,
    this.filaMortesIds = const [],
    this.mortesResolucaoIds = const [],
    this.mortesCacadorIds = const [],
    this.origemResolucao,
    this.votosDia = const {},
    this.emRevoto = false,
    this.candidatosVotoIds = const [],
    this.empatadosIds = const [],
    this.votoNaoEliminou = false,
    this.aguardandoRevoto = false,
    this.discussaoSegundosRestantes = 0,
    this.discussaoPausada = false,
    this.vencedor,
    this.boboVenceu = false,
  });

  LobisomemJogador get narrador {
    return jogadores.firstWhere((jogador) => jogador.ehNarrador);
  }

  List<LobisomemJogador> get vivos {
    return jogadores.where((jogador) => jogador.vivo).toList(growable: false);
  }

  List<LobisomemJogador> get vivosPorAssento {
    final lista = [...vivos]..sort((a, b) => a.assento.compareTo(b.assento));
    return List.unmodifiable(lista);
  }

  List<LobisomemJogador> get mortos {
    return jogadores.where((jogador) => !jogador.vivo).toList(growable: false);
  }

  List<LobisomemJogador> get lobisomensVivos {
    return vivos.where((jogador) => jogador.ehLobisomem).toList(growable: false);
  }

  List<LobisomemJogador> get aldeiaViva {
    return vivos
        .where((jogador) => jogador.equipe == LobisomemEquipe.aldeia)
        .toList(growable: false);
  }

  LobisomemJogador? get bruxa {
    for (final jogador in jogadores) {
      if (jogador.papel == LobisomemPapel.bruxa) return jogador;
    }
    return null;
  }

  bool get bruxaVivaComPocao {
    final atual = bruxa;
    return atual != null && atual.vivo && (bruxaTemCura || bruxaTemVeneno);
  }

  bool get precisaPasseBruxa => bruxaVivaComPocao;

  int get quantidadeJogadores => jogadores.length;

  bool get todosLobisomensVotaram {
    return lobisomensVivos.every(
      (jogador) => votosLobisomens.containsKey(jogador.id),
    );
  }

  List<LobisomemJogador> get eleitores {
    return vivosPorAssento;
  }

  List<LobisomemJogador> get alvosVoto {
    if (candidatosVotoIds.isEmpty) return vivosPorAssento;
    return vivosPorAssento
        .where((jogador) => candidatosVotoIds.contains(jogador.id))
        .toList(growable: false);
  }

  bool get todosVotaramDia {
    return eleitores.every((jogador) => votosDia.containsKey(jogador.id));
  }

  String get morteAtualId => filaMortesIds.first;

  bool get temMorteNaFila => filaMortesIds.isNotEmpty;

  LobisomemJogador jogadorPorId(String id) {
    return jogadores.firstWhere((jogador) => jogador.id == id);
  }

  String nomePorId(String id) => jogadorPorId(id).nome;

  List<String> nomesPorIds(List<String> ids) {
    return [
      for (final id in ids) nomePorId(id),
    ];
  }

  LobisomemPartida copyWith({
    LobisomemConfiguracao? configuracao,
    List<LobisomemJogador>? jogadores,
    LobisomemFase? fase,
    int? noiteAtual,
    bool? bruxaTemCura,
    bool? bruxaTemVeneno,
    Map<String, String?>? votosLobisomens,
    String? investigacaoAlvoId,
    bool? investigacaoEhLobisomem,
    bool? bruxaUsouCuraNestaNoite,
    String? bruxaVenenoAlvoId,
    String? vitimaAtaqueId,
    List<String>? filaMortesIds,
    List<String>? mortesResolucaoIds,
    List<String>? mortesCacadorIds,
    LobisomemOrigemResolucao? origemResolucao,
    Map<String, String?>? votosDia,
    bool? emRevoto,
    List<String>? candidatosVotoIds,
    List<String>? empatadosIds,
    bool? votoNaoEliminou,
    bool? aguardandoRevoto,
    int? discussaoSegundosRestantes,
    bool? discussaoPausada,
    LobisomemVencedor? vencedor,
    bool? boboVenceu,
    bool limparInvestigacao = false,
    bool limparVeneno = false,
    bool limparVitima = false,
    bool limparOrigem = false,
    bool limparVencedor = false,
  }) {
    return LobisomemPartida(
      configuracao: configuracao ?? this.configuracao,
      jogadores: jogadores ?? this.jogadores,
      fase: fase ?? this.fase,
      noiteAtual: noiteAtual ?? this.noiteAtual,
      bruxaTemCura: bruxaTemCura ?? this.bruxaTemCura,
      bruxaTemVeneno: bruxaTemVeneno ?? this.bruxaTemVeneno,
      votosLobisomens: votosLobisomens ?? this.votosLobisomens,
      investigacaoAlvoId: limparInvestigacao
          ? null
          : (investigacaoAlvoId ?? this.investigacaoAlvoId),
      investigacaoEhLobisomem: limparInvestigacao
          ? null
          : (investigacaoEhLobisomem ?? this.investigacaoEhLobisomem),
      bruxaUsouCuraNestaNoite:
          bruxaUsouCuraNestaNoite ?? this.bruxaUsouCuraNestaNoite,
      bruxaVenenoAlvoId: limparVeneno
          ? null
          : (bruxaVenenoAlvoId ?? this.bruxaVenenoAlvoId),
      vitimaAtaqueId: limparVitima
          ? null
          : (vitimaAtaqueId ?? this.vitimaAtaqueId),
      filaMortesIds: filaMortesIds ?? this.filaMortesIds,
      mortesResolucaoIds: mortesResolucaoIds ?? this.mortesResolucaoIds,
      mortesCacadorIds: mortesCacadorIds ?? this.mortesCacadorIds,
      origemResolucao: limparOrigem
          ? null
          : (origemResolucao ?? this.origemResolucao),
      votosDia: votosDia ?? this.votosDia,
      emRevoto: emRevoto ?? this.emRevoto,
      candidatosVotoIds: candidatosVotoIds ?? this.candidatosVotoIds,
      empatadosIds: empatadosIds ?? this.empatadosIds,
      votoNaoEliminou: votoNaoEliminou ?? this.votoNaoEliminou,
      aguardandoRevoto: aguardandoRevoto ?? this.aguardandoRevoto,
      discussaoSegundosRestantes:
          discussaoSegundosRestantes ?? this.discussaoSegundosRestantes,
      discussaoPausada: discussaoPausada ?? this.discussaoPausada,
      vencedor: limparVencedor ? null : (vencedor ?? this.vencedor),
      boboVenceu: boboVenceu ?? this.boboVenceu,
    );
  }
}
