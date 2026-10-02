import 'dart:math';

import '../../core/enums/lobisomem_consenso.dart';
import '../../core/enums/lobisomem_vencedor.dart';
import '../models/lobisomem_jogador.dart';

class LobisomemResolucaoService {
  final Random _random;

  LobisomemResolucaoService({Random? random}) : _random = random ?? Random();

  String? resolverAtaque({
    required Map<String, String?> votos,
    required LobisomemConsenso consenso,
  }) {
    if (votos.isEmpty) return null;

    if (consenso == LobisomemConsenso.semAtaqueSeDivergirem) {
      String? alvo;
      for (final voto in votos.values) {
        if (voto == null) return null;
        if (alvo == null) {
          alvo = voto;
        } else if (alvo != voto) {
          return null;
        }
      }
      return alvo;
    }

    final contagem = <String, int>{};
    var desistencias = 0;
    for (final voto in votos.values) {
      if (voto == null) {
        desistencias++;
      } else {
        contagem[voto] = (contagem[voto] ?? 0) + 1;
      }
    }
    if (contagem.isEmpty) return null;

    final maior = contagem.values.reduce((a, b) => a > b ? a : b);
    final lideres = [
      for (final entrada in contagem.entries)
        if (entrada.value == maior) entrada.key,
    ];
    if (lideres.length != 1) return null;
    if (maior < desistencias) return null;
    if (maior == desistencias) return null;
    return lideres.first;
  }

  List<String> mortesIniciaisNoite({
    required String? vitimaAtaqueId,
    required bool usouCura,
    required String? venenoAlvoId,
  }) {
    final mortes = <String>{};
    if (vitimaAtaqueId != null && !usouCura) {
      mortes.add(vitimaAtaqueId);
    }
    if (venenoAlvoId != null) {
      mortes.add(venenoAlvoId);
    }
    return List.unmodifiable(mortes);
  }

  Map<String, int> contarVotos(Map<String, String?> votos) {
    final contagem = <String, int>{};
    for (final alvo in votos.values) {
      if (alvo == null) continue;
      contagem[alvo] = (contagem[alvo] ?? 0) + 1;
    }
    return Map.unmodifiable(contagem);
  }

  List<String> maisVotados(Map<String, int> contagem) {
    if (contagem.isEmpty) return const [];
    final maior = contagem.values.reduce((a, b) => a > b ? a : b);
    return [
      for (final entrada in contagem.entries)
        if (entrada.value == maior) entrada.key,
    ];
  }

  String sortearEmpatado(List<String> empatados) {
    if (empatados.isEmpty) {
      throw ArgumentError('Não há empatados para sortear');
    }
    return empatados[_random.nextInt(empatados.length)];
  }

  LobisomemVencedor? verificarVitoria(List<LobisomemJogador> jogadores) {
    final vivos = jogadores.where((jogador) => jogador.vivo).toList();
    if (vivos.isEmpty) return LobisomemVencedor.empate;

    final lobisomens = vivos.where((jogador) => jogador.ehLobisomem).length;
    final aldeia = vivos.length - lobisomens;

    if (lobisomens == 0) return LobisomemVencedor.aldeia;
    if (lobisomens >= aldeia) return LobisomemVencedor.lobisomens;
    return null;
  }
}
