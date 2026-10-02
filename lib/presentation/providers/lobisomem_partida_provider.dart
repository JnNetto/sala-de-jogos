import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/enums/lobisomem_fase.dart';
import '../../core/enums/lobisomem_empate.dart';
import '../../core/enums/lobisomem_papel.dart';
import '../../data/models/lobisomem_configuracao.dart';
import '../../data/models/lobisomem_jogador.dart';
import '../../data/models/lobisomem_partida.dart';
import '../../data/services/lobisomem_resolucao_service.dart';
import '../../data/services/lobisomem_roteiro_service.dart';
import '../../data/services/lobisomem_sorteio_service.dart';

class LobisomemPartidaProvider extends ChangeNotifier {
  final LobisomemSorteioService _sorteioService;
  final LobisomemResolucaoService _resolucaoService;
  final LobisomemRoteiroService _roteiroService;

  LobisomemPartida? _partida;
  bool _isLoading = false;
  String? _erro;
  Timer? _timerDiscussao;

  LobisomemPartidaProvider({
    LobisomemSorteioService? sorteioService,
    LobisomemResolucaoService? resolucaoService,
    LobisomemRoteiroService? roteiroService,
  }) : _sorteioService = sorteioService ?? LobisomemSorteioService(),
       _resolucaoService = resolucaoService ?? LobisomemResolucaoService(),
       _roteiroService = roteiroService ?? LobisomemRoteiroService();

  LobisomemPartida? get partida => _partida;
  bool get isLoading => _isLoading;
  String? get erro => _erro;
  bool get temPartida => _partida != null;

  List<LobisomemJogador> alcateiaDe(String jogadorId) {
    final partida = _partida;
    if (partida == null) return const [];
    return partida.jogadores
        .where(
          (jogador) =>
              jogador.id != jogadorId &&
              jogador.papel == LobisomemPapel.lobisomem,
        )
        .toList(growable: false);
  }

  String textoAberturaNoite() {
    return _roteiroService.aberturaNoite(_partida?.noiteAtual ?? 1);
  }

  String textoAmanhecer() {
    final partida = _partida;
    if (partida == null) return '';
    return _roteiroService.amanhecer(partida);
  }

  String textoChamadaVotacao() => _roteiroService.chamadaVotacao();

  String textoResultadoVoto() {
    final partida = _partida;
    if (partida == null) return '';
    return _roteiroService.resultadoVoto(partida);
  }

  String textoMortesExtra() {
    final partida = _partida;
    if (partida == null) return '';
    return _roteiroService.mortesExtra(partida);
  }

  String textoDesfecho() {
    final vencedor = _partida?.vencedor;
    if (vencedor == null) return '';
    return _roteiroService.desfecho(vencedor);
  }

  Future<bool> iniciarNovaPartida({
    required List<String> nomes,
    required int narradorIndex,
    required LobisomemConfiguracao configuracao,
  }) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      final sorteio = _sorteioService.sortear(
        nomes: nomes,
        narradorIndex: narradorIndex,
        configuracao: configuracao,
      );
      final config = sorteio.configuracao.copyWith(
        narradorId: sorteio.jogadores[narradorIndex].id,
      );
      _partida = LobisomemPartida(
        configuracao: config,
        jogadores: List.unmodifiable(sorteio.jogadores),
        fase: LobisomemFase.distribuindo,
        bruxaTemCura: config.temBruxa,
        bruxaTemVeneno: config.temBruxa,
      );
      return true;
    } catch (e) {
      _erro = e.toString().replaceFirst('Invalid argument(s): ', '');
      _partida = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void limparPartida() {
    _cancelarTimer();
    _partida = null;
    _erro = null;
    notifyListeners();
  }

  void iniciarPrimeiraNoite() {
    final partida = _partida;
    if (partida == null) return;
    _partida = partida.copyWith(fase: LobisomemFase.narrandoNoite);
    notifyListeners();
  }

  void iniciarPasse1() {
    final partida = _partida;
    if (partida == null) return;
    _partida = partida.copyWith(fase: LobisomemFase.noitePasse1);
    notifyListeners();
  }

  void registrarVotoLobisomem(String lobisomemId, String? alvoId) {
    final partida = _partida;
    if (partida == null) return;
    final lobisomem = partida.jogadorPorId(lobisomemId);
    if (!lobisomem.vivo || !lobisomem.ehLobisomem) return;
    if (alvoId != null) {
      final alvo = partida.jogadorPorId(alvoId);
      if (!alvo.vivo || alvo.ehLobisomem) return;
    }
    final votos = Map<String, String?>.from(partida.votosLobisomens);
    votos[lobisomemId] = alvoId;
    _partida = partida.copyWith(votosLobisomens: Map.unmodifiable(votos));
    notifyListeners();
  }

  bool registrarInvestigacao(String alvoId) {
    final partida = _partida;
    if (partida == null) return false;
    final alvo = partida.jogadorPorId(alvoId);
    _partida = partida.copyWith(
      investigacaoAlvoId: alvoId,
      investigacaoEhLobisomem: alvo.ehLobisomem,
    );
    notifyListeners();
    return alvo.ehLobisomem;
  }

  void concluirPasse1() {
    final partida = _partida;
    if (partida == null) return;
    final vitima = _resolucaoService.resolverAtaque(
      votos: partida.votosLobisomens,
      consenso: partida.configuracao.consenso,
    );
    _partida = partida.copyWith(
      vitimaAtaqueId: vitima,
      limparVitima: vitima == null,
    );
    if (_partida!.precisaPasseBruxa) {
      _partida = _partida!.copyWith(fase: LobisomemFase.noitePasse2);
      notifyListeners();
      return;
    }
    resolverNoite();
  }

  void registrarAcaoBruxa({required bool usouCura, String? venenoAlvoId}) {
    final partida = _partida;
    if (partida == null) return;
    if (usouCura && (!partida.bruxaTemCura || partida.vitimaAtaqueId == null)) {
      return;
    }
    if (venenoAlvoId != null && !partida.bruxaTemVeneno) return;
    if (venenoAlvoId != null) {
      final alvo = partida.jogadorPorId(venenoAlvoId);
      if (!alvo.vivo) return;
    }

    _partida = partida.copyWith(
      bruxaUsouCuraNestaNoite: usouCura,
      bruxaTemCura: usouCura ? false : partida.bruxaTemCura,
      bruxaVenenoAlvoId: venenoAlvoId,
      limparVeneno: venenoAlvoId == null,
      bruxaTemVeneno: venenoAlvoId != null ? false : partida.bruxaTemVeneno,
    );
    notifyListeners();
  }

  void resolverNoite() {
    final partida = _partida;
    if (partida == null) return;
    final mortesBrutas = _resolucaoService.mortesIniciaisNoite(
      vitimaAtaqueId: partida.vitimaAtaqueId,
      usouCura: partida.bruxaUsouCuraNestaNoite,
      venenoAlvoId: partida.bruxaVenenoAlvoId,
    );
    final resultado = _filtrarMortesComAnciao(
      partida: partida,
      mortes: mortesBrutas,
      vitimaAtaqueId: partida.vitimaAtaqueId,
      usouCura: partida.bruxaUsouCuraNestaNoite,
      venenoAlvoId: partida.bruxaVenenoAlvoId,
    );
    _partida = partida.copyWith(jogadores: resultado.jogadores);
    _aplicarMortes(resultado.mortes);
    _partida = _partida!.copyWith(
      fase: LobisomemFase.resolvendoMortes,
      origemResolucao: LobisomemOrigemResolucao.noite,
      filaMortesIds: List.unmodifiable(resultado.mortes),
      mortesResolucaoIds: List.unmodifiable(resultado.mortes),
      mortesCacadorIds: const [],
    );
    if (resultado.mortes.isEmpty) {
      _fecharResolucao();
    }
    notifyListeners();
  }

  ({List<LobisomemJogador> jogadores, List<String> mortes})
  _filtrarMortesComAnciao({
    required LobisomemPartida partida,
    required List<String> mortes,
    required String? vitimaAtaqueId,
    required bool usouCura,
    required String? venenoAlvoId,
  }) {
    final ataqueEfetivo =
        vitimaAtaqueId != null && !usouCura ? vitimaAtaqueId : null;
    final jogadores = [...partida.jogadores];
    final filtradas = <String>[];

    for (final id in mortes) {
      final index = jogadores.indexWhere((jogador) => jogador.id == id);
      if (index < 0) continue;
      final jogador = jogadores[index];
      final soAtaqueLobo =
          id == ataqueEfetivo && (venenoAlvoId == null || venenoAlvoId != id);
      if (jogador.ehAnciao && !jogador.anciaoJaResistiu && soAtaqueLobo) {
        jogadores[index] = jogador.copyWith(anciaoJaResistiu: true);
        continue;
      }
      filtradas.add(id);
    }

    return (
      jogadores: List.unmodifiable(jogadores),
      mortes: filtradas,
    );
  }

  void confirmarDespedida() {
    final partida = _partida;
    if (partida == null || !partida.temMorteNaFila) return;
    final fila = List<String>.from(partida.filaMortesIds)..removeAt(0);
    _partida = partida.copyWith(filaMortesIds: List.unmodifiable(fila));
    if (fila.isEmpty) {
      _fecharResolucao();
    }
    notifyListeners();
  }

  void registrarTiroCacador(String alvoId) {
    final partida = _partida;
    if (partida == null || !partida.temMorteNaFila) return;
    final cacador = partida.jogadorPorId(partida.morteAtualId);
    if (!cacador.ehCacador) return;
    final alvo = partida.jogadorPorId(alvoId);
    if (!alvo.vivo) return;

    _aplicarMortes([alvoId]);
    final fila = List<String>.from(_partida!.filaMortesIds)..removeAt(0);
    fila.add(alvoId);
    final mortes = [..._partida!.mortesResolucaoIds, alvoId];
    final extras = [..._partida!.mortesCacadorIds, alvoId];
    _partida = _partida!.copyWith(
      filaMortesIds: List.unmodifiable(fila),
      mortesResolucaoIds: List.unmodifiable(mortes),
      mortesCacadorIds: List.unmodifiable(extras),
    );
    notifyListeners();
  }

  void _fecharResolucao() {
    final partida = _partida;
    if (partida == null) return;
    final vencedor = _resolucaoService.verificarVitoria(partida.jogadores);
    if (vencedor != null) {
      _partida = partida.copyWith(
        fase: LobisomemFase.finalizada,
        vencedor: vencedor,
      );
      return;
    }
    if (partida.origemResolucao == LobisomemOrigemResolucao.noite) {
      _partida = partida.copyWith(fase: LobisomemFase.narrandoAmanhecer);
    }
  }

  bool get deveAnunciarMortesExtra {
    final partida = _partida;
    if (partida == null) return false;
    return partida.origemResolucao == LobisomemOrigemResolucao.voto &&
        partida.mortesCacadorIds.isNotEmpty &&
        partida.vencedor == null;
  }

  void iniciarDiscussao() {
    final partida = _partida;
    if (partida == null) return;
    _cancelarTimer();
    final minutos = partida.configuracao.timerDiscussaoMinutos;
    _partida = partida.copyWith(
      fase: LobisomemFase.discutindo,
      discussaoSegundosRestantes: minutos == null ? 0 : minutos * 60,
      discussaoPausada: false,
    );
    if (minutos != null) {
      _timerDiscussao = Timer.periodic(const Duration(seconds: 1), (_) {
        final atual = _partida;
        if (atual == null || atual.discussaoPausada) return;
        final resto = atual.discussaoSegundosRestantes - 1;
        if (resto <= 0) {
          _cancelarTimer();
          _partida = atual.copyWith(discussaoSegundosRestantes: 0);
        } else {
          _partida = atual.copyWith(discussaoSegundosRestantes: resto);
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void pausarDiscussao() {
    final partida = _partida;
    if (partida == null) return;
    _partida = partida.copyWith(discussaoPausada: true);
    notifyListeners();
  }

  void retomarDiscussao() {
    final partida = _partida;
    if (partida == null) return;
    _partida = partida.copyWith(discussaoPausada: false);
    notifyListeners();
  }

  void encerrarDiscussao() {
    _cancelarTimer();
    final partida = _partida;
    if (partida == null) return;
    _partida = partida.copyWith(fase: LobisomemFase.narrandoVotacao);
    notifyListeners();
  }

  void iniciarVotacao() {
    final partida = _partida;
    if (partida == null) return;
    _partida = partida.copyWith(
      fase: LobisomemFase.votando,
      votosDia: const {},
      emRevoto: false,
      candidatosVotoIds: const [],
      empatadosIds: const [],
      votoNaoEliminou: false,
      aguardandoRevoto: false,
    );
    notifyListeners();
  }

  void registrarVotoDia(String eleitorId, String? alvoId) {
    final partida = _partida;
    if (partida == null || partida.fase != LobisomemFase.votando) return;
    if (partida.votosDia.containsKey(eleitorId)) return;
    final eleitor = partida.jogadorPorId(eleitorId);
    if (!eleitor.vivo) return;
    if (alvoId != null) {
      final alvo = partida.jogadorPorId(alvoId);
      if (!alvo.vivo) return;
      if (!partida.configuracao.permitirVotoEmSi && alvoId == eleitorId) {
        return;
      }
      if (partida.candidatosVotoIds.isNotEmpty &&
          !partida.candidatosVotoIds.contains(alvoId)) {
        return;
      }
    } else if (!partida.configuracao.permitirAbstencao) {
      return;
    }
    final votos = Map<String, String?>.from(partida.votosDia);
    votos[eleitorId] = alvoId;
    _partida = partida.copyWith(votosDia: Map.unmodifiable(votos));
    notifyListeners();
  }

  void resolverVotacao() {
    final partida = _partida;
    if (partida == null || !partida.todosVotaramDia) return;
    final contagem = _resolucaoService.contarVotos(partida.votosDia);
    final lideres = _resolucaoService.maisVotados(contagem);

    if (lideres.isEmpty) {
      _partida = partida.copyWith(
        fase: LobisomemFase.narrandoEliminacao,
        votoNaoEliminou: true,
        aguardandoRevoto: false,
        filaMortesIds: const [],
        mortesResolucaoIds: const [],
        mortesCacadorIds: const [],
        origemResolucao: LobisomemOrigemResolucao.voto,
      );
      notifyListeners();
      return;
    }

    if (lideres.length == 1) {
      _iniciarEliminacao(lideres);
      return;
    }

    switch (partida.configuracao.empate) {
      case LobisomemEmpate.defesaRevoto:
        if (partida.emRevoto) {
          _partida = partida.copyWith(
            fase: LobisomemFase.narrandoEliminacao,
            votoNaoEliminou: true,
            aguardandoRevoto: false,
            empatadosIds: List.unmodifiable(lideres),
            filaMortesIds: const [],
            mortesResolucaoIds: const [],
            mortesCacadorIds: const [],
            origemResolucao: LobisomemOrigemResolucao.voto,
          );
        } else {
          _partida = partida.copyWith(
            fase: LobisomemFase.narrandoEliminacao,
            aguardandoRevoto: true,
            votoNaoEliminou: false,
            empatadosIds: List.unmodifiable(lideres),
            origemResolucao: LobisomemOrigemResolucao.voto,
          );
        }
        notifyListeners();
      case LobisomemEmpate.sorteio:
        _iniciarEliminacao([_resolucaoService.sortearEmpatado(lideres)]);
      case LobisomemEmpate.todosSaem:
        _iniciarEliminacao(lideres);
      case LobisomemEmpate.ninguemMorre:
        _partida = partida.copyWith(
          fase: LobisomemFase.narrandoEliminacao,
          votoNaoEliminou: true,
          aguardandoRevoto: false,
          empatadosIds: List.unmodifiable(lideres),
          filaMortesIds: const [],
          mortesResolucaoIds: const [],
          mortesCacadorIds: const [],
          origemResolucao: LobisomemOrigemResolucao.voto,
        );
        notifyListeners();
    }
  }

  void iniciarRevoto() {
    final partida = _partida;
    if (partida == null || !partida.aguardandoRevoto) return;
    _partida = partida.copyWith(
      fase: LobisomemFase.votando,
      emRevoto: true,
      aguardandoRevoto: false,
      votosDia: const {},
      candidatosVotoIds: List.unmodifiable(partida.empatadosIds),
    );
    notifyListeners();
  }

  void iniciarProximaNoite() {
    final partida = _partida;
    if (partida == null) return;
    _partida = partida.copyWith(
      fase: LobisomemFase.narrandoNoite,
      noiteAtual: partida.noiteAtual + 1,
      votosLobisomens: const {},
      limparInvestigacao: true,
      bruxaUsouCuraNestaNoite: false,
      limparVeneno: true,
      limparVitima: true,
      filaMortesIds: const [],
      mortesResolucaoIds: const [],
      mortesCacadorIds: const [],
      limparOrigem: true,
      votosDia: const {},
      emRevoto: false,
      candidatosVotoIds: const [],
      empatadosIds: const [],
      votoNaoEliminou: false,
      aguardandoRevoto: false,
    );
    notifyListeners();
  }

  void _iniciarEliminacao(List<String> ids) {
    final partida = _partida;
    if (partida == null) return;
    final boboEliminado = ids.any((id) => partida.jogadorPorId(id).ehBobo);
    _aplicarMortes(ids);
    _partida = _partida!.copyWith(
      fase: LobisomemFase.narrandoEliminacao,
      origemResolucao: LobisomemOrigemResolucao.voto,
      filaMortesIds: List.unmodifiable(ids),
      mortesResolucaoIds: List.unmodifiable(ids),
      mortesCacadorIds: const [],
      votoNaoEliminou: false,
      aguardandoRevoto: false,
      boboVenceu: boboEliminado ? true : partida.boboVenceu,
    );
    notifyListeners();
  }

  void _aplicarMortes(List<String> ids) {
    final partida = _partida;
    if (partida == null || ids.isEmpty) return;
    final set = ids.toSet();
    _partida = partida.copyWith(
      jogadores: List.unmodifiable([
        for (final jogador in partida.jogadores)
          set.contains(jogador.id) ? jogador.copyWith(vivo: false) : jogador,
      ]),
    );
  }

  void _cancelarTimer() {
    _timerDiscussao?.cancel();
    _timerDiscussao = null;
  }

  @override
  void dispose() {
    _cancelarTimer();
    super.dispose();
  }
}
