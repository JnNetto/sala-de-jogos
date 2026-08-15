import '../../core/enums/estado_partida.dart';
import '../../core/enums/vencedor.dart';
import 'categoria.dart';
import 'configuracao_partida.dart';
import 'jogador_partida.dart';
import 'palavra.dart';

class PartidaAtual {
  final List<JogadorPartida> jogadores;
  final Palavra palavraSecreta;
  final Palavra? palavraRelacionada;
  final Categoria categoria;
  final EstadoPartida estado;
  final ConfiguracaoPartida configuracao;
  final JogadorPartida? jogadorInicial;
  final int tempoRestanteSegundos;
  final Vencedor vencedor;

  PartidaAtual({
    required this.jogadores,
    required this.palavraSecreta,
    this.palavraRelacionada,
    required this.categoria,
    this.estado = EstadoPartida.configuracao,
    required this.configuracao,
    this.jogadorInicial,
    int? tempoRestanteSegundos,
    this.vencedor = Vencedor.emAndamento,
  }) : tempoRestanteSegundos =
           tempoRestanteSegundos ?? configuracao.duracaoDiscussaoSegundos;

  PartidaAtual copyWith({
    List<JogadorPartida>? jogadores,
    Palavra? palavraSecreta,
    Palavra? palavraRelacionada,
    Categoria? categoria,
    EstadoPartida? estado,
    ConfiguracaoPartida? configuracao,
    JogadorPartida? jogadorInicial,
    int? tempoRestanteSegundos,
    Vencedor? vencedor,
  }) {
    return PartidaAtual(
      jogadores: jogadores ?? this.jogadores,
      palavraSecreta: palavraSecreta ?? this.palavraSecreta,
      palavraRelacionada: palavraRelacionada ?? this.palavraRelacionada,
      categoria: categoria ?? this.categoria,
      estado: estado ?? this.estado,
      configuracao: configuracao ?? this.configuracao,
      jogadorInicial: jogadorInicial ?? this.jogadorInicial,
      tempoRestanteSegundos:
          tempoRestanteSegundos ?? this.tempoRestanteSegundos,
      vencedor: vencedor ?? this.vencedor,
    );
  }

  List<JogadorPartida> get jogadoresAtivos =>
      jogadores.where((j) => j.estaAtivo).toList();

  List<JogadorPartida> get jogadoresEliminados =>
      jogadores.where((j) => j.foiEliminado).toList();

  List<JogadorPartida> get espioes =>
      jogadores.where((j) => j.isEspiao).toList();

  List<JogadorPartida> get civis => jogadores.where((j) => j.isCivil).toList();

  List<JogadorPartida> get espioesAtivos =>
      jogadoresAtivos.where((j) => j.isEspiao).toList();

  List<JogadorPartida> get civisAtivos =>
      jogadoresAtivos.where((j) => j.isCivil).toList();

  int get quantidadeJogadoresAtivos => jogadoresAtivos.length;
  int get quantidadeEspioesAtivos => espioesAtivos.length;
  int get quantidadeCivisAtivos => civisAtivos.length;

  bool get partidaFinalizada => vencedor != Vencedor.emAndamento;
  bool get temEspioesAtivos => quantidadeEspioesAtivos > 0;

  Vencedor verificarVencedor() {
    if (quantidadeEspioesAtivos == 0) {
      return Vencedor.civis;
    }

    if (quantidadeJogadoresAtivos - quantidadeEspioesAtivos <= 2) {
      return Vencedor.espioes;
    }

    return Vencedor.emAndamento;
  }

  PartidaAtual eliminarJogador(int jogadorId) {
    final novosJogadores = jogadores.map((j) {
      if (j.id == jogadorId) {
        return j.copyWith(foiEliminado: true);
      }
      return j;
    }).toList();

    final partidaAtualizada = copyWith(jogadores: novosJogadores);
    final novoVencedor = partidaAtualizada.verificarVencedor();

    return partidaAtualizada.copyWith(vencedor: novoVencedor);
  }

  @override
  String toString() {
    return 'PartidaAtual(categoria: ${categoria.nome}, estado: ${estado.displayName}, jogadores: ${jogadores.length}, ativos: $quantidadeJogadoresAtivos)';
  }
}
