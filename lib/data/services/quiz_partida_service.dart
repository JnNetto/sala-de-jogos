import 'dart:math';
import '../../core/constants/game_constants.dart';
import '../../core/constants/quiz_da_vez_constants.dart';
import '../../core/enums/estado_partida_quiz.dart';
import '../../core/enums/modo_passe_quiz.dart';
import '../models/configuracao_quiz.dart';
import '../models/partida_quiz.dart';
import '../models/quiz_jogador.dart';
import '../models/resultado_rodada_quiz.dart';
import '../repositories/quiz_repository.dart';
import 'storage_service.dart';

class QuizPartidaService {
  final QuizRepository _repository;
  final StorageService _storage;
  final Random _random = Random();

  QuizPartidaService({
    required QuizRepository repository,
    required StorageService storage,
  }) : _repository = repository,
       _storage = storage;

  Future<PartidaQuiz?> iniciarPartida({
    required ConfiguracaoQuiz configuracao,
    List<String>? nomes,
  }) async {
    final erro = configuracao.getValidationError();
    if (erro != null) throw ArgumentError(erro);

    final jogadores = <QuizJogador>[];
    for (int i = 0; i < configuracao.quantidadeJogadores; i++) {
      final nome = (nomes != null && i < nomes.length && nomes[i].isNotEmpty)
          ? nomes[i]
          : GameConstants.getNomeJogadorPadrao(i + 1);
      jogadores.add(QuizJogador(id: i + 1, nome: nome));
    }

    return PartidaQuiz(
      jogadores: jogadores,
      configuracao: configuracao,
      estado: EstadoPartidaQuiz.passagem,
      rodadaAtual: 0,
      indiceJogadorRodada: 0,
    );
  }

  PartidaQuiz iniciarPassagem(PartidaQuiz partida) {
    return partida.copyWith(
      estado: EstadoPartidaQuiz.passagem,
      limparAlvo: true,
      limparPergunta: true,
      limparResultado: true,
    );
  }

  Future<PartidaQuiz?> sortearPerguntaECategoria(PartidaQuiz partida) async {
    final usadosGlobais = await _storage.getQuizPerguntasUsadas();
    final usadas = {
      ...usadosGlobais,
      ...partida.perguntasUsadasNaPartida,
    }.toList();

    var disponiveis = _repository.getDisponiveis(
      categorias: partida.configuracao.categoriasAtivas,
      dificuldades: partida.configuracao.dificuldadesAtivas,
      usadasIds: usadas,
      evitarCategoria: partida.ultimaCategoria,
    );

    if (disponiveis.isEmpty) {
      disponiveis = _repository.getDisponiveis(
        categorias: partida.configuracao.categoriasAtivas,
        dificuldades: partida.configuracao.dificuldadesAtivas,
        usadasIds: usadas,
      );
    }

    if (disponiveis.isEmpty) {
      await _storage.limparQuizPerguntasUsadas();
      disponiveis = _repository.getDisponiveis(
        categorias: partida.configuracao.categoriasAtivas,
        dificuldades: partida.configuracao.dificuldadesAtivas,
        usadasIds: partida.perguntasUsadasNaPartida,
      );
    }

    if (disponiveis.isEmpty) return null;

    final pergunta = disponiveis[_random.nextInt(disponiveis.length)];
    await _storage.adicionarQuizPerguntaUsada(pergunta.id);

    return partida.copyWith(
      estado: EstadoPartidaQuiz.categoria,
      perguntaAtual: pergunta,
      ultimaCategoria: pergunta.categoria,
      perguntasUsadasNaPartida: [
        ...partida.perguntasUsadasNaPartida,
        pergunta.id,
      ],
      tempoRestanteSegundos: partida.configuracao.tempoPerguntaSegundos,
      limparAlvo: true,
    );
  }

  PartidaQuiz iniciarPergunta(PartidaQuiz partida) {
    return partida.copyWith(
      estado: EstadoPartidaQuiz.pergunta,
      tempoRestanteSegundos: partida.configuracao.tempoPerguntaSegundos,
    );
  }

  PartidaQuiz atualizarTempo(PartidaQuiz partida, int segundos) {
    return partida.copyWith(tempoRestanteSegundos: segundos);
  }

  PartidaQuiz iniciarEscolhaAlvo(PartidaQuiz partida) {
    if (partida.configuracao.modoPasse == ModoPasseQuiz.proximoDaFila) {
      final proximoIndex =
          (partida.indiceJogadorRodada + 1) % partida.jogadores.length;
      return partida.copyWith(
        estado: EstadoPartidaQuiz.passagemAlvo,
        alvoPasseId: partida.jogadores[proximoIndex].id,
      );
    }
    return partida.copyWith(estado: EstadoPartidaQuiz.escolhaAlvo);
  }

  PartidaQuiz selecionarAlvo(PartidaQuiz partida, int alvoId) {
    return partida.copyWith(
      estado: EstadoPartidaQuiz.passagemAlvo,
      alvoPasseId: alvoId,
    );
  }

  PartidaQuiz iniciarPerguntaAlvo(PartidaQuiz partida) {
    return partida.copyWith(
      estado: EstadoPartidaQuiz.perguntaAlvo,
      tempoRestanteSegundos: partida.configuracao.tempoPerguntaSegundos,
    );
  }

  PartidaQuiz responderProprio(PartidaQuiz partida, int? indiceResposta) {
    final pergunta = partida.perguntaAtual!;
    final acertou =
        indiceResposta != null && pergunta.isCorreta(indiceResposta);
    final dono = partida.jogadorDaRodada;
    final delta = acertou
        ? QuizDaVezConstants.pontosAcertoProprio
        : QuizDaVezConstants.pontosErroProprio;

    final novosJogadores = partida.jogadores
        .map((j) => j.id == dono.id ? j.adicionarPontos(delta) : j)
        .toList();

    final resultado = ResultadoRodadaQuiz(
      jogadorRodadaNome: dono.nome,
      respondenteNome: dono.nome,
      passou: false,
      acertou: acertou,
      pergunta: pergunta.pergunta,
      respostaCorreta: pergunta.textoRespostaCorreta,
      explicacao: pergunta.explicacao,
      mudancas: [
        MudancaPontosQuiz(jogadorId: dono.id, nome: dono.nome, delta: delta),
      ],
      mensagem: acertou
          ? '${dono.nome} respondeu e acertou: +$delta'
          : '${dono.nome} respondeu e errou: $delta',
    );

    return partida.copyWith(
      jogadores: novosJogadores,
      estado: EstadoPartidaQuiz.resumoRodada,
      ultimoResultado: resultado,
    );
  }

  PartidaQuiz responderAlvo(PartidaQuiz partida, int? indiceResposta) {
    final pergunta = partida.perguntaAtual!;
    final acertou =
        indiceResposta != null && pergunta.isCorreta(indiceResposta);
    final dono = partida.jogadorDaRodada;
    final alvo = partida.alvoDoPasse!;

    final deltaAlvo = acertou
        ? QuizDaVezConstants.pontosAcertoAlvo
        : QuizDaVezConstants.pontosErroAlvo;
    final deltaDono = acertou
        ? QuizDaVezConstants.pontosErroRemetenteNoAcertoAlvo
        : QuizDaVezConstants.pontosAcertoRemetenteNoErroAlvo;

    final novosJogadores = partida.jogadores.map((j) {
      if (j.id == alvo.id) return j.adicionarPontos(deltaAlvo);
      if (j.id == dono.id) return j.adicionarPontos(deltaDono);
      return j;
    }).toList();

    final resultado = ResultadoRodadaQuiz(
      jogadorRodadaNome: dono.nome,
      respondenteNome: alvo.nome,
      passou: true,
      acertou: acertou,
      pergunta: pergunta.pergunta,
      respostaCorreta: pergunta.textoRespostaCorreta,
      explicacao: pergunta.explicacao,
      mudancas: [
        MudancaPontosQuiz(
          jogadorId: alvo.id,
          nome: alvo.nome,
          delta: deltaAlvo,
        ),
        MudancaPontosQuiz(
          jogadorId: dono.id,
          nome: dono.nome,
          delta: deltaDono,
        ),
      ],
      mensagem: acertou
          ? '${dono.nome} passou para ${alvo.nome}. ${alvo.nome} acertou: ${alvo.nome} +$deltaAlvo / ${dono.nome} $deltaDono'
          : '${dono.nome} passou para ${alvo.nome}. ${alvo.nome} errou: ${dono.nome} +$deltaDono / ${alvo.nome} $deltaAlvo',
    );

    return partida.copyWith(
      jogadores: novosJogadores,
      estado: EstadoPartidaQuiz.resumoRodada,
      ultimoResultado: resultado,
    );
  }

  PartidaQuiz avancarParaProximaRodada(PartidaQuiz partida) {
    final proximaRodada = partida.rodadaAtual + 1;
    if (proximaRodada >= partida.totalRodadas) {
      return partida.copyWith(
        estado: EstadoPartidaQuiz.resultado,
        rodadaAtual: proximaRodada,
        limparPergunta: true,
        limparAlvo: true,
      );
    }

    final proximoIndice =
        (partida.indiceJogadorRodada + 1) % partida.jogadores.length;

    return partida.copyWith(
      estado: EstadoPartidaQuiz.passagem,
      rodadaAtual: proximaRodada,
      indiceJogadorRodada: proximoIndice,
      limparPergunta: true,
      limparAlvo: true,
      limparResultado: true,
    );
  }

  Future<void> salvarConfiguracao(ConfiguracaoQuiz config) =>
      _storage.saveConfiguracaoQuiz(config);

  Future<ConfiguracaoQuiz> carregarConfiguracao() =>
      _storage.getConfiguracaoQuiz();
}
