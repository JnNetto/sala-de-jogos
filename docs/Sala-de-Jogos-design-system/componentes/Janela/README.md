# Janela

A janela de sistema retrô das referências: uma barra de título com três luzinhas e o título em pixel, sobre um corpo arredondado. É a moldura dos momentos de foco.

## Quando usar

- Diálogos (`Dialogo`), regras rápidas, configurações de partida, sala de espera.
- A carta de revelação e o resultado final podem usar a barra para dar o rótulo ("SEU PAPEL", "FIM DE JOGO").
- Não use em listas: card de lista é `CartaoJogo` ou `CartaoConfig`. Mais de uma janela na mesma tela vira ruído.

## Anatomia

- Barra: altura 40, fundo `janela-barra`, título `labelMedium` em CAIXA ALTA em `janela-barra-texto`, três quadradinhos 8 × 8 (raio 2) em `lampada`, `rosa` e `menta`. Fechar opcional à direita, alvo de 40 px dentro de uma barra de 40.
- Corpo: `superficie`, padding `espaco-6`, raio externo `raio-xl`.
- Noite: filete `linha` de `borda-fina` e `sombra-card`. Dia: contorno 2 px em `contorno`, barra cobalto e sombra dura.

## Movimento

Abre com escala de 0,9 para 1 e sobe 8 px, em `dur-media` com `curva-entrada`, a partir do ponto tocado. Fecha em 70% do tempo com `curva-saida`.
