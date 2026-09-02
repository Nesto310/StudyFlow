# Arquitetura do StudyFlow

Este documento registra o estado implementado na Fase 2B e a próxima integração planejada. Funcionalidades futuras são apresentadas somente como alvo.

## Estado atual

O aplicativo Flutter e o backend ainda operam separadamente:

```text
Flutter UI
    |
    v
AppState local
    |
    +-- Subjects
    +-- Tasks
    +-- Availability

Backend FastAPI
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

O `AppState` continua sendo a fonte em memória do aplicativo. A Fase 2B não altera o Flutter nem substitui esse estado pela API.

O backend possui configuração por ambiente, sessões síncronas, modelos persistentes, migrations Alembic e health checks. Agora também possui registro, hashing Argon2, login OAuth2 Password, JWT Bearer, usuário atual e CRUD acadêmico. O Planner e a integração Flutter/API continuam fora do escopo.

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

## Próxima integração planejada

```text
Flutter
    |
    v
API Client
    |
    v
FastAPI
    |
    v
PostgreSQL
```

O cliente HTTP e a integração do estado Flutter com a API serão tratados na Fase 2C. Autenticação e CRUD já estão implementados no backend, mas o Flutter ainda não os consome.

## Responsabilidades atuais

### Flutter

- interface e navegação;
- tema da aplicação;
- estado local de disciplinas, tarefas e disponibilidade;
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
