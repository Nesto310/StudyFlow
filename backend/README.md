# Backend do StudyFlow

Base da API do StudyFlow construída com FastAPI, SQLAlchemy 2.x, Alembic e PostgreSQL. Nesta Fase 2A existem somente a infraestrutura, os modelos persistentes e os health checks. Autenticação, CRUD e integração com o Flutter ainda não foram implementados.

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

O health check do banco retorna HTTP 503 sem detalhes internos quando a conexão não está disponível.

## Decisões de persistência

IDs são UUIDs gerados pela aplicação. Datas de entrega e timestamps usam `TIMESTAMP WITH TIME ZONE`; envie datas com fuso explícito. Horários semanais usam `TIME`, sem data ou fuso embutidos. `updated_at` é atualizado nas escritas SQLAlchemy, não por trigger para SQL externo.

As FKs usam `ON DELETE CASCADE`, também protegido por testes de SQL direto: excluir um usuário remove disciplinas, tarefas e disponibilidades; excluir uma disciplina remove suas tarefas. As regras de permissão e confirmação dessas operações serão responsabilidade da Fase 2B. O comportamento atual do Flutter não foi alterado.

## Testes

Os testes ORM usam SQLite somente como banco isolado de teste. A aplicação continua configurada para PostgreSQL.

```powershell
pytest
```
