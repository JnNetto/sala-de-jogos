# Padrões de tela

Todas as telas: fundo `Ceu`, margem `margem-tela`, conteúdo até 560 px, só retrato. As medidas abaixo usam os tokens.

## Splash

- Céu completo com varal decorativo no topo (14 lâmpadas).
- Marca (`marca-noite` ou `marca-dia`, 120 px) centralizada um pouco acima do meio; wordmark 220 px de largura `espaco-6` abaixo.
- Rodapé: varal em modo carregando (5 lâmpadas) só se os dados demorarem mais de 1 s.
- Segue o tema salvo, não o brilho do sistema. Coreografia na seção Movimento.

## Home

1. Topo: varal decorativo de ponta a ponta, colado à `SafeArea`; `AlternarTema` à direita, `espaco-4` abaixo do varal.
2. Cabeçalho: marca de 48 px e, ao lado, o título em `displayLarge` ("Sala de Jogos") alinhado à esquerda; abaixo, subtítulo `bodyLarge` em `texto-2` ("Escolha um jogo e chame a galera.").
3. `espaco-8`, depois a lista de `CartaoJogo` com `espaco-3` entre eles. Jogos novos sobem para o topo com a tag "NOVO".
4. Rodapé: versão em `labelSmall` `texto-3` centralizada, `espaco-12` abaixo do último card.
5. Ao rolar: título encolhe para `titleMedium` numa barra compacta (`SliverAppBar` com `collapsedHeight` 64), estrelas em parallax a 30%.

## Home de jogo

- `BarraTopo` com voltar e, à direita, regras (`menu_book`).
- Corpo centralizado: poço de 120 × 120 (`raio-2xl`) com ícone 56 na cor do jogo e `brilho-jogo` forte; `espaco-6`; título `displayMedium`; descrição `bodyLarge` `texto-2` em até três linhas; tags de jogadores e duração.
- Rodapé fixo: `Botao` de jogo em largura total ("Jogar"), `espaco-3`, `Botao` secundário ("Estatísticas") em largura total. `espaco-6` até a `SafeArea`.
- Fundo ganha um brilho radial da cor do jogo a 18% atrás do poço.

## Montar a mesa (jogadores)

- Título `headlineLarge` "Quem vai jogar?" e subtítulo com a faixa ("De 3 a 12 jogadores").
- `Campo` "Nome do jogador" com botão `+` dentro; Enter adiciona e mantém o foco.
- Chips em `Wrap` com `espaco-2`. Toque longo reordena.
- Contador ao vivo no rodapé, em `hud`: "5 JOGADORES".
- Botão "Continuar" desabilitado até o mínimo; ao habilitar, ele dá um pulo de 1,04.

## Configurar partida

- Pilha de `CartaoConfig` com `espaco-3`. Valores recomendados aparecem no subtítulo.
- Botão fixo "Começar" na cor do jogo.

## Revelação de papel

- `BarraTopo` com sobretítulo "REVELAÇÃO" e abortar; varal de progresso logo abaixo.
- `CartaRevelacao` centralizada, ocupando até 80% da largura.
- Nada mais na tela: sem dicas ou botões que entreguem o papel por cor de fundo. O brilho atrás da carta só muda depois da virada.

## Rodada

- `BarraTopo` com "RODADA 2 DE 5" e abortar; `Cronometro` centralizado abaixo.
- Conteúdo do jogo numa `Janela` ou em cards; ação principal fixa embaixo.
- Votação: lista de chips grandes (64 de altura) selecionáveis; selecionado ganha `marca-suave` de fundo, borda `marca` e o avatar acende.

## Resultado

- `Janela` com barra "FIM DE JOGO".
- Selo do vencedor (civis ou espiões) e frase curta em `headlineMedium`.
- Lista de `LinhaResultado` ou placar por jogador em `displaySmall`.
- Ações: "Jogar de novo" (jogo, largura total) e "Voltar ao início" (fantasma).

## Estatísticas

- Grade de `CartaoEstatistica` (2 colunas), depois histórico em lista de linhas de 56.
- Estado vazio: marca a 64 px com 40% de opacidade, "Nenhuma partida ainda" em `titleLarge` e "A primeira rodada fica registrada aqui." em `bodyMedium` `texto-2`, com botão "Jogar agora".

## Erro e sem conexão

- Erros de ação: `Aviso` de erro com "Tentar".
- Tela que não carrega: ícone `wifi_off` 48 em `carmim-tinta` dentro de poço `carmim-suave`, título `titleLarge`, explicação em `bodyMedium` e botão secundário "Tentar de novo". Jogos locais nunca mostram essa tela: funcionam offline.
