# StudyFlow

## Visao do projeto

StudyFlow e um aplicativo Flutter para universitarios que conciliam trabalho e estudos. O objetivo e ajudar a organizar disciplinas, tarefas, tempo disponivel, cronogramas de estudo e progresso academico em uma experiencia simples para o dia a dia.

O projeto pretende evoluir para planejamento inteligente, replanejamento automatico, recomendacao de cursos e recursos de IA. Neste momento, ainda nao ha backend real, banco de dados, autenticacao, integracao persistente entre todas as areas nem planner completo em producao.

## Estado atual

- Aplicativo Flutter com Material 3.
- Tema claro/escuro controlado localmente.
- Navegacao inferior com abas de tarefas, horarios, cursos e perfil.
- Lista local de tarefas com criacao simples, status de conclusao e dica de IA/fallback.
- Lista local de disponibilidade com repeticao semanal.
- Lista local de cursos com progresso visual.
- Algoritmo inicial de cronograma em `SchedulerService`.
- Experimento de dica de IA via Gemini quando configurado por ambiente, com fallback local quando nao ha chave.

## Stack atual

- Flutter e Dart.
- Material 3.
- `http` para chamadas HTTP.
- `shared_preferences` disponivel como dependencia local.
- `flutter_lints` para regras basicas de qualidade.

## Como executar

```bash
flutter pub get
flutter run
```

Para testar a integracao experimental com Gemini em ambiente local, use uma chave propria via `--dart-define`:

```bash
flutter run --dart-define=GEMINI_API_KEY=valor_ficticio
```

Sem essa variavel, o app continua funcionando com fallback local.

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

1. Fase 0 - organizacao.
2. Fase 1 - dominio e integracao dos dados.
3. Fase 2 - FastAPI + PostgreSQL.
4. Fase 3 - Planner.
5. Fase 4 - Tela Hoje.
6. Fase 5 - replanejamento.
7. Fase 6 - recomendacao de cursos.
8. Fase 7 - StudyFlow Coach / IA.
9. Fase 8 - polimento e competicao.
