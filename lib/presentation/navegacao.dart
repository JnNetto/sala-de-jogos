import 'package:flutter/widgets.dart';

/// Nome da rota da lista de jogos: a base para onde um jogo volta ao sair
/// ou ao terminar.
const rotaJogos = '/jogos';

/// Predicado para `popUntil` e `pushAndRemoveUntil`: para na lista de jogos,
/// ou na primeira rota se o jogo não foi aberto por ela.
bool ehBaseDosJogos(Route<dynamic> rota) =>
    rota.settings.name == rotaJogos || rota.isFirst;

/// O primeiro passo do Quem é o Espião? ("Quem vai jogar?"): para onde a
/// partida volta ao abortar ou em "Voltar ao início".
const rotaEspiaoInicio = '/espiao/jogadores';

bool ehInicioDoEspiao(Route<dynamic> rota) =>
    rota.settings.name == rotaEspiaoInicio || ehBaseDosJogos(rota);

/// O primeiro passo do Pergunta Impostora ("Quem vai jogar?").
const rotaImpostoraInicio = '/impostora/jogadores';

bool ehInicioDaImpostora(Route<dynamic> rota) =>
    rota.settings.name == rotaImpostoraInicio || ehBaseDosJogos(rota);
