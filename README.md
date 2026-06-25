# StudyFlow

Aplicativo Flutter para controle academico de materias e tarefas.

## Objetivo do trabalho

Esta entrega representa o backend incompleto da aplicacao, com foco em:

- rotas estaticas e dinamicas;
- processamento de formularios;
- validacao e manipulacao de dados;
- organizacao em models, services, routes, screens e widgets;
- persistencia local usando `SharedPreferences`.

## Funcionalidades implementadas

- Cadastro de materias com nome, professor e carga horaria.
- Cadastro de tarefas vinculadas a uma materia.
- Listagem de materias e tarefas.
- Consulta de detalhes por rota dinamica usando o ID do registro.
- Alteracao de status da tarefa.
- Exclusao de tarefas.
- Exclusao de materias com remocao das tarefas vinculadas.
- Validacoes de campos obrigatorios, tamanho minimo e carga horaria valida.

## Simulacao de backend

Como a proposta permite entregar o backend incompleto, a aplicacao usa services
locais para simular requisicoes:

- `getTasks()` e `getSubjects()` simulam o metodo GET.
- `postTask()` e `postSubject()` simulam o metodo POST.
- `updateTask()` e `updateSubject()` simulam atualizacao de dados.
- `deleteTask()` e `deleteSubject()` simulam remocao de dados.

Os dados sao convertidos para JSON pelos models e gravados no armazenamento local
do dispositivo com `SharedPreferences`.

## Estrutura principal

```text
lib/
  main.dart
  models/
    subject_model.dart
    task_model.dart
  routes/
    app_routes.dart
  screens/
    add_subject_screen.dart
    add_task_screen.dart
    home_screen.dart
    subject_screen.dart
    task_screen.dart
  services/
    subject_service.dart
    task_service.dart
  widgets/
    subject_card.dart
    task_card.dart
```

## Como executar

```bash
flutter pub get
flutter run
```

## Observacao

O arquivo `firestore_service.dart` ficou como ponto de expansao para uma proxima
etapa com Firebase/Firestore. Nesta entrega, a persistencia funcional esta nos
services com `SharedPreferences`.
