import 'package:flutter/foundation.dart';

import '../../core/enums/resistencia_fase.dart';
import '../../data/models/resistencia_jogador.dart';
import '../../data/models/resistencia_partida.dart';
import '../../data/models/resistencia_sorteio.dart';
import '../../data/services/resistencia_sorteio_service.dart';
import '../../data/services/resistencia_turno.dart';

class ResistenciaPartidaProvider extends ChangeNotifier {
  final ResistenciaSorteioService _sorteioService;

  ResistenciaSorteio? _sorteio;
  ResistenciaPartida? _partida;
  bool _isLoading = false;
  String? _erro;

  ResistenciaPartidaProvider({ResistenciaSorteioService? sorteioService})
    : _sorteioService = sorteioService ?? ResistenciaSorteioService();

  ResistenciaSorteio? get sorteio => _sorteio;
  ResistenciaPartida? get partida => _partida;
  bool get isLoading => _isLoading;
  String? get erro => _erro;
  bool get temPartida => _partida != null;

  Future<bool> iniciarNovaPartida(List<String> nomesJogadores) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      final jogadores = <ResistenciaJogador>[
        for (var i = 0; i < nomesJogadores.length; i++)
          ResistenciaJogador(
            id: 'jogador_$i',
            nome: nomesJogadores[i].trim().isEmpty
                ? 'Jogador ${i + 1}'
                : nomesJogadores[i].trim(),
          ),
      ];

      _sorteio = _sorteioService.sortear(jogadores);
      _partida = ResistenciaPartida(
        jogadores: _sorteio!.jogadores,
        tamanhosEquipe: _sorteio!.tamanhosEquipe,
      );
      return true;
    } catch (e) {
      _erro = e.toString().replaceFirst('Invalid argument(s): ', '');
      _sorteio = null;
      _partida = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void limparPartida() {
    _sorteio = null;
    _partida = null;
    _erro = null;
    notifyListeners();
  }

  void alternarJogadorNaProposta(String jogadorId) {
    final partida = _partida;
    if (partida == null) return;

    final equipe = List<String>.from(partida.equipePropostaIds);
    if (equipe.contains(jogadorId)) {
      equipe.remove(jogadorId);
    } else if (equipe.length < partida.tamanhoEquipeAtual) {
      equipe.add(jogadorId);
    }

    _partida = partida.copyWith(equipePropostaIds: List.unmodifiable(equipe));
    notifyListeners();
  }

  bool confirmarProposta() {
    final partida = _partida;
    if (partida == null) return false;
    if (!partida.equipeCompleta) {
      _erro = 'Selecione exatamente ${partida.tamanhoEquipeAtual} jogadores';
      notifyListeners();
      return false;
    }

    _partida = partida.copyWith(
      fase: ResistenciaFase.votando,
      votosProposta: const {},
      limparUltimaPropostaAprovada: true,
    );
    _erro = null;
    notifyListeners();
    return true;
  }

  void registrarVotoProposta(String jogadorId, bool aprovar) {
    final partida = _partida;
    if (partida == null || partida.fase != ResistenciaFase.votando) return;
    if (partida.votosProposta.containsKey(jogadorId)) return;

    final votos = Map<String, bool>.from(partida.votosProposta);
    votos[jogadorId] = aprovar;

    _partida = partida.copyWith(votosProposta: Map.unmodifiable(votos));
    notifyListeners();
  }

  bool resolverVotacaoProposta() {
    final partida = _partida;
    if (partida == null || !partida.todosVotaram) return false;

    _partida = ResistenciaTurno.resolverVotacao(partida);
    _erro = null;
    notifyListeners();
    return true;
  }

  void registrarCartaMissao(String jogadorId, bool sucesso) {
    final partida = _partida;
    if (partida == null || partida.fase != ResistenciaFase.missao) return;
    if (!partida.equipePropostaIds.contains(jogadorId)) return;
    if (partida.cartasMissao.containsKey(jogadorId)) return;

    final jogador = partida.jogadores.firstWhere((j) => j.id == jogadorId);
    final cartaLegal = ResistenciaTurno.cartaDaMissao(
      papel: jogador.papel,
      sucessoPedido: sucesso,
    );
    final cartas = Map<String, bool>.from(partida.cartasMissao);
    cartas[jogadorId] = cartaLegal;

    _partida = partida.copyWith(cartasMissao: Map.unmodifiable(cartas));
    notifyListeners();
  }

  /// Usa a Lanterna em alguém da última câmara e devolve a carta dele
  /// (`true` = Avançar). Só o guia da câmara deve ver o resultado.
  bool? usarLanterna(String alvoId) {
    final partida = _partida;
    if (partida == null || partida.fase != ResistenciaFase.lanterna) {
      return null;
    }
    final carta = partida.cartasDaUltimaMissao[alvoId];
    if (carta == null || alvoId == partida.guiaDaLanterna) return null;
    _partida = partida.copyWith(
      fase: ResistenciaFase.propondo,
      lanternaUsada: true,
      limparGuiaDaLanterna: true,
      lanternaAlvoId: alvoId,
      lanternaCarta: carta,
    );
    notifyListeners();
    return carta;
  }

  /// O guia guarda a Lanterna para outra câmara.
  void guardarLanterna() {
    final partida = _partida;
    if (partida == null || partida.fase != ResistenciaFase.lanterna) return;
    _partida = partida.copyWith(
      fase: ResistenciaFase.propondo,
      limparGuiaDaLanterna: true,
    );
    notifyListeners();
  }

  bool resolverMissao() {
    final partida = _partida;
    if (partida == null || !partida.todosJogaramMissao) return false;

    _partida = ResistenciaTurno.resolverMissao(partida);
    _erro = null;
    notifyListeners();
    return true;
  }
}
