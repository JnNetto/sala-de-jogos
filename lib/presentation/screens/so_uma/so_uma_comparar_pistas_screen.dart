import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/so_uma_pista.dart';
import '../../providers/so_uma_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'so_uma_adivinhar_screen.dart';
import 'so_uma_passar_dispositivo_screen.dart';

class SoUmaCompararPistasScreen extends StatefulWidget {
  const SoUmaCompararPistasScreen({super.key});

  @override
  State<SoUmaCompararPistasScreen> createState() =>
      _SoUmaCompararPistasScreenState();
}

class _SoUmaCompararPistasScreenState extends State<SoUmaCompararPistasScreen> {
  bool _prontoParaChamarAdivinhador = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SoUmaPartidaProvider>();
    final partida = provider.partida;
    final rodada = partida?.rodadaAtual;
    if (partida == null || rodada == null) {
      return const Scaffold(body: Center(child: Text('Rodada não iniciada')));
    }

    if (_prontoParaChamarAdivinhador) {
      return SoUmaPassarDispositivoScreen(
        titulo: 'Chamem ${partida.adivinhadorAtual.nome} de volta',
        subtitulo: 'Ele vai ver só as pistas que sobraram.',
        icone: Icons.campaign,
        onConfirmar: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SoUmaAdivinharScreen()),
          );
        },
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comparar e Anular'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Toquem para anular pistas repetidas, da mesma família ou inválidas. '
                'As marcadas em vermelho já foram anuladas automaticamente, mas '
                'vocês podem corrigir.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              for (final pista in rodada.pistas)
                _PistaTile(
                  pista: pista,
                  onToggle: () => provider.alternarAnulacaoPista(pista.id),
                ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Pronto, ele pode adivinhar',
                icon: Icons.arrow_forward,
                onPressed: () {
                  provider.finalizarComparacao();
                  setState(() => _prontoParaChamarAdivinhador = true);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PistaTile extends StatelessWidget {
  final SoUmaPista pista;
  final VoidCallback onToggle;

  const _PistaTile({required this.pista, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cor = pista.anulada ? Colors.red : Colors.green;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onToggle,
        leading: Icon(
          pista.anulada ? Icons.block : Icons.check_circle_outline,
          color: cor,
        ),
        title: Text(
          pista.texto,
          style: TextStyle(
            decoration: pista.anulada ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: pista.motivoAutoAnulacao != null
            ? Text(_descricaoMotivo(pista.motivoAutoAnulacao!))
            : null,
        trailing: Switch(value: !pista.anulada, onChanged: (_) => onToggle()),
      ),
    );
  }

  String _descricaoMotivo(String motivo) {
    switch (motivo) {
      case 'identica':
        return 'Idêntica a outra pista';
      case 'plural':
        return 'Mesma palavra, no plural';
      case 'genero':
        return 'Mesma palavra, outro gênero';
      case 'raiz':
        return 'Possível mesma raiz de outra pista';
      case 'palavra_alvo':
        return 'É a própria palavra-alvo';
      case 'palavra_alvo_raiz':
        return 'Possível mesma raiz da palavra-alvo';
      default:
        return 'Anulada automaticamente';
    }
  }
}
