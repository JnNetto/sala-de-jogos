import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/enums/lobisomem_papel.dart';
import '../../../data/models/lobisomem_jogador.dart';
import '../../../data/models/lobisomem_partida.dart';
import '../../providers/lobisomem_partida_provider.dart';
import '../../widgets/lobisomem_sair_partida.dart';
import '../../widgets/primary_button.dart';
import 'lobisomem_fluxo.dart';
import 'lobisomem_passar_dispositivo_screen.dart';

class LobisomemNoiteTurnoScreen extends StatefulWidget {
  final int passe;

  const LobisomemNoiteTurnoScreen({super.key, required this.passe});

  @override
  State<LobisomemNoiteTurnoScreen> createState() =>
      _LobisomemNoiteTurnoScreenState();
}

class _LobisomemNoiteTurnoScreenState extends State<LobisomemNoiteTurnoScreen> {
  int _indice = 0;
  bool _mostrandoPasse = true;
  String? _alvoSelecionado;
  bool _desistir = false;
  bool? _resultadoVidente;
  bool _usouCura = false;
  String? _venenoAlvoId;

  List<LobisomemJogador> _fila(LobisomemPartida partida) =>
      partida.vivosPorAssento;

  void _resetTurno() {
    _mostrandoPasse = true;
    _alvoSelecionado = null;
    _desistir = false;
    _resultadoVidente = null;
    _usouCura = false;
    _venenoAlvoId = null;
  }

  void _avancar(LobisomemPartidaProvider provider, LobisomemPartida partida) {
    final fila = _fila(partida);
    if (_indice + 1 >= fila.length) {
      if (widget.passe == 1) {
        provider.concluirPasse1();
      } else {
        provider.resolverNoite();
      }
      if (!mounted) return;
      continuarAposNoite(context, provider);
      return;
    }
    setState(() {
      _indice++;
      _resetTurno();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: lobisomemAppBar(context: context, title: 'Noite'),
        body: SafeArea(
          child: Consumer<LobisomemPartidaProvider>(
            builder: (context, provider, _) {
              final partida = provider.partida;
              if (partida == null) {
                return const Center(child: Text('Partida não iniciada'));
              }
              final fila = _fila(partida);
              if (fila.isEmpty || _indice >= fila.length) {
                return const Center(child: Text('Ninguém está acordado'));
              }
              final jogador = fila[_indice];

              if (_mostrandoPasse) {
                return LobisomemPassarDispositivoScreen(
                  titulo: 'Passe o celular para ${jogador.nome}',
                  subtitulo: 'Só esta pessoa deve olhar a próxima tela.',
                  onConfirmar: () => setState(() => _mostrandoPasse = false),
                );
              }

              if (widget.passe == 2) {
                return _PasseDois(
                  partida: partida,
                  jogador: jogador,
                  usouCura: _usouCura,
                  venenoAlvoId: _venenoAlvoId,
                  onToggleCura: (value) => setState(() => _usouCura = value),
                  onVeneno: (id) => setState(() => _venenoAlvoId = id),
                  onContinuar: () {
                    if (jogador.papel == LobisomemPapel.bruxa) {
                      provider.registrarAcaoBruxa(
                        usouCura: _usouCura,
                        venenoAlvoId: _venenoAlvoId,
                      );
                    }
                    _avancar(provider, partida);
                  },
                );
              }

              return _PasseUm(
                partida: partida,
                jogador: jogador,
                provider: provider,
                alvoSelecionado: _alvoSelecionado,
                desistir: _desistir,
                resultadoVidente: _resultadoVidente,
                onAlvo: (id) => setState(() {
                  _alvoSelecionado = id;
                  _desistir = false;
                }),
                onDesistir: () => setState(() {
                  _desistir = true;
                  _alvoSelecionado = null;
                }),
                onInvestigar: () {
                  if (_alvoSelecionado == null) return;
                  final resultado = provider.registrarInvestigacao(
                    _alvoSelecionado!,
                  );
                  setState(() {
                    _resultadoVidente = resultado;
                  });
                },
                onConfirmarLobo: () {
                  provider.registrarVotoLobisomem(
                    jogador.id,
                    _desistir ? null : _alvoSelecionado,
                  );
                  _avancar(provider, partida);
                },
                onDormir: () => _avancar(provider, partida),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PasseUm extends StatelessWidget {
  final LobisomemPartida partida;
  final LobisomemJogador jogador;
  final LobisomemPartidaProvider provider;
  final String? alvoSelecionado;
  final bool desistir;
  final bool? resultadoVidente;
  final ValueChanged<String> onAlvo;
  final VoidCallback onDesistir;
  final VoidCallback onInvestigar;
  final VoidCallback onConfirmarLobo;
  final VoidCallback onDormir;

  const _PasseUm({
    required this.partida,
    required this.jogador,
    required this.provider,
    required this.alvoSelecionado,
    required this.desistir,
    required this.resultadoVidente,
    required this.onAlvo,
    required this.onDesistir,
    required this.onInvestigar,
    required this.onConfirmarLobo,
    required this.onDormir,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                _CabecalhoPapel(jogador: jogador),
                const SizedBox(height: 24),
                if (jogador.papel == LobisomemPapel.lobisomem)
                  _AcaoLobisomem(
                    partida: partida,
                    jogador: jogador,
                    provider: provider,
                    alvoSelecionado: alvoSelecionado,
                    desistir: desistir,
                    onAlvo: onAlvo,
                    onDesistir: onDesistir,
                  )
                else if (jogador.papel == LobisomemPapel.vidente)
                  _AcaoVidente(
                    partida: partida,
                    jogador: jogador,
                    alvoSelecionado: alvoSelecionado,
                    resultado: resultadoVidente,
                    onAlvo: onAlvo,
                  )
                else
                  Text(
                    'Você dorme.',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          if (jogador.papel == LobisomemPapel.lobisomem)
            PrimaryButton(
              text: 'Confirmar',
              icon: Icons.check,
              onPressed: (desistir || alvoSelecionado != null)
                  ? onConfirmarLobo
                  : null,
            )
          else if (jogador.papel == LobisomemPapel.vidente &&
              resultadoVidente == null)
            PrimaryButton(
              text: 'Investigar',
              icon: Icons.search,
              onPressed: alvoSelecionado == null ? null : onInvestigar,
            )
          else
            PrimaryButton(
              text: 'Continuar',
              icon: Icons.arrow_forward,
              onPressed: onDormir,
            ),
        ],
      ),
    );
  }
}

class _CabecalhoPapel extends StatelessWidget {
  final LobisomemJogador jogador;

  const _CabecalhoPapel({required this.jogador});

  @override
  Widget build(BuildContext context) {
    final cor = jogador.ehLobisomem
        ? Colors.red
        : jogador.ehBobo
        ? Colors.purple
        : Colors.blue;
    return Column(
      children: [
        Text(
          jogador.nome,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          jogador.papel.nome,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: cor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          jogador.papel.descricao,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AcaoLobisomem extends StatelessWidget {
  final LobisomemPartida partida;
  final LobisomemJogador jogador;
  final LobisomemPartidaProvider provider;
  final String? alvoSelecionado;
  final bool desistir;
  final ValueChanged<String> onAlvo;
  final VoidCallback onDesistir;

  const _AcaoLobisomem({
    required this.partida,
    required this.jogador,
    required this.provider,
    required this.alvoSelecionado,
    required this.desistir,
    required this.onAlvo,
    required this.onDesistir,
  });

  @override
  Widget build(BuildContext context) {
    final alcateia = provider.alcateiaDe(jogador.id);
    final alvos = partida.vivos
        .where((vivo) => !vivo.ehLobisomem)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          alcateia.isEmpty
              ? 'Você age sozinho nesta noite.'
              : 'Alcateia: ${alcateia.map((lobo) => lobo.nome).join(', ')}',
          textAlign: TextAlign.center,
        ),
        if (partida.votosLobisomens.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Escolhas já feitas:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (final entrada in partida.votosLobisomens.entries)
            Text(
              '${partida.nomePorId(entrada.key)}: ${entrada.value == null ? 'desistiu' : partida.nomePorId(entrada.value!)}',
            ),
        ],
        const SizedBox(height: 16),
        Text(
          'Escolha uma vítima ou desista do ataque.',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: desistir ? '__desistir__' : alvoSelecionado,
          onChanged: (value) {
            if (value == null) return;
            if (value == '__desistir__') {
              onDesistir();
            } else {
              onAlvo(value);
            }
          },
          child: Column(
            children: [
              for (final alvo in alvos)
                RadioListTile<String>(
                  title: Text(alvo.nome),
                  value: alvo.id,
                ),
              const RadioListTile<String>(
                title: Text('Desistir de atacar'),
                value: '__desistir__',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AcaoVidente extends StatelessWidget {
  final LobisomemPartida partida;
  final LobisomemJogador jogador;
  final String? alvoSelecionado;
  final bool? resultado;
  final ValueChanged<String> onAlvo;

  const _AcaoVidente({
    required this.partida,
    required this.jogador,
    required this.alvoSelecionado,
    required this.resultado,
    required this.onAlvo,
  });

  @override
  Widget build(BuildContext context) {
    if (resultado != null) {
      return Column(
        children: [
          Icon(
            resultado! ? Icons.nightlight_round : Icons.cottage_outlined,
            size: 72,
            color: resultado! ? Colors.red : Colors.blue,
          ),
          const SizedBox(height: 16),
          Text(
            resultado! ? 'Lobisomem' : 'Não é Lobisomem',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: resultado! ? Colors.red : Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final alvos = partida.vivos
        .where((vivo) => vivo.id != jogador.id)
        .toList(growable: false);

    return Column(
      children: [
        Text(
          'Aponte alguém vivo para investigar.',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: alvoSelecionado,
          onChanged: (value) {
            if (value != null) onAlvo(value);
          },
          child: Column(
            children: [
              for (final alvo in alvos)
                RadioListTile<String>(
                  title: Text(alvo.nome),
                  value: alvo.id,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PasseDois extends StatelessWidget {
  final LobisomemPartida partida;
  final LobisomemJogador jogador;
  final bool usouCura;
  final String? venenoAlvoId;
  final ValueChanged<bool> onToggleCura;
  final ValueChanged<String?> onVeneno;
  final VoidCallback onContinuar;

  const _PasseDois({
    required this.partida,
    required this.jogador,
    required this.usouCura,
    required this.venenoAlvoId,
    required this.onToggleCura,
    required this.onVeneno,
    required this.onContinuar,
  });

  @override
  Widget build(BuildContext context) {
    final ehBruxa = jogador.papel == LobisomemPapel.bruxa;
    if (!ehBruxa) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Text(
              jogador.nome,
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Nada a fazer neste momento. Toque em Continuar.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            PrimaryButton(
              text: 'Continuar',
              icon: Icons.arrow_forward,
              onPressed: onContinuar,
            ),
          ],
        ),
      );
    }

    final vitima = partida.vitimaAtaqueId;
    final alvosVeneno = partida.vivos.toList(growable: false);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                Text(
                  'Bruxa',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  vitima == null
                      ? 'Nesta noite, ninguém foi marcado pela alcateia.'
                      : 'A vítima marcada é ${partida.nomePorId(vitima)}.',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (partida.bruxaTemCura && vitima != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Usar a poção de cura'),
                    subtitle: Text('Salva ${partida.nomePorId(vitima)}'),
                    value: usouCura,
                    onChanged: onToggleCura,
                  )
                else if (!partida.bruxaTemCura)
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('A cura já foi usada'),
                  )
                else
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Não há vítima para curar'),
                  ),
                const SizedBox(height: 12),
                if (partida.bruxaTemVeneno) ...[
                  Text(
                    'Poção de veneno',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  RadioGroup<String>(
                    groupValue: venenoAlvoId ?? '__guardar__',
                    onChanged: (value) {
                      if (value == null || value == '__guardar__') {
                        onVeneno(null);
                      } else {
                        onVeneno(value);
                      }
                    },
                    child: Column(
                      children: [
                        const RadioListTile<String>(
                          title: Text('Guardar o veneno'),
                          value: '__guardar__',
                        ),
                        for (final alvo in alvosVeneno)
                          RadioListTile<String>(
                            title: Text('Envenenar ${alvo.nome}'),
                            value: alvo.id,
                          ),
                      ],
                    ),
                  ),
                ] else
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('O veneno já foi usado'),
                  ),
              ],
            ),
          ),
          PrimaryButton(
            text: 'Continuar',
            icon: Icons.arrow_forward,
            onPressed: onContinuar,
          ),
        ],
      ),
    );
  }
}
