# Phase 3 — Docker Compose Orchestration

Part of the **EventHub** project (Red Hat DO188 training, Cairo University).

## Goal

Orchestrate all EventHub microservices together using **Docker Compose**, replacing the single-container Podman setup from Phase 2 with a full multi-service stack.

## Architecture

```
Client (browser)
   -> Frontend (React)
        -> Legacy Catalog service (Java)   -> MySQL
        -> Auth service (Node.js)          -> PostgreSQL
        -> Booking service (Python)        -> MongoDB
               -> publishes events -> Message broker -> Notification worker (Go)
               -> calls -> AI Insight service (Python) -> local LLM via Ollama
        -> Analytics API (Python)          -> Redis
   -> Auth & Booking also read/write a shared cache (Redis)
```

## Services

| Service | Language | Role | Backing Store |
|---|---|---|---|
| `frontend` | React | Client UI | — |
| `legacy-catalog` | Java | Deliberately "legacy-style" catalog service — old config/dependency patterns, no health endpoint | MySQL |
| `auth` | Node.js | JWT-based authentication; other services trust its tokens | PostgreSQL |
| `booking` | Python | Booking creation, owns reviews, publishes booking events | MongoDB |
| `notification-worker` | Go | Pure message consumer — listens for booking events, logs confirmations | — |
| `ai-insight` | Python | Scores review sentiment via local LLM (Ollama), with rule-based fallback | — |
| `analytics` | Python | Background job aggregates stats into a snapshot; read-only API serves it to the dashboard | Redis |
| Message broker | — | Async event bus between `booking` and `notification-worker` | — |

## Why It's Structured This Way

- **Legacy catalog** simulates an inherited legacy system on purpose — no health checks, older dependency style — to practice containerizing something you don't control.
- **Booking → broker → notification-worker** is the async path: booking creation doesn't block on notification delivery.
- **Booking → AI Insight** is synchronous: a review's sentiment is computed and stored with the review before the response returns.
- **Analytics** decouples computation from serving: a background job writes a snapshot to Redis; the API only reads it.

## Run the Stack

```bash
docker-compose up -d
```

or with Podman:

```bash
podman-compose up -d
```

## Useful Commands

```bash
docker-compose ps          # status of all services
docker-compose logs -f     # follow logs across services
docker-compose down        # tear down the stack
```

## Related Commit

Add Docker Compose orchestration for Phase 3
