import 'dart:math';
import '../../core/constants/game_constants.dart';
import '../../core/constants/pergunta_impostora_constants.dart';
import '../../core/enums/estado_partida_pergunta.dart';
import '../../core/enums/vencedor.dart';
import '../models/configuracao_pergunta_impostora.dart';
import '../models/jogador_pergunta.dart';
import '../models/par_perguntas.dart';
import '../models/partida_pergunta_impostora.dart';
import '../repositories/pergunta_repository.dart';
import 'sorteio_service.dart';
import 'storage_service.dart';

class PerguntaPartidaService {
  final PerguntaRepository _perguntaRepository;
  final SorteioService _sorteioService;
  final StorageService _storageService;
  final Random _random = Random();

  PerguntaPartidaService({
    required PerguntaRepository perguntaRepository,
    required SorteioService sorteioService,
    required StorageService storageService,
  }) : _perguntaRepository = perguntaRepository,
       _sorteioService = sorteioService,
       _storageService = storageService;

  Future<PartidaPerguntaImpostora?> iniciarNovaPartida({
    required ConfiguracaoPerguntaImpostora configuracao,
    List<String>? nomesJogadores,
  }) async {
    final erro = configuracao.getValidationError();
    if (erro != null) {
      throw ArgumentError(erro);
    }

    final usados = await _storageService.getParesPerguntaUsados();
    var par = _sortearPar(configuracao, usados);

    if (par == null) {
      await _storageService.limparParesPerguntaUsados();
      par = _sortearPar(configuracao, []);
    }

    if (par == null) {
      return null;
    }

    await _storageService.adicionarParPerguntaUsado(par.idString);
    return _criarPartida(
      configuracao: configuracao,
      par: par,
      nomesJogadores: nomesJogadores,
    );
  }

  ParPerguntas? _sortearPar(
    ConfiguracaoPerguntaImpostora configuracao,
    List<String> usados,
  ) {
    final disponiveis = _perguntaRepository.getParesDisponiveis(
      categoriasIds: configuracao.categoriasAtivasIds,
      niveis: configuracao.niveisAtivos,
      usadosIds: usados,
    );
    if (disponiveis.isEmpty) return null;
    return disponiveis[_random.nextInt(disponiveis.length)];
  }

  PartidaPerguntaImpostora _criarPartida({
    required ConfiguracaoPerguntaImpostora configuracao,
    required ParPerguntas par,
    List<String>? nomesJogadores,
  }) {
    final papeis = _sorteioService.sortearPapeis(
      quantidadeJogadores: configuracao.quantidadeJogadores,
      quantidadeEspioes: configuracao.quantidadeImpostores,
    );

    final jogadores = <JogadorPergunta>[];
    for (int i = 0; i < configuracao.quantidadeJogadores; i++) {
      final nome = (nomesJogadores != null && i < nomesJogadores.length)
          ? nomesJogadores[i]
          : GameConstants.getNomeJogadorPadrao(i + 1);

      jogadores.add(JogadorPergunta(id: i + 1, nome: nome, papel: papeis[i]));
    }

    return PartidaPerguntaImpostora(
      jogadores: jogadores,
      par: par,
      categoriaNome: PerguntaImpostoraConstants.nomeCategoria(par.categoriaId),
      estado: EstadoPartidaPergunta.configuracao,
      configuracao: configuracao,
    );
  }

  PartidaPerguntaImpostora iniciarDistribuicao(
    PartidaPerguntaImpostora partida,
  ) {
    return partida.copyWith(
      estado: EstadoPartidaPergunta.distribuicaoPerguntas,
    );
  }

  PartidaPerguntaImpostora iniciarColetaRespostas(
    PartidaPerguntaImpostora partida,
  ) {
    return partida.copyWith(estado: EstadoPartidaPergunta.coletaRespostas);
  }

  PartidaPerguntaImpostora registrarResposta(
    PartidaPerguntaImpostora partida,
    int jogadorId,
    String resposta,
  ) {
    return partida.registrarResposta(jogadorId, resposta);
  }

  PartidaPerguntaImpostora iniciarRevelacaoRespostas(
    PartidaPerguntaImpostora partida,
  ) {
    return partida.copyWith(estado: EstadoPartidaPergunta.revelacaoRespostas);
  }

  PartidaPerguntaImpostora iniciarDiscussao(PartidaPerguntaImpostora partida) {
    return partida.copyWith(
      estado: EstadoPartidaPergunta.discussao,
      tempoRestanteSegundos: partida.configuracao.duracaoDiscussaoSegundos,
    );
  }

  PartidaPerguntaImpostora atualizarTempoDiscussao(
    PartidaPerguntaImpostora partida,
    int segundosRestantes,
  ) {
    return partida.copyWith(tempoRestanteSegundos: segundosRestantes);
  }

  PartidaPerguntaImpostora iniciarVotacao(PartidaPerguntaImpostora partida) {
    return partida.copyWith(estado: EstadoPartidaPergunta.votacao);
  }

  PartidaPerguntaImpostora votarJogador(
    PartidaPerguntaImpostora partida,
    int jogadorId,
  ) {
    final atualizada = partida.eliminarJogador(jogadorId);
    final vencedor = atualizada.verificarVencedor();

    if (vencedor != Vencedor.emAndamento) {
      return atualizada.copyWith(
        estado: EstadoPartidaPergunta.resultado,
        vencedor: vencedor,
      );
    }

    return atualizada.copyWith(estado: EstadoPartidaPergunta.votacao);
  }

  Future<void> finalizarPartida(PartidaPerguntaImpostora partida) async {
    final stats = await _storageService.getEstatisticasPergunta();
    final duracao =
        partida.configuracao.duracaoDiscussaoSegundos -
        partida.tempoRestanteSegundos;

    final novasStats = stats.registrarPartida(
      civisVenceram: partida.vencedor == Vencedor.civis,
      duracaoSegundos: duracao < 0 ? 0 : duracao,
    );

    await _storageService.saveEstatisticasPergunta(novasStats);
  }

  Future<void> salvarConfiguracao(ConfiguracaoPerguntaImpostora config) async {
    await _storageService.saveConfiguracaoPergunta(config);
  }

  Future<ConfiguracaoPerguntaImpostora> carregarConfiguracao() async {
    return _storageService.getConfiguracaoPergunta();
  }
}
