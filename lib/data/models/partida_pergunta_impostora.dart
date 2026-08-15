import '../../core/enums/estado_partida_pergunta.dart';
import '../../core/enums/vencedor.dart';
import 'configuracao_pergunta_impostora.dart';
import 'jogador_pergunta.dart';
import 'par_perguntas.dart';

class PartidaPerguntaImpostora {
  final List<JogadorPergunta> jogadores;
  final ParPerguntas par;
  final String categoriaNome;
  final EstadoPartidaPergunta estado;
  final ConfiguracaoPerguntaImpostora configuracao;
  final JogadorPergunta? jogadorInicial;
  final int tempoRestanteSegundos;
  final Vencedor vencedor;

  PartidaPerguntaImpostora({
    required this.jogadores,
    required this.par,
    required this.categoriaNome,
    this.estado = EstadoPartidaPergunta.configuracao,
    required this.configuracao,
    this.jogadorInicial,
    int? tempoRestanteSegundos,
    this.vencedor = Vencedor.emAndamento,
  }) : tempoRestanteSegundos =
           tempoRestanteSegundos ?? configuracao.duracaoDiscussaoSegundos;

  PartidaPerguntaImpostora copyWith({
    List<JogadorPergunta>? jogadores,
    ParPerguntas? par,
    String? categoriaNome,
    EstadoPartidaPergunta? estado,
    ConfiguracaoPerguntaImpostora? configuracao,
    JogadorPergunta? jogadorInicial,
    int? tempoRestanteSegundos,
    Vencedor? vencedor,
  }) {
    return PartidaPerguntaImpostora(
      jogadores: jogadores ?? this.jogadores,
      par: par ?? this.par,
      categoriaNome: categoriaNome ?? this.categoriaNome,
      estado: estado ?? this.estado,
      configuracao: configuracao ?? this.configuracao,
      jogadorInicial: jogadorInicial ?? this.jogadorInicial,
      tempoRestanteSegundos:
          tempoRestanteSegundos ?? this.tempoRestanteSegundos,
      vencedor: vencedor ?? this.vencedor,
    );
  }

  List<JogadorPergunta> get jogadoresAtivos =>
      jogadores.where((j) => j.estaAtivo).toList();

  List<JogadorPergunta> get jogadoresEliminados =>
      jogadores.where((j) => j.foiEliminado).toList();

  List<JogadorPergunta> get espioes =>
      jogadores.where((j) => j.isEspiao).toList();

  List<JogadorPergunta> get civis => jogadores.where((j) => j.isCivil).toList();

  List<JogadorPergunta> get espioesAtivos =>
      jogadoresAtivos.where((j) => j.isEspiao).toList();

  List<JogadorPergunta> get civisAtivos =>
      jogadoresAtivos.where((j) => j.isCivil).toList();

  int get quantidadeJogadoresAtivos => jogadoresAtivos.length;
  int get quantidadeEspioesAtivos => espioesAtivos.length;
  int get quantidadeCivisAtivos => civisAtivos.length;

  bool get todosResponderam => jogadores.every((j) => j.temResposta);

  String perguntaPara(JogadorPergunta jogador) {
    return jogador.isEspiao ? par.impostor : par.principal;
  }

  /// Civis vencem ao eliminar todos os impostores.
  /// Impostores vencem quando restam no máximo N jogadores (incluindo impostores).
  Vencedor verificarVencedor() {
    if (quantidadeEspioesAtivos == 0) {
      return Vencedor.civis;
    }

    if (quantidadeJogadoresAtivos <=
        configuracao.limiarVitoriaImpostorClamped) {
      return Vencedor.espioes;
    }

    return Vencedor.emAndamento;
  }

  PartidaPerguntaImpostora eliminarJogador(int jogadorId) {
    final novosJogadores = jogadores.map((j) {
      if (j.id == jogadorId) {
        return j.copyWith(foiEliminado: true);
      }
      return j;
    }).toList();

    final atualizada = copyWith(jogadores: novosJogadores);
    return atualizada.copyWith(vencedor: atualizada.verificarVencedor());
  }

  PartidaPerguntaImpostora registrarResposta(int jogadorId, String resposta) {
    final novosJogadores = jogadores.map((j) {
      if (j.id == jogadorId) {
        return j.copyWith(resposta: resposta.trim());
      }
      return j;
    }).toList();

    return copyWith(jogadores: novosJogadores);
  }
}
