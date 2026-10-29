# BotaoIcone

Botão quadrado de 48 × 48 para ações de navegação e de barra: voltar, abortar partida, estatísticas, fechar.

- Fundo `superficie` com filete `linha`; versão `nu` sem fundo para dentro de janelas e toasts.
- Ícone 24 em `texto`; abortar usa `carmim-tinta` e sempre pede confirmação (`Dialogo`).
- Raio `raio-md`. Ao tocar encolhe para 0,9 em `dur-instante` e volta com `curva-pulo`.
- Sempre com `tooltip`/`semanticLabel` ("Abortar partida"), porque não há texto visível.
- Substitui o `IconButton(stop_circle_outlined)` solto da app bar antiga.
