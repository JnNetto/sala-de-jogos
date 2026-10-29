# BarraTopo

A app bar dos fluxos de jogo: transparente sobre o céu, com botões quadrados nas pontas. Substitui a app bar roxa sólida.

- Altura 64, `backgroundColor` transparente, `elevation` 0, `scrolledUnderElevation` 0. Ao rolar, ganha fundo `fundo` a 92% com desfoque de 12 px e filete `linha` embaixo, em `dur-base`.
- Esquerda: `BotaoIcone` voltar. Direita: uma ação (abortar em `carmim-tinta`, regras, estatísticas).
- Título centralizado em `titleMedium` peso 900 com sobretítulo opcional em pixel (`labelSmall`) na cor do jogo: "RODADA 2 DE 5".
- Abaixo dela pode entrar o `Varal` de progresso.
- A home principal não tem barra: o título grande e o `AlternarTema` ficam no próprio conteúdo.
