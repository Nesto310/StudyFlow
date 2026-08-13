# Contribuindo

O StudyFlow sera desenvolvido por duas pessoas com apoio de agentes de IA. O fluxo deve ser simples e revisavel:

```text
main
  |
  v
feature/*
fix/*
chore/*
  |
  v
Pull Request
  |
  v
Review
  |
  v
Merge
```

## Regras

- Nao desenvolver diretamente na `main`.
- Usar uma funcionalidade por branch.
- Fazer commits claros e pequenos o suficiente para revisao.
- Nao misturar correcoes nao relacionadas.
- Executar testes antes de abrir Pull Request.
- Nao adicionar credenciais, tokens, senhas ou arquivos `.env` privados.
- Revisar codigo produzido por IA com o mesmo criterio usado para codigo humano.
- Nao aceitar mudancas que o desenvolvedor nao consiga explicar.

## Nomes de branch sugeridos

```text
feature/task-crud
feature/availability
feature/planner-v1

fix/task-validation

chore/update-readme
```
