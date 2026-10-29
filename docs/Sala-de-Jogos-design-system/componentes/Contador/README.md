# Contador

Seletor de mais e menos para números pequenos (rodadas, pontos para vencer). Intencional: o app hoje usa slider para tudo; para faixas de até 10 valores o contador é mais rápido e preciso.

- Caixa `superficie-funda`, raio `raio-lg`, padding 6. Botões são `BotaoIcone` de 48.
- Número `displaySmall` (32 px no contador) centralizado numa janela de 64 × 48.
- Ao mudar, o número antigo sai para cima (ou para baixo, ao diminuir) e o novo entra do lado oposto, em `dur-base` com `curva-pulo`.
- No limite, o botão fica desabilitado e o número treme 4 px uma vez. Háptico leve a cada passo.
