import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/sala_tokens.dart';
import '../../widgets/sala/botao_sala.dart';
import '../../widgets/sala/cartao_config.dart';
import '../../widgets/sala/tela_da_sala.dart';
import '../../widgets/so_uma/pecas_so_uma.dart';
import 'so_uma_configuracao_screen.dart';
import 'so_uma_entrada_sala_screen.dart';

/// Como a turma vai jogar: passando um celular só ou cada um no seu.
class SoUmaModoScreen extends StatelessWidget {
  const SoUmaModoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luz(matizSoUma);

    return TelaDaSala(
      titulo: 'Só uma!',
      matiz: matizSoUma,
      corpo: ListView(
        padding: const EdgeInsets.fromLTRB(
          Espaco.margemTela,
          Espaco.e4,
          Espaco.margemTela,
          Espaco.e6,
        ),
        children: [
          Text('Como vão jogar?', style: texto.headlineLarge),
          const SizedBox(height: Espaco.e2),
          Text(
            'As regras são as mesmas. Muda só quem segura o celular.',
            style: texto.bodyLarge?.copyWith(color: c.texto2),
          ),
          const SizedBox(height: Espaco.e6),
          CartaoConfig(
            icone: Symbols.smartphone_rounded,
            titulo: 'Num celular só',
            subtitulo:
                'O celular passa de mão em mão. Funciona sem internet, com '
                'todo mundo na mesma roda.',
            luz: luz,
            controle: BotaoSala(
              rotulo: 'Passar o celular',
              icone: Symbols.arrow_forward_rounded,
              iconeNoFim: true,
              luz: luz,
              bloco: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SoUmaConfiguracaoScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: Espaco.e3),
          CartaoConfig(
            icone: Symbols.devices_rounded,
            titulo: 'Cada um no seu',
            subtitulo:
                'Uma sala online com código. Cada um escreve a pista no '
                'próprio celular, sem ninguém espiar.',
            luz: luz,
            controle: BotaoSala(
              rotulo: 'Sala online',
              icone: Symbols.wifi_rounded,
              variante: VarianteBotao.secundario,
              bloco: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SoUmaEntradaSalaScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
