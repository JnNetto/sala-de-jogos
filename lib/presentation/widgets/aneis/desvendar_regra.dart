import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/sala_tokens.dart';
import '../../../data/models/aneis_estado_remoto.dart';
import '../../../data/models/aneis_palpite_regra.dart';
import '../sala/botao_opcao.dart';
import '../sala/botao_sala.dart';
import '../sala/pressionavel.dart';
import '../sala/tela_da_sala.dart';
import 'cores_dos_aneis.dart';

/// O nome de um anel na partida ("Letra"), pelo id.
String nomeDoAnel(AneisEstadoRemoto estado, String id) {
  for (final anel in estado.aneis) {
    if (anel.id == id && anel.nome.isNotEmpty) return anel.nome;
  }
  return switch (id) {
    'palavra' => 'Letra',
    'atributo' => 'Jeito',
    'contexto' => 'Lugar',
    _ => id,
  };
}

/// Os anéis que ainda dá para desvendar.
List<String> aneisPorDesvendar(AneisEstadoRemoto estado) => [
  for (final id in const ['palavra', 'atributo', 'contexto'])
    if (!estado.aneisDesvendados.any((r) => r.anel == id)) id,
];

/// Abre a folha do "Desvendar uma regra": escolher o anel e dizer a regra.
/// Com um Guardião de verdade, a regra é escrita; com o jogo como Guardião,
/// escolhida entre as opções. Devolve o palpite, ou `null` se desistir.
Future<({String anel, String palpite})?> mostrarDesvendarRegra(
  BuildContext context, {
  required AneisEstadoRemoto estado,
}) {
  final tema = temaComLuz(Theme.of(context), context.cores.luz(Matiz.ceu));
  return showModalBottomSheet<({String anel, String palpite})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => Theme(
      data: tema,
      child: _FolhaDesvendar(estado: estado),
    ),
  );
}

class _FolhaDesvendar extends StatefulWidget {
  const _FolhaDesvendar({required this.estado});

  final AneisEstadoRemoto estado;

  @override
  State<_FolhaDesvendar> createState() => _FolhaDesvendarState();
}

class _FolhaDesvendarState extends State<_FolhaDesvendar> {
  final _texto = TextEditingController();
  late String _anel = aneisPorDesvendar(widget.estado).first;
  String? _opcao;

  bool get _livre => widget.estado.knowerHumano;

  @override
  void initState() {
    super.initState();
    _texto.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  String? get _palpite {
    final p = _livre ? _texto.text.trim() : _opcao;
    return p == null || p.isEmpty ? null : p;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = Theme.of(context).textTheme;
    final luz = c.luz(Matiz.ceu);
    final estado = widget.estado;
    final opcoes = estado.opcoesRegras[_anel] ?? const <String>[];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Espaco.margemTela,
          0,
          Espaco.margemTela,
          Espaco.e5 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Desvendar uma regra', style: t.headlineSmall),
            const SizedBox(height: Espaco.e2),
            Text(
              'Acertou: você descarta 2 cartas e o anel fica aberto para '
              'todos. Errou: compra 1. A vez passa nos dois casos.',
              style: t.bodyMedium?.copyWith(color: c.texto2),
            ),
            const SizedBox(height: Espaco.e5),
            Text('QUAL ANEL', style: t.labelSmall?.copyWith(color: c.texto3)),
            const SizedBox(height: Espaco.e2),
            Row(
              children: [
                for (final (i, id) in aneisPorDesvendar(estado).indexed) ...[
                  if (i > 0) const SizedBox(width: Espaco.e2),
                  Expanded(
                    child: BotaoOpcao(
                      rotulo: nomeDoAnel(estado, id),
                      selecionado: _anel == id,
                      luz: c.luzDoAnel(id),
                      aoTocar: () => setState(() {
                        _anel = id;
                        _opcao = null;
                      }),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: Espaco.e5),
            Text(
              _livre ? 'QUAL É A REGRA' : 'QUAL DESTAS É A REGRA',
              style: t.labelSmall?.copyWith(color: c.texto3),
            ),
            const SizedBox(height: Espaco.e2),
            if (_livre)
              TextField(
                controller: _texto,
                autofocus: true,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                style: t.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Ex.: começa com vogal',
                  counterText: '',
                ),
              )
            else
              for (final (i, opcao) in opcoes.indexed) ...[
                if (i > 0) const SizedBox(height: Espaco.e2),
                _Opcao(
                  texto: opcao,
                  escolhida: _opcao == opcao,
                  luz: c.luzDoAnel(_anel),
                  aoTocar: () => setState(() => _opcao = opcao),
                ),
              ],
            if (_livre) ...[
              const SizedBox(height: Espaco.e2),
              Text(
                'O Guardião decide se o seu palpite vale.',
                style: t.bodySmall?.copyWith(color: c.texto3),
              ),
            ],
            const SizedBox(height: Espaco.e5),
            BotaoSala(
              rotulo: 'Arriscar',
              icone: Symbols.key_rounded,
              luz: luz,
              bloco: true,
              onPressed: _palpite == null
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pop((anel: _anel, palpite: _palpite!)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Opcao extends StatelessWidget {
  const _Opcao({
    required this.texto,
    required this.escolhida,
    required this.luz,
    required this.aoTocar,
  });

  final String texto;
  final bool escolhida;
  final Luz luz;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Semantics(
      button: true,
      selected: escolhida,
      label: texto,
      excludeSemantics: true,
      child: Pressionavel(
        onTap: aoTocar,
        escala: .98,
        child: AnimatedContainer(
          duration: Movimento.base,
          curve: Movimento.padrao,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(
            horizontal: Espaco.e4,
            vertical: Espaco.e3,
          ),
          decoration: BoxDecoration(
            color: escolhida ? luz.suave : c.superficieFunda,
            borderRadius: BorderRadius.circular(Raio.md),
            border: Border.all(
              color: escolhida
                  ? (c.ehDia ? c.contorno : luz.cor)
                  : (c.ehDia ? c.contorno : c.linha),
              width: escolhida ? 2 : c.bordaControle,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  texto,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: escolhida ? luz.tinta : c.texto,
                  ),
                ),
              ),
              if (escolhida) Icon(Symbols.check_rounded, color: luz.tinta),
            ],
          ),
        ),
      ),
    );
  }
}

/// O painel do Guardião para julgar um "Desvendar uma regra": o palpite, a
/// regra de verdade e os dois botões.
class JulgarPalpite extends StatelessWidget {
  const JulgarPalpite({
    super.key,
    required this.estado,
    required this.palpite,
    required this.regraCerta,
    required this.carregando,
    required this.aoJulgar,
  });

  final AneisEstadoRemoto estado;
  final AneisPalpiteRegra palpite;
  final String? regraCerta;
  final bool carregando;
  final ValueChanged<bool> aoJulgar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = Theme.of(context).textTheme;
    final luz = c.luzDoAnel(palpite.anel);
    final anel = nomeDoAnel(estado, palpite.anel);

    return Container(
      margin: const EdgeInsets.only(top: Espaco.e3),
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Raio.xxl),
        ),
        border: Border(
          top: BorderSide(color: c.ehDia ? c.contorno : luz.cor, width: 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Espaco.margemTela,
            Espaco.e4,
            Espaco.margemTela,
            Espaco.e4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'PALPITE DE ${palpite.nome.toUpperCase()} · ${anel.toUpperCase()}',
                style: t.labelSmall?.copyWith(color: luz.tinta),
              ),
              const SizedBox(height: Espaco.e1),
              Text('"${palpite.palpite}"', style: t.headlineSmall),
              if (regraCerta != null) ...[
                const SizedBox(height: Espaco.e2),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'A regra é: '),
                      TextSpan(
                        text: regraCerta,
                        style: TextStyle(color: luz.tinta),
                      ),
                    ],
                  ),
                  style: t.titleSmall?.copyWith(color: c.texto2),
                ),
              ],
              const SizedBox(height: Espaco.e2),
              Text(
                'Vale se disser o mesmo, mesmo com outras palavras.',
                style: t.bodySmall?.copyWith(color: c.texto3),
              ),
              const SizedBox(height: Espaco.e4),
              Row(
                children: [
                  Expanded(
                    child: BotaoSala(
                      rotulo: 'Errou',
                      icone: Symbols.close_rounded,
                      variante: VarianteBotao.secundario,
                      bloco: true,
                      onPressed: carregando ? null : () => aoJulgar(false),
                    ),
                  ),
                  const SizedBox(width: Espaco.e3),
                  Expanded(
                    child: BotaoSala(
                      rotulo: 'Acertou',
                      icone: Symbols.check_rounded,
                      luz: c.sucesso,
                      bloco: true,
                      carregando: carregando,
                      onPressed: () => aoJulgar(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
