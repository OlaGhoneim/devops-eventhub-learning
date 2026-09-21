

## 0. The most important mental model

### `podman run`

```bash
podman run [OPTIONS] IMAGE [COMMAND] [ARGUMENTS...]
```

Think:

```text
podman run IMAGE COMMAND
                  ↑
          command INSIDE a NEW container
```

Example:

```bash
podman run --rm registry.access.redhat.com/ubi9/ubi-minimal:9.5 cat /etc/os-release
```

Meaning:

> Create a container from this image → run `cat /etc/os-release` inside it → remove the container when finished.

### `podman exec`

```bash
podman exec CONTAINER COMMAND
                       ↑
                command INSIDE
                an existing container
```

Example:

```bash
podman exec web cat /etc/os-release
```

### ⭐ Exam distinction

|Command|Meaning|
|---|---|
|`podman run`|Create **new** container and run command|
|`podman exec`|Run command inside **existing** container|
|`podman rm`|Remove container|
|`podman rmi`|Remove image|
|`rm`|Remove Linux file|

---

# 1. Running containers

### Basic syntax

```bash
podman run IMAGE
```

### Run a command inside a new container

```bash
podman run IMAGE COMMAND
```

### Automatically remove container

```bash
podman run --rm IMAGE
```

Remember:

```text
--rm = remove container automatically after it exits
```

---

# 2. Images

## List images

```bash
podman image ls
```

or:

```bash
podman images
```

## Inspect an image

```bash
podman image inspect IMAGE
```

Example:

```bash
podman image inspect simple-server
```

### Inspect a specific value

```bash
podman image inspect simple-server --format="{{.Config.Cmd}}"
```

⭐ Remember the pattern:

```bash
podman image inspect IMAGE --format="..."
```

---

# 3. Build an image

## ⭐ Most important syntax

```bash
podman build -f Containerfile -t IMAGE .
```

Think:

```text
-f → Containerfile
-t → name/tag
.  → build context
```

Example:

```bash
podman build -f Containerfile -t simple-server .
```

### If Containerfile is somewhere else

```bash
podman build -f /home/student/DO188/labs/images-lab/Containerfile -t images-lab .
```

⚠️ **Important:** the final `.` is the **build context**.

---

# 4. Tag an image

### Syntax

```bash
podman tag SOURCE_IMAGE TARGET_IMAGE
```

Example:

```bash
podman tag simple-server simple-server:0.1
```

For a registry:

```bash
podman tag images-lab \
registry.ocp4.example.com:8443/developer/images-lab:grue
```

Think:

```text
podman tag OLD_NAME NEW_NAME
```

Tagging **does not create a second copy of the image**. It gives the image another name/tag.

---

# 5. Save an image to a `.tar`

### Syntax

```bash
podman save -o OUTPUT_FILE IMAGE
```

Example:

```bash
podman save -o simple-server.tar localhost/simple-server
```

Think:

```text
save image → Linux archive file
```

---

# 6. Load an image from `.tar`

### Syntax

```bash
podman load -i TAR_FILE
```

Example:

```bash
podman load -i simple-server.tar
```

Think:

```text
.tar → Podman image
```

### ⭐ Save vs Load

```text
podman save → IMAGE → .tar
podman load → .tar → IMAGE
```

---

# 7. Remove things

This is VERY important for the exam.

### Remove Linux file

```bash
rm simple-server.tar
```

➡️ Deletes a normal file.

### Remove container

```bash
podman rm http-server
```

➡️ Deletes a container.

### Force-remove image

```bash
podman rmi -f simple-server:0.1
```

➡️ Deletes an image.

### ⭐ Memorize

```text
rm      → Linux file
podman rm → container
podman rmi → image
```

---

# 8. Filter images

The option is:

```bash
--filter reference=
```

Example:

```bash
podman image ls --filter reference="simple-server"
```

⚠️ Be careful with spelling:

```text
reference
```

not:

```text
refrence
```

And:

```text
simple-server
```

not:

```text
simple server
```

---

# 9. Registry operations

## Login

```bash
podman login REGISTRY
```

Example:

```bash
podman login registry.ocp4.example.com:8443
```

With credentials:

```bash
podman login REGISTRY --username USER --password PASSWORD
```

Example:

```bash
podman login registry.ocp4.example.com:8443 \
  --username developer \
  --password developer
```

---

# 10. Push an image to a registry

There are **3 steps** to memorize:

```text
LOGIN → TAG → PUSH
```

### Step 1 — Login

```bash
podman login REGISTRY
```

### Step 2 — Build

```bash
podman build -f Containerfile -t images-lab .
```

### Step 3 — Tag

```bash
podman tag images-lab \
registry.ocp4.example.com:8443/developer/images-lab:grue
```

### Step 4 — Push

```bash
podman push \
registry.ocp4.example.com:8443/developer/images-lab:grue
```

### ⭐ Mental model

```text
local image
    ↓
   tag
    ↓
registry/user/image:tag
    ↓
   push
    ↓
registry
```

---

# 11. `podman system migrate`

```bash
podman system migrate
```

Purpose:

> Migrates Podman's rootless user/group ID mappings.

Usually:

```text
no output expected
```

### Exam memory

If the exercise says:

> Migrate the Podman ID ranges.

Answer:

```bash
podman system migrate
```

---

# 12. Volumes

There are two concepts you need to distinguish:

### Bind mount

Uses a **host directory**.

```text
HOST DIRECTORY → CONTAINER DIRECTORY
```

### Named volume

Uses a **Podman-managed volume**.

```text
PODMAN VOLUME → CONTAINER DIRECTORY
```

---

# 13. Bind mounts

## ⭐ Most important syntax

```bash
-v HOST:CONTAINER:Z
```

or:

```bash
--volume HOST:CONTAINER:Z
```

Example:

```bash
podman run \
  --volume ~/www:/server:Z \
  IMAGE
```

Meaning:

```text
~/www on host
      ↓
/server inside container
```

### What is `:Z`?

```text
Z → adjust SELinux labeling for the container
```

For your exam, memorize:

```bash
-v HOST:CONTAINER:Z
```

---

# 14. Long bind-mount syntax

Instead of:

```bash
-v ~/www:/server:Z
```

you can use:

```bash
--mount type=bind,source=~/www,destination=/server,Z
```

### ⭐ Memorize the short form first

```bash
-v HOST:CONTAINER:Z
```

The long form is useful to recognize:

```bash
--mount type=bind,source=HOST,destination=CONTAINER,Z
```

---

# 15. Port mapping

## ⭐ Syntax

```bash
-p HOST_PORT:CONTAINER_PORT
```

Example:

```bash
-p 8000:8000
```

Meaning:

```text
HOST                CONTAINER
8000       →        8000
```

If the application listens on `8080` inside the container and you want to access it through `3000` on your computer:

```bash
-p 3000:8080
```

Think:

> **Left = my computer. Right = container.**

---

# 16. Find the container user's GID

Command:

```bash
podman run --rm IMAGE id
```

Why?

You may need the container's user/group ID when dealing with bind-mount permissions.

---

# 17. Fix rootless bind-mount permissions

Command:

```bash
podman unshare chgrp -R GID DIRECTORY
```

Example:

```bash
podman unshare chgrp -R 1001 ~/www
```

Break it down:

```text
podman unshare
      ↓
run command in Podman's user namespace

chgrp
      ↓
change group

-R
      ↓
recursive

GID
      ↓
group ID

DIRECTORY
      ↓
directory to change
```

### ⭐ Exam sequence

If the exercise asks you to fix permissions:

```text
1. Find GID
2. Change group
```

```bash
podman run --rm IMAGE id
```

then:

```bash
podman unshare chgrp -R GID DIRECTORY
```

---

# 18. Named volumes

## Create a named volume

```bash
podman volume create NAME
```

Example:

```bash
podman volume create html-vol
```

## List volumes

```bash
podman volume ls
```

---

# 19. Mount a named volume

### Syntax

```bash
--mount type=volume,source=VOLUME,destination=PATH
```

Example:

```bash
--mount type=volume,source=html-vol,destination=/usr/share/nginx/html
```

### Short form

You may also see:

```bash
-v html-vol:/usr/share/nginx/html
```

---

# 20. Read-only volume

```bash
--mount type=volume,source=VOLUME,destination=PATH,ro
```

`ro` = **read-only**

So:

```text
rw → read/write
ro → read-only
```

---

# 21. Import archive into a volume

### ⭐ Important syntax

```bash
podman volume import VOLUME_NAME ARCHIVE_FILE
```

Example:

```bash
podman volume import html-vol index.tar.gz
```

Think:

> **Put the contents of this archive into this volume.**

Another example:

```bash
podman volume import postgres-vol \
  /home/student/DO188/labs/persisting-lab/postgres-vol.tar.gz
```

---

# 22. PostgreSQL container

You may see environment variables like:

```bash
-e POSTGRESQL_USER=backend
-e POSTGRESQL_PASSWORD=secret_pass
-e POSTGRESQL_DATABASE=rpi-store
```

Understand them:

```text
POSTGRESQL_USER
       ↓
database username

POSTGRESQL_PASSWORD
       ↓
database password

POSTGRESQL_DATABASE
       ↓
database name
```

⭐ Don't just memorize the values. The **variable names** are what matter.

---

# 23. PostgreSQL backup with `pg_dump`

Example:

```bash
podman exec persisting-pg12 \
  pg_dump -Fc rpi-store -f /tmp/db_dump
```

Break it down:

```text
podman exec
     ↓
run command in existing container

persisting-pg12
     ↓
container name

pg_dump
     ↓
PostgreSQL backup command

-Fc
     ↓
custom dump format

rpi-store
     ↓
database

-f /tmp/db_dump
     ↓
output file
```

### ⭐ Mental model

```text
podman exec CONTAINER COMMAND ARGUMENTS
```

---

# 24. PostgreSQL readiness output

You may see:

```text
server started
/var/run/postgresql:5432 - accepting connections
```

The important part:

```text
accepting connections
```

means PostgreSQL is ready to accept connections.

---

# 25. Compose

Now move from individual containers to **multiple containers**.

Instead of:

```bash
podman run ...
podman run ...
podman run ...
```

Compose lets you define services in:

```text
compose.yaml
```

---

# 26. Basic Compose structure

Memorize this pattern:

```yaml
services:
  db:
    image: postgres:16
    volumes:
      - rpi:/var/lib/pgsql/data

volumes:
  rpi: {}
```

### Why is `rpi` written twice?

First:

```yaml
- rpi:/var/lib/pgsql/data
```

means:

> Mount the volume named `rpi`.

Second:

```yaml
volumes:
  rpi: {}
```

means:

> Declare/create the named volume `rpi`.

### `{}`

Means:

> Use default configuration.

---

# 27. Compose commands

## Start services

```bash
podman compose up -d
```

Meaning:

```text
up → create/start services
-d → detached/background
```

## Build and start

```bash
podman compose up -d --build
```

⭐ Very useful for exams.

```text
--build → rebuild images before starting
```

---

## Check Compose containers

```bash
podman compose ps
```

Think:

> Show the status of the services in this Compose application.

---

## View volumes

```bash
podman volume ls
```

---

## View logs

```bash
podman compose logs
```

Follow logs:

```bash
podman compose logs -f
```

`-f` = follow.

You wrote:

```bash
podman compose logs -n -f
```

Be careful here: `-n` has a specific meaning depending on the Compose implementation/version. For exam purposes, the safer core command to memorize is:

```bash
podman compose logs -f
```

---

# 28. Stop/remove Compose application

```bash
podman compose down
```

Meaning:

> Stop and remove the containers/networks created by the Compose application.

### Important distinction

```bash
podman compose down
```

does **not automatically mean "delete every volume."**

If an exercise specifically asks to remove volumes, pay attention to the requested Compose options.

---

# 🧠 THE EXAM MEMORY SHEET

If you only have a few minutes before the practical exam, memorize these.

### Containers

```bash
podman run IMAGE
podman run --rm IMAGE COMMAND
podman exec CONTAINER COMMAND
podman ps
podman ps -a
podman rm CONTAINER
```

### Images

```bash
podman image ls
podman image inspect IMAGE
podman build -f Containerfile -t IMAGE .
podman tag IMAGE NEW_NAME
podman rmi IMAGE
podman save -o FILE.tar IMAGE
podman load -i FILE.tar
```

### Registry

```bash
podman login REGISTRY
podman tag IMAGE REGISTRY/USER/IMAGE:TAG
podman push REGISTRY/USER/IMAGE:TAG
```

### Volumes

```bash
podman volume create NAME
podman volume ls
podman volume import VOLUME ARCHIVE
```

### Mounts

```bash
-v HOST:CONTAINER:Z
```

or:

```bash
--volume HOST:CONTAINER:Z
```

Named volume:

```bash
-v VOLUME:CONTAINER
```

### Ports

```bash
-p HOST:CONTAINER
```

### Permissions

```bash
podman run --rm IMAGE id
podman unshare chgrp -R GID DIRECTORY
```

### System

```bash
podman system migrate
```

### PostgreSQL

```bash
podman exec CONTAINER pg_dump -Fc DATABASE -f FILE
```

### Compose

```bash
podman compose up -d
podman compose up -d --build
podman compose ps
podman compose logs -f
podman compose down
```

---

# 🎯 Practice method for your exam

I strongly recommend **not studying this as one giant list**.

Instead, train yourself with questions like this:

### Question 1

You have a `Containerfile` in the current directory. Build an image called `simple-server`.

**Answer:**

```bash
podman build -f Containerfile -t simple-server .
```

### Question 2

Run `cat /etc/os-release` inside a new UBI container and automatically remove the container afterward.

**Answer:**

```bash
podman run --rm IMAGE cat /etc/os-release
```

### Question 3

Run `ls /app` inside an already-running container called `web`.

**Answer:**

```bash
podman exec web ls /app
```

### Question 4

Map port `3000` on your host to port `8080` in the container.

**Answer:**

```bash
-p 3000:8080
```

### Question 5

Mount the host directory `~/www` at `/server` inside the container with SELinux labeling.

**Answer:**

```bash
-v ~/www:/server:Z
```

### Question 6

Create a named volume called `postgres-vol`.

**Answer:**

```bash
podman volume create postgres-vol
```

### Question 7

Save the image `simple-server` into `simple-server.tar`.

**Answer:**

```bash
podman save -o simple-server.tar simple-server
```

### Question 8

Load `simple-server.tar` back into Podman.

**Answer:**

```bash
podman load -i simple-server.tar
```

### Question 9

Tag `simple-server` as version `0.1`.

**Answer:**

```bash
podman tag simple-server simple-server:0.1
```

### Question 10

Start a Compose application in the background and rebuild its images.

**Answer:**

```bash
podman compose up -d --build
```

---

## ⭐ The 10 patterns I would memorize first

If your exam is practical, these are the highest-value patterns:

```text
1.  podman run IMAGE COMMAND

2.  podman exec CONTAINER COMMAND

3.  podman build -f Containerfile -t IMAGE .

4.  podman tag IMAGE REGISTRY/USER/IMAGE:TAG

5.  podman push REGISTRY/USER/IMAGE:TAG

6.  podman save -o FILE.tar IMAGE

7.  podman load -i FILE.tar

8.  -v HOST:CONTAINER:Z

9.  -p HOST:CONTAINER

10. podman compose up -d --build
```

**Most important mental rule:** whenever you see a command in the exam, ask yourself **"Am I working with an image, a container, a volume, a host file, or Compose?"** That alone will prevent a lot of command-mixing mistakes.