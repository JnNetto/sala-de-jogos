# Varal

O varal de luzes das referências virou componente: um fio com lâmpadas nas cores dos jogos. Intencional, é a assinatura visual do app e tem três usos.

## Modos

| Modo | Onde | Comportamento |
|---|---|---|
| Decorativo | Topo da home e splash | Todas acesas, cintilam com fases diferentes (`dur-ambiente`). |
| Progresso | Topo do fluxo de revelação, votação | Uma lâmpada por jogador, na cor do jogador. Acende quando ele termina a vez. |
| Carregando | Entrar na sala, sincronizar | Duas lâmpadas acesas correm pelo fio a cada 160 ms. Troca o `CircularProgressIndicator`. |

## Anatomia

- Fio: curva quadrática com barriga de 8 a 14 px, traço 1,5 em `linha-forte` (Dia: `contorno`).
- Soquete 6 × 5 em `linha-forte`; bulbo elipse 10 × 14.
- Apagada: `superficie-elevada` com filete `linha`. Acesa: a cor da lâmpada e um halo desfocado a 45% (só no Noite).

## Movimento

- Acender: o bulbo cresce para 1,35 e volta, em `dur-media` com `curva-pulo`, preso pelo soquete. Háptico leve.
- Cintilar: halo entre 25% e 60%, fase aleatória por lâmpada para não piscar em uníssono.
- Com movimento reduzido: sem cintilar e sem corrida; carregando vira as lâmpadas acesas fixas e um texto "Carregando".
