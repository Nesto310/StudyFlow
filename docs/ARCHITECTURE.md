# Arquitetura do StudyFlow

Este documento registra o estado implementado na Fase 3. Funcionalidades futuras são apresentadas somente como alvo.

## Estado atual

O Flutter nativo consome a API autenticada:

```text
StudyFlowApp
    +-- AuthState -- TokenStorage (secure storage)
    |       |
    |       +-------+
    +-- AppState    |
            |       |
            +-------+
            |
            v
        ApiClient (HTTP + Bearer)
            |
            v
        FastAPI
            |
            v
        Auth JWT
            |
            v
        API CRUD
            |
            v
        SQLAlchemy 2.x
            |
            v
        PostgreSQL
```

O `AppState` começa vazio e carrega disciplinas, tarefas e disponibilidade em paralelo. As listas são somente leitura e são substituídas juntas após um carregamento bem-sucedido. Criação, alteração e exclusão só mudam o snapshot depois da confirmação do servidor. UUIDs vêm do backend.

O backend mantém configuração por ambiente, sessões síncronas, modelos persistentes, migrations Alembic, health checks, registro, hashing Argon2, login OAuth2 Password, JWT Bearer, usuário atual e CRUD acadêmico. A Fase 3 adiciona o Planner como leitura/cálculo e uma sessão demo exclusiva de desenvolvimento, sem alteração de schema, migrations ou CORS. IA externa continua fora do escopo.

## Domínio persistente

```text
User
  +-- Subjects
  |     +-- Tasks
  +-- AvailabilitySlots
```

As entidades usam UUID. `Subject` referencia `User`, `Task` referencia `Subject` e `AvailabilitySlot` referencia `User`.

As FKs da Fase 2A continuam com `ON DELETE CASCADE` no banco. A API aplica uma regra mais restritiva: disciplina com tarefas vinculadas retorna 409 ao tentar excluir, preservando ambos. Não existe endpoint de exclusão de usuário. Nenhuma alteração de schema/migration foi necessária.

## Autenticação e propriedade

`/api/v1/auth/register` valida e normaliza o email e persiste somente o hash Argon2 da senha. `/api/v1/auth/token` recebe formulário OAuth2 Password, usando `username` como email, e retorna JWT com `sub` (UUID) e `exp` (UTC). O segredo é obrigatório, privado e configurado por ambiente; o algoritmo permitido é HS256, com expiração padrão de 30 minutos.

`get_current_user` valida assinatura, expiração e claims e busca o usuário. Falhas retornam 401 com Bearer, sem detalhes internos. No login, emails inexistentes passam por verificação com dummy hash e recebem o mesmo erro público de senha incorreta.

As queries de disciplinas e horários incluem `user_id` autenticado. Tarefas são filtradas por JOIN com disciplinas; criação e transferência de tarefa também validam a disciplina de destino. O cliente nunca define ownership. Acesso a recurso alheio retorna 404, e erros de integridade fazem rollback antes de responder com um conflito sanitizado.

## Sessão no Flutter

```text
initializing -> ler token -> /users/me
    +-- sem token / 401 -> unauthenticated -> AuthScreen
    +-- erro de rede -> erro + tentar novamente (token preservado)
    +-- 200 -> authenticated -> carregar AppState -> area principal
```

`AuthState` usa `ChangeNotifier`, sem framework adicional. Registro JSON é seguido de login automático; login envia `username` (email) e `password` como form-urlencoded. Somente o JWT é persistido via `TokenStorage`; o usuário atual é obtido da API e nenhuma senha é retida no estado. `StudyFlowApp` cria e descarta os estados e o cliente que possui.

Logout e 401 autenticado limpam imediatamente usuário, token em memória e listas acadêmicas, além de apagar o token do secure storage. Escritas/exclusões no storage são serializadas para evitar que um login pendente restaure um token depois do logout. Se a exclusão nativa falhar, a interface oferece tentar novamente e bloqueia a restauração até concluir a saída.

Requisições e operações de estado capturam a geração da sessão. Respostas atrasadas não repopulam dados de um usuário anterior nem invalidam a nova sessão. A árvore de navegação é substituída ao trocar de usuário, incluindo modais abertos. Os testes cobrem explicitamente usuário A, logout, usuário B e essas condições de concorrência.

## Transporte e mapeamento

`ApiClient` recebe `http.Client`, URL e timeout (15 segundos por padrão). Centraliza JSON, formulário, Bearer e `ApiException`. Erros 401/404/409/422/500, conexão e timeout recebem mensagens em português, sem exibir corpo arbitrário, HTML, SQL ou token. Um 401 público de login não aciona o encerramento de sessão.

Os mappers convertem snake_case para os models Flutter. `teacher: null` vira string vazia; datas de entrega são enviadas em UTC com timezone explícito e exibidas no fuso local. Horários FastAPI `HH:mm[:ss[.ffffff]]` são validados e convertidos para minutos, mantendo a resolução de minutos da UI. `durationMinutes` e `aiTip` não são enviados ao backend.

`API_BASE_URL` é configurada por `dart-define`, conforme os exemplos desktop/emulador no README. HTTP Android só é liberado em debug. O alvo é Flutter nativo; não há Flutter Web nesta fase.

## Responsabilidades atuais

### Flutter

- interface e navegação;
- tema da aplicação;
- autenticação, secure token storage e ciclo de sessão;
- snapshot remoto de disciplinas, tarefas e disponibilidade;
- solicitação e preview do Planner calculado pelo backend;
- cursos locais, separados do domínio acadêmico persistido;
- fallback local para dicas de estudo.

### FastAPI

- inicialização e documentação OpenAPI;
- health checks da aplicação e do banco;
- configuração segura por variáveis de ambiente;
- acesso ao banco por sessões SQLAlchemy;
- autenticação JWT e senhas Argon2;
- CRUD acadêmico com validações e isolamento por usuário.
- Planner determinístico e sessão demo exclusivamente em desenvolvimento.

### PostgreSQL e Alembic

- persistência de usuários e dados acadêmicos da API;
- integridade relacional;
- evolução versionada do schema.

## Segurança

Arquivos `.env`, credenciais pessoais, tokens e chaves privadas não são versionados. A integração futura com serviços externos deverá ocorrer pelo backend; nenhuma chave deve ser armazenada no Flutter.

## Planner V1

`Flutter -> solicita/exibe plano; FastAPI -> executa algoritmo`. Uma única regra mantém consistência entre dispositivos, simplifica a evolução e prepara a base para replanning e StudyFlow Coach, sem implementá-los agora. O Scheduler local e seu model antigo foram removidos após substituir os usos.

`POST /api/v1/planner/plan` exige JWT e busca tarefas por JOIN com disciplinas do `current_user`, além dos horários desse usuário. Não aceita `user_id`, IDs arbitrários, tarefas ou disponibilidade no corpo. É somente leitura, sem tabelas de plano, migrations, alterações automáticas ou histórico.

- `start_at`: datetime com fuso, opcional, padrão agora UTC; pode ser fixado para testes.
- `horizon_days`: inteiro 1..30, padrão 14; horizonte `[start_at, start_at + dias)`.
- `timezone_offset_minutes`: inteiro -840..840, padrão 0. O Flutter sempre envia o offset local atual. Disponibilidade semanal é expandida nesse offset fixo e a resposta usa UTC; a UI converte para local. Não há timezone IANA/DST persistido na V1.
- `repeat_next_week=false`: somente a primeira ocorrência futura do slot dentro do horizonte. A porção restante do slot de hoje conta como essa ocorrência. Ocorrências já encerradas são ignoradas.
- `repeat_next_week=true`: repetição semanal enquanto dentro do horizonte.
- Janelas são recortadas no início/fim do horizonte. Limites com segundos são arredondados para dentro, à resolução de um minuto. Sobreposições e horários adjacentes formam uma janela contínua, sem capacidade duplicada.
- Apenas tarefas pendentes, ordenadas por `due_date`, `created_at` e UUID. Earliest Deadline First usa `estimated_minutes` integralmente, dividindo tarefas ou colocando várias tarefas na mesma janela.
- `MAX_STUDY_BLOCK_MINUTES=90`; `BREAK_MINUTES=10` entre blocos da mesma janela contínua. Intervalos não viram blocos na resposta; se não restar um minuto útil, a janela termina.
- Para prazos futuros, nenhum bloco termina depois de `due_date`. Minutos restantes resultam em `at_risk`; alocação completa resulta em `on_track`.
- Prazo `<= start_at` resulta em `overdue`, mesmo se totalmente alocado. A tarefa vencida continua sendo planejada na primeira disponibilidade.
- Blocos estão em ordem cronológica; resumos de tarefas em ordem de prazo. `total_available_minutes` é a capacidade bruta das janelas unidas (antes dos intervalos), e os minutos planejados contam somente estudo.
- Sem tarefas: plano vazio válido. Sem disponibilidade: nenhum bloco e tarefas `at_risk`/`overdue`.

`AppState` guarda apenas o último plano em memória. CRUD acadêmico bem-sucedido, recarga dos dados e saída invalidam o plano. Dicas locais não invalidam. A geração tem loading, deduplicação e erro com retry preservando o plano anterior. Além da geração da sessão, uma revisão do plano impede que respostas anteriores a uma mutação substituam o estado atual. Não há geração automática.

## Modo demonstração temporário

O app factory registra `/api/v1/dev/demo-session` somente quando `APP_ENV` é exatamente `development`. O padrão é `production` (fail-closed); outros ambientes recebem 404 e não incluem a rota no OpenAPI. A rota pública não recebe credenciais, cria/busca um usuário comum e emite JWT normal com headers `no-store`. Não existem roles, admin ou permissões adicionais.

Email: `demo@studyflow.example.com`, domínio reservado compatível com `EmailStr`; `.local` não foi usado porque o validador atual o rejeita. O hash Argon2 deriva de uma senha aleatória interna nunca retornada. A conta é compartilhada por todas as sessões demo desse banco: alterações são visíveis entre desenvolvedores, portanto use apenas banco de desenvolvimento sem dados privados e rede restrita.

O seed ocorre somente quando disciplinas, tarefas e horários estão todos vazios. Cria três disciplinas, tarefas de 90/60/120 minutos com prazos relativos de 2/4/6 dias e sete horários 19:00-21:00. A linha do usuário é bloqueada na transação e a unicidade do email trata criação concorrente; validação de concorrência real requer PostgreSQL. Dados existentes não são apagados, duplicados ou resetados.

`DEMO_MODE` é centralizado em `app_config.dart`, temporariamente true por padrão em debug. Tanto a configuração quanto `ApiClient.startDemoSession` são protegidos por `kDebugMode`; override não habilita demo em release/profile. `AuthState` compartilha o caminho `setToken -> /users/me -> AppState.loadData` com o login real. JWT demo nunca é lido/escrito no secure storage; uma sessão real salva fica intacta. Logout volta para AuthScreen e desativa a entrada demo automática nesta execução. `DEMO_MODE=false` mantém login/registro/restauração seguros existentes.

A remoção antes da versão final está registrada em [TECHNICAL_DEBT.md](TECHNICAL_DEBT.md).
