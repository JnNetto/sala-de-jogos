import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/sala_tokens.dart';
import '../../navegacao.dart';
import '../../providers/pergunta_partida_provider.dart';
import '../../widgets/sala/botao_sala.dart';
import '../../widgets/sala/carta_revelacao.dart';
import '../../widgets/sala/dialogo.dart';
import '../../widgets/sala/tela_da_sala.dart';

/// A frente da carta do Pergunta Impostora: só a pergunta. Ninguém vê o
/// próprio papel, então não há selo nem cor de papel aqui.
class FrentePergunta extends StatelessWidget {
  const FrentePergunta({
    super.key,
    required this.pergunta,
    required this.efeito,
    required this.dica,
    required this.acao,
  });

  final String pergunta;
  final Animation<double> efeito;
  final String dica;

  /// O botão de baixo: "Esconder e passar" ou "Escrever resposta".
  final Widget acao;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luz(Matiz.rosa);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Faiscas(
          efeito: efeito,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: c.brilho(luz.cor, alpha: .4, blur: 40),
            ),
            child: Icon(
              Symbols.help_rounded,
              size: 56,
              fill: 1,
              color: luz.tinta,
            ),
          ),
        ),
        const SizedBox(height: Espaco.e3),
        Text(
          'SUA PERGUNTA',
          style: texto.labelSmall?.copyWith(color: c.texto3),
        ),
        const SizedBox(height: Espaco.e2),
        BlocoPergunta(pergunta: pergunta),
        const SizedBox(height: Espaco.e3),
        Text(
          dica,
          textAlign: TextAlign.center,
          style: texto.bodySmall?.copyWith(color: c.texto2),
        ),
        const SizedBox(height: Espaco.e4),
        acao,
      ],
    );
  }
}

/// A pergunta em destaque, num bloco com a luz do jogo.
class BlocoPergunta extends StatelessWidget {
  const BlocoPergunta({super.key, required this.pergunta});

  final String pergunta;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final luz = c.luz(Matiz.rosa);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Espaco.e4),
      decoration: BoxDecoration(
        color: luz.suave,
        borderRadius: BorderRadius.circular(Raio.lg),
        border: Border.all(color: c.ehDia ? c.contorno : luz.cor, width: 2),
        boxShadow: c.brilho(luz.cor, alpha: .25, blur: 24),
      ),
      child: Text(
        pergunta,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          fontVariations: const [FontVariation.weight(900)],
        ),
      ),
    );
  }
}

/// Abre a folha de escrever a resposta, acima do teclado. Devolve a
/// resposta, ou `null` se a pessoa fechou sem guardar.
Future<String?> escreverResposta(
  BuildContext context, {
  required String nome,
  required String pergunta,
}) {
  final tema = temaComLuz(Theme.of(context), context.cores.luz(Matiz.rosa));
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => Theme(
      data: tema,
      child: _FolhaResposta(nome: nome, pergunta: pergunta),
    ),
  );
}

class _FolhaResposta extends StatefulWidget {
  const _FolhaResposta({required this.nome, required this.pergunta});

  final String nome, pergunta;

  @override
  State<_FolhaResposta> createState() => _FolhaRespostaState();
}

class _FolhaRespostaState extends State<_FolhaResposta> {
  final _campo = TextEditingController();

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _guardar() {
    final resposta = _campo.text.trim();
    if (resposta.isEmpty) return;
    Navigator.of(context).pop(resposta);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final vazio = _campo.text.trim().isEmpty;
    return Padding(
      // A folha sobe junto com o teclado.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Espaco.margemTela,
          0,
          Espaco.margemTela,
          Espaco.e4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'A RESPOSTA DE ${widget.nome.toUpperCase()}',
              style: texto.labelSmall?.copyWith(color: c.texto3),
            ),
            const SizedBox(height: Espaco.e2),
            BlocoPergunta(pergunta: widget.pergunta),
            const SizedBox(height: Espaco.e5),
            Text('Sua resposta', style: texto.titleSmall),
            const SizedBox(height: Espaco.e2),
            TextField(
              controller: _campo,
              autofocus: true,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              style: texto.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontVariations: const [FontVariation.weight(700)],
              ),
              decoration: const InputDecoration(
                hintText: 'Curta e sem pensar muito',
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _guardar(),
            ),
            const SizedBox(height: Espaco.e3),
            BotaoSala(
              rotulo: vazio ? 'Escreva uma resposta' : 'Guardar e passar',
              icone: Symbols.check_rounded,
              luz: c.luz(Matiz.rosa),
              bloco: true,
              onPressed: vazio ? null : _guardar,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pergunta se abortam a partida; abortando, voltam para "Quem vai jogar?".
Future<void> abortarPerguntaImpostora(
  BuildContext context, {
  required String corpo,
  String escape = 'Continuar jogando',
}) async {
  final abortar = await mostrarDialogo(
    context,
    matiz: Matiz.rosa,
    barra: 'ATENÇÃO',
    icone: Symbols.stop_circle_rounded,
    titulo: 'Abortar a partida?',
    corpo: corpo,
    acao: 'Abortar',
    escape: escape,
    perigo: true,
  );
  if (abortar != true || !context.mounted) return;
  context.read<PerguntaPartidaProvider>().encerrarPartida();
  Navigator.of(context).popUntil(ehInicioDaImpostora);
}
