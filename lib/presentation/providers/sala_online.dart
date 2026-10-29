import 'package:flutter/foundation.dart';

/// O que as telas de sala online precisam de um provider de sala: os
/// providers dos jogos online já têm esses nomes.
abstract interface class SalaOnline implements Listenable {
  bool get isLoading;
  String? get erro;
  String? get uid;
  bool get souHost;
  bool get podeIniciar;

  Future<bool> criarSala(String nome);
  Future<bool> entrarNaSala({required String codigo, required String nome});
  Future<bool> iniciarPartidaRemota();
  Future<bool> sairDaSalaRemota();
  Future<bool> removerJogadorRemoto(String targetUid);
  Future<bool> voltarAoLobbyRemoto();
  Future<bool> abortarPartidaRemota();
}
