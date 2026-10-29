# Contagem

A contagem regressiva antes de uma rodada começar. Substitui o número de 32 px solto.

- Anel de 200 com traço 8: trilho `superficie-funda`, anel na cor do jogo com brilho. Ele esvazia em 1 s linear a cada número.
- Número em pixel 96 (`Display`), "JÁ!" em 64.
- Cada número entra de 1,7 para 1 com fade em `dur-dramatica` e `curva-pulo`. Háptico leve em 3, 2, 1 e médio no "JÁ!".
- Ao terminar, a contagem some com escala 0,9 em `dur-rapida` e a tela da rodada entra por fade-through.
- Com movimento reduzido: só troca o número, sem anel animado.
