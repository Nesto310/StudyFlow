# Arquitetura do StudyFlow

Este documento registra o estado implementado na Fase 2A e a próxima integração planejada. Funcionalidades futuras são apresentadas somente como alvo.

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
SQLAlchemy 2.x
    |
    v
PostgreSQL
```

O `AppState` continua sendo a fonte em memória do aplicativo. A Fase 2A não altera o Flutter nem substitui esse estado pela API.

O backend possui configuração por ambiente, sessões síncronas, modelos persistentes, migrations Alembic e health checks. Ainda não possui autenticação, endpoints CRUD ou regras do Planner.

## Domínio persistente

```text
User
  +-- Subjects
  |     +-- Tasks
  +-- AvailabilitySlots
```

As entidades usam UUID. `Subject` referencia `User`, `Task` referencia `Subject` e `AvailabilitySlot` referencia `User`.

As FKs usam `ON DELETE CASCADE`: a remoção explícita de um usuário elimina seus dados acadêmicos, e a remoção explícita de uma disciplina elimina suas tarefas. O banco garante esse comportamento e a integridade referencial; ele não depende apenas das cascatas Python do ORM.

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

O cliente HTTP, a autenticação e o CRUD serão tratados nas próximas etapas da Fase 2. Eles não estão implementados nesta branch.

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
- acesso ao banco por sessões SQLAlchemy.

### PostgreSQL e Alembic

- persistência futura de usuários e dados acadêmicos;
- integridade relacional;
- evolução versionada do schema.

## Segurança

Arquivos `.env`, credenciais pessoais, tokens e chaves privadas não são versionados. A integração futura com serviços externos deverá ocorrer pelo backend; nenhuma chave deve ser armazenada no Flutter.
