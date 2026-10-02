import '../../core/enums/lobisomem_equipe.dart';
import '../../core/enums/lobisomem_papel.dart';

class LobisomemJogador {
  final String id;
  final String nome;
  final int assento;
  final LobisomemPapel papel;
  final bool vivo;
  final bool ehNarrador;
  final bool anciaoJaResistiu;

  const LobisomemJogador({
    required this.id,
    required this.nome,
    required this.assento,
    required this.papel,
    this.vivo = true,
    this.ehNarrador = false,
    this.anciaoJaResistiu = false,
  });

  LobisomemEquipe get equipe => papel.equipe;

  bool get ehLobisomem => papel.ehLobisomem;

  bool get ehCacador => papel == LobisomemPapel.cacador;

  bool get ehBobo => papel == LobisomemPapel.bobo;

  bool get ehAnciao => papel == LobisomemPapel.anciao;

  LobisomemJogador copyWith({
    String? id,
    String? nome,
    int? assento,
    LobisomemPapel? papel,
    bool? vivo,
    bool? ehNarrador,
    bool? anciaoJaResistiu,
  }) {
    return LobisomemJogador(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      assento: assento ?? this.assento,
      papel: papel ?? this.papel,
      vivo: vivo ?? this.vivo,
      ehNarrador: ehNarrador ?? this.ehNarrador,
      anciaoJaResistiu: anciaoJaResistiu ?? this.anciaoJaResistiu,
    );
  }
}
