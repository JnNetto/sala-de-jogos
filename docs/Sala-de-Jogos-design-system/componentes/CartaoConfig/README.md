# CartaoConfig

Card de uma opção de partida: ícone, título, subtítulo e o controle (slider, interruptor, contador ou campo). Substitui o `ConfigCard`.

- Card `superficie`, raio `raio-xl`, padding `espaco-4` em cima e `espaco-5` nas laterais e embaixo.
- Topo: ícone 24 na cor do contexto (`primaria-tinta` fora de jogo, `<cor>-tinta` dentro), título `titleLarge`, valor atual à direita em `hud`.
- Subtítulo `bodyMedium` em `texto-2`, `espaco-1` abaixo do título. Use para a recomendação ("Com 8 jogadores, recomendamos 2").
- Controle `espaco-4` abaixo. Interruptor fica na linha do título para economizar altura.
- Ao mudar o valor, o número em `hud` troca com deslize vertical de 8 px (`dur-base`).
