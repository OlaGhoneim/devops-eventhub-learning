#!/bin/bash

set -e

NETWORK=eventhub-net

echo "Creating network..."
podman network exists $NETWORK || podman network create $NETWORK

echo "Starting databases..."

podman volume exists mysql-data || podman volume create mysql-data
podman volume exists postgres-data || podman volume create postgres-data
podman volume exists mongo-data || podman volume create mongo-data
podman volume exists redis-data || podman volume create redis-data
podman volume exists rabbitmq-data || podman volume create rabbitmq-data

podman rm -f mysql postgres mongodb redis rabbitmq 2>/dev/null || true

podman run -d \
  --name mysql \
  --network $NETWORK \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=eventhub_catalog \
  -v mysql-data:/var/lib/mysql \
  mysql:8.0

podman run -d \
  --name postgres \
  --network $NETWORK \
  -e POSTGRES_USER=eventhub \
  -e POSTGRES_PASSWORD=eventhub \
  -e POSTGRES_DB=eventhub_auth \
  -v postgres-data:/var/lib/postgresql/data \
  postgres:16

podman run -d \
  --name mongodb \
  --network $NETWORK \
  -v mongo-data:/data/db \
  mongo:7

podman run -d \
  --name redis \
  --network $NETWORK \
  -v redis-data:/data \
  redis:7

podman run -d \
  --name rabbitmq \
  --network $NETWORK \
  -e RABBITMQ_DEFAULT_USER=guest \
  -e RABBITMQ_DEFAULT_PASS=guest \
  -v rabbitmq-data:/var/lib/rabbitmq \
  rabbitmq:3-management

echo "Waiting for databases..."

until podman exec mysql mysqladmin ping -h localhost --silent; do
  sleep 2
done

until podman exec postgres pg_isready -U eventhub; do
  sleep 2
done

until podman exec mongodb mongosh --quiet --eval "db.adminCommand('ping').ok" | grep 1; do
  sleep 2
done

until podman exec redis redis-cli ping | grep PONG; do
  sleep 2
done

until podman exec rabbitmq rabbitmq-diagnostics -q ping; do
  sleep 2
done

echo "Building service images..."

podman build -t legacy-catalog-service:phase2 ./services/legacy-catalog-java
podman build -t auth-service:phase2 ./services/auth-service-node
podman build -t booking-service:phase2 ./services/booking-service-python
podman build -t notification-worker:phase2 ./services/notification-worker-go
podman build -t ai-insight-service:phase2 ./services/ai-insight-service-python
podman build -t analytics-service:phase2 ./services/analytics-service-python

echo "Starting services..."

podman rm -f legacy-catalog auth booking notification-worker ai-insight analytics 2>/dev/null || true

podman run -d \
  --name legacy-catalog \
  --network $NETWORK \
  -e DB_URL=jdbc:mysql://mysql:3306/eventhub_catalog \
  -e DB_USERNAME=root \
  -e DB_PASSWORD=rootpassword \
  -p 8081:8081 \
  legacy-catalog-service:phase2

until podman exec legacy-catalog curl -f http://localhost:8081/api/catalog/health; do
  sleep 2
done

podman run -d \
  --name auth \
  --network $NETWORK \
  -e PORT=8082 \
  -e PGHOST=postgres \
  -e PGPORT=5432 \
  -e PGUSER=eventhub \
  -e PGPASSWORD=eventhub \
  -e PGDATABASE=eventhub_auth \
  -e JWT_SECRET=change-me-in-every-environment \
  -p 8082:8082 \
  auth-service:phase2

podman run -d \
  --name ai-insight \
  --network $NETWORK \
  -e OLLAMA_URL="${OLLAMA_URL:-}" \
  -e OLLAMA_MODEL="${OLLAMA_MODEL:-llama3.2:1b}" \
  -p 8084:8084 \
  ai-insight-service:phase2

until curl -f http://localhost:8084/health >/dev/null 2>&1; do
  sleep 2
done

podman run -d \
  --name booking \
  --network $NETWORK \
  -e PORT=8083 \
  -e MONGO_URI=mongodb://mongodb:27017 \
  -e MONGO_DB=eventhub_bookings \
  -e RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672/ \
  -e RABBITMQ_QUEUE=bookings \
  -e AI_INSIGHT_URL=http://ai-insight:8084 \
  -p 8083:8083 \
  booking-service:phase2

until podman exec booking \
  python -c "import urllib.request; urllib.request.urlopen('http://localhost:8083/health')" \
  >/dev/null 2>&1; do
  sleep 2
done

podman run -d \
  --name notification-worker \
  --network $NETWORK \
  -e RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672/ \
  -e RABBITMQ_QUEUE=bookings \
  notification-worker:phase2

podman run -d \
  --name analytics \
  --network $NETWORK \
  -e REDIS_URL=redis://redis:6379/0 \
  -e BOOKING_SERVICE_URL=http://booking:8083 \
  -e CATALOG_SERVICE_URL=http://legacy-catalog:8081 \
  -e SNAPSHOT_KEY=analytics:snapshot \
  -p 8085:8085 \
  analytics-service:phase2

until curl -f http://localhost:8085/health >/dev/null 2>&1; do
  sleep 2
done

echo "Running analytics job..."

podman run --rm \
  --network $NETWORK \
  -e REDIS_URL=redis://redis:6379/0 \
  -e BOOKING_SERVICE_URL=http://booking:8083 \
  -e CATALOG_SERVICE_URL=http://legacy-catalog:8081 \
  -e SNAPSHOT_KEY=analytics:snapshot \
  analytics-service:phase2 \
  python job.py

echo "All services are running."

podman ps
