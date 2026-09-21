# Phase 2 — Containerization with Podman

Part of the **DevOps Event Booking System** project (Red Hat DO188 training, Cairo University).

## Goal

Take the plain application from Phase 1 and containerize it using **Podman**, without relying on Docker Compose or any orchestration layer — a single container running the app.

## What Changed from Phase 1

- Added a `Dockerfile` / `Containerfile` to define the application image
- Application now runs isolated inside a container instead of directly on the host
- No orchestration yet — this phase is single-container only (that comes in Phase 3)

## Build the Image

```bash
podman build -t event-booking-app:phase2 .
```

## Run the Container

```bash
podman run -d -p <HOST_PORT>:<CONTAINER_PORT> --name event-booking-app event-booking-app:phase2
```

Replace `<HOST_PORT>` and `<CONTAINER_PORT>` with the actual ports your app uses.

## Useful Commands

```bash
podman ps                        # check running containers
podman logs event-booking-app    # view container logs
podman stop event-booking-app    # stop the container
podman rm event-booking-app      # remove the container
```

## Notes

- Environment variables (if any): list them here, e.g. `DB_HOST`, `DB_PORT`
- Base image used: *(fill in, e.g. `python:3.11-slim`, `node:20-alpine`)*

## Related Commit

[Complete Phase 2 containerization with Podman](https://github.com/OlaGhoneim/Devops-event-booking-system/commit/f94f5e08ee8306b18ee86542be18c41dbbae3a8)
