

## Objective

Create a Compose file that runs a Redis service and a Click Counter application.

The two services must:

- Use the required container images.
    
- Share a custom network called `appnet`.
    
- Persist Redis data using a named volume called `redis_data`.
    
- Expose the Click Counter application on host port `8085`.
    

## Compose File

```yaml
services:

  redis:
    image: "redis:alpine"
    volumes:
      - redis_data:/data
    networks:
      - appnet

  clickcounter:
    image: "kodekloud/click-counter"
    ports:
      - "8085:5000"
    networks:
      - appnet

volumes:
  redis_data: {}

networks:
  appnet: {}
```

## Important Concepts

### Port Mapping

```yaml
ports:
  - "8085:5000"
```

The format is:

```text
HOST_PORT:CONTAINER_PORT
```

Therefore:

```text
8085 → 5000
```

The application can be accessed from the host using:

```text
http://localhost:8085
```

### Named Volume

```yaml
volumes:
  - redis_data:/data
```

This maps the named volume `redis_data` to `/data` inside the Redis container.

The purpose is to keep Redis data persistent when the container is recreated.

### Custom Network

Both services use:

```yaml
networks:
  - appnet
```

This allows the Redis and Click Counter containers to communicate through the same Docker/Podman network.

## Run the Application

Start the services:

```bash
podman-compose up
```

Or run them in the background:

```bash
podman-compose up -d
```

Check running containers:

```bash
podman ps
```

Check the created network:

```bash
podman network ls
```

Check the created volume:

```bash
podman volume ls
```

## Test

Open:

```text
http://localhost:8085
```

Or test from the terminal:

```bash
curl http://localhost:8085
```

## Key Things to Remember

```text
ports:
  - "HOST:CONTAINER"

volumes:
  - "VOLUME:CONTAINER_PATH"

networks:
  - NETWORK_NAME
```

For this task:

```text
Host port       = 8085
Container port  = 5000
Volume          = redis_data
Network         = appnet
Redis image     = redis:alpine
Click Counter   = kodekloud/click-counter
```