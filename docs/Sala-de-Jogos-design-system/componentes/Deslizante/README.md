# Deslizante

Slider para quantidades (jogadores, espiões, rodadas). Cobre o `SliderTheme`.

- Trilho de 10 px, `raio-pill`: inativo `superficie-funda` com filete `linha`; ativo na cor do contexto com brilho.
- Polegar 28 na cor do contexto com anel interno de 3 px em `sobre-cor`.
- Valores discretos ganham marcas de 4 px em `texto-3`.
- Ao arrastar: polegar cresce para 1,12 e ganha halo de 10 px; uma janelinha `janela-barra` com o valor em `hud` sobe com `curva-pulo`. Cada passo dá háptico `selectionClick`.
- Sempre mostre o valor também fora do slider (no `CartaoConfig`), porque a janelinha some ao soltar.
