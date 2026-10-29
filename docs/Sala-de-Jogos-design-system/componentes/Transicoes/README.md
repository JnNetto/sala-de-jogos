# Transicoes

Demonstração das três transições de navegação do app. A especificação completa está na seção Movimento.

- **Container transform** (home → home do jogo): o card cresce até ocupar a tela em `dur-lenta` com `curva-padrao`; a home some em 150 ms e o conteúdo do jogo aparece depois, subindo 12 px. Voltar faz o caminho inverso até o mesmo card. No Flutter: `OpenContainer` do pacote `animations`.
- **Eixo compartilhado X** (passos de um fluxo: jogadores → configuração → revelação): a tela atual sai 30 px para o lado em 90 ms, a próxima entra 30 px do lado oposto em 230 ms. Voltar inverte o sentido. `SharedAxisTransition(horizontal)`.
- **Janela** (diálogos e folhas): véu em fade e janela de 0,9 para 1 em `dur-media`.
