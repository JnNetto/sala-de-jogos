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

  test('quinta rejeição entrega a partida aos espiões', () {
    final fim = ResistenciaTurno.resolverVotacao(
      _votacao(jogadores: 5, tentativa: 5, aprovacoes: 2),
    );

    expect(fim.fase, ResistenciaFase.finalizada);
    expect(fim.vencedor, ResistenciaVencedor.espioes);
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
  Map<String, bool> cartasAntigas = const {},
}) {
  return ResistenciaPartida(
    jogadores: _jogadores(jogadores),
    tamanhosEquipe: ResistenciaConstants.tamanhosEquipe(jogadores),
    fase: ResistenciaFase.votando,
    tentativaAtual: tentativa,
    equipePropostaIds: ['j0', 'j1'],
    votosProposta: {
      for (var i = 0; i < jogadores; i++) 'j$i': i < aprovacoes,
    },
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
    resultadosMissoes: [
      for (var i = 0; i < sabotagensAnteriores; i++) false,
    ],
    cartasMissao: {
      for (var i = 0; i < tamanho; i++) 'j$i': i >= fracassos,
    },
  );
}

List<ResistenciaJogador> _jogadores(int quantidade) {
  return [
    for (var i = 0; i < quantidade; i++)
      ResistenciaJogador(
        id: 'j$i',
        nome: 'Jogador ${i + 1}',
        papel: i == 0
            ? ResistenciaPapel.espiao
            : ResistenciaPapel.resistencia,
      ),
  ];
}
