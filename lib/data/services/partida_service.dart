import '../../core/constants/app_constants.dart';
import '../../core/constants/game_constants.dart';
import '../../core/enums/estado_partida.dart';
import '../../core/enums/vencedor.dart';
import '../models/categoria.dart';
import '../models/configuracao_partida.dart';
import '../models/jogador_partida.dart';
import '../models/partida_atual.dart';
import '../models/palavra.dart';
import '../repositories/palavra_repository.dart';
import 'sorteio_service.dart';
import 'storage_service.dart';

class PartidaService {
  final PalavraRepository _palavraRepository;
  final SorteioService _sorteioService;
  final StorageService _storageService;

  PartidaService({
    required PalavraRepository palavraRepository,
    required SorteioService sorteioService,
    required StorageService storageService,
  }) : _palavraRepository = palavraRepository,
       _sorteioService = sorteioService,
       _storageService = storageService;

  Future<PartidaAtual?> iniciarNovaPartida({
    required ConfiguracaoPartida configuracao,
    List<String>? nomesJogadores,
  }) async {
    final erro = configuracao.getValidationError();
    if (erro != null) {
      throw ArgumentError(erro);
    }

    final palavrasUsadas = await _storageService.getPalavrasUsadas();

    final palavraSorteada = _sorteioService.sortearPalavra(
      categoriasIds: configuracao.categoriasAtivasIds,
      palavrasUsadasIds: palavrasUsadas,
    );

    if (palavraSorteada == null) {
      await _storageService.limparPalavrasUsadas();

      final palavraAposClear = _sorteioService.sortearPalavra(
        categoriasIds: configuracao.categoriasAtivasIds,
        palavrasUsadasIds: [],
      );

      if (palavraAposClear == null) {
        return null;
      }

      return _criarPartida(
        configuracao: configuracao,
        palavraSecreta: palavraAposClear,
        nomesJogadores: nomesJogadores,
      );
    }

    await _storageService.adicionarPalavraUsada(palavraSorteada.id);

    return _criarPartida(
      configuracao: configuracao,
      palavraSecreta: palavraSorteada,
      nomesJogadores: nomesJogadores,
    );
  }

  PartidaAtual _criarPartida({
    required ConfiguracaoPartida configuracao,
    required Palavra palavraSecreta,
    List<String>? nomesJogadores,
  }) {
    final papeis = _sorteioService.sortearPapeis(
      quantidadeJogadores: configuracao.quantidadeJogadores,
      quantidadeEspioes: configuracao.quantidadeEspioes,
    );

    final jogadores = <JogadorPartida>[];
    for (int i = 0; i < configuracao.quantidadeJogadores; i++) {
      final nome = (nomesJogadores != null && i < nomesJogadores.length)
          ? nomesJogadores[i]
          : GameConstants.getNomeJogadorPadrao(i + 1);

      jogadores.add(JogadorPartida(id: i + 1, nome: nome, papel: papeis[i]));
    }

    final categoria = _palavraRepository.getCategoriaById(
      palavraSecreta.categoriaId,
    );

    final palavraRelacionada = configuracao.espiaoVePalavraRelacionada
        ? _palavraRepository.getPalavraRelacionada(palavraSecreta.id)
        : null;

    return PartidaAtual(
      jogadores: jogadores,
      palavraSecreta: palavraSecreta,
      palavraRelacionada: palavraRelacionada,
      categoria: categoria ?? _categoriaPadrao(),
      estado: EstadoPartida.configuracao,
      configuracao: configuracao,
    );
  }

  PartidaAtual iniciarDistribuicaoPapeis(PartidaAtual partida) {
    return partida.copyWith(estado: EstadoPartida.distribuicaoPapeis);
  }

  PartidaAtual iniciarDiscussao(PartidaAtual partida) {
    final jogadorInicial = _sorteioService.sortearJogadorInicial(
      partida.jogadores,
    );

    return partida.copyWith(
      estado: EstadoPartida.discussao,
      jogadorInicial: jogadorInicial,
      tempoRestanteSegundos:
          partida.configuracao.duracaoDiscussaoSegundos +
          AppConstants.duracaoAnuncioJogadorInicialSegundos,
    );
  }

  PartidaAtual atualizarTempoDiscussao(
    PartidaAtual partida,
    int segundosRestantes,
  ) {
    return partida.copyWith(tempoRestanteSegundos: segundosRestantes);
  }

  PartidaAtual iniciarVotacao(PartidaAtual partida) {
    return partida.copyWith(estado: EstadoPartida.votacao);
  }

  PartidaAtual votarJogador(PartidaAtual partida, int jogadorId) {
    final partidaAtualizada = partida.eliminarJogador(jogadorId);
    final vencedor = partidaAtualizada.verificarVencedor();

    if (vencedor != Vencedor.emAndamento) {
      return partidaAtualizada.copyWith(
        estado: EstadoPartida.resultado,
        vencedor: vencedor,
      );
    }

    return partidaAtualizada.copyWith(estado: EstadoPartida.votacao);
  }

  Future<void> finalizarPartida(PartidaAtual partida) async {
    final stats = await _storageService.getEstatisticas();

    final duracaoPartida =
        partida.configuracao.duracaoDiscussaoSegundos -
        partida.tempoRestanteSegundos;

    final novasStats = stats.registrarPartida(
      civisVenceram: partida.vencedor == Vencedor.civis,
      duracaoSegundos: duracaoPartida,
    );

    await _storageService.saveEstatisticas(novasStats);
  }

  Categoria _categoriaPadrao() {
    return Categoria(
      id: 'default',
      nome: 'Geral',
      descricao: 'Categoria padrão',
      ativa: true,
    );
  }

  Future<void> salvarConfiguracao(ConfiguracaoPartida config) async {
    await _storageService.saveConfiguracao(config);
  }

  Future<ConfiguracaoPartida> carregarConfiguracao() async {
    return await _storageService.getConfiguracao();
  }
}
