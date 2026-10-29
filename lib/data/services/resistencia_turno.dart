import '../../core/constants/resistencia_constants.dart';
import '../../core/enums/resistencia_fase.dart';
import '../../core/enums/resistencia_papel.dart';
import '../models/resistencia_partida.dart';

class ResistenciaTurno {
  static bool cartaDaMissao({
    required ResistenciaPapel? papel,
    required bool sucessoPedido,
  }) {
    if (papel == ResistenciaPapel.resistencia) return true;
    return sucessoPedido;
  }

  static ResistenciaPartida resolverVotacao(ResistenciaPartida partida) {
    if (partida.propostaAprovada) {
      return partida.copyWith(
        fase: ResistenciaFase.missao,
        cartasMissao: const {},
        ultimaPropostaAprovada: true,
        limparUltimaMissao: true,
      );
    }

    final proximaTentativa = partida.tentativaAtual + 1;
    if (proximaTentativa > ResistenciaConstants.maxRejeicoes) {
      return partida.copyWith(
        fase: ResistenciaFase.finalizada,
        ultimaPropostaAprovada: false,
      );
    }

    return partida.copyWith(
      fase: ResistenciaFase.propondo,
      tentativaAtual: proximaTentativa,
      liderIndex: (partida.liderIndex + 1) % partida.jogadores.length,
      equipePropostaIds: const [],
      votosProposta: const {},
      ultimaPropostaAprovada: false,
      limparUltimaMissao: true,
    );
  }

  static ResistenciaPartida resolverMissao(ResistenciaPartida partida) {
    final fracassos = partida.cartasMissao.values
        .where((sucesso) => !sucesso)
        .length;
    final falhasNecessarias =
        ResistenciaConstants.fracassosNecessariosParaFalhar(
          missao: partida.missaoAtual,
          quantidadeJogadores: partida.quantidadeJogadores,
        );
    final missaoSucesso = fracassos < falhasNecessarias;

    final resultados = List<bool>.from(partida.resultadosMissoes)
      ..add(missaoSucesso);
    final fracassosPorMissao = List<int>.from(partida.fracassosPorMissao)
      ..add(fracassos);
    final sucessos = resultados.where((resultado) => resultado).length;
    final sabotagens = resultados.where((resultado) => !resultado).length;
    final finalizada =
        sucessos >= ResistenciaConstants.vitoriasNecessarias ||
        sabotagens >= ResistenciaConstants.vitoriasNecessarias;

    return partida.copyWith(
      resultadosMissoes: List.unmodifiable(resultados),
      fracassosPorMissao: List.unmodifiable(fracassosPorMissao),
      ultimaMissaoSucesso: missaoSucesso,
      ultimosFracassosMissao: fracassos,
      fase: finalizada ? ResistenciaFase.finalizada : ResistenciaFase.propondo,
      missaoAtual: finalizada ? partida.missaoAtual : partida.missaoAtual + 1,
      tentativaAtual: 1,
      liderIndex: (partida.liderIndex + 1) % partida.jogadores.length,
      equipePropostaIds: finalizada ? partida.equipePropostaIds : const [],
      votosProposta: const {},
      cartasMissao: const {},
      limparUltimaPropostaAprovada: true,
    );
  }
}
