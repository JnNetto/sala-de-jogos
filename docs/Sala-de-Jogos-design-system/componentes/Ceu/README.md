# Ceu

O fundo de todas as telas: o céu da sala à noite. Troca o `#F7F7F7`/`#121212` chapado.

- Degradê vertical de `ceu-topo` até `fundo` (55% da altura), mais um brilho radial `ceu-brilho` saindo do rodapé, como a luz de uma tela acesa.
- Camada de estrelas pixel (`estrela`): 18 a 28 por tela, entre cruz 9 × 9 e ponto 3 × 3, opacidade 55%. Uma em cada quatro cintila em `dur-ambiente` com fase aleatória. Posições fixas por tela (semente), para não "dançarem" ao navegar.
- Dia: o céu vira papel, com pontinhos `estrela` em grade de 18 px sobre o degradê `ceu-topo` → `fundo`. Sem cintilar.
- Home e splash recebem o `Varal` decorativo no topo; telas de fluxo não.
- Parallax: ao rolar a home, estrelas andam a 30% da velocidade do conteúdo e o varal a 60%.
- Nada de texto pequeno em cima do brilho: conteúdo fica em `superficie`.
