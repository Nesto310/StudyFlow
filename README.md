# StudyFlow

## Visão do projeto

StudyFlow é um aplicativo Flutter para universitários que conciliam trabalho e estudos. O objetivo é ajudar a organizar disciplinas, tarefas, tempo disponível, cronogramas de estudo e progresso acadêmico em uma experiência simples para o dia a dia.

O projeto pretende evoluir para planejamento inteligente, replanejamento automático, recomendação de cursos e recursos de IA. A integração Gemini está planejada para uma fase futura através do backend. Neste momento, ainda não há backend real, banco de dados, autenticação, integração persistente entre todas as áreas nem planner completo em produção.

## Estado atual

- Aplicativo Flutter com Material 3.
- Tema claro/escuro controlado localmente.
- Navegação inferior com abas de tarefas, horários, cursos e perfil.
- Lista local de tarefas com criação simples, status de conclusão e dica de IA/fallback local.
- Lista local de disponibilidade com repetição semanal.
- Lista local de cursos com progresso visual.
- Algoritmo inicial de cronograma em `SchedulerService`.
- Experimento de dica de IA usando fallback local.

## Stack atual

- Flutter e Dart.
- Material 3.
- `http` para chamadas HTTP.
- `shared_preferences` disponível como dependência local.
- `flutter_lints` para regras básicas de qualidade.

## Como executar

```bash
flutter pub get
flutter run
```

## Estrutura atual

```text
lib/
  config/
    app_theme.dart
  models/
    availability_model.dart
    course_model.dart
    schedule_model.dart
    task_model.dart
  screens/
    availability/
    courses/
    profile/
    tasks/
    main_navigation_screen.dart
  services/
    ai_service.dart
    scheduler_service.dart
    theme_controller.dart
  main.dart
```

## Roadmap resumido

1. Fase 0 - organização.
2. Fase 1 - domínio e integração dos dados.
3. Fase 2 - FastAPI + PostgreSQL.
4. Fase 3 - Planner.
5. Fase 4 - Tela Hoje.
6. Fase 5 - replanejamento.
7. Fase 6 - recomendação de cursos.
8. Fase 7 - StudyFlow Coach / IA.
9. Fase 8 - polimento e competição.
