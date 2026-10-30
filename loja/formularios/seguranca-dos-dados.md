# Segurança dos dados (Data safety)

Play Console → **Política e programas → Conteúdo do app → Segurança dos dados**.

As respostas abaixo seguem o que o app faz hoje (conta Google/Apple só para o
online, salas apagadas em até 2 horas paradas, sem anúncios, analytics ou
relatório de falhas). Antes de enviar, confira também a página oficial do
Firebase sobre esse formulário, que diz o que cada SDK coleta:
https://firebase.google.com/docs/android/play-data-disclosure

---

## 1. Coleta e segurança

| Pergunta | Resposta |
|---|---|
| O app coleta ou compartilha algum dos tipos de dados exigidos? | **Sim** |
| Todos os dados coletados são criptografados em trânsito? | **Sim** |
| Você oferece uma forma de os usuários pedirem a exclusão dos dados? | **Sim** — no app (Configurações → Conta → Excluir conta) e pela web |
| URL para pedir a exclusão da conta | https://sala-de-jogos-7298f.web.app/excluir-conta.html |

> "Compartilhar" para a Play é passar dados a terceiros. Provedores que
> processam em seu nome (Firebase/Google) **não** contam como
> compartilhamento. Por isso todos os itens abaixo ficam como
> "Coletado: sim / Compartilhado: não".

## 2. Tipos de dados

Marque **só** estes. Em todos: **Coletado = Sim**, **Compartilhado = Não**,
**Processado de forma temporária = Não**, **Obrigatório ou opcional =
Opcional** (só quem joga online entra com conta; o resto do app funciona sem).

### Informações pessoais
| Dado | Finalidades |
|---|---|
| **Nome** (nome da conta e apelido nas salas) | Funcionalidade do app · Gerenciamento da conta |
| **Endereço de e-mail** | Gerenciamento da conta |
| **IDs do usuário** (identificador da conta no Firebase) | Funcionalidade do app · Gerenciamento da conta |

### Atividade no app
| Dado | Finalidades |
|---|---|
| **Outro conteúdo gerado pelo usuário** (pistas, palpites e jogadas das partidas online) | Funcionalidade do app |

### IDs do dispositivo ou outros
| Dado | Finalidades |
|---|---|
| **IDs do dispositivo ou outros** (instalação do Firebase e verificação do App Check/Play Integrity) | Funcionalidade do app · Prevenção contra fraudes, segurança e conformidade |

> Este último item é a opção mais segura: os SDKs do Firebase usam um
> identificador de instalação, e o App Check verifica o aparelho. Declarar a
> mais não causa problema; deixar de declarar pode causar.

## 3. O que NÃO marcar

Localização · Informações financeiras · Saúde e condicionamento físico ·
Mensagens (não há chat) · Fotos e vídeos · Áudio · Arquivos e documentos ·
Agenda · Contatos · Histórico de navegação · Informações e desempenho do app
(sem analytics nem Crashlytics) · Outras ações do usuário no app.

> Se um dia entrar Firebase Analytics ou Crashlytics, este formulário precisa
> ser atualizado (Atividade no app e Informações e desempenho do app).
