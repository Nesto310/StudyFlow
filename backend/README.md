# Backend do StudyFlow

API do StudyFlow construída com FastAPI, SQLAlchemy 2.x, Alembic e PostgreSQL. A Fase 2B implementa registro, autenticação JWT e CRUD de disciplinas, tarefas e disponibilidade, sempre isolados pelo usuário autenticado. A partir da Fase 2C, o Flutter consome esta API; a configuração de `API_BASE_URL` está no [README do projeto](../README.md).

## Requisitos

- Python 3.10 ou superior;
- PostgreSQL local, ou Docker com Compose;
- PowerShell para os comandos abaixo no Windows.

## Preparação do ambiente

A partir da pasta `backend`:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements-dev.txt
Copy-Item .env.example .env
```

O arquivo `.env` é local e ignorado pelo Git. Ajuste `DATABASE_URL` nele conforme a sua instalação do PostgreSQL. Não use credenciais pessoais ou de produção.

Para instalar apenas as dependências de execução, use `pip install -r requirements.txt`. O arquivo de desenvolvimento já inclui essas dependências.

## Chave JWT local

Gere uma chave aleatória somente para seu ambiente local:

```powershell
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

Configure o resultado em `JWT_SECRET_KEY` no `.env` privado. Não publique o valor nem o inclua em exemplos, commits ou capturas de tela. O placeholder de `.env.example` é rejeitado pela aplicação e deve ser substituído; a chave precisa ter pelo menos 32 bytes.

`JWT_ALGORITHM=HS256` é o único algoritmo aceito nesta fase. `ACCESS_TOKEN_EXPIRE_MINUTES=30` define a duração padrão do token, configurável com um inteiro positivo. Tokens contêm somente o UUID do usuário em `sub` e a expiração em `exp`, calculada em UTC. Após expirar, faça login novamente; não há refresh token ou logout no servidor nesta fase.

Senhas são armazenadas somente como hashes Argon2 gerados por `pwdlib`. Registro exige de 8 a 128 caracteres e normaliza o email com trim e lowercase. A verificação de login usa um dummy hash quando o email não existe e apresenta a mesma resposta pública para email inexistente ou senha incorreta.

## PostgreSQL com Docker

O Compose usa exclusivamente valores locais de desenvolvimento:

```powershell
docker compose up -d db
docker compose ps
```

## PostgreSQL sem Docker

Instale o PostgreSQL para Windows com as ferramentas de linha de comando (psql) ou pgAdmin. Conecte-se ao banco administrativo `postgres` pelo pgAdmin ou pelo PowerShell:

```powershell
psql -h localhost -U postgres -d postgres
```

No console SQL, crie um usuário e um banco exclusivos de desenvolvimento:

```sql
CREATE ROLE studyflow WITH LOGIN PASSWORD 'studyflow';
CREATE DATABASE studyflow OWNER studyflow;
```

Esses valores são fictícios e somente locais, compatíveis com `.env.example`. Use-os apenas em uma instância de desenvolvimento sem exposição externa. Para outra configuração, ajuste a URL no `.env`:

```text
postgresql+psycopg://usuario:senha@localhost:5432/studyflow
```

Se `psql` não estiver no PATH, use o executável na pasta `bin` da instalação ou o Query Tool do pgAdmin. Confirme que o serviço PostgreSQL está iniciado antes das migrations.

## Migrations

O schema é controlado pelo Alembic. Com o PostgreSQL disponível e o `.env` configurado:

```powershell
alembic upgrade head
alembic current
```

Para criar migrations futuras a partir do metadata:

```powershell
alembic revision --autogenerate -m "descricao_da_migration"
```

## Execução da API

```powershell
uvicorn app.main:app --reload
```

Com a API em execução:

- `GET http://127.0.0.1:8000/health` verifica a aplicação;
- `GET http://127.0.0.1:8000/health/db` verifica a conexão com o banco;
- `GET http://127.0.0.1:8000/docs` abre a documentação interativa.

O health check do banco retorna HTTP 503 sem detalhes internos quando a conexão não está disponível. Os comandos HTTP abaixo são apenas para desenvolvimento local; uma implantação futura deve usar HTTPS.

## Autenticação pelo PowerShell

Use uma conta local fictícia. `Get-Credential` recebe o email como nome de usuário e a senha sem mostrá-la no terminal:

```powershell
$api = "http://127.0.0.1:8000"
$credential = Get-Credential -Message "Conta local do StudyFlow (email e senha)"
$body = @{
    email = $credential.UserName
    password = $credential.GetNetworkCredential().Password
} | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "$api/api/v1/auth/register" -ContentType "application/json" -Body $body

$auth = Invoke-RestMethod -Method Post -Uri "$api/api/v1/auth/token" -ContentType "application/x-www-form-urlencoded" -Body @{
    username = $credential.UserName
    password = $credential.GetNetworkCredential().Password
    grant_type = "password"
}
$headers = @{ Authorization = "Bearer $($auth.access_token)" }
Invoke-RestMethod -Uri "$api/api/v1/users/me" -Headers $headers
Invoke-RestMethod -Method Post -Uri "$api/api/v1/subjects" -Headers $headers -ContentType "application/json" -Body '{"name":"Calculus"}'
Invoke-RestMethod -Uri "$api/api/v1/subjects" -Headers $headers
```

O registro usa JSON; o login usa formulário, com **email no campo `username`**. Não registre novamente uma conta já criada: email duplicado retorna 409. Evite imprimir ou persistir `$auth`, `$body` e `$credential`.

## Swagger e endpoints

Em `/docs`, execute `POST /api/v1/auth/register` para criar a conta. Depois clique em **Authorize**, informe o email em `username` e a senha em `password`; deixe `client_id` e `client_secret` vazios. O Swagger obtém o token em `/api/v1/auth/token` e adiciona o Bearer automaticamente aos endpoints protegidos. Confirme em `GET /api/v1/users/me`.

| Recurso | Endpoints |
| --- | --- |
| Saúde pública | `GET /health`, `GET /health/db` |
| Registro público | `POST /api/v1/auth/register` (201) |
| Login público | `POST /api/v1/auth/token` (200) |
| Usuário autenticado | `GET /api/v1/users/me` (200) |
| Disciplinas | `POST`, `GET /api/v1/subjects`; `GET`, `PATCH`, `DELETE /api/v1/subjects/{subject_id}` |
| Tarefas | `POST`, `GET /api/v1/tasks`; `GET`, `PATCH`, `DELETE /api/v1/tasks/{task_id}` |
| Disponibilidade | `POST`, `GET /api/v1/availability`; `GET`, `PATCH`, `DELETE /api/v1/availability/{slot_id}` |

Criações retornam 201, consultas/atualizações 200 e exclusões 204 sem corpo. Ausência de autenticação ou token inválido/expirado retorna 401 com `WWW-Authenticate: Bearer`. Recurso inexistente ou de outro usuário retorna 404. Validações retornam 422; conflitos de integridade retornam 409 com rollback e sem SQL na resposta.

## Regras da API

- Todas as operações acadêmicas exigem Bearer Token; `user_id` e outros campos não declarados são rejeitados no corpo da requisição.
- Uma tarefa pertence ao usuário através de sua disciplina. A disciplina é verificada na criação e novamente na troca de `subject_id`.
- Disciplina com tarefas não pode ser excluída: retorna 409 e preserva tanto a disciplina quanto suas tarefas.
- Nomes/títulos recebem trim e não podem ficar vazios. Professor é opcional; `teacher: null` permite limpá-lo.
- Tarefas começam com `is_completed=false`; esse campo só pode ser alterado por PATCH. `estimated_minutes` deve ser inteiro positivo e `due_date` deve incluir timezone explícito. A descrição pode ser omitida ou vazia.
- Disponibilidade aceita dias de 1 a 7 e horários locais sem fuso, com `start_time < end_time`. PATCH valida o resultado junto com os valores armazenados, mesmo se apenas um horário for enviado. Não há detecção de sobreposição.
- PATCH usa somente os campos enviados. Campos obrigatórios não aceitam `null`; um corpo vazio preserva o recurso.
- Listagens retornam somente os dados do usuário autenticado; paginação ainda não foi implementada.

## Decisões de persistência

IDs são UUIDs gerados pela aplicação. Datas de entrega e timestamps usam `TIMESTAMP WITH TIME ZONE`; envie datas com fuso explícito. Horários semanais usam `TIME`, sem data ou fuso embutidos. `updated_at` é atualizado nas escritas SQLAlchemy, não por trigger para SQL externo.

As FKs da Fase 2A continuam usando `ON DELETE CASCADE` para operações diretas no banco. Isso não representa permissão para a API apagar tarefas junto com uma disciplina: a rota DELETE verifica vínculos e responde 409. No PostgreSQL, essa verificação usa bloqueio da linha da disciplina até o fim da transação, impedindo inserções concorrentes por FK durante a exclusão. Não há endpoint DELETE de usuário. Nenhum model ou schema do banco foi alterado; não foi criada migration nova.

## Testes

Os testes ORM usam SQLite somente como banco isolado de teste. A aplicação continua configurada para PostgreSQL.

```powershell
python -m pytest
```

A suíte cobre registro/hash Argon2, login/dummy hash, assinatura/expiração/claims do JWT, CRUD, ownership entre duas contas, regras de exclusão, validação de PATCH, rollback e o contrato OAuth2/OpenAPI. A chave JWT dos testes é gerada em memória, sem usar a chave do `.env` local. Os testes da Fase 2A permanecem na suíte.

Testes SQLite não substituem validação real do PostgreSQL, especialmente de bloqueios concorrentes. Com PostgreSQL disponível, execute `alembic upgrade head`, `alembic check` e o fluxo de autenticação/CRUD acima contra esse banco.
