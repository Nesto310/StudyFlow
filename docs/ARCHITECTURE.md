# Arquitetura do StudyFlow

Este documento registra o estado implementado na Fase 2C. Funcionalidades futuras são apresentadas somente como alvo.

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

O backend aprovado da Fase 2B mantém configuração por ambiente, sessões síncronas, modelos persistentes, migrations Alembic, health checks, registro, hashing Argon2, login OAuth2 Password, JWT Bearer, usuário atual e CRUD acadêmico. A integração não exige alteração de schema, migrations ou CORS. Planner e IA externa continuam fora do escopo.

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
- Scheduler local sobre dados recebidos da API, sem mudança de algoritmo;
- cursos locais, separados do domínio acadêmico persistido;
- fallback local para dicas de estudo.

### FastAPI

- inicialização e documentação OpenAPI;
- health checks da aplicação e do banco;
- configuração segura por variáveis de ambiente;
- acesso ao banco por sessões SQLAlchemy;
- autenticação JWT e senhas Argon2;
- CRUD acadêmico com validações e isolamento por usuário.

### PostgreSQL e Alembic

- persistência de usuários e dados acadêmicos da API;
- integridade relacional;
- evolução versionada do schema.

## Segurança

Arquivos `.env`, credenciais pessoais, tokens e chaves privadas não são versionados. A integração futura com serviços externos deverá ocorrer pelo backend; nenhuma chave deve ser armazenada no Flutter.
