# Arquitetura alvo

Este documento registra a arquitetura prevista para o StudyFlow. A Fase 1 consolida o domínio acadêmico e adiciona uma fonte única de estado em memória; ela ainda não implementa backend, banco, autenticação ou persistência.

## Estado local atual

```text
Flutter UI
    |
    v
AppState
    |
    +-- Subjects
    +-- Tasks
    +-- Availability
```

O `AppState` centraliza disciplinas, tarefas e disponibilidade. As telas consomem a mesma instância e solicitam alterações por métodos explícitos, evitando listas isoladas por tela.

Futuramente, o `AppState` deverá consumir a API FastAPI em vez de manter os dados somente em memória.

## Arquitetura futura

```text
Flutter Mobile
      |
      | HTTP/JSON
      v
FastAPI
      |
      v
PostgreSQL

FastAPI
   |
   +---- serviços externos / Gemini futuramente
```

## Flutter

Responsabilidades previstas:

- interface;
- navegação;
- estado da aplicação;
- consumo da API;
- experiência do usuário.

## FastAPI

Responsabilidades previstas:

- autenticação;
- regras de negócio;
- Planner;
- acesso ao banco;
- integração futura com IA;
- proteção de credenciais externas.

## PostgreSQL

Persistência prevista de:

- usuários;
- disciplinas;
- tarefas;
- disponibilidade;
- sessões de estudo;
- cronogramas.

## Segurança

Chaves privadas de serviços externos nunca devem ser armazenadas dentro do aplicativo Flutter. Credenciais como chaves Gemini devem ficar protegidas no backend ou em configuração local privada, nunca versionadas no repositório.
