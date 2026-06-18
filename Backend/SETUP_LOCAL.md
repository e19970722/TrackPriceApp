# Local Backend Setup (macOS + Homebrew)

不使用 Docker，純本機 Homebrew 跑 Postgres / Redis 的開發環境。

## 心智模型

三層，新電腦要各自 setup 一次；之後每次開發只需要最底層那一步。

| 層 | 新電腦做一次 | 每次開發 |
|---|---|---|
| 系統服務 (Postgres / Redis) | `brew install` + `brew services start` | 自動跑（brew services 開機啟動） |
| 資料庫內容 (role + DB + schema) | 建 `postgres` role + `createdb trackprice` + `alembic upgrade head` | 有新 migration 時再 `alembic upgrade head` |
| Python 環境 (venv + 套件) | `python -m venv .venv` + `pip install -r requirements.txt` | `source .venv/bin/activate` + `uvicorn ...` |

---

## 1. 安裝系統服務（一次性）

```bash
brew install postgresql@16 redis python@3.12
brew services start postgresql@16
brew services start redis            # Celery / 排程任務需要
```

> Postgres 16 對齊 `docker-compose.yml` 用的版本，避免之後切回 Docker 時 DB 版本不相容。

## 2. 建立 DB role + database（一次性）

```bash
psql -d postgres -c "CREATE ROLE postgres WITH LOGIN SUPERUSER PASSWORD 'postgres';"
createdb -O postgres trackprice
```

這對應 `app/config.py` 的預設 `DATABASE_URL`：
`postgresql+asyncpg://postgres:postgres@localhost:5432/trackprice`

## 3. 專案初始化（一次性）

```bash
cd Backend
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
alembic upgrade head                  # 建表 + 跑所有 migrations
```

## 4. 每次開發啟動

```bash
cd Backend && source .venv/bin/activate
uvicorn app.main:app --reload         # API server (http://localhost:8000)
```

要測排程 / 推播時，另開 terminal：

```bash
celery -A app.worker worker --loglevel=info
celery -A app.worker beat --loglevel=info
```

---

## 不需要做的事

- **不用建 `.env`** — `app/config.py` 預設值就指向本機 Postgres / Redis。只有要設 APNs key、proxy、`SECRET_KEY` 等才需要 `cp .env.example .env`。
- **不用裝 Docker** — Homebrew 路線跟 Docker 互斥。若要切回 `docker-compose`，先 `brew services stop postgresql@16` 避免 5432 port 衝突。

## 常見錯誤

**`role "postgres" does not exist`**
→ 跳過了第 2 步。執行 `CREATE ROLE postgres ...` 那行。

**`database "trackprice" does not exist`**
→ 跳過了 `createdb -O postgres trackprice`。

**`Connection refused` on 5432 / 6379**
→ service 沒開：`brew services start postgresql@16` / `brew services start redis`。
檢查狀態：`brew services list`。

**新 migration 跑不起來 / 表結構過舊**
→ `alembic upgrade head`。
