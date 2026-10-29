# Marca

A marca é uma janela acesa à noite: moldura, cortina de linho presa nas laterais, peitoril e quatro vidros nas cores de quatro jogos. Diz "sala com luz, gente jogando" e "vários jogos num lugar só".

- `icone-app.svg`: ícone do app em 1024 px, fundo de céu (`ceu-topo` → `fundo`), varal e janela. Fundo sangrado: a loja e o sistema aplicam a máscara. Exporte em PNG para `flutter_launcher_icons`.
- `icone-app-frente.svg`: só a janela, fundo transparente, para a camada da frente do ícone adaptativo do Android sobre `#0D0F2B`.
- `marca-noite.svg`: a janela com moldura `janela-barra` do Noite e halo âmbar, para fundos escuros (splash, home, estado vazio).
- `marca-dia.svg`: moldura em `contorno` (`#1B1D5C`), sem halo, para o tema Dia.
- `wordmark-noite.svg` (tinta `#F1EEFF`) e `wordmark-dia.svg` (tinta `#1B1D5C`): "Sala de Jogos" em Pixelify Sans Bold convertida em curvas. Use o da tinta do tema.

Regras: não recolora os vidros, não gire a janela, deixe em volta pelo menos um quarto da largura da marca de respiro. Abaixo de 32 px use só a marca, sem wordmark.
