# CartaRevelacao

A carta de revelação de papel: o jogador segura o botão por 600 ms, a carta vira e mostra o papel. Substitui a tela cheia com `ScaleTransition`.

## Por que segurar

Tocar sem querer revela o papel para quem está ao lado. Segurar exige intenção e cria um micro suspense. Soltar antes dos 600 ms desfaz o anel.

## Anatomia

- Carta 300 × 400 (máx. 80% da largura), raio `raio-2xl`, `sombra-flutuante`.
- Verso: `superficie` com brilho `ceu-brilho` embaixo, rótulo "JOGADOR 3 DE 8" (`labelSmall`), nome em `displayMedium`, instrução em `bodyMedium` `texto-2`, botão de segurar de 112 com anel de progresso na cor do jogo e ícone `fingerprint`.
- Frente: `SeloPapel`, ícone 88 na cor do papel com brilho, palavra (civil) ou dica (espião), botão secundário "Esconder e passar".

## Movimento

- Segurando: o ícone encolhe para 0,88; o anel enche em 600 ms linear. Háptico leve ao começar.
- Virada: `rotateY` de 0 a 180° em `dur-dramatica` com `curva-padrao`, perspectiva 0,0012. Troca de face no meio (90°). Háptico médio no meio da virada; para o espião, pesado.
- Espião: depois da virada, um glitch de 260 ms (desloca 3 px com separação `carmim`/`ceu`), em dois passos. Civil: 8 faíscas pixel saem do ícone.
- Esconder: a carta volta em `dur-media`; ao terminar, o `Varal` do topo acende a lâmpada desse jogador.
