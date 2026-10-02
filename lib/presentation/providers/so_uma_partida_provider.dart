import 'package:flutter/foundation.dart';

import '../../core/enums/so_uma_fase.dart';
import '../../core/enums/so_uma_resultado_rodada.dart';
import '../../core/utils/so_uma_pista_matcher.dart';
import '../../data/models/so_uma_jogador.dart';
import '../../data/models/so_uma_partida.dart';
import '../../data/models/so_uma_pista.dart';
import '../../data/models/so_uma_rodada.dart';
import '../../data/repositories/so_uma_banco_repository.dart';
import '../../data/services/so_uma_baralho_service.dart';

class SoUmaPartidaProvider extends ChangeNotifier {
  final SoUmaBancoRepository _bancoRepository;
  final SoUmaBaralhoService _baralhoService;

  SoUmaPartida? _partida;
  bool _isLoading = false;
  String? _erro;

  SoUmaPartidaProvider({
    SoUmaBancoRepository? bancoRepository,
    SoUmaBaralhoService? baralhoService,
  }) : _bancoRepository = bancoRepository ?? SoUmaBancoRepository(),
       _baralhoService = baralhoService ?? SoUmaBaralhoService();

  SoUmaPartida? get partida => _partida;
  bool get isLoading => _isLoading;
  String? get erro => _erro;
  bool get temPartida => _partida != null;

  Future<bool> iniciarNovaPartida(List<String> nomesJogadores) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      await _bancoRepository.carregar();

      final jogadores = <SoUmaJogador>[
        for (var i = 0; i < nomesJogadores.length; i++)
          SoUmaJogador(
            id: 'jogador_$i',
            nome: nomesJogadores[i].trim().isEmpty
                ? 'Jogador ${i + 1}'
                : nomesJogadores[i].trim(),
          ),
      ];

      final baralho = _baralhoService.montar(
        jogadores: jogadores,
        banco: _bancoRepository.cartas,
      );

      _partida = SoUmaPartida(
        jogadores: baralho.jogadores,
        baralho: baralho.cartas,
      );
      return true;
    } catch (e) {
      _erro = e.toString().replaceFirst('Invalid argument(s): ', '');
      _partida = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void limparPartida() {
    _partida = null;
    _erro = null;
    notifyListeners();
  }

  bool escolherNumero(int numero) {
    final partida = _partida;
    if (partida == null || partida.fase != SoUmaFase.escolhendoNumero) {
      return false;
    }
    if (numero < 1 || numero > 5 || partida.baralho.isEmpty) return false;

    final carta = partida.baralho.first;
    final baralhoRestante = partida.baralho.skip(1).toList(growable: false);

    _partida = partida.copyWith(
      baralho: baralhoRestante,
      fase: SoUmaFase.escrevendoPistas,
      rodadaAtual: SoUmaRodada(
        numero: partida.numeroRodadaAtual,
        adivinhador: partida.adivinhadorAtual,
        carta: carta,
        numeroEscolhido: numero,
        palavraAlvo: carta.palavras[numero - 1],
      ),
    );
    notifyListeners();
    return true;
  }

  int pistasEscritasPorAutor(String autorId) {
    final rodada = _partida?.rodadaAtual;
    if (rodada == null) return 0;
    return rodada.pistas.where((pista) => pista.autorId == autorId).length;
  }

  bool adicionarPista(String autorId, String texto) {
    final partida = _partida;
    final rodada = partida?.rodadaAtual;
    if (partida == null ||
        rodada == null ||
        partida.fase != SoUmaFase.escrevendoPistas) {
      return false;
    }
    if (texto.trim().isEmpty) return false;

    final pista = SoUmaPista(
      id: '${autorId}_${pistasEscritasPorAutor(autorId)}',
      autorId: autorId,
      texto: texto.trim(),
    );

    _partida = partida.copyWith(
      rodadaAtual: rodada.copyWith(pistas: [...rodada.pistas, pista]),
    );
    notifyListeners();
    return true;
  }

  bool finalizarEscritaPistas() {
    final partida = _partida;
    final rodada = partida?.rodadaAtual;
    if (partida == null ||
        rodada == null ||
        partida.fase != SoUmaFase.escrevendoPistas) {
      return false;
    }

    final pistasAnalisadas = SoUmaPistaMatcher.aplicar(
      rodada.pistas,
      rodada.palavraAlvo,
    );

    _partida = partida.copyWith(
      fase: SoUmaFase.comparandoPistas,
      rodadaAtual: rodada.copyWith(pistas: pistasAnalisadas),
    );
    notifyListeners();
    return true;
  }

  void alternarAnulacaoPista(String pistaId) {
    final partida = _partida;
    final rodada = partida?.rodadaAtual;
    if (partida == null ||
        rodada == null ||
        partida.fase != SoUmaFase.comparandoPistas) {
      return;
    }

    final pistas = [
      for (final pista in rodada.pistas)
        pista.id == pistaId ? pista.copyWith(anulada: !pista.anulada) : pista,
    ];

    _partida = partida.copyWith(rodadaAtual: rodada.copyWith(pistas: pistas));
    notifyListeners();
  }

  bool finalizarComparacao() {
    final partida = _partida;
    if (partida == null || partida.fase != SoUmaFase.comparandoPistas) {
      return false;
    }
    _partida = partida.copyWith(fase: SoUmaFase.adivinhando);
    notifyListeners();
    return true;
  }

  bool responderRodada({String? palpite, bool passar = false}) {
    final partida = _partida;
    final rodada = partida?.rodadaAtual;
    if (partida == null ||
        rodada == null ||
        partida.fase != SoUmaFase.adivinhando) {
      return false;
    }

    final SoUmaResultadoRodada resultado;
    if (passar) {
      resultado = SoUmaResultadoRodada.passou;
    } else if (SoUmaPistaMatcher.palpiteCorreto(
      palpite ?? '',
      rodada.palavraAlvo,
    )) {
      resultado = SoUmaResultadoRodada.acerto;
    } else {
      resultado = SoUmaResultadoRodada.erro;
    }

    var baralho = partida.baralho;
    var cartasGanhas = partida.cartasGanhas;
    switch (resultado) {
      case SoUmaResultadoRodada.acerto:
        cartasGanhas += 1;
      case SoUmaResultadoRodada.erro:
        if (baralho.isNotEmpty) {
          baralho = baralho.skip(1).toList(growable: false);
        }
      case SoUmaResultadoRodada.passou:
        break;
    }

    final rodadaConcluida = rodada.copyWith(
      palpite: passar ? null : palpite,
      resultado: resultado,
    );
    final historico = [...partida.historico, rodadaConcluida];
    final terminou = baralho.isEmpty;

    _partida = partida.copyWith(
      baralho: baralho,
      cartasGanhas: cartasGanhas,
      historico: historico,
      fase: terminou ? SoUmaFase.finalizada : SoUmaFase.escolhendoNumero,
      adivinhadorIndex: terminou
          ? partida.adivinhadorIndex
          : (partida.adivinhadorIndex + 1) % partida.quantidadeJogadores,
      limparRodadaAtual: true,
    );
    notifyListeners();
    return true;
  }
}
