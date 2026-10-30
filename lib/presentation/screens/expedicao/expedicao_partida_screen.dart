import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/resistencia_constants.dart';
import '../../../core/enums/resistencia_fase.dart';
import '../../../core/enums/resistencia_papel.dart';
import '../../../core/enums/resistencia_vencedor.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../../data/models/resistencia_jogador.dart';
import '../../../data/models/resistencia_partida.dart';
import '../../navegacao.dart';
import '../../providers/resistencia_partida_provider.dart';
import '../../widgets/expedicao/pecas_expedicao.dart';
import '../../widgets/sala/botao_sala.dart';
import '../../widgets/sala/dialogo.dart';
import '../../widgets/sala/janela.dart';
import '../../widgets/sala/jogador_sala.dart';
import '../../widgets/sala/sala_online.dart';
import '../../widgets/sala/tela_da_sala.dart';
import 'expedicao_distribuicao_screen.dart';

/// O resultado de uma votação, guardado até a mesa tocar em "Continuar".
typedef _Voto = ({bool aprovada, int aFavor, int contra});

/// O resultado de uma câmara, guardado enquanto as cartas viram.
typedef _Camara = ({int numero, bool explorada, List<bool> cartas});

/// A Expedição num celular só, numa rota: o guia monta a equipe, a mesa
/// vota de mão aberta, quem entra joga a carta em segredo, as cartas viram
/// e, quando dá, o guia usa a Lanterna. As etapas trocam com um fade.
class ExpedicaoPartidaScreen extends StatefulWidget {
  const ExpedicaoPartidaScreen({super.key});

  @override
  State<ExpedicaoPartidaScreen> createState() => _ExpedicaoPartidaScreenState();
}

class _ExpedicaoPartidaScreenState extends State<ExpedicaoPartidaScreen> {
  /// Quem recusou na votação aberta (o resto segue).
  final _recusas = <String>{};
  _Voto? _voto;
  int _membro = 0;
  bool _membroPegou = false;
  _Camara? _camara;
  bool _cartasViradas = false;
  bool _guiaPegou = false;
  ({String nome, bool avancou})? _visao;

  ResistenciaPartidaProvider get _p =>
      context.read<ResistenciaPartidaProvider>();

  String _etapa(ResistenciaPartida p) {
    if (_camara != null) return 'camara';
    if (_voto != null) return 'voto';
    if (_visao != null) return 'visao';
    return switch (p.fase) {
      ResistenciaFase.propondo => 'propor',
      ResistenciaFase.votando => 'votar',
      ResistenciaFase.missao =>
        _membro >= p.equipeProposta.length
            ? 'revelar'
            : _membroPegou
            ? 'carta'
            : 'passar-carta',
      ResistenciaFase.lanterna => _guiaPegou ? 'lanterna' : 'passar-lanterna',
      ResistenciaFase.finalizada => 'fim',
    };
  }

  int _indice(ResistenciaPartida p, String id) =>
      p.jogadores.indexWhere((j) => j.id == id);

  Future<void> _sair() async {
    final p = _p;
    if (p.partida?.fase != ResistenciaFase.finalizada) {
      final sair = await mostrarDialogo(
        context,
        perigo: true,
        icone: Symbols.logout_rounded,
        barra: 'SAIR',
        titulo: 'Abandonar a expedição?',
        corpo: 'A partida acaba aqui e os papéis se perdem.',
        acao: 'Abandonar',
        escape: 'Continuar',
      );
      if (sair != true || !mounted) return;
    }
    p.limparPartida();
    Navigator.of(context).popUntil(ehBaseDosJogos);
  }

  void _contarVotos(ResistenciaPartida p) {
    for (final j in p.jogadores) {
      _p.registrarVotoProposta(j.id, !_recusas.contains(j.id));
    }
    final aFavor = p.jogadores.length - _recusas.length;
    final aprovada = aFavor > p.jogadores.length / 2;
    HapticFeedback.mediumImpact();
    _p.resolverVotacaoProposta();
    setState(() {
      _voto = (aprovada: aprovada, aFavor: aFavor, contra: _recusas.length);
      _recusas.clear();
      _membro = 0;
      _membroPegou = false;
    });
  }

  void _jogarCarta(ResistenciaPartida p, bool avancar) {
    _p.registrarCartaMissao(p.equipeProposta[_membro].id, avancar);
    setState(() {
      _membro++;
      _membroPegou = false;
    });
  }

  void _revelar(ResistenciaPartida p) {
    final cartas = [...p.cartasMissao.values]..shuffle();
    final numero = p.missaoAtual;
    _p.resolverMissao();
    final depois = _p.partida!;
    setState(() {
      _camara = (
        numero: numero,
        explorada: depois.ultimaMissaoSucesso ?? true,
        cartas: cartas,
      );
      _cartasViradas = false;
      _guiaPegou = false;
    });
  }

  void _usarLanterna(ResistenciaPartida p, ResistenciaJogador alvo) {
    final carta = _p.usarLanterna(alvo.id);
    if (carta == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _visao = (nome: alvo.nome, avancou: carta));
  }

  Future<void> _jogarDeNovo(ResistenciaPartida p) async {
    final nomes = [for (final j in p.jogadores) j.nome];
    final ok = await _p.iniciarNovaPartida(nomes);
    if (!ok || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ExpedicaoDistribuicaoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ResistenciaPartidaProvider>().partida;
    if (p == null) return const TelaDaSala(corpo: SizedBox.shrink());
    final etapa = _etapa(p);
    final numero = _camara?.numero ?? p.missaoAtual;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) _sair();
      },
      child: TelaDaSala(
        sobretitulo: etapa == 'fim'
            ? 'FIM DA EXPEDIÇÃO'
            : 'CÂMARA $numero DE ${ResistenciaConstants.totalMissoes}',
        titulo: ResistenciaConstants.jogoNome,
        matiz: matizExpedicao,
        inicio: BotaoIcone(
          icone: Symbols.close_rounded,
          rotulo: 'Sair da expedição',
          onPressed: _sair,
        ),
        corpo: TrocaDeFase(
          fase: '$etapa-$numero-$_membro-${p.tentativaAtual}',
          child: _conteudo(p, etapa),
        ),
      ),
    );
  }

  Widget _painel(ResistenciaPartida p) => PainelDaExpedicao(
    resultados: p.resultadosMissoes,
    tamanhos: p.tamanhosEquipe,
    atual: p.missaoAtual,
    jogadores: p.quantidadeJogadores,
    rejeicoes: p.rejeicoes,
    nota: p.lanternaUsada && p.lanternaAlvoId != null
        ? 'A Lanterna já foi usada em '
              '${p.jogadores.firstWhere((j) => j.id == p.lanternaAlvoId).nome}.'
        : null,
  );

  Widget _conteudo(ResistenciaPartida p, String etapa) {
    final c = context.cores;
    final t = Theme.of(context).textTheme;
    final luz = c.luz(matizExpedicao);
    final guia = p.liderAtual;

    switch (etapa) {
      case 'propor':
        final falta = p.tamanhoEquipeAtual - p.equipePropostaIds.length;
        return Etapa(
          rodape: BotaoSala(
            rotulo: falta > 0 ? 'Escolha mais $falta' : 'Levar para a votação',
            icone: Symbols.how_to_vote_rounded,
            luz: luz,
            bloco: true,
            onPressed: falta == 0
                ? () {
                    HapticFeedback.mediumImpact();
                    _p.confirmarProposta();
                  }
                : null,
          ),
          children: [
            _painel(p),
            const SizedBox(height: Espaco.e5),
            CabecaDaEtapa(
              nome: guia.nome,
              indice: _indice(p, guia.id),
              titulo: '${guia.nome} é o guia',
              texto:
                  'Escolha ${p.tamanhoEquipeAtual} pessoas para entrar na '
                  'câmara. Conversem antes: a mesa vai votar.',
            ),
            const SizedBox(height: Espaco.e4),
            for (final (i, j) in p.jogadores.indexed) ...[
              if (i > 0) const SizedBox(height: Espaco.e2),
              LinhaJogador(
                nome: j.nome,
                indice: i,
                selecionado: p.jogadorEstaNaProposta(j.id),
                apoio: j.id == guia.id ? 'Guia' : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _p.alternarJogadorNaProposta(j.id);
                },
                direita: p.jogadorEstaNaProposta(j.id)
                    ? Icon(
                        Symbols.check_circle_rounded,
                        fill: 1,
                        color: luz.tinta,
                      )
                    : null,
              ),
            ],
          ],
        );

      case 'votar':
        final contra = _recusas.length;
        final aFavor = p.jogadores.length - contra;
        return Etapa(
          rodape: BotaoSala(
            rotulo: 'Contar: $aFavor seguem, $contra recusam',
            icone: Symbols.check_rounded,
            luz: luz,
            bloco: true,
            onPressed: () => _contarVotos(p),
          ),
          children: [
            CabecaDaEtapa(
              titulo: 'A equipe segue?',
              texto:
                  'No três, todo mundo mostra o polegar. Toquem em quem '
                  'recusou. Com a maioria a favor, a equipe entra.',
            ),
            const SizedBox(height: Espaco.e4),
            Text('A EQUIPE', style: t.labelSmall?.copyWith(color: c.texto3)),
            const SizedBox(height: Espaco.e2),
            Wrap(
              spacing: Espaco.e2,
              runSpacing: Espaco.e2,
              children: [
                for (final j in p.equipeProposta)
                  ChipJogador(nome: j.nome, indice: _indice(p, j.id)),
              ],
            ),
            const SizedBox(height: Espaco.e5),
            for (final (i, j) in p.jogadores.indexed) ...[
              if (i > 0) const SizedBox(height: Espaco.e2),
              LinhaDeVoto(
                nome: j.nome,
                indice: i,
                segue: !_recusas.contains(j.id),
                aoTocar: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (!_recusas.remove(j.id)) _recusas.add(j.id);
                  });
                },
              ),
            ],
          ],
        );

      case 'voto':
        final v = _voto!;
        final acabou = p.fase == ResistenciaFase.finalizada;
        final restam = ResistenciaConstants.maxRejeicoes - p.rejeicoes;
        return Etapa(
          rodape: BotaoSala(
            rotulo: acabou
                ? 'Ver o fim'
                : v.aprovada
                ? 'Entrar na câmara'
                : 'Próximo guia',
            icone: Symbols.arrow_forward_rounded,
            iconeNoFim: true,
            luz: luz,
            bloco: true,
            onPressed: () => setState(() => _voto = null),
          ),
          children: [
            Janela(
              titulo: v.aprovada ? 'EQUIPE APROVADA' : 'EQUIPE RECUSADA',
              child: Column(
                children: [
                  Icon(
                    v.aprovada
                        ? Symbols.thumb_up_rounded
                        : Symbols.local_fire_department_rounded,
                    size: 48,
                    fill: v.aprovada ? 1 : 0,
                    color: v.aprovada ? c.explorador.tinta : c.texto3,
                  ),
                  const SizedBox(height: Espaco.e2),
                  Text(
                    v.aprovada ? 'A equipe segue!' : 'Uma tocha se apagou',
                    style: t.headlineMedium,
                  ),
                  const SizedBox(height: Espaco.e1),
                  Text(
                    '${v.aFavor} a favor, ${v.contra} contra.',
                    style: t.bodyLarge?.copyWith(color: c.texto2),
                  ),
                  if (!v.aprovada) ...[
                    const SizedBox(height: Espaco.e4),
                    Tochas(apagadas: p.rejeicoes),
                    const SizedBox(height: Espaco.e2),
                    Text(
                      acabou
                          ? 'Sem tochas, a expedição se perde no escuro.'
                          : restam == 1
                          ? 'Resta uma tocha. Mais uma recusa e os '
                                'saqueadores vencem.'
                          : 'Restam $restam tochas na partida.',
                      textAlign: TextAlign.center,
                      style: t.bodyMedium?.copyWith(color: c.texto2),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

      case 'passar-carta':
        final membro = p.equipeProposta[_membro];
        return PasseOCelular(
          matiz: matizExpedicao,
          nome: membro.nome,
          indice: _indice(p, membro.id),
          titulo: _membro == 0
              ? 'Passe para ${membro.nome}'
              : 'Agora, ${membro.nome}',
          texto:
              'Só ${membro.nome} olha. A carta é escolhida em segredo. '
              '(${_membro + 1} de ${p.equipeProposta.length})',
          acao: 'Sou eu',
          aoContinuar: () => setState(() => _membroPegou = true),
        );

      case 'carta':
        final membro = p.equipeProposta[_membro];
        return Etapa(
          children: [
            CabecaDaEtapa(
              nome: membro.nome,
              indice: _indice(p, membro.id),
              titulo: 'Dentro da câmara',
              texto: 'Escolha sua carta. Depois, passe o celular adiante.',
            ),
            const SizedBox(height: Espaco.e6),
            EscolhaDaCarta(
              saqueador: membro.papel == ResistenciaPapel.espiao,
              aoEscolher: (avancar) => _jogarCarta(p, avancar),
            ),
          ],
        );

      case 'revelar':
        return PasseOCelular(
          matiz: matizExpedicao,
          icone: Symbols.style_rounded,
          titulo: 'Todos jogaram',
          texto:
              'Celular no meio da mesa. As cartas viram embaralhadas: '
              'ninguém sabe quem jogou o quê.',
          acao: 'Virar as cartas',
          aoContinuar: () => _revelar(p),
        );

      case 'camara':
        final r = _camara!;
        final armadilhas = r.cartas.where((a) => !a).length;
        final acabou = p.fase == ResistenciaFase.finalizada;
        return Etapa(
          rodape: BotaoSala(
            rotulo: acabou ? 'Ver o fim' : 'Continuar',
            icone: Symbols.arrow_forward_rounded,
            iconeNoFim: true,
            luz: luz,
            bloco: true,
            onPressed: _cartasViradas
                ? () => setState(() => _camara = null)
                : null,
          ),
          children: [
            const SizedBox(height: Espaco.e4),
            CartasReveladas(
              cartas: r.cartas,
              aoTerminar: () {
                if (mounted) setState(() => _cartasViradas = true);
              },
            ),
            const SizedBox(height: Espaco.e6),
            AnimatedOpacity(
              duration: Movimento.lenta,
              opacity: _cartasViradas ? 1 : 0,
              child: ResultadoDaCamara(
                numero: r.numero,
                explorada: r.explorada,
                armadilhas: armadilhas,
              ),
            ),
          ],
        );

      case 'passar-lanterna':
        final dono = p.jogadores.firstWhere((j) => j.id == p.guiaDaLanterna);
        return PasseOCelular(
          matiz: matizExpedicao,
          nome: dono.nome,
          indice: _indice(p, dono.id),
          titulo: 'A Lanterna',
          texto:
              '${dono.nome} guiou essa câmara e pode usar a Lanterna, uma vez '
              'na partida, para ver a carta de alguém da equipe. Só '
              '${dono.nome} olha.',
          acao: 'Sou eu',
          aoContinuar: () => setState(() => _guiaPegou = true),
        );

      case 'lanterna':
        final equipe = [
          for (final j in p.jogadores)
            if (p.equipeDaUltimaMissao.contains(j.id) &&
                j.id != p.guiaDaLanterna)
              j,
        ];
        return Etapa(
          rodape: BotaoSala(
            rotulo: 'Guardar a Lanterna',
            icone: Symbols.flashlight_off_rounded,
            variante: VarianteBotao.secundario,
            bloco: true,
            onPressed: () {
              _p.guardarLanterna();
              setState(() => _guiaPegou = false);
            },
          ),
          children: [
            const CabecaDaEtapa(
              titulo: 'Usar a Lanterna?',
              texto:
                  'Toque em alguém da equipe para ver a carta que jogou. A '
                  'Lanterna só funciona uma vez na partida.',
            ),
            const SizedBox(height: Espaco.e4),
            for (final (i, j) in equipe.indexed) ...[
              if (i > 0) const SizedBox(height: Espaco.e2),
              LinhaJogador(
                nome: j.nome,
                indice: _indice(p, j.id),
                onTap: () => _usarLanterna(p, j),
                direita: Icon(Symbols.flashlight_on_rounded, color: luz.tinta),
              ),
            ],
            if (equipe.isEmpty)
              Text(
                'Só você entrou nesta câmara. Guarde a Lanterna.',
                style: t.bodyMedium?.copyWith(color: c.texto2),
              ),
          ],
        );

      case 'visao':
        final v = _visao!;
        return Etapa(
          rodape: BotaoSala(
            rotulo: 'Esconder e devolver',
            icone: Symbols.visibility_off_rounded,
            luz: luz,
            bloco: true,
            onPressed: () => setState(() {
              _visao = null;
              _guiaPegou = false;
            }),
          ),
          children: [
            const CabecaDaEtapa(
              titulo: 'A Lanterna mostrou',
              texto: 'Guarde só para você. Depois, decida o que contar.',
            ),
            const SizedBox(height: Espaco.e5),
            VisaoDaLanterna(nome: v.nome, avancou: v.avancou),
          ],
        );

      default:
        return Etapa(
          rodape: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BotaoSala(
                rotulo: 'Jogar de novo',
                icone: Symbols.replay_rounded,
                luz: luz,
                bloco: true,
                onPressed: () => _jogarDeNovo(p),
              ),
              const SizedBox(height: Espaco.e2),
              BotaoSala(
                rotulo: 'Sair',
                variante: VarianteBotao.fantasma,
                luz: Luz(c.texto, c.texto2, c.superficieFunda),
                bloco: true,
                onPressed: _sair,
              ),
            ],
          ),
          children: [
            FimDaExpedicao(
              exploradoresVenceram:
                  p.vencedor == ResistenciaVencedor.resistencia,
              porTochas: p.rejeicoes >= ResistenciaConstants.maxRejeicoes,
              resultados: p.resultadosMissoes,
              tamanhos: p.tamanhosEquipe,
              jogadores: p.quantidadeJogadores,
              papeis: [
                for (final (i, j) in p.jogadores.indexed)
                  (
                    nome: j.nome,
                    indice: i,
                    saqueador: j.papel == ResistenciaPapel.espiao,
                  ),
              ],
            ),
          ],
        );
    }
  }
}
