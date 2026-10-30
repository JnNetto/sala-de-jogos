import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/sala_tokens.dart';
import '../../providers/conta_provider.dart';
import 'aviso.dart';
import 'carregando_tela.dart';
import 'dialogo.dart';
import 'botao_sala.dart';
import 'cartao_config.dart';

/// O cartão da conta: com ninguém logado, os botões de entrar (Google e,
/// no iOS, Apple); logado, quem é e o "Sair da conta".
class CartaoConta extends StatelessWidget {
  const CartaoConta({
    super.key,
    this.luz,
    this.titulo = 'Sua conta',
    this.convite =
        'Entre com sua conta para jogar online. Os jogos num celular só '
        'funcionam sem login.',
  });

  final Luz? luz;
  final String titulo;

  /// O texto para quem ainda não entrou.
  final String convite;

  Future<void> _excluir(BuildContext context) async {
    final conta = context.read<ContaProvider>();
    final excluir = await mostrarDialogo(
      context,
      perigo: true,
      icone: Symbols.delete_forever_rounded,
      barra: 'EXCLUIR CONTA',
      titulo: 'Excluir sua conta?',
      corpo:
          'Sua conta é apagada, você sai das salas online e seu apelido some '
          'das partidas em andamento. Os jogos num celular só não mudam. '
          'Não dá para desfazer.',
      acao: 'Excluir para sempre',
      escape: 'Cancelar',
    );
    if (excluir != true || !context.mounted) return;
    final ok = await comCarregando(
      context,
      'Excluindo sua conta…',
      conta.excluirConta,
    );
    if (ok && context.mounted) {
      mostrarAviso(context, 'Conta excluída.', tipo: TipoAviso.sucesso);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = Theme.of(context).textTheme;
    final conta = context.watch<ContaProvider>();

    if (conta.logado) {
      return CartaoConfig(
        icone: Symbols.verified_user_rounded,
        titulo: conta.nome ?? 'Conta conectada',
        subtitulo: conta.email ?? 'Você pode jogar online.',
        luz: luz,
        controle: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BotaoSala(
              rotulo: 'Sair da conta',
              icone: Symbols.logout_rounded,
              variante: VarianteBotao.fantasma,
              luz: Luz(c.texto, c.texto2, c.superficieFunda),
              bloco: true,
              onPressed: conta.ocupado ? null : conta.sair,
            ),
            BotaoSala(
              rotulo: 'Excluir conta',
              icone: Symbols.delete_forever_rounded,
              variante: VarianteBotao.fantasma,
              luz: c.erro,
              bloco: true,
              onPressed: conta.ocupado ? null : () => _excluir(context),
            ),
            if (conta.erro != null) ...[
              const SizedBox(height: Espaco.e2),
              Text(
                conta.erro!,
                style: t.bodyMedium?.copyWith(color: c.erro.tinta),
              ),
            ],
          ],
        ),
      );
    }

    return CartaoConfig(
      icone: Symbols.account_circle_rounded,
      titulo: titulo,
      subtitulo: convite,
      luz: luz,
      controle: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BotaoSala(
            rotulo: 'Entrar com Google',
            icone: Symbols.login_rounded,
            luz: luz,
            bloco: true,
            carregando: conta.ocupado,
            onPressed: conta.entrarComGoogle,
          ),
          if (conta.temApple) ...[
            const SizedBox(height: Espaco.e3),
            BotaoSala(
              rotulo: 'Entrar com Apple',
              icone: Symbols.login_rounded,
              variante: VarianteBotao.secundario,
              bloco: true,
              onPressed: conta.ocupado ? null : conta.entrarComApple,
            ),
          ],
          if (conta.erro != null) ...[
            const SizedBox(height: Espaco.e3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Symbols.error_rounded, size: 18, color: c.erro.tinta),
                const SizedBox(width: Espaco.e2),
                Expanded(
                  child: Text(
                    conta.erro!,
                    style: t.bodyMedium?.copyWith(color: c.erro.tinta),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
