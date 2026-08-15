import 'dart:math';
import '../../core/enums/papel.dart';
import '../models/jogador_partida.dart';
import '../models/palavra.dart';
import '../repositories/palavra_repository.dart';

class SorteioService {
  final PalavraRepository _palavraRepository;
  final Random _random = Random();

  SorteioService(this._palavraRepository);

  Palavra? sortearPalavra({
    required List<String> categoriasIds,
    required List<String> palavrasUsadasIds,
  }) {
    final palavrasDisponiveis = _palavraRepository
        .getPalavrasDisponiveisParaSorteio(
          categoriasIds: categoriasIds,
          palavrasUsadasIds: palavrasUsadasIds,
        );

    if (palavrasDisponiveis.isEmpty) {
      return null;
    }

    final index = _random.nextInt(palavrasDisponiveis.length);
    return palavrasDisponiveis[index];
  }

  List<Papel> sortearPapeis({
    required int quantidadeJogadores,
    required int quantidadeEspioes,
  }) {
    if (quantidadeEspioes >= quantidadeJogadores) {
      throw ArgumentError(
        'Quantidade de espiões deve ser menor que quantidade de jogadores',
      );
    }

    final papeis = <Papel>[];

    for (int i = 0; i < quantidadeEspioes; i++) {
      papeis.add(Papel.espiao);
    }

    for (int i = 0; i < quantidadeJogadores - quantidadeEspioes; i++) {
      papeis.add(Papel.civil);
    }

    papeis.shuffle(_random);

    return papeis;
  }

  JogadorPartida sortearJogadorInicial(List<JogadorPartida> jogadores) {
    if (jogadores.isEmpty) {
      throw ArgumentError('Lista de jogadores não pode estar vazia');
    }

    final jogadoresAtivos = jogadores.where((j) => j.estaAtivo).toList();

    if (jogadoresAtivos.isEmpty) {
      throw ArgumentError('Deve haver pelo menos um jogador ativo');
    }

    final index = _random.nextInt(jogadoresAtivos.length);
    return jogadoresAtivos[index];
  }

  T sortearItem<T>(List<T> items) {
    if (items.isEmpty) {
      throw ArgumentError('Lista não pode estar vazia');
    }
    return items[_random.nextInt(items.length)];
  }

  List<T> embaralhar<T>(List<T> items) {
    final listaEmbaralhada = List<T>.from(items);
    listaEmbaralhada.shuffle(_random);
    return listaEmbaralhada;
  }
}
