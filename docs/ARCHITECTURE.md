# Arquitetura alvo

Este documento registra a arquitetura prevista para o StudyFlow. A Fase 0 apenas prepara o repositorio; ela nao implementa backend, banco, autenticacao ou novas funcionalidades.

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
   +---- servicos externos / Gemini futuramente
```

## Flutter

Responsabilidades previstas:

- interface;
- navegacao;
- estado da aplicacao;
- consumo da API;
- experiencia do usuario.

## FastAPI

Responsabilidades previstas:

- autenticacao;
- regras de negocio;
- Planner;
- acesso ao banco;
- integracao futura com IA;
- protecao de credenciais externas.

## PostgreSQL

Persistencia prevista de:

- usuarios;
- disciplinas;
- tarefas;
- disponibilidade;
- sessoes de estudo;
- cronogramas.

## Seguranca

Chaves privadas de servicos externos nunca devem ser armazenadas dentro do aplicativo Flutter. Credenciais como chaves Gemini devem ficar protegidas no backend ou em configuracao local privada, nunca versionadas no repositorio.
