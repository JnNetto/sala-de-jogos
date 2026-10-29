# Movimento

O movimento da Sala de Jogos tem dois trabalhos: deixar claro o que mudou e fazer cada toque parecer um botão de fliperama. Ele nunca segura o jogador: nenhuma animação de interface passa de 450 ms, e as coreografias mais longas (virada da carta, contagem) são parte do jogo.

## Tokens

| Duração | Valor | Uso |
|---|---|---|
| `dur-instante` | 80 ms | Afundar ao pressionar |
| `dur-rapida` | 140 ms | Soltar, troca de cor, saída de toast |
| `dur-base` | 220 ms | Interruptor, slider, chip, troca de conteúdo |
| `dur-media` | 320 ms | Eixo compartilhado, diálogo, troca de tema |
| `dur-lenta` | 450 ms | Container transform do card de jogo |
| `dur-dramatica` | 640 ms | Virada da carta, número da contagem |
| `dur-ambiente` | 3200 ms | Cintilar (loop) |

| Curva | Cubic | Uso |
|---|---|---|
| `curva-padrao` | (0.2, 0, 0, 1) | Tudo que muda de lugar e fica na tela |
| `curva-entrada` | (0.05, 0.7, 0.1, 1) | Elementos entrando |
| `curva-saida` | (0.3, 0, 0.8, 0.15) | Elementos saindo, com 70% da duração de entrada |
| `curva-pulo` | (0.34, 1.56, 0.64, 1) | Retorno do toque, lâmpada acendendo, número e selo aparecendo |

Regra de bolso: entrou, `curva-entrada`; saiu, `curva-saida`; mudou de estado, `curva-padrao`; foi tocado ou comemorou, `curva-pulo`.

## Navegação

| De → para | Transição | Duração | Flutter |
|---|---|---|---|
| Home → home do jogo | Container transform: o card cresce até a tela inteira, a cor de fundo vai de `superficie` a `fundo`; o ícone do poço viaja como `Hero` até o ícone grande | `dur-lenta` | `OpenContainer` (`animations`), `transitionType: fadeThrough` |
| Home do jogo → configuração → mesa → revelação | Eixo compartilhado X: sai 30 px para a esquerda em 90 ms, entra 30 px da direita em 230 ms. Voltar inverte | `dur-media` | `SharedAxisTransition(transitionType: horizontal)` no `PageTransitionsTheme` |
| Rodada → resultado, contagem → rodada | Fade-through: sai com fade, entra com escala de 0,92 para 1 | `dur-media` | `FadeThroughTransition` |
| Abrir estatísticas, regras | Eixo compartilhado Y (folha sobe 30 px) | `dur-media` | `SharedAxisTransition(vertical)` |
| Diálogo | Véu em fade (`dur-base`) e janela de 0,9 para 1 subindo 8 px, a partir do ponto tocado | `dur-media` entra, `dur-rapida` sai | `showGeneralDialog` com `transitionBuilder` próprio |
| Folha inferior | Sobe com mola (rigidez 400, amortecimento 30), alça de 4 × 36 em `linha-forte` | ~300 ms | `showModalBottomSheet` com `AnimationStyle` |
| Splash → home | Fade-through com as lâmpadas do varal da splash continuando acesas no varal da home | `dur-media` | `PageRouteBuilder` |

Voltar pelo gesto do Android (predictive back) usa a mesma transição ao contrário; habilite `PredictiveBackPageTransitionsBuilder` só para rotas fora de partida, porque dentro da partida voltar pede confirmação.

## Toque

Todo elemento tocável segue a mesma física, implementada uma vez num widget `Pressionavel`:

1. **Pointer down:** escala para 0,97 (cards) ou 0,985 com descida de 3 px (botões), em `dur-instante` e `curva-padrao`. Háptico `lightImpact`.
2. **Pointer up dentro:** volta em `dur-rapida` com `curva-pulo` (passa um pouquinho do tamanho e assenta). A ação dispara no up, não no fim da animação.
3. **Cancelado (arrastou para fora):** volta em `dur-rapida` com `curva-padrao`, sem háptico.

Sem ripple do Material: `splashFactory: NoSplash.splashFactory`. O retorno visual é a descida e, nos cards, o fundo `superficie-elevada` e o brilho do poço subindo de 32% para 55%.

## Microinterações

| Componente | Movimento |
|---|---|
| Card de jogo | Ícone balança (−8°, +6°, 0) em 320 ms; seta anda 4 px para a direita |
| Lista de jogos | Entrada em cascata: cada card sobe 12 px com fade, 40 ms de atraso entre eles, `dur-base` |
| Interruptor | Bulbo estica para 24 px ao pressionar; desliza 24 px com `curva-pulo`; brilho acende em `dur-base` |
| Slider | Polegar cresce para 1,12 com halo de 10 px; janelinha com o valor sobe com `curva-pulo`; háptico a cada passo |
| Contador | Número sai para cima e entra por baixo (ou o contrário), `dur-base`, `curva-pulo` |
| Chip de jogador | Entra subindo 10 px de 0,85 para 1; sai encolhendo em `dur-rapida`; vizinhos fecham o espaço com `AnimatedList` |
| Campo | Borda e halo de foco em `dur-base`; erro treme 4 px uma vez |
| Alternar tema | Polegar desliza 36 px; lua e sol giram 90°; o app inteiro troca com `AnimatedTheme` em `dur-media` |
| Toast | Sobe 18 px de 0,96 para 1 em `dur-media`; sai descendo em `dur-rapida`; arrastar para baixo dispensa |
| Cronômetro | Atenção a ≤10 s (troca de cor em `dur-base`); crítico a ≤5 s pulsa 1,06 a cada segundo |
| Varal | Lâmpada acende crescendo para 1,35 e voltando, presa no soquete, `dur-media`, `curva-pulo` |
| Barra do topo | Ao rolar, ganha fundo `fundo` a 92% e desfoque em `dur-base` |
| Botão carregando | Três bolinhas acendem em sequência a cada 150 ms (ciclo de 900 ms) |

## Coreografias

### Splash (máximo 1,6 s)

1. 0 ms: céu `ceu-topo` → `fundo`, estrelas já no lugar.
2. 120 ms: o varal acende da esquerda para a direita, 70 ms por lâmpada, cada uma com o pulo de acender.
3. 520 ms: a marca (janela) aparece de 0,8 para 1 com `curva-pulo` em 500 ms; os quatro vidros acendem em sequência de 60 ms.
4. 760 ms: wordmark sobe 8 px com fade em `dur-media`.
5. Assim que os dados locais carregam (mínimo 1,2 s, máximo 1,6 s): fade-through para a home, com o varal continuando no topo.

A splash nativa (Android 12+ e iOS) mostra só o ícone sobre `ceu-topo`, para emendar sem piscar.

### Revelação de papel

1. Verso da carta com o nome; o varal de progresso mostra quem já viu.
2. Segurar o botão por 600 ms: anel enche linear; o ícone encolhe para 0,88. Soltar antes desfaz o anel em `dur-base`.
3. Virada: `rotateY` 0 → 180° em `dur-dramatica`, `curva-padrao`, perspectiva 0,0012. Háptico no meio (médio; pesado para espião).
4. Frente: selo entra de 0,8 para 1 com `curva-pulo`, 120 ms depois do fim da virada; palavra entra subindo 8 px, mais 80 ms.
5. Espião: glitch de 260 ms em dois passos (deslocamento de 3 px com sombras `carmim` e `ceu`). Civil: 8 estrelas pixel saem do ícone em 520 ms.
6. "Esconder e passar": carta volta em `dur-media`; a lâmpada desse jogador acende no varal; o próximo nome entra por eixo compartilhado X.

### Contagem e rodada

1. 3, 2, 1: cada número entra de 1,7 para 1 em `dur-dramatica`, anel esvazia em 1 s linear, háptico leve.
2. "JÁ!": 64 px, háptico médio, varal do topo pisca uma vez.
3. Fade-through para a rodada; cronômetro entra deslizando de cima.

### Resultado

1. Título ("Os civis venceram!") entra com escala de 0,9 e fade em `dur-media`.
2. Linhas de resultado em cascata de 60 ms.
3. Placar conta de 0 até o valor em 600 ms.
4. Vitória: faíscas pixel nas cores dos vencedores caem do topo por 1,2 s (máximo 40 partículas). Derrota: sem faíscas, só o selo do perdedor treme uma vez.

## Movimento reduzido

Quando `MediaQuery.disableAnimationsOf(context)` é verdadeiro:

- Durações de transição viram 120 ms de fade simples; container transform e eixo compartilhado viram fade.
- Sem cintilar, parallax, faíscas, glitch, tremidas e pulso. O cronômetro crítico só troca de cor.
- Virada da carta vira troca de face com fade de 120 ms. O botão de segurar continua (é segurança, não enfeite).
- Hápticos continuam, a menos que "Vibração" esteja desligada.
