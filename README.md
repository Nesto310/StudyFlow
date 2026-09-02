# StudyFlow

## Visão do projeto

StudyFlow é um aplicativo Flutter para universitários que conciliam trabalho e estudos. O objetivo é ajudar a organizar disciplinas, tarefas, tempo disponível, cronogramas de estudo e progresso acadêmico em uma experiência simples para o dia a dia.

O projeto pretende evoluir para replanejamento automático, recomendação de cursos e recursos de IA. A Fase 3 implementa o Planner V1 determinístico no backend e um modo demonstração temporário de desenvolvimento. Gemini continua planejado para uma fase futura via backend; nenhuma credencial externa pertence ao aplicativo.

## Estado atual

- Aplicativo Flutter com Material 3.
- Tema claro/escuro controlado localmente.
- Navegação inferior com abas de tarefas, disciplinas, horários, cursos e perfil.
- Login, criação de conta, restauração de sessão e logout.
- Disciplinas acadêmicas carregadas e persistidas pela API.
- Tarefas vinculadas a disciplinas por `subjectId`.
- Disponibilidade criada e persistida pela API, com repetição semanal.
- Planner V1 no backend com preview na aba Horários.
- Modo demonstração temporário em debug, com dados semeados pela API de desenvolvimento.
- Cursos externos mantidos separados de disciplinas acadêmicas.
- Experimento de dica de IA usando fallback local.
- Backend FastAPI com modelos SQLAlchemy, migrations Alembic e PostgreSQL como banco alvo.
- Health checks da aplicação e da conexão com o banco.
- Registro/login com Argon2 e JWT Bearer, além de CRUD acadêmico isolado por usuário.

Os dados acadêmicos do Flutter agora vêm da API, sem exemplos hardcoded no `AppState`. Cursos e dicas de estudo (fallback de IA) continuam locais. A dica é transitória e pode desaparecer ao recarregar tarefas.

## Stack atual

- Flutter e Dart.
- Material 3.
- `http` para chamadas HTTP centralizadas no `ApiClient`.
- `flutter_secure_storage` para persistir somente o access token.
- `shared_preferences` disponível como dependência local.
- `flutter_lints` para regras básicas de qualidade.
- FastAPI e Uvicorn.
- SQLAlchemy 2.x e Alembic.
- PostgreSQL com psycopg 3.
- pytest e httpx para testes do backend.
- PyJWT, pwdlib (Argon2), python-multipart e email-validator para autenticação/validação.

## Como executar

Primeiro execute o backend conforme [`backend/README.md`](backend/README.md), incluindo configuração privada de `JWT_SECRET_KEY` e migrations. PostgreSQL continua sendo o banco alvo.

Desktop, com FastAPI na mesma máquina:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Android Emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

`10.0.2.2` representa a máquina host no Android Emulator. Em dispositivo físico, use o IP LAN da máquina do FastAPI em `API_BASE_URL`; o servidor precisa escutar uma interface acessível (por exemplo `uvicorn app.main:app --host 0.0.0.0 --port 8000`) e o firewall precisa permitir acesso na rede local. Não versione IP pessoal nem exponha o servidor de desenvolvimento à internet.

`API_BASE_URL` fica em `lib/config/api_config.dart`, com default local `http://127.0.0.1:8000`. HTTP cleartext é habilitado somente no manifesto Android de **debug**. Release não recebe essa liberação; produção deverá usar HTTPS. Backups Android estão desabilitados para evitar restaurar tokens sem as respectivas chaves do dispositivo.

### Sessão e uso

Em debug, o modo demonstração está temporariamente ativo por padrão. Configure `APP_ENV=development` no backend privado e execute o comando do emulador acima: o aplicativo obtém uma sessão demo, carrega dados e abre sem preencher login. A conta compartilhada é um usuário comum, sem privilégios, com senha aleatória interna desconhecida. Seus dados existentes não são resetados nem duplicados. Não exponha a API de desenvolvimento à internet.

Para testar autenticação normal:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 --dart-define=DEMO_MODE=false
```

O JWT demo fica somente em memória e não substitui uma sessão real salva. **Sair** encerra o demo e mantém a tela de login nesta execução. Em release/profile, `kDebugMode` impede o bypass mesmo com `DEMO_MODE=true`. O backend só registra a rota demo em `APP_ENV=development`; sem configuração explícita, o ambiente padrão é `production` e a rota não existe. A remoção definitiva está registrada em [`docs/TECHNICAL_DEBT.md`](docs/TECHNICAL_DEBT.md).

No modo normal, crie uma conta com email e senha ou entre em uma existente. O registro faz login automaticamente. Depois, cadastre disciplinas, tarefas (com data e horário de entrega) e disponibilidade nas respectivas abas. O servidor gera os IDs e confirma cada alteração antes da atualização das listas.

O JWT é guardado por `SecureTokenStorage`, usando o armazenamento protegido da plataforma, nunca `SharedPreferences`. Senhas só participam do formulário e das requisições e não são persistidas. Ao abrir o app, o token salvo é validado em `/users/me`; falhas de conexão preservam a sessão salva e oferecem nova tentativa. Um 401 autenticado encerra a sessão; senha incorreta no login não é tratada como expiração. **Sair**, no Perfil, remove o token e esvazia todos os dados acadêmicos locais.

### SDK e validação

Validado com Flutter 3.35.3 / Dart 3.9.2. A versão estável compatível de `flutter_secure_storage` é 10.3.1: a 11.0.0 depende transitivamente de `win32` 6.x, que exige Dart 3.10. Nenhum upgrade de SDK foi feito. O minSdk Android existente (24 neste SDK Flutter) já atende ao mínimo 23 do plugin e não foi alterado. Os registradores nativos Linux/Windows são atualizados pelo Flutter para incluir o plugin.

```powershell
dart format .
flutter analyze
flutter test
```

Os testes usam `MockClient` e `MemoryTokenStorage`, sem servidor ou plugin nativo. Windows requer Visual Studio com suporte C++/ATL; Android requer SDK e emulador/dispositivo configurados. Flutter Web e CORS não fazem parte desta fase.

Na validação da Fase 2C, o APK debug também foi executado no Android Emulator com FastAPI e SQLite descartável: registro/login, criação dos dados, reabertura com sessão restaurada, conclusão de tarefa, atualização de disponibilidade e logout. Esse smoke test não substitui a validação contra PostgreSQL real nem a execução nativa em Windows.

Na Fase 3, passaram 211 testes backend e 111 testes Flutter, além de `flutter analyze`. O smoke Android + FastAPI + SQLite confirmou entrada demo, seed sem duplicação, preview, criação de tarefa (270 -> 330 minutos planejados), conclusão e nova geração sem essa tarefa (270 minutos). O debug com `DEMO_MODE=false` abriu o login normal. Um APK release compilado com `--dart-define=DEMO_MODE=true` também foi instalado no emulador e abriu o login, sem bypass demo. Capturas foram conferidas; no emulador headless foi necessário cold boot com renderização SwiftShader. Migration e `alembic check` passaram no SQLite descartável. PostgreSQL real não foi executado, pois Docker/PostgreSQL não estavam disponíveis.

## Planner V1

Em **Horários**, use **Gerar plano de estudos**. O backend calcula os próximos 14 dias por Earliest Deadline First (prazo, criação, ID), usando apenas tarefas pendentes do usuário. A duração estimada é dividida em blocos de até 90 minutos, com 10 minutos entre blocos na mesma janela contínua. Uma janela pode receber várias tarefas.

Tarefas futuras só recebem blocos antes do prazo: `on_track` indica alocação completa e `at_risk` indica minutos não alocados. Tarefas já vencidas são `overdue` e continuam sendo encaixadas. O preview mostra datas/horas locais, minutos e avisos de risco. Alterações acadêmicas invalidam o plano; falhas temporárias na geração preservam o anterior e permitem tentar novamente.

A disponibilidade é local e o Flutter envia o offset atual em minutos. `repeat_next_week=false` usa somente a primeira ocorrência futura no horizonte (incluindo a parte restante de hoje); `true` repete semanalmente. O offset é fixo neste plano, sem regras de horário de verão. Não há persistência do plano, alterações automáticas nas tarefas, IA, cursos no algoritmo ou replanejamento. Detalhes em [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Arquitetura nesta fase

```text
Flutter
   |
   | HTTP + JWT
   v
FastAPI
   |
   v
PostgreSQL
```

`AuthState` administra a sessão e `AppState` mantém o snapshot remoto em memória. Ambos recebem o mesmo `ApiClient`; as telas não montam requests.

## Estrutura atual

```text
lib/
  config/
    app_theme.dart
    api_config.dart
    app_config.dart
  models/
    availability_model.dart
    course_model.dart
    study_plan_model.dart
    subject_model.dart
    task_model.dart
    user_model.dart
  screens/
    availability/
    auth/
    courses/
    profile/
    subjects/
    tasks/
    widgets/
    main_navigation_screen.dart
  services/
    ai_service.dart
    api_client.dart
    token_storage.dart
    theme_controller.dart
  state/
    app_state.dart
    auth_state.dart
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
