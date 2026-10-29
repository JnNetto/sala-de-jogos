# CartaoJogo

O card da lista de jogos da home. Cada jogo acende a própria cor: o poço de ícone brilha como uma tela no escuro. Substitui o `JogoCard`.

## O que o consumidor passa

Nome, ícone (Material Symbols Rounded), cor do jogo (`jogo-*`), descrição de uma linha, faixa de jogadores, duração e um estado opcional: `novo` ou `indisponivel`.

## Anatomia

- Card: `superficie`, raio `raio-xl`, padding `espaco-4`, altura mínima 96, filete `linha` e `sombra-card`. Lista com `espaco-3` entre cards.
- Poço 64 × 64, raio `raio-lg`, fundo `<cor>-suave`, ícone 32 em `<cor>-tinta`, halo da cor a 32% e linhas de CRT a 10% (detalhe de tela antiga).
- Título `titleLarge`, descrição `bodyMedium` em `texto-2`, tags `labelSmall` em pixel: jogadores na cor do jogo, duração neutra, "NOVO" em `lampada`.
- Seta `chevron_right` em `<cor>-tinta`.

## Interação

- Toque: escala 0,97 e fundo `superficie-elevada` em `dur-instante`; o halo sobe para 55% e o ícone balança (−8°, +6°, 0) em 320 ms. Volta com `curva-pulo`.
- Abrir: o card cresce até virar a home do jogo (container transform, `dur-lenta`). Ver Movimento.
- Entrada da lista: cards sobem 12 px e aparecem em cascata de 40 ms, `dur-base`, `curva-entrada`.
- Indisponível: `opac-desabilitado` e tag "EM BREVE"; não navega, só treme 4 px e mostra um `Aviso` informativo.
