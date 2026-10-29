# Cronometro

O relógio HUD da rodada, em pixel, como o "00:25:12" das referências.

- Pílula de 44 de altura em `superficie` com filete `linha`, ícone `timer` em `texto-2`, tempo em `hud`.
- Dígitos em caixas de largura fixa (0,66 em; dois-pontos 0,4 em), porque a fonte pixel não tem números tabulares: o texto não pula quando o segundo muda.
- Atenção (≤10 s): fundo `lampada-suave`, texto `lampada-tinta`, borda `lampada`.
- Crítico (≤5 s): fundo `carmim-suave`, texto `carmim-tinta`, borda `carmim`, pulso de 1,06 por segundo e háptico leve a cada segundo.
- Fim: vibração média, o cronômetro treme e a `Contagem` ou o resultado entram.
- Pausado: dígitos piscam a 50% a cada 800 ms e o ícone vira `pause`.
