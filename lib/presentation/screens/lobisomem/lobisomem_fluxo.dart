import 'package:flutter/material.dart';

import '../../../core/enums/lobisomem_fase.dart';
import '../../providers/lobisomem_partida_provider.dart';
import 'lobisomem_discussao_screen.dart';
import 'lobisomem_morte_acao_screen.dart';
import 'lobisomem_narrador_screen.dart';
import 'lobisomem_noite_turno_screen.dart';
import 'lobisomem_resultado_final_screen.dart';
import 'lobisomem_votacao_screen.dart';

void _ir(BuildContext context, Widget tela) {
  if (!context.mounted) return;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => tela),
  );
}

void irParaDesfecho(BuildContext context, LobisomemPartidaProvider provider) {
  _ir(
    context,
    LobisomemNarradorScreen(
      texto: provider.textoDesfecho(),
      textoBotao: 'Ver resultado',
      onContinuar: (ctx) => _ir(ctx, const LobisomemResultadoFinalScreen()),
    ),
  );
}

void irParaAberturaNoite(BuildContext context, LobisomemPartidaProvider provider) {
  _ir(
    context,
    LobisomemNarradorScreen(
      texto: provider.textoAberturaNoite(),
      onContinuar: (ctx) {
        provider.iniciarPasse1();
        _ir(ctx, const LobisomemNoiteTurnoScreen(passe: 1));
      },
    ),
  );
}

void irParaAmanhecer(BuildContext context, LobisomemPartidaProvider provider) {
  _ir(
    context,
    LobisomemNarradorScreen(
      texto: provider.textoAmanhecer(),
      onContinuar: (ctx) {
        provider.iniciarDiscussao();
        _ir(ctx, const LobisomemDiscussaoScreen());
      },
    ),
  );
}

void irParaChamadaVotacao(BuildContext context, LobisomemPartidaProvider provider) {
  _ir(
    context,
    LobisomemNarradorScreen(
      texto: provider.textoChamadaVotacao(),
      onContinuar: (ctx) {
        provider.iniciarVotacao();
        _ir(ctx, const LobisomemVotacaoScreen());
      },
    ),
  );
}

void continuarAposNoite(BuildContext context, LobisomemPartidaProvider provider) {
  final partida = provider.partida;
  if (partida == null) return;

  if (partida.fase == LobisomemFase.noitePasse2) {
    _ir(context, const LobisomemNoiteTurnoScreen(passe: 2));
    return;
  }
  if (partida.temMorteNaFila) {
    _ir(context, const LobisomemMorteAcaoScreen());
    return;
  }
  continuarAposMortes(context, provider);
}

void continuarAposMortes(BuildContext context, LobisomemPartidaProvider provider) {
  final partida = provider.partida;
  if (partida == null) return;

  if (partida.vencedor != null) {
    irParaDesfecho(context, provider);
    return;
  }
  if (partida.temMorteNaFila) {
    _ir(context, const LobisomemMorteAcaoScreen());
    return;
  }
  if (partida.fase == LobisomemFase.narrandoAmanhecer) {
    irParaAmanhecer(context, provider);
    return;
  }
  if (provider.deveAnunciarMortesExtra) {
    _ir(
      context,
      LobisomemNarradorScreen(
        texto: provider.textoMortesExtra(),
        onContinuar: (ctx) {
          provider.iniciarProximaNoite();
          irParaAberturaNoite(ctx, provider);
        },
      ),
    );
    return;
  }

  provider.iniciarProximaNoite();
  irParaAberturaNoite(context, provider);
}

void continuarAposNarracaoEliminacao(
  BuildContext context,
  LobisomemPartidaProvider provider,
) {
  final partida = provider.partida;
  if (partida == null) return;

  if (partida.aguardandoRevoto) {
    provider.iniciarRevoto();
    _ir(context, const LobisomemVotacaoScreen());
    return;
  }
  if (partida.temMorteNaFila) {
    _ir(context, const LobisomemMorteAcaoScreen());
    return;
  }
  if (partida.vencedor != null) {
    irParaDesfecho(context, provider);
    return;
  }

  provider.iniciarProximaNoite();
  irParaAberturaNoite(context, provider);
}
