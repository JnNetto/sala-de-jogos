# ChipJogador

Chip de um jogador na tela de montar a mesa. Intencional: hoje os nomes ficam numa lista simples; o chip dá identidade a cada pessoa ao longo da partida.

- Altura 48, raio `raio-md`, `superficie` com filete `linha`.
- Avatar 36 × 36 (`raio-sm`) com a inicial em pixel sobre uma cor da roda de jogadores: `violeta`, `rosa`, `menta`, `brasa`, `lampada`, `luar`, `ceu`, nessa ordem. A mesma cor acompanha o jogador na revelação e no placar.
- Nome `titleMedium`; remover é um `×` com alvo de 40 × 40 em `texto-3`.
- Entra subindo 10 px com escala de 0,85 para 1 em `dur-base` e `curva-pulo`; sai encolhendo em `dur-rapida`. Use `AnimatedList` para os vizinhos fecharem o espaço.
- Toque longo arrasta para reordenar (ordem de passar o celular), com o chip a 1,05 e `sombra-flutuante`.
