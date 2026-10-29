# Interruptor

O switch é uma lâmpada: desligado, o bulbo fica apagado à esquerda; ligado, ele acende na cor do contexto e brilha. Cobre o `SwitchTheme`.

- Trilho 56 × 32, `raio-pill`. Desligado: `superficie-funda` com borda `linha-forte`; bulbo 20 em `texto-3`.
- Ligado: trilho `<cor>-suave` com borda `<cor>`; bulbo na `<cor>` com brilho de 14 px a 70%. Fora de jogo a cor é `primaria`.
- Alvo de toque de 48 em volta do trilho.
- Ao pressionar o bulbo estica para 24 de largura (como o Material 3); ao soltar desliza 24 px com `curva-pulo` em `dur-base`. Háptico `selectionClick`.
- Dia: contorno de 2 px em `contorno` no trilho e no bulbo aceso.
