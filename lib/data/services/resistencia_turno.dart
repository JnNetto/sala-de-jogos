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

    // As rejeições contam na partida inteira, não só em sequência.
    final rejeicoes = partida.rejeicoes + 1;
    if (rejeicoes >= ResistenciaConstants.maxRejeicoes) {
      return partida.copyWith(
        fase: ResistenciaFase.finalizada,
        rejeicoes: rejeicoes,
        ultimaPropostaAprovada: false,
      );
    }

    return partida.copyWith(
      fase: ResistenciaFase.propondo,
      rejeicoes: rejeicoes,
      tentativaAtual: partida.tentativaAtual + 1,
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

    // Enquanto a Lanterna não for usada, o guia da câmara pode usá-la.
    final lanterna = !finalizada && !partida.lanternaUsada;

    return partida.copyWith(
      resultadosMissoes: List.unmodifiable(resultados),
      fracassosPorMissao: List.unmodifiable(fracassosPorMissao),
      ultimaMissaoSucesso: missaoSucesso,
      ultimosFracassosMissao: fracassos,
      guiaDaLanterna: lanterna ? partida.liderAtual.id : null,
      limparGuiaDaLanterna: !lanterna,
      cartasDaUltimaMissao: Map.unmodifiable(partida.cartasMissao),
      equipeDaUltimaMissao: List.unmodifiable(partida.equipePropostaIds),
      fase: finalizada
          ? ResistenciaFase.finalizada
          : lanterna
          ? ResistenciaFase.lanterna
          : ResistenciaFase.propondo,
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
