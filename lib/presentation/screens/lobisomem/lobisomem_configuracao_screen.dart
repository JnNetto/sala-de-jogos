import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/lobisomem_constants.dart';
import '../../../core/enums/lobisomem_consenso.dart';
import '../../../core/enums/lobisomem_empate.dart';
import '../../../core/enums/lobisomem_revelacao.dart';
import '../../../core/utils/service_locator.dart';
import '../../../data/models/lobisomem_configuracao.dart';
import '../../providers/lobisomem_partida_provider.dart';
import '../../widgets/config_card.dart';
import '../../widgets/primary_button.dart';
import 'lobisomem_distribuicao_screen.dart';

class LobisomemConfiguracaoScreen extends StatefulWidget {
  const LobisomemConfiguracaoScreen({super.key});

  @override
  State<LobisomemConfiguracaoScreen> createState() =>
      _LobisomemConfiguracaoScreenState();
}

class _LobisomemConfiguracaoScreenState
    extends State<LobisomemConfiguracaoScreen> {
  final List<TextEditingController> _nomeControllers = [];
  int _quantidadeJogadores = LobisomemConstants.minJogadores;
  int _narradorIndex = 0;
  int _quantidadeLobisomens = 1;
  bool _temVidente = true;
  bool _temBruxa = false;
  bool _temCacador = false;
  bool _temBobo = false;
  bool _temAnciao = false;
  bool _papeisEspeciaisAleatorios = false;
  LobisomemRevelacao _revelacao = LobisomemRevelacao.total;
  LobisomemEmpate _empate = LobisomemEmpate.defesaRevoto;
  bool _permitirAbstencao = false;
  bool _permitirVotoEmSi = true;
  int? _timerMinutos = LobisomemConstants.timerDiscussaoPadraoMinutos;
  LobisomemConsenso _consenso = LobisomemConsenso.semAtaqueSeDivergirem;
  bool _carregando = true;
  bool _cachePronto = false;

  @override
  void initState() {
    super.initState();
    _carregarCache();
  }

  Future<void> _carregarCache() async {
    LobisomemConfiguracao config = const LobisomemConfiguracao();
    try {
      config = await ServiceLocator().storageService.getConfiguracaoLobisomem();
    } catch (_) {
      config = const LobisomemConfiguracao();
    }
    if (!mounted) return;
    setState(() {
      _aplicarConfig(config);
      _carregando = false;
      _cachePronto = true;
    });
  }

  void _aplicarConfig(LobisomemConfiguracao config) {
    _quantidadeJogadores = config.quantidadeJogadores;
    _narradorIndex = config.narradorIndex;
    _quantidadeLobisomens = config.quantidadeLobisomens;
    _temVidente = config.temVidente;
    _temBruxa = config.temBruxa;
    _temCacador = config.temCacador;
    _temBobo = config.temBobo;
    _temAnciao = config.temAnciao;
    _papeisEspeciaisAleatorios = config.papeisEspeciaisAleatorios;
    _revelacao = config.revelacao;
    _empate = config.empate;
    _permitirAbstencao = config.permitirAbstencao;
    _permitirVotoEmSi = config.permitirVotoEmSi;
    _timerMinutos = config.timerDiscussaoMinutos;
    _consenso = config.consenso;
    _ajustarControllers(_quantidadeJogadores);
    for (var i = 0; i < _nomeControllers.length; i++) {
      if (i < config.nomesJogadores.length &&
          config.nomesJogadores[i].trim().isNotEmpty) {
        _nomeControllers[i].text = config.nomesJogadores[i];
      }
    }
  }

  void _aplicarRecomendado() {
    _quantidadeLobisomens = LobisomemConstants.lobisomensRecomendados(
      _quantidadeJogadores,
    );
    if (_papeisEspeciaisAleatorios) {
      _temVidente = false;
      _temBruxa = false;
      _temCacador = false;
      _temBobo = false;
      _temAnciao = false;
      return;
    }
    _temVidente = LobisomemConstants.videnteRecomendada(_quantidadeJogadores);
    _temBruxa = LobisomemConstants.bruxaRecomendada(_quantidadeJogadores);
    _temCacador = LobisomemConstants.cacadorRecomendado(_quantidadeJogadores);
    _temBobo = false;
    _temAnciao = false;
  }

  void _atualizar(VoidCallback fn) {
    setState(fn);
    _persistir();
  }

  Future<void> _persistir() async {
    if (!_cachePronto) return;
    try {
      await ServiceLocator().storageService.saveConfiguracaoLobisomem(
        _montarConfiguracao(),
      );
    } catch (_) {}
  }

  LobisomemConfiguracao _montarConfiguracao() {
    return LobisomemConfiguracao(
      quantidadeJogadores: _quantidadeJogadores,
      nomesJogadores: _nomes,
      narradorIndex: _narradorIndex,
      quantidadeLobisomens: _quantidadeLobisomens,
      temVidente: _temVidente,
      temBruxa: _temBruxa,
      temCacador: _temCacador,
      temBobo: _temBobo,
      temAnciao: _temAnciao,
      papeisEspeciaisAleatorios: _papeisEspeciaisAleatorios,
      narradorId: 'jogador_$_narradorIndex',
      revelacao: _revelacao,
      empate: _empate,
      permitirAbstencao: _permitirAbstencao,
      permitirVotoEmSi: _permitirVotoEmSi,
      timerDiscussaoMinutos: _timerMinutos,
      consenso: _consenso,
    );
  }

  void _ajustarControllers(int quantidade) {
    if (_nomeControllers.length < quantidade) {
      for (var i = _nomeControllers.length; i < quantidade; i++) {
        _nomeControllers.add(TextEditingController(text: 'Jogador ${i + 1}'));
      }
    } else if (_nomeControllers.length > quantidade) {
      while (_nomeControllers.length > quantidade) {
        _nomeControllers.removeLast().dispose();
      }
    }
    if (_narradorIndex >= quantidade) {
      _narradorIndex = 0;
    }
    _quantidadeLobisomens = _quantidadeLobisomens.clamp(1, _maxLobisomens);
  }

  List<String> get _nomes {
    return [
      for (var i = 0; i < _nomeControllers.length; i++)
        _nomeControllers[i].text.trim().isEmpty
            ? 'Jogador ${i + 1}'
            : _nomeControllers[i].text.trim(),
    ];
  }

  int get _especiais =>
      (_temVidente ? 1 : 0) +
      (_temBruxa ? 1 : 0) +
      (_temCacador ? 1 : 0) +
      (_temBobo ? 1 : 0) +
      (_temAnciao ? 1 : 0);

  int get _maxEspeciaisAleatorios =>
      LobisomemConstants.maxEspeciaisAleatorios(_quantidadeJogadores);

  int get _maxLobisomens {
    final peloTamanho = LobisomemConstants.maxLobisomens(_quantidadeJogadores);
    final especiaisContados = _papeisEspeciaisAleatorios
        ? _maxEspeciaisAleatorios
        : _especiais;
    final peloResto = _quantidadeJogadores - especiaisContados;
    return peloTamanho < peloResto ? peloTamanho : peloResto;
  }

  int get _aldeoes => LobisomemConstants.quantidadeAldeoes(
    quantidadeJogadores: _quantidadeJogadores,
    quantidadeLobisomens: _quantidadeLobisomens,
    temVidente: _temVidente,
    temBruxa: _temBruxa,
    temCacador: _temCacador,
    temBobo: _temBobo,
    temAnciao: _temAnciao,
  );

  bool get _composicaoValida {
    if (_quantidadeLobisomens < 1 ||
        _quantidadeLobisomens >= _quantidadeJogadores / 2) {
      return false;
    }
    if (_papeisEspeciaisAleatorios) {
      return _quantidadeLobisomens + _maxEspeciaisAleatorios <=
          _quantidadeJogadores;
    }
    return _aldeoes >= 0;
  }

  bool _podeAtivarEspecial(bool jaAtivo) {
    if (jaAtivo) return true;
    return _quantidadeLobisomens + _especiais + 1 <= _quantidadeJogadores;
  }

  Future<void> _iniciarPartida() async {
    if (!_composicaoValida) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<LobisomemPartidaProvider>();

    final configuracao = _montarConfiguracao();
    await _persistir();

    final sucesso = await provider.iniciarNovaPartida(
      nomes: _nomes,
      narradorIndex: _narradorIndex,
      configuracao: configuracao,
    );
    if (!mounted) return;

    if (sucesso) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const LobisomemDistribuicaoScreen()),
      );
    } else if (provider.erro != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _nomeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Partida')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ConfigCard(
              title: 'Jogadores',
              subtitle: 'Todos jogam, inclusive o Narrador. De 5 a 12 pessoas.',
              icon: Icons.group,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_quantidadeJogadores jogadores',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${LobisomemConstants.minJogadores}-${LobisomemConstants.maxJogadores}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _quantidadeJogadores.toDouble(),
                    min: LobisomemConstants.minJogadores.toDouble(),
                    max: LobisomemConstants.maxJogadores.toDouble(),
                    divisions:
                        LobisomemConstants.maxJogadores -
                        LobisomemConstants.minJogadores,
                    onChanged: (value) {
                      _atualizar(() {
                        _quantidadeJogadores = value.toInt();
                        _aplicarRecomendado();
                        _ajustarControllers(_quantidadeJogadores);
                      });
                    },
                  ),
                ],
              ),
            ),
            ConfigCard(
              title: 'Nomes dos Jogadores',
              subtitle: 'A ordem da mesa é a ordem desta lista',
              icon: Icons.edit,
              child: Column(
                children: [
                  for (var i = 0; i < _nomeControllers.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _nomeControllers[i],
                        decoration: InputDecoration(
                          labelText: 'Jogador ${i + 1}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => _atualizar(() {}),
                      ),
                    ),
                ],
              ),
            ),
            ConfigCard(
              title: 'Narrador',
              subtitle:
                  'É um dos jogadores: recebe papel, age à noite e vota. Também lê a historinha.',
              icon: Icons.menu_book,
              child: DropdownButtonFormField<int>(
                initialValue: _narradorIndex,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  for (var i = 0; i < _nomes.length; i++)
                    DropdownMenuItem(value: i, child: Text(_nomes[i])),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  _atualizar(() => _narradorIndex = value);
                },
              ),
            ),
            ConfigCard(
              title: 'Lobisomens',
              subtitle: 'Mínimo 1, e menos da metade da mesa',
              icon: Icons.nightlight_round,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _quantidadeLobisomens > 1
                        ? () => _atualizar(() => _quantidadeLobisomens--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$_quantidadeLobisomens',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  IconButton(
                    onPressed: _quantidadeLobisomens < _maxLobisomens
                        ? () => _atualizar(() => _quantidadeLobisomens++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            ConfigCard(
              title: 'Papéis especiais',
              subtitle: _papeisEspeciaisAleatorios
                  ? 'Até $_maxEspeciaisAleatorios especiais (jogadores − 4). Sorteados no início.'
                  : 'Aldeão preenche o restante',
              icon: Icons.style,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Especiais aleatórios'),
                    subtitle: Text(
                      'Máximo de $_maxEspeciaisAleatorios nesta mesa',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    value: _papeisEspeciaisAleatorios,
                    onChanged: (value) => _atualizar(() {
                      _papeisEspeciaisAleatorios = value;
                      if (value) {
                        _temVidente = false;
                        _temBruxa = false;
                        _temCacador = false;
                        _temBobo = false;
                        _temAnciao = false;
                      } else {
                        _aplicarRecomendado();
                      }
                      _quantidadeLobisomens = _quantidadeLobisomens.clamp(
                        1,
                        _maxLobisomens,
                      );
                    }),
                  ),
                  if (!_papeisEspeciaisAleatorios) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Vidente'),
                      value: _temVidente,
                      onChanged: _podeAtivarEspecial(_temVidente)
                          ? (value) => _atualizar(() => _temVidente = value)
                          : null,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bruxa'),
                      value: _temBruxa,
                      onChanged: _podeAtivarEspecial(_temBruxa)
                          ? (value) => _atualizar(() => _temBruxa = value)
                          : null,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Caçador'),
                      value: _temCacador,
                      onChanged: _podeAtivarEspecial(_temCacador)
                          ? (value) => _atualizar(() => _temCacador = value)
                          : null,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bobo da Corte'),
                      subtitle: const Text(
                        'Vence sozinho se for eliminado na votação',
                      ),
                      value: _temBobo,
                      onChanged: _podeAtivarEspecial(_temBobo)
                          ? (value) => _atualizar(() => _temBobo = value)
                          : null,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ancião'),
                      subtitle: const Text(
                        'Sobrevive ao 1º ataque dos lobisomens',
                      ),
                      value: _temAnciao,
                      onChanged: _podeAtivarEspecial(_temAnciao)
                          ? (value) => _atualizar(() => _temAnciao = value)
                          : null,
                    ),
                  ],
                ],
              ),
            ),
            ConfigCard(
              title: 'Composição',
              subtitle: 'Preview da mesa',
              icon: Icons.preview,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('$_quantidadeLobisomens Lobisomem(ns)')),
                  if (_papeisEspeciaisAleatorios)
                    Chip(
                      label: Text(
                        'Até $_maxEspeciaisAleatorios especiais aleatórios',
                      ),
                    )
                  else ...[
                    if (_temVidente) const Chip(label: Text('1 Vidente')),
                    if (_temBruxa) const Chip(label: Text('1 Bruxa')),
                    if (_temCacador) const Chip(label: Text('1 Caçador')),
                    if (_temBobo) const Chip(label: Text('1 Bobo da Corte')),
                    if (_temAnciao) const Chip(label: Text('1 Ancião')),
                    Chip(label: Text('$_aldeoes Aldeão(ões)')),
                  ],
                ],
              ),
            ),
            ConfigCard(
              title: 'Revelação dos mortos',
              icon: Icons.visibility,
              child: RadioGroup<LobisomemRevelacao>(
                groupValue: _revelacao,
                onChanged: (value) {
                  if (value == null) return;
                  _atualizar(() => _revelacao = value);
                },
                child: Column(
                  children: [
                    for (final opcao in LobisomemRevelacao.values)
                      RadioListTile<LobisomemRevelacao>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(opcao.nome),
                        subtitle: Text(opcao.descricao),
                        value: opcao,
                      ),
                  ],
                ),
              ),
            ),
            ConfigCard(
              title: 'Empate na votação',
              icon: Icons.balance,
              child: RadioGroup<LobisomemEmpate>(
                groupValue: _empate,
                onChanged: (value) {
                  if (value == null) return;
                  _atualizar(() => _empate = value);
                },
                child: Column(
                  children: [
                    for (final opcao in LobisomemEmpate.values)
                      RadioListTile<LobisomemEmpate>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(opcao.nome),
                        subtitle: Text(opcao.descricao),
                        value: opcao,
                      ),
                  ],
                ),
              ),
            ),
            ConfigCard(
              title: 'Votação',
              icon: Icons.how_to_vote,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Permitir abstenção'),
                    subtitle: const Text('Desligado por padrão'),
                    value: _permitirAbstencao,
                    onChanged: (value) =>
                        _atualizar(() => _permitirAbstencao = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Permitir voto em si'),
                    subtitle: const Text('Ligado por padrão'),
                    value: _permitirVotoEmSi,
                    onChanged: (value) =>
                        _atualizar(() => _permitirVotoEmSi = value),
                  ),
                ],
              ),
            ),
            ConfigCard(
              title: 'Timer da discussão',
              subtitle: 'Desligado ou de 3 a 10 minutos',
              icon: Icons.timer,
              child: DropdownButtonFormField<int?>(
                initialValue: _timerMinutos,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Desligado')),
                  for (var m = LobisomemConstants.timerDiscussaoMinMinutos;
                      m <= LobisomemConstants.timerDiscussaoMaxMinutos;
                      m++)
                    DropdownMenuItem(
                      value: m,
                      child: Text('$m minuto${m == 1 ? '' : 's'}'),
                    ),
                ],
                onChanged: (value) => _atualizar(() => _timerMinutos = value),
              ),
            ),
            ConfigCard(
              title: 'Consenso dos lobisomens',
              icon: Icons.groups,
              child: RadioGroup<LobisomemConsenso>(
                groupValue: _consenso,
                onChanged: (value) {
                  if (value == null) return;
                  _atualizar(() => _consenso = value);
                },
                child: Column(
                  children: [
                    for (final opcao in LobisomemConsenso.values)
                      RadioListTile<LobisomemConsenso>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(opcao.nome),
                        subtitle: Text(opcao.descricao),
                        value: opcao,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Consumer<LobisomemPartidaProvider>(
              builder: (context, provider, _) {
                return PrimaryButton(
                  text: 'Iniciar Partida',
                  icon: Icons.play_arrow,
                  isLoading: provider.isLoading,
                  onPressed: _composicaoValida ? _iniciarPartida : null,
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
