import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/aneis_constants.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../../data/models/aneis_jogador_remoto.dart';
import '../../../data/models/aneis_sala.dart';
import '../../providers/aneis_sala_provider.dart';
import '../../widgets/sala/botao_opcao.dart';
import '../../widgets/sala/cartao_config.dart';
import '../../widgets/sala/jogador_sala.dart';
import '../../widgets/sala/pressionavel.dart';
import '../../widgets/sala/sala_online.dart';

/// O lobby do Cabe Aqui?: o comum das salas online e, para o host, quem
/// sabe as regras e a dificuldade.
class AneisLobbyRemotoScreen extends StatelessWidget {
  const AneisLobbyRemotoScreen({
    super.key,
    required this.sala,
    required this.jogadores,
  });

  final AneisSala sala;
  final List<AneisJogadorRemoto> jogadores;

  @override
  Widget build(BuildContext context) {
    return LobbyOnline(
      nomeDoJogo: AneisConstants.jogoNome,
      matiz: Matiz.ceu,
      sala: context.watch<AneisSalaProvider>(),
      codigo: sala.codigo,
      hostUid: sala.hostUid,
      jogadores: [
        for (final (i, j) in jogadores.indexed)
          (uid: j.uid, nome: j.displayName, indice: j.seat ?? i),
      ],
      minimo: AneisConstants.minJogadores,
      maximo: AneisConstants.maxJogadores,
      enquantoEspera:
          'Cada anel tem uma regra secreta. Na sua vez, coloque uma carta '
          'da mão na região que achar certa, ou tente desvendar a regra de '
          'um anel. Quem esvaziar a mão primeiro vence.',
      ajustesDoHost: _AjustesDoHost(jogadores: jogadores),
    );
  }
}

/// O "Como vai ser?" do host: quem sabe as regras e a dificuldade.
class _AjustesDoHost extends StatelessWidget {
  const _AjustesDoHost({required this.jogadores});

  final List<AneisJogadorRemoto> jogadores;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luz(Matiz.ceu);
    final provider = context.watch<AneisSalaProvider>();
    final modo = provider.knowerMode;
    final porJogador = modo == AneisConstants.knowerJogador;
    final escolhido = provider.knowerUidEscolhido;
    final valido = jogadores.any((j) => j.uid == escolhido) ? escolhido : null;

    void escolher(VoidCallback mudar) {
      HapticFeedback.selectionClick();
      mudar();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Como vai ser?', style: texto.headlineSmall),
        const SizedBox(height: Espaco.e3),
        CartaoConfig(
          icone: Symbols.visibility_rounded,
          titulo: 'Quem é o Guardião',
          subtitulo: AneisConstants.descricaoKnowerMode(modo),
          luz: luz,
          controle: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: BotaoOpcao(
                      rotulo: 'Uma pessoa',
                      icone: Symbols.person_rounded,
                      selecionado: porJogador,
                      luz: luz,
                      aoTocar: () => escolher(
                        () => provider.definirKnowerMode(
                          AneisConstants.knowerJogador,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Espaco.e2),
                  Expanded(
                    child: BotaoOpcao(
                      rotulo: 'O jogo',
                      icone: Symbols.smart_toy_rounded,
                      selecionado: !porJogador,
                      luz: luz,
                      aoTocar: () => escolher(
                        () => provider.definirKnowerMode(
                          AneisConstants.knowerApp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (porJogador) ...[
                const SizedBox(height: Espaco.e4),
                Text(
                  'QUEM VAI SER',
                  style: texto.labelSmall?.copyWith(color: c.texto3),
                ),
                const SizedBox(height: Espaco.e2),
                Wrap(
                  spacing: Espaco.e2,
                  runSpacing: Espaco.e2,
                  children: [
                    _Escolha(
                      selecionada: valido == null,
                      aoTocar: () =>
                          escolher(() => provider.definirKnowerUid(null)),
                      inicio: Icon(
                        Symbols.casino_rounded,
                        size: 20,
                        color: valido == null ? luz.tinta : c.texto2,
                      ),
                      rotulo: 'Sorteio',
                    ),
                    for (final (i, j) in jogadores.indexed)
                      _Escolha(
                        selecionada: valido == j.uid,
                        aoTocar: () =>
                            escolher(() => provider.definirKnowerUid(j.uid)),
                        inicio: AvatarJogador(
                          nome: j.displayName,
                          indice: j.seat ?? i,
                          tamanho: 24,
                        ),
                        rotulo: j.displayName,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Espaco.e3),
        CartaoConfig(
          icone: Symbols.signal_cellular_alt_rounded,
          titulo: 'Dificuldade',
          subtitulo: 'Quanto mais difícil, mais escondidas as regras.',
          luz: luz,
          controle: Row(
            children: [
              for (final (i, nivel) in AneisConstants.dificuldades.indexed) ...[
                if (i > 0) const SizedBox(width: Espaco.e2),
                Expanded(
                  child: BotaoOpcao(
                    rotulo: AneisConstants.rotuloDificuldade(nivel),
                    semantica:
                        'Dificuldade ${AneisConstants.rotuloDificuldade(nivel)}',
                    selecionado: provider.dificuldade == nivel,
                    luz: luz,
                    aoTocar: () =>
                        escolher(() => provider.definirDificuldade(nivel)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Uma pílula de escolha de pessoa (ou do sorteio).
class _Escolha extends StatelessWidget {
  const _Escolha({
    required this.selecionada,
    required this.aoTocar,
    required this.inicio,
    required this.rotulo,
  });

  final bool selecionada;
  final VoidCallback aoTocar;
  final Widget inicio;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final luz = c.luz(Matiz.ceu);
    return Semantics(
      button: true,
      selected: selecionada,
      label: rotulo,
      excludeSemantics: true,
      child: Pressionavel(
        onTap: aoTocar,
        escala: .96,
        child: AnimatedContainer(
          duration: Movimento.base,
          curve: Movimento.padrao,
          height: 40,
          padding: const EdgeInsets.only(left: 8, right: Espaco.e3),
          decoration: BoxDecoration(
            color: selecionada ? luz.suave : c.superficieFunda,
            borderRadius: BorderRadius.circular(Raio.pill),
            border: Border.all(
              color: selecionada
                  ? (c.ehDia ? c.contorno : luz.cor)
                  : (c.ehDia ? c.contorno : c.linha),
              width: selecionada ? 2 : c.bordaControle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              inicio,
              const SizedBox(width: Espaco.e2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: selecionada ? luz.tinta : c.texto2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
