import '../../core/constants/lobisomem_constants.dart';
import '../../core/enums/lobisomem_revelacao.dart';
import '../../core/enums/lobisomem_vencedor.dart';
import '../models/lobisomem_jogador.dart';
import '../models/lobisomem_partida.dart';

class LobisomemRoteiroService {
  String aberturaNoite(int noiteAtual) {
    final cabeca = noiteAtual <= 1
        ? 'Cai a primeira noite sobre a aldeia.'
        : 'A noite volta a cair.';
    return '$cabeca ${LobisomemConstants.aberturaNoite} ${LobisomemConstants.ponteNoite}';
  }

  String amanhecer(LobisomemPartida partida) {
    final mortes = partida.mortesResolucaoIds;
    if (mortes.isEmpty) {
      return LobisomemConstants.amanhecerSemVitimas;
    }
    final nomes = LobisomemConstants.juntarNomes(partida.nomesPorIds(mortes));
    final verbo = mortes.length == 1 ? 'morreu' : 'morreram';
    final anuncio = 'A aldeia amanhece. Durante a noite, $nomes $verbo.';
    final revelacoes = _revelacoes(partida, mortes);
    if (revelacoes.isEmpty) return anuncio;
    return '$anuncio $revelacoes';
  }

  String aberturaDiscussao(int? minutos) {
    if (minutos == null) return LobisomemConstants.aberturaDiscussao;
    final unidade = minutos == 1 ? 'minuto' : 'minutos';
    return '${LobisomemConstants.aberturaDiscussao} Vocês têm $minutos $unidade.';
  }

  String chamadaVotacao() => LobisomemConstants.chamadaVotacao;

  String resultadoVoto(LobisomemPartida partida) {
    if (partida.aguardandoRevoto) {
      final nomes = LobisomemConstants.juntarNomes(
        partida.nomesPorIds(partida.empatadosIds),
      );
      return 'Houve empate entre $nomes. Cada um tem ${LobisomemConstants.segundosDefesaEmpate} segundos para se defender. Depois haverá nova votação somente entre eles.';
    }
    if (partida.votoNaoEliminou) {
      return 'Ninguém será eliminado neste dia.';
    }
    final mortes = partida.mortesResolucaoIds
        .where((id) => !partida.mortesCacadorIds.contains(id))
        .toList(growable: false);
    if (mortes.isEmpty) {
      return 'Ninguém será eliminado neste dia.';
    }
    final nomes = LobisomemConstants.juntarNomes(partida.nomesPorIds(mortes));
    final verbo = mortes.length == 1
        ? 'foi eliminado pela aldeia'
        : 'foram eliminados pela aldeia';
    final anuncio = '$nomes $verbo.';
    final revelacoes = _revelacoes(partida, mortes);
    final bobo = partida.boboVenceu &&
            mortes.any((id) => partida.jogadorPorId(id).ehBobo)
        ? ' O Bobo da Corte venceu individualmente. A partida continua para as outras equipes.'
        : '';
    if (revelacoes.isEmpty) return '$anuncio$bobo';
    return '$anuncio $revelacoes$bobo';
  }

  String mortesExtra(LobisomemPartida partida) {
    final extras = partida.mortesCacadorIds;
    if (extras.isEmpty) return '';
    final nomes = LobisomemConstants.juntarNomes(partida.nomesPorIds(extras));
    final verbo = extras.length == 1 ? 'caiu' : 'caíram';
    final anuncio = 'O destino ainda cobrou outro nome: $nomes $verbo.';
    final revelacoes = _revelacoes(partida, extras);
    if (revelacoes.isEmpty) return anuncio;
    return '$anuncio $revelacoes';
  }

  String desfecho(LobisomemVencedor vencedor) {
    switch (vencedor) {
      case LobisomemVencedor.aldeia:
        return LobisomemConstants.desfechoAldeia;
      case LobisomemVencedor.lobisomens:
        return LobisomemConstants.desfechoLobisomens;
      case LobisomemVencedor.empate:
        return LobisomemConstants.desfechoEmpate;
      case LobisomemVencedor.bobo:
        return 'O Bobo da Corte foi eliminado pela votação e venceu sozinho.';
    }
  }

  String _revelacoes(LobisomemPartida partida, List<String> ids) {
    if (partida.configuracao.revelacao == LobisomemRevelacao.nenhuma) {
      return '';
    }
    final partes = <String>[];
    for (final id in ids) {
      final jogador = partida.jogadorPorId(id);
      partes.add(_revelacaoJogador(jogador, partida.configuracao.revelacao));
    }
    return partes.join(' ');
  }

  String _revelacaoJogador(
    LobisomemJogador jogador,
    LobisomemRevelacao revelacao,
  ) {
    switch (revelacao) {
      case LobisomemRevelacao.total:
        return '${jogador.nome} era ${jogador.papel.nome}.';
      case LobisomemRevelacao.soEquipe:
        return '${jogador.nome} pertencia à ${jogador.equipe.nome}.';
      case LobisomemRevelacao.nenhuma:
        return '';
    }
  }

}
