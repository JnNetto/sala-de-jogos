import 'package:flutter_test/flutter_test.dart';
import 'package:impostor_app/core/constants/resistencia_constants.dart';
import 'package:impostor_app/core/enums/resistencia_fase.dart';
import 'package:impostor_app/core/enums/resistencia_papel.dart';
import 'package:impostor_app/core/enums/resistencia_vencedor.dart';
import 'package:impostor_app/data/models/resistencia_jogador.dart';
import 'package:impostor_app/data/models/resistencia_partida.dart';
import 'package:impostor_app/data/services/resistencia_turno.dart';

void main() {
  test('quarta missão com 7 jogadores só cai com duas falhas', () {
    final segurou = ResistenciaTurno.resolverMissao(
      _missao(jogadores: 7, missao: 4, fracassos: 1),
    );
    final caiu = ResistenciaTurno.resolverMissao(
      _missao(jogadores: 7, missao: 4, fracassos: 2),
    );

    expect(segurou.ultimaMissaoSucesso, isTrue);
    expect(caiu.ultimaMissaoSucesso, isFalse);
  });

  test('quarta missão com 5 jogadores cai com uma falha', () {
    final caiu = ResistenciaTurno.resolverMissao(
      _missao(jogadores: 5, missao: 4, fracassos: 1),
    );

    expect(caiu.ultimaMissaoSucesso, isFalse);
  });

  test('a quinta rejeição da partida entrega o jogo aos saqueadores', () {
    final fim = ResistenciaTurno.resolverVotacao(
      _votacao(jogadores: 5, tentativa: 1, aprovacoes: 2, rejeicoes: 4),
    );

    expect(fim.fase, ResistenciaFase.finalizada);
    expect(fim.vencedor, ResistenciaVencedor.espioes);
  });

  test('rejeições somam na partida, sem precisar ser em sequência', () {
    final segue = ResistenciaTurno.resolverVotacao(
      _votacao(jogadores: 5, tentativa: 1, aprovacoes: 2, rejeicoes: 2),
    );

    expect(segue.fase, ResistenciaFase.propondo);
    expect(segue.rejeicoes, 3);
  });

  test('depois de uma câmara, o guia dela pode usar a Lanterna', () {
    final depois = ResistenciaTurno.resolverMissao(
      _missao(jogadores: 5, missao: 1, fracassos: 1),
    );

    expect(depois.fase, ResistenciaFase.lanterna);
    expect(depois.guiaDaLanterna, depois.jogadores.first.id);
    expect(depois.cartasDaUltimaMissao, isNotEmpty);
  });

  test('com a Lanterna usada, a próxima câmara vem direto', () {
    final depois = ResistenciaTurno.resolverMissao(
      _missao(
        jogadores: 5,
        missao: 1,
        fracassos: 0,
      ).copyWith(lanternaUsada: true),
    );

    expect(depois.fase, ResistenciaFase.propondo);
    expect(depois.guiaDaLanterna, isNull);
  });

  test('maioria aprova e a missão começa sem cartas antigas', () {
    final aprovada = ResistenciaTurno.resolverVotacao(
      _votacao(
        jogadores: 5,
        tentativa: 1,
        aprovacoes: 3,
        cartasAntigas: const {'j0': false},
      ),
    );

    expect(aprovada.fase, ResistenciaFase.missao);
    expect(aprovada.cartasMissao, isEmpty);
  });

  test('jogador da resistência não joga carta de fracasso', () {
    expect(
      ResistenciaTurno.cartaDaMissao(
        papel: ResistenciaPapel.resistencia,
        sucessoPedido: false,
      ),
      isTrue,
    );
    expect(
      ResistenciaTurno.cartaDaMissao(
        papel: ResistenciaPapel.espiao,
        sucessoPedido: false,
      ),
      isFalse,
    );
  });

  test('três sabotagens encerram com vitória dos espiões', () {
    final fim = ResistenciaTurno.resolverMissao(
      _missao(jogadores: 5, missao: 3, fracassos: 1, sabotagensAnteriores: 2),
    );

    expect(fim.fase, ResistenciaFase.finalizada);
    expect(fim.vencedor, ResistenciaVencedor.espioes);
    expect(fim.missaoAtual, 3);
  });
}

ResistenciaPartida _votacao({
  required int jogadores,
  required int tentativa,
  required int aprovacoes,
  int rejeicoes = 0,
  Map<String, bool> cartasAntigas = const {},
}) {
  return ResistenciaPartida(
    jogadores: _jogadores(jogadores),
    tamanhosEquipe: ResistenciaConstants.tamanhosEquipe(jogadores),
    fase: ResistenciaFase.votando,
    tentativaAtual: tentativa,
    rejeicoes: rejeicoes,
    equipePropostaIds: ['j0', 'j1'],
    votosProposta: {for (var i = 0; i < jogadores; i++) 'j$i': i < aprovacoes},
    cartasMissao: cartasAntigas,
  );
}

ResistenciaPartida _missao({
  required int jogadores,
  required int missao,
  required int fracassos,
  int sabotagensAnteriores = 0,
}) {
  final tamanho = ResistenciaConstants.tamanhosEquipe(jogadores)[missao - 1];
  final equipe = [for (var i = 0; i < tamanho; i++) 'j$i'];
  return ResistenciaPartida(
    jogadores: _jogadores(jogadores),
    tamanhosEquipe: ResistenciaConstants.tamanhosEquipe(jogadores),
    fase: ResistenciaFase.missao,
    missaoAtual: missao,
    equipePropostaIds: equipe,
    resultadosMissoes: [for (var i = 0; i < sabotagensAnteriores; i++) false],
    cartasMissao: {for (var i = 0; i < tamanho; i++) 'j$i': i >= fracassos},
  );
}

List<ResistenciaJogador> _jogadores(int quantidade) {
  return [
    for (var i = 0; i < quantidade; i++)
      ResistenciaJogador(
        id: 'j$i',
        nome: 'Jogador ${i + 1}',
        papel: i == 0 ? ResistenciaPapel.espiao : ResistenciaPapel.resistencia,
      ),
  ];
}
