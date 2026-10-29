import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/sala_tokens.dart';
import '../../../core/utils/service_locator.dart';
import '../../navegacao.dart';
import '../../providers/sala_online.dart';
import 'aviso.dart';
import 'botao_sala.dart';
import 'carregando_tela.dart';
import 'cartao_config.dart';
import 'dialogo.dart';
import 'fim_de_jogo.dart';
import 'janela.dart';
import 'jogador_sala.dart';
import 'tag_sala.dart';
import 'tela_da_sala.dart';
import 'varal.dart';

export '../../providers/sala_online.dart';

/// Um jogador como o lobby mostra: o índice dá a cor.
typedef JogadorDaSala = ({String uid, String nome, int indice});

/// Roda uma ação do servidor e mostra o erro, se houver.
Future<bool> _agir(
  BuildContext context,
  SalaOnline sala,
  Future<bool> Function() acao, {
  String? carregando,
}) async {
  final ok = await (carregando == null
      ? acao()
      : comCarregando(context, carregando, acao));
  if (context.mounted && !ok && sala.erro != null) {
    mostrarAviso(context, sala.erro!);
  }
  return ok;
}

// ─── Entrada ──────────────────────────────────────────────────────────────

enum _Acao { criar, entrar, continuar }

/// A porta de uma sala online: o nome de quem joga e três caminhos —
/// voltar para a última sala, criar uma nova ou entrar com um código.
class EntradaSalaOnline extends StatefulWidget {
  const EntradaSalaOnline({
    super.key,
    required this.nomeDoJogo,
    required this.matiz,
    required this.sala,
    required this.chaveUltimaSala,
    required this.abrirSala,
  });

  final String nomeDoJogo;
  final Matiz matiz;
  final SalaOnline sala;

  /// Onde o provider guarda o id da última sala (para o "Continuar").
  final String chaveUltimaSala;

  /// A tela da sala; com `restaurar`, ela busca a última sala salva.
  final Widget Function(bool restaurar) abrirSala;

  @override
  State<EntradaSalaOnline> createState() => _EntradaSalaOnlineState();
}

class _EntradaSalaOnlineState extends State<EntradaSalaOnline> {
  final _nome = TextEditingController();
  final _codigo = TextEditingController();
  _Acao? _acao;
  bool _temSalaSalva = false;

  @override
  void initState() {
    super.initState();
    _nome.text = ServiceLocator().storageService.getNomeJogador() ?? '';
    _codigo.addListener(() => setState(() {}));
    SharedPreferences.getInstance().then((prefs) {
      final id = prefs.getString(widget.chaveUltimaSala);
      if (mounted && id != null && id.isNotEmpty) {
        setState(() => _temSalaSalva = true);
      }
    });
  }

  @override
  void dispose() {
    _nome.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _ir(_Acao acao) async {
    if (_acao != null) return;
    final navigator = Navigator.of(context);

    if (acao == _Acao.continuar) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => widget.abrirSala(true)),
      );
      return;
    }

    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      mostrarAviso(
        context,
        'Escreva seu nome para a turma saber quem é você.',
        tipo: TipoAviso.aviso,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _acao = acao);
    await ServiceLocator().storageService.saveNomeJogador(nome);
    final sala = widget.sala;
    final ok = acao == _Acao.criar
        ? await sala.criarSala(nome)
        : await sala.entrarNaSala(codigo: _codigo.text, nome: nome);
    if (!mounted) return;
    setState(() => _acao = null);

    if (ok) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => widget.abrirSala(false)),
      );
    } else if (sala.erro != null) {
      mostrarAviso(context, sala.erro!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luz(widget.matiz);
    final ocupado = _acao != null;
    final codigoGrande = context.estilos.hud.copyWith(
      fontSize: 28,
      letterSpacing: 8,
      color: c.texto,
    );

    return TelaDaSala(
      sobretitulo: 'SALA ONLINE',
      titulo: widget.nomeDoJogo,
      matiz: widget.matiz,
      corpo: ListView(
        padding: EdgeInsets.fromLTRB(
          Espaco.margemTela,
          Espaco.e4,
          Espaco.margemTela,
          Espaco.e6 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text('Como você se chama?', style: texto.headlineLarge),
          const SizedBox(height: Espaco.e2),
          Text(
            'É o nome que a turma vai ver na mesa.',
            style: texto.bodyLarge?.copyWith(color: c.texto2),
          ),
          const SizedBox(height: Espaco.e4),
          TextField(
            controller: _nome,
            enabled: !ocupado,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            maxLength: 20,
            style: texto.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontVariations: const [FontVariation.weight(700)],
            ),
            decoration: const InputDecoration(
              hintText: 'Seu nome',
              counterText: '',
              prefixIcon: Icon(Symbols.person_rounded),
            ),
          ),
          const SizedBox(height: Espaco.e6),
          if (_temSalaSalva) ...[
            CartaoConfig(
              icone: Symbols.history_rounded,
              titulo: 'Voltar para a sala',
              subtitulo:
                  'Você estava numa sala. Dá para continuar de onde '
                  'parou.',
              luz: luz,
              controle: BotaoSala(
                rotulo: 'Continuar',
                icone: Symbols.arrow_forward_rounded,
                iconeNoFim: true,
                luz: luz,
                bloco: true,
                onPressed: ocupado ? null : () => _ir(_Acao.continuar),
              ),
            ),
            const SizedBox(height: Espaco.e3),
          ],
          CartaoConfig(
            icone: Symbols.add_home_rounded,
            titulo: 'Criar uma sala',
            subtitulo: 'Você recebe um código para passar para a turma.',
            luz: luz,
            controle: BotaoSala(
              rotulo: 'Criar sala',
              icone: Symbols.add_rounded,
              luz: luz,
              variante: _temSalaSalva
                  ? VarianteBotao.secundario
                  : VarianteBotao.primario,
              bloco: true,
              carregando: _acao == _Acao.criar,
              onPressed: ocupado ? null : () => _ir(_Acao.criar),
            ),
          ),
          const SizedBox(height: Espaco.e3),
          CartaoConfig(
            icone: Symbols.key_rounded,
            titulo: 'Entrar com código',
            subtitulo: 'Peça o código para quem criou a sala.',
            luz: luz,
            controle: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _codigo,
                  enabled: !ocupado,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                    _Maiusculas(),
                  ],
                  onSubmitted: (_) {
                    if (_codigo.text.trim().isNotEmpty) _ir(_Acao.entrar);
                  },
                  style: codigoGrande,
                  decoration: InputDecoration(
                    hintText: 'ABC123',
                    counterText: '',
                    hintStyle: codigoGrande.copyWith(
                      color: c.texto3.withValues(alpha: .5),
                    ),
                  ),
                ),
                const SizedBox(height: Espaco.e3),
                BotaoSala(
                  rotulo: 'Entrar',
                  icone: Symbols.login_rounded,
                  variante: VarianteBotao.secundario,
                  bloco: true,
                  carregando: _acao == _Acao.entrar,
                  onPressed: ocupado || _codigo.text.trim().isEmpty
                      ? null
                      : () => _ir(_Acao.entrar),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Maiusculas extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antes,
    TextEditingValue depois,
  ) => depois.copyWith(text: depois.text.toUpperCase());
}

// ─── Lobby ────────────────────────────────────────────────────────────────

/// O lobby de uma sala online: o código para a turma entrar, quem já
/// chegou e, embaixo, "Começar" para o host. Os ajustes do jogo (só o host
/// vê) entram em [ajustesDoHost].
class LobbyOnline extends StatelessWidget {
  const LobbyOnline({
    super.key,
    required this.nomeDoJogo,
    required this.matiz,
    required this.sala,
    required this.codigo,
    required this.hostUid,
    required this.jogadores,
    required this.minimo,
    required this.maximo,
    required this.enquantoEspera,
    this.ajustesDoHost,
  });

  final String nomeDoJogo;
  final Matiz matiz;
  final SalaOnline sala;
  final String codigo, hostUid;
  final List<JogadorDaSala> jogadores;
  final int minimo, maximo;

  /// O resumo das regras para quem espera o host.
  final String enquantoEspera;
  final Widget? ajustesDoHost;

  Future<void> _sair(BuildContext context) async {
    final sair = await mostrarDialogo(
      context,
      matiz: matiz,
      icone: Symbols.logout_rounded,
      barra: 'SAIR',
      titulo: 'Sair da sala?',
      corpo: sala.souHost
          ? 'Você é o host. Se sair, outra pessoa da sala assume.'
          : 'Para voltar depois, vai precisar do código de novo.',
      acao: 'Sair da sala',
      escape: 'Ficar',
    );
    if (sair != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    final ok = await _agir(
      context,
      sala,
      sala.sairDaSalaRemota,
      carregando: 'Saindo da sala…',
    );
    if (ok) navigator.popUntil(ehBaseDosJogos);
  }

  Future<void> _remover(BuildContext context, JogadorDaSala j) async {
    final remover = await mostrarDialogo(
      context,
      perigo: true,
      icone: Symbols.person_remove_rounded,
      barra: 'REMOVER',
      titulo: 'Tirar ${j.nome}?',
      corpo: 'A pessoa sai da sala e precisa do código para voltar.',
      acao: 'Tirar da sala',
      escape: 'Cancelar',
    );
    if (remover != true || !context.mounted) return;
    await _agir(
      context,
      sala,
      () => sala.removerJogadorRemoto(j.uid),
      carregando: 'Tirando ${j.nome} da sala…',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luz(matiz);
    final souHost = sala.souHost;
    final faltam = minimo - jogadores.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) _sair(context);
      },
      child: TelaDaSala(
        sobretitulo: 'SALA ONLINE',
        titulo: nomeDoJogo,
        matiz: matiz,
        aoVoltar: () => _sair(context),
        corpo: ListView(
          padding: const EdgeInsets.fromLTRB(
            Espaco.margemTela,
            Espaco.e4,
            Espaco.margemTela,
            Espaco.e6,
          ),
          children: [
            _CodigoDaSala(codigo: codigo, souHost: souHost, luz: luz),
            const SizedBox(height: Espaco.e8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text('Na sala', style: texto.headlineSmall)),
                Text(
                  '${jogadores.length}/$maximo',
                  style: context.estilos.hud.copyWith(color: luz.tinta),
                ),
              ],
            ),
            const SizedBox(height: Espaco.e3),
            for (final (i, j) in jogadores.indexed) ...[
              if (i > 0) const SizedBox(height: Espaco.e2),
              LinhaJogador(
                nome: j.nome,
                indice: j.indice,
                apoio: j.uid == sala.uid ? 'Você' : null,
                direita: j.uid == hostUid
                    ? TagSala('HOST', icone: Symbols.star_rounded, luz: luz)
                    : souHost
                    ? BotaoIcone(
                        icone: Symbols.person_remove_rounded,
                        rotulo: 'Tirar ${j.nome} da sala',
                        perigo: true,
                        onPressed: sala.isLoading
                            ? null
                            : () => _remover(context, j),
                      )
                    : null,
              ),
            ],
            if (faltam > 0) ...[
              const SizedBox(height: Espaco.e3),
              Row(
                children: [
                  Icon(
                    Symbols.hourglass_top_rounded,
                    size: 18,
                    color: c.texto3,
                  ),
                  const SizedBox(width: Espaco.e2),
                  Expanded(
                    child: Text(
                      faltam == 1
                          ? 'Falta mais 1 pessoa para começar.'
                          : 'Faltam mais $faltam pessoas para começar.',
                      style: texto.bodyMedium?.copyWith(color: c.texto3),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: Espaco.e8),
            if (souHost && ajustesDoHost != null)
              ajustesDoHost!
            else
              CartaoConfig(
                icone: Symbols.lightbulb_rounded,
                titulo: souHost ? 'Como se joga' : 'Enquanto espera',
                subtitulo: enquantoEspera,
                luz: luz,
              ),
          ],
        ),
        rodape: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Espaco.margemTela,
              Espaco.e3,
              Espaco.margemTela,
              Espaco.e4,
            ),
            child: souHost
                ? BotaoSala(
                    rotulo: 'Começar',
                    icone: Symbols.play_arrow_rounded,
                    luz: luz,
                    bloco: true,
                    carregando: sala.isLoading,
                    onPressed: sala.podeIniciar
                        ? () => _agir(context, sala, sala.iniciarPartidaRemota)
                        : null,
                  )
                : EsperandoHost('Esperando o host começar', matiz: matiz),
          ),
        ),
      ),
    );
  }
}

class _CodigoDaSala extends StatelessWidget {
  const _CodigoDaSala({
    required this.codigo,
    required this.souHost,
    required this.luz,
  });

  final String codigo;
  final bool souHost;
  final Luz luz;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Janela(
      titulo: 'CÓDIGO DA SALA',
      preenchimento: const EdgeInsets.fromLTRB(
        Espaco.e5,
        Espaco.e5,
        Espaco.e5,
        Espaco.e4,
      ),
      child: Column(
        children: [
          Semantics(
            label: 'Código da sala: ${codigo.split('').join(' ')}',
            excludeSemantics: true,
            child: FittedBox(
              child: Text(
                codigo,
                style: context.estilos.hud.copyWith(
                  fontSize: 48,
                  letterSpacing: 10,
                  color: luz.tinta,
                  shadows: c.ehDia
                      ? null
                      : [
                          Shadow(
                            color: luz.cor.withValues(alpha: .55),
                            blurRadius: 18,
                          ),
                        ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Espaco.e2),
          Text(
            souHost
                ? 'Passe o código para a turma entrar.'
                : 'Você está dentro. Quem mais for jogar usa este código.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: c.texto2),
          ),
          const SizedBox(height: Espaco.e3),
          BotaoSala(
            rotulo: 'Copiar código',
            icone: Symbols.content_copy_rounded,
            variante: VarianteBotao.fantasma,
            luz: luz,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: codigo));
              mostrarAviso(context, 'Código copiado.', tipo: TipoAviso.sucesso);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Peças da partida ─────────────────────────────────────────────────────

/// O lugar do botão principal para quem espera alguém: as bolinhas
/// correndo e o que se está esperando.
class EsperandoHost extends StatelessWidget {
  const EsperandoHost(this.texto, {super.key, required this.matiz});

  final String texto;
  final Matiz matiz;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: Espaco.e4),
      decoration: BoxDecoration(
        color: c.superficieFunda,
        borderRadius: BorderRadius.circular(Raio.lg),
        border: c.ehDia ? Border.all(color: c.contorno, width: 2) : null,
      ),
      child: Row(
        children: [
          BolinhasCarregando(cor: c.luz(matiz).cor),
          const SizedBox(width: Espaco.e3),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: c.texto2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sair da mesa no meio da partida: a pessoa sai da tela, mas continua na
/// sala e pode voltar pelo "Continuar" da entrada.
Future<void> sairDaMesa(
  BuildContext context, {
  required String nomeDoJogo,
  required Matiz matiz,
}) async {
  final sair = await mostrarDialogo(
    context,
    matiz: matiz,
    icone: Symbols.logout_rounded,
    barra: 'SAIR',
    titulo: 'Sair da mesa?',
    corpo:
        'A partida continua sem esperar você. Para voltar, toque em '
        'Jogar no $nomeDoJogo e depois em Continuar.',
    acao: 'Sair',
    escape: 'Ficar',
  );
  if (sair == true && context.mounted) {
    Navigator.of(context).popUntil(ehBaseDosJogos);
  }
}

class BotaoSairDaMesa extends StatelessWidget {
  const BotaoSairDaMesa({
    super.key,
    required this.nomeDoJogo,
    required this.matiz,
  });

  final String nomeDoJogo;
  final Matiz matiz;

  @override
  Widget build(BuildContext context) => BotaoIcone(
    icone: Symbols.close_rounded,
    rotulo: 'Sair da mesa',
    onPressed: () => sairDaMesa(context, nomeDoJogo: nomeDoJogo, matiz: matiz),
  );
}

/// O botão vermelho do host para encerrar a partida e voltar ao lobby.
class BotaoEncerrarPartida extends StatelessWidget {
  const BotaoEncerrarPartida({super.key, required this.sala});

  final SalaOnline sala;

  Future<void> _encerrar(BuildContext context) async {
    final encerrar = await mostrarDialogo(
      context,
      perigo: true,
      icone: Symbols.stop_circle_rounded,
      barra: 'ENCERRAR',
      titulo: 'Encerrar a partida?',
      corpo: 'A partida acaba para todo mundo e a sala volta para o lobby.',
      acao: 'Encerrar',
      escape: 'Continuar jogando',
    );
    if (encerrar != true || !context.mounted) return;
    await _agir(
      context,
      sala,
      sala.abortarPartidaRemota,
      carregando: 'Encerrando a partida…',
    );
  }

  @override
  Widget build(BuildContext context) => BotaoIcone(
    icone: Symbols.stop_circle_rounded,
    rotulo: 'Encerrar a partida',
    perigo: true,
    onPressed: sala.isLoading ? null : () => _encerrar(context),
  );
}

/// "Jogar de novo" do host no fim (a sala volta ao lobby); os outros
/// esperam.
class RodapeDoFimOnline extends StatelessWidget {
  const RodapeDoFimOnline({super.key, required this.sala, required this.matiz});

  final SalaOnline sala;
  final Matiz matiz;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Espaco.margemTela,
          Espaco.e3,
          Espaco.margemTela,
          Espaco.e4,
        ),
        child: sala.souHost
            ? BotaoSala(
                rotulo: 'Jogar de novo',
                icone: Symbols.replay_rounded,
                luz: context.cores.luz(matiz),
                bloco: true,
                carregando: sala.isLoading,
                onPressed: () => _agir(
                  context,
                  sala,
                  sala.voltarAoLobbyRemoto,
                  carregando: 'Voltando para a sala…',
                ),
              )
            : EsperandoHost(
                'Esperando o host abrir outra rodada',
                matiz: matiz,
              ),
      ),
    );
  }
}

/// Mostra o erro do provider num aviso; para as ações das fases.
Future<bool> agirNaSala(
  BuildContext context,
  SalaOnline sala,
  Future<bool> Function() acao,
) => _agir(context, sala, acao);

/// Troca de fase dentro da rota da sala, em fade-through: a que sai some
/// na primeira metade, a que entra surge na segunda.
class TrocaDeFase extends StatelessWidget {
  const TrocaDeFase({super.key, required this.fase, required this.child});

  final Object fase;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 640),
      switchInCurve: const Interval(.5, 1, curve: Curves.easeOutCubic),
      switchOutCurve: const Interval(.5, 1, curve: Curves.easeInCubic),
      transitionBuilder: (filho, animacao) => FadeTransition(
        opacity: animacao,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, .02),
            end: Offset.zero,
          ).animate(animacao),
          child: filho,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(fase), child: child),
    );
  }
}

/// Enquanto a sala chega do servidor.
class SalaCarregando extends StatelessWidget {
  const SalaCarregando({
    super.key,
    required this.nomeDoJogo,
    required this.matiz,
  });

  final String nomeDoJogo;
  final Matiz matiz;

  @override
  Widget build(BuildContext context) {
    return TelaDaSala(
      titulo: nomeDoJogo,
      sobretitulo: 'SALA ONLINE',
      matiz: matiz,
      corpo: const Center(child: Varal.carregando()),
    );
  }
}

/// A sala salva sumiu (ou foi fechada).
class SemSalaOnline extends StatelessWidget {
  const SemSalaOnline({
    super.key,
    required this.nomeDoJogo,
    required this.matiz,
  });

  final String nomeDoJogo;
  final Matiz matiz;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    return TelaDaSala(
      titulo: nomeDoJogo,
      sobretitulo: 'SALA ONLINE',
      matiz: matiz,
      corpo: Center(
        child: Padding(
          padding: const EdgeInsets.all(Espaco.margemTela),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PocoIcone(icone: Symbols.cloud_off_rounded, luz: c.info),
              const SizedBox(height: Espaco.e4),
              Text(
                'A sala não está mais aqui',
                textAlign: TextAlign.center,
                style: texto.headlineSmall,
              ),
              const SizedBox(height: Espaco.e2),
              Text(
                'Ela pode ter sido fechada. Crie outra ou entre com um '
                'código novo.',
                textAlign: TextAlign.center,
                style: texto.bodyLarge?.copyWith(color: c.texto2),
              ),
              const SizedBox(height: Espaco.e6),
              BotaoSala(
                rotulo: 'Voltar',
                icone: Symbols.arrow_back_rounded,
                variante: VarianteBotao.secundario,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
