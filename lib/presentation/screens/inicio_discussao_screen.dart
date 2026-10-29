import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/sala_tokens.dart';
import '../providers/partida_provider.dart';
import '../widgets/sala/jogador_sala.dart';
import '../widgets/sala/tela_da_sala.dart';
import 'discussao_screen.dart';

class InicioDiscussaoScreen extends StatefulWidget {
  const InicioDiscussaoScreen({super.key});

  @override
  State<InicioDiscussaoScreen> createState() => _InicioDiscussaoScreenState();
}

class _InicioDiscussaoScreenState extends State<InicioDiscussaoScreen>
    with SingleTickerProviderStateMixin {
  int _tempoRestante = AppConstants.duracaoAnuncioJogadorInicialSegundos;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _tempoRestante--;
      });

      if (_tempoRestante <= 0) {
        timer.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DiscussaoScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final luz = c.luz(Matiz.violeta);
    final texto = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: TelaDaSala(
        matiz: Matiz.violeta,
        corpo: Consumer<PartidaProvider>(
          builder: (context, provider, _) {
            final partida = provider.partida;
            if (partida == null || partida.jogadorInicial == null) {
              return const Center(
                child: Text('Não deu para começar a partida.'),
              );
            }

            return SafeArea(
              top: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(Espaco.e6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'QUEM COMEÇA',
                        style: texto.labelMedium?.copyWith(color: luz.tinta),
                      ),
                      const SizedBox(height: Espaco.e4),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Espaco.e5,
                            vertical: Espaco.e4,
                          ),
                          decoration: BoxDecoration(
                            color: c.superficie,
                            borderRadius: BorderRadius.circular(Raio.xl),
                            border: Border.all(
                              color: c.ehDia ? c.contorno : luz.cor,
                              width: 2,
                            ),
                            boxShadow: [
                              ...c.sombraCard,
                              ...c.brilho(luz.cor, alpha: .35, blur: 40),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AvatarJogador(
                                nome: partida.jogadorInicial!.nome,
                                indice: partida.jogadorInicial!.id - 1,
                                tamanho: 48,
                              ),
                              const SizedBox(width: Espaco.e4),
                              // Nome em Nunito: precisa ser lido sem erro.
                              Flexible(
                                child: Text(
                                  partida.jogadorInicial!.nome,
                                  style: texto.headlineLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: Espaco.e12),
                      Container(
                        width: 88,
                        height: 88,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: luz.suave,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c.ehDia ? c.contorno : luz.cor,
                            width: 3,
                          ),
                        ),
                        child: Text(
                          '$_tempoRestante',
                          style: context.estilos.hud.copyWith(
                            fontSize: 40,
                            height: 1,
                            color: luz.tinta,
                          ),
                        ),
                      ),
                      const SizedBox(height: Espaco.e4),
                      Text(
                        'A discussão começa já já.',
                        style: texto.bodyMedium?.copyWith(color: c.texto2),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
