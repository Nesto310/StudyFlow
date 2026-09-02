# StudyFlow

## Visão do projeto

StudyFlow é um aplicativo Flutter para universitários que conciliam trabalho e estudos. O objetivo é ajudar a organizar disciplinas, tarefas, tempo disponível, cronogramas de estudo e progresso acadêmico em uma experiência simples para o dia a dia.

O projeto pretende evoluir para planejamento inteligente, replanejamento automático, recomendação de cursos e recursos de IA. A integração Gemini está planejada para uma fase futura através do backend. A Fase 2A adiciona a fundação da API e da persistência, mas ainda não há autenticação, CRUD, integração Flutter/API nem planner completo.

## Estado atual

- Aplicativo Flutter com Material 3.
- Tema claro/escuro controlado localmente.
- Navegação inferior com abas de tarefas, disciplinas, horários, cursos e perfil.
- Disciplinas acadêmicas em estado compartilhado.
- Tarefas vinculadas a disciplinas por `subjectId`.
- Disponibilidade em estado compartilhado com repetição semanal.
- Scheduler inicial usando tarefas e horários reais do estado local.
- Cursos externos mantidos separados de disciplinas acadêmicas.
- Experimento de dica de IA usando fallback local.
- Backend FastAPI com modelos SQLAlchemy, migrations Alembic e PostgreSQL como banco alvo.
- Health checks da aplicação e da conexão com o banco.

Nesta fase, o Flutter ainda não consome a API. Seus dados acadêmicos continuam somente no `AppState` local.

## Stack atual

- Flutter e Dart.
- Material 3.
- `http` disponível para chamadas HTTP futuras.
- `shared_preferences` disponível como dependência local.
- `flutter_lints` para regras básicas de qualidade.
- FastAPI e Uvicorn.
- SQLAlchemy 2.x e Alembic.
- PostgreSQL com psycopg 3.
- pytest e httpx para testes do backend.

## Como executar

```bash
flutter pub get
flutter run
```

As instruções do backend estão em [`backend/README.md`](backend/README.md).

## Arquitetura nesta fase

```text
Flutter
   |
   | futuramente HTTP
   v
FastAPI
   |
   v
PostgreSQL
```

O backend e o aplicativo são executáveis separadamente na Fase 2A.

## Estrutura atual

```text
lib/
  config/
    app_theme.dart
  models/
    availability_model.dart
    course_model.dart
    schedule_model.dart
    subject_model.dart
    task_model.dart
  screens/
    availability/
    courses/
    profile/
    subjects/
    tasks/
    main_navigation_screen.dart
  services/
    ai_service.dart
    scheduler_service.dart
    theme_controller.dart
  state/
    app_state.dart
  main.dart

backend/
  app/
  alembic/
  tests/
  requirements.txt
```

## Roadmap resumido

1. Fase 0 - organização.
2. Fase 1 - domínio e integração dos dados.
3. Fase 2A - fundação FastAPI + PostgreSQL.
4. Fase 2B - autenticação + CRUD da API.
5. Fase 2C - integração Flutter/API.
6. Fase 3 - Planner.
7. Fase 4 - Tela Hoje.
8. Fase 5 - replanejamento.
9. Fase 6 - recomendação de cursos.
10. Fase 7 - StudyFlow Coach / IA.
11. Fase 8 - polimento e competição.
