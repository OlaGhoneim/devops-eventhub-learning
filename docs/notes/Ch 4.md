

```dockerfile

FROM python:3.12
```

you're not just saying:

> "Give me Python."

You're effectively choosing a **starting environment** that determines things such as:

```text
             FROM python:3.12
                    │
       ┌────────────┼────────────┐
       ↓            ↓            ↓
   Linux base    Python       system
   environment   runtime      libraries
       │
       ├── package manager
       ├── filesystem
       ├── dependencies
       ├── architecture support
       └── image size
```



> **`FROM` determines the foundation of your container.**

That's why choosing a base image is an important DevOps decision, not just a syntax choice.


## Why does `apt` work here?

Because you chose:

```dockerfile
FROM ubuntu:24.04
```

Ubuntu uses **APT** as its package manager.

So:

```dockerfile
RUN apt update
RUN apt install -y curl
```

works.



## What if you use CentOS/RHEL?

For example:

```dockerfile
FROM centos:9
```

The package management commands are different.

You might use:

```dockerfile
RUN yum install -y curl
```

or, on newer Red Hat-family systems:

```dockerfile
RUN dnf install -y curl
```

So:

```text
Ubuntu/Debian
     ↓
    apt

RHEL/Fedora/CentOS
     ↓
   dnf / yum

Alpine
     ↓
    apk
```



## Why can't I just use `apt` everywhere?

Because `apt` isn't automatically available in every image.

For example:

```dockerfile
FROM alpine:3.20

RUN apt install curl
```

❌ This will generally fail because Alpine uses `apk`, not `apt`.

You would write:

```dockerfile
FROM alpine:3.20

RUN apk add curl
```

✅

So the **base image determines what tools are available to you**.


-----------

## 1. `COPY`

`COPY` means:

> **Take files from my computer (the build context) and put them inside the image.**

Example:

```
COPY app.py /app/app.py
```

Suppose your project is:

```
booking-service/
├── Containerfile
├── app.py
└── requirements.txt
```

You run:

```
podman build -t booking:v1 .
```

The `.` at the end means:

> "Use this directory as the **build context**."

So Podman can access:

```
booking-service/
├── Containerfile
├── app.py
└── requirements.txt
```

Then:

```
COPY app.py /app/app.py
```

does:

```
Your computer
booking-service/app.py
       │
       │ COPY
       ↓
Container image
/app/app.py
```



## 2. What is "build context"?

This is very important.

When you run:

```
podman build -t booking:v1 .
```

the final `.` means the **current directory is the build context**.

For example, if you're here:

```
/home/ola/project/booking-service
```

and run:

```
podman build -t booking:v1 .
```

then:

```
Build context
      ↓
/home/ola/project/booking-service
```

`COPY` can copy files from that context.

For example:

```
COPY requirements.txt /app/
COPY app.py /app/
```



## 3. You cannot use a URL with `COPY`

This won't work:

```
COPY https://example.com/app.py /app/
```

❌ `COPY` doesn't download files from URLs.

It's for copying files from the **local build context**.


# 4. `ADD`

`ADD` can also copy files:

```
ADD app.py /app/
```

So for ordinary local files:

```
COPY app.py /app/
```

and:

```
ADD app.py /app/
```

can look identical.

But `ADD` has **extra behavior**.


## 5. `ADD` can use remote sources

For example, conceptually:

```
ADD https://example.com/file.tar.gz /app/
```

`ADD` can retrieve remote resources depending on the container builder's supported behavior.

But there is an important practical rule:

> **Prefer `COPY` for ordinary local files.**

Use `ADD` only when you actually need its special behavior.



## 6. `ADD` can automatically unpack `.tar` archives

This is the biggest difference you'll probably be asked about.

Suppose you have:

```
project/
├── Containerfile
└── application.tar
```

The archive contains:

```
application.tar
├── app.py
├── config.json
└── data/
```

With:

```
ADD application.tar /app/
```

the archive can be **unpacked** into `/app/`.

Result:

```
/app/
├── app.py
├── config.json
└── data/
```

Whereas:

```
COPY application.tar /app/
```

copies the `.tar` file itself:

```
/app/
└── application.tar
```

So:

```
COPY
.tar → remains .tar

ADD
.tar → can be automatically extracted
```


# 7. Why do people usually prefer `COPY`?

Because `COPY` is simpler and more predictable.

If you write:

```
COPY . /app
```

you're clearly saying:

> Copy these local files into `/app`.

With `ADD`, there are additional behaviors to remember.

A common best practice is:

```
COPY requirements.txt .
COPY src/ ./src/
```

rather than using `ADD` unless you specifically need its functionality

--------------


## 1. `ENTRYPOINT`

`ENTRYPOINT` defines:

> **The main executable that the container will run.**

Example:

```dockerfile
ENTRYPOINT ["python"]
```

When you start the container:

```bash
podman run myimage
```

Podman runs:

```text
python
```

So think:

```text
ENTRYPOINT = "What program am I running?"
```



## 2. `CMD`

`CMD` provides:

> **The default arguments/command to use when the container starts.**

For example:

```dockerfile
ENTRYPOINT ["python"]
CMD ["app.py"]
```

Together they effectively produce:

```bash
python app.py
```

Think:

```text
ENTRYPOINT = main program
CMD        = default arguments
```



## 3. Visual example

Suppose your Containerfile is:

```dockerfile
FROM python:3.12

COPY app.py /app/app.py

ENTRYPOINT ["python"]
CMD ["/app/app.py"]
```

When you run:

```bash
podman run myapp
```

Podman combines them:

```text
ENTRYPOINT
    ↓
python

CMD
    ↓
/app/app.py

Result:
    python /app/app.py
```



# 4. Why is `CMD` useful?

Because you can **override CMD when you run the container**.

Suppose:

```dockerfile
ENTRYPOINT ["python"]
CMD ["app.py"]
```

Normally:

```bash
podman run myapp
```

runs:

```text
python app.py
```

But you can do:

```bash
podman run myapp test.py
```

Now the result is:

```text
python test.py
```

The `ENTRYPOINT` stays:

```text
python
```

but the `CMD` is replaced.

This is why you can think:

```text
ENTRYPOINT = fixed executable
CMD        = default argument that can be replaced
```



# 5. Another example with `echo`

```dockerfile
ENTRYPOINT ["echo"]
CMD ["Hello Ola"]
```

Running:

```bash
podman run myimage
```

gives:

```text
Hello Ola
```

Because:

```text
ENTRYPOINT → echo
CMD        → Hello Ola
```

Together:

```bash
echo "Hello Ola"
```

But:

```bash
podman run myimage "Hello World"
```

gives:

```text
Hello World
```

because you replaced the default `CMD`.



# 6. What does your note mean by "passed to the executable"?

Your note says:

> CMD: Runs a command when the container is started. This command is passed to the executable defined by ENTRYPOINT.

Using:

```dockerfile
ENTRYPOINT ["python"]
CMD ["app.py"]
```

means:

```text
             ENTRYPOINT
                  ↓
               python
                  ↑
                  │ receives
                  │
                CMD
                  ↓
               app.py
```

Result:

```bash
python app.py
```


# 7. What about the "base image defines a default ENTRYPOINT"?

Your notes mention:

> Base images define a default ENTRYPOINT.

This means a base image can already contain an `ENTRYPOINT` or `CMD`.

For example, imagine a base image has:

```dockerfile
ENTRYPOINT ["/bin/bash"]
```

If your Containerfile doesn't override it, that configuration can be inherited.

But don't assume **every** base image has Bash as its default entrypoint. Minimal images may not even contain Bash.



# 8. `ENTRYPOINT` vs `CMD` in your EventHub project

For your services, you'll often see something like:

### Python service

```dockerfile
ENTRYPOINT ["python"]
CMD ["app.py"]
```

Result:

```text
python app.py
```

### Node.js service

```dockerfile
ENTRYPOINT ["node"]
CMD ["server.js"]
```

Result:

```text
node server.js
```

### Go service

You might instead have:

```dockerfile
ENTRYPOINT ["/app/notification-worker"]
```

There may be no `CMD` at all.

---


## 1. `USER` — who runs the application?

Example:

```dockerfile
USER appuser
```

This means:

> From this point onward, commands/processes run as `appuser` instead of `root`.

For example:

```dockerfile
FROM python:3.12

RUN useradd -m appuser

COPY app.py /app/app.py

USER appuser

CMD ["python", "/app/app.py"]
```

The application runs as:

```text
appuser
```

instead of:

```text
root
```

### Why?

Running applications as root gives the application more privileges than necessary.

So this:

```text
root
  ↓
application
```

is generally less desirable than:

```text
appuser
  ↓
application
```

**Memory:** `USER` = **Who is running?**



# 2. `LABEL` — information about the image

Example:

```dockerfile
LABEL maintainer="Ola"
LABEL version="1.0"
```

This doesn't change how your application runs.

It adds **metadata** to the image:

```text
Image
├── application
├── files
├── layers
└── metadata
      ├── maintainer = Ola
      └── version = 1.0
```

You can inspect labels with:

```bash
podman image inspect myimage
```

Labels are useful for organizing and identifying images.

**Memory:** `LABEL` = **Information about the image.**



# 3. `EXPOSE` — documentation for a port

Example:

```dockerfile
EXPOSE 8080
```

This means:

> "The application inside this container is expected to listen on port 8080."

But **very important**:

`EXPOSE` does **NOT** publish port 8080 to your Fedora machine.

So:

```dockerfile
EXPOSE 8080
```

does **not** mean you can automatically access:

```text
localhost:8080
```

You still need to publish the port when running:

```bash
podman run -p 8080:8080 myimage
```

Think:

```text
EXPOSE 8080
      ↓
Documentation/metadata
      ↓
"Application uses 8080"
```

while:

```bash
-p 8080:8080
```

actually creates the host → container port mapping.

**Memory:** `EXPOSE` = **"This container uses this port."**

`-p` = **"Make this port accessible from the host."**



# 4. `ENV` — environment variables available at runtime

Example:

```dockerfile
ENV APP_PORT=8080
ENV APP_NAME=eventhub
```

Now inside the container, you can use:

```bash
echo $APP_PORT
```

and get:

```text
8080
```

Or:

```bash
env
```

to see environment variables.

Your application can also read them.

For example, Python:

```python
import os

port = os.getenv("APP_PORT")
```

So:

```text
ENV
 ↓
Environment variable
 ↓
Available when container runs
 ↓
Application can read it
```

**Memory:** `ENV` = **runtime environment variable.**



# 5. `ARG` — variable used during the build

This is where `ARG` and `ENV` are easy to confuse.

Example:

```dockerfile
ARG PYTHON_VERSION=3.12
```

You can use it during the image build.

For example:

```dockerfile
ARG APP_VERSION=1.0

LABEL version=$APP_VERSION
```

Then build with a different value:

```bash
podman build --build-arg APP_VERSION=2.0 -t myapp .
```

Now the build receives:

```text
APP_VERSION=2.0
```

### `ARG` vs `ENV`

Think:

```text
ARG
 ↓
BUILD TIME
```

while:

```text
ENV
 ↓
RUNTIME
```

Example:

```dockerfile
ARG APP_VERSION=1.0
ENV APP_ENV=production
```

During build:

```text
ARG APP_VERSION
       ↓
used while building image
```

When container runs:

```text
ENV APP_ENV
       ↓
available to application
```

### Important security point

Don't use `ARG` or `ENV` as a safe way to hide passwords or secrets. Build arguments and image environment configuration can potentially be exposed through image/build metadata or inspection.

**Memory:** `ARG` = **build-time variable.**



# 6. `VOLUME` — persistent data location

Example:

```dockerfile
VOLUME /var/lib/mysql
```

This tells Podman:

> "This directory is intended to contain data that should be stored separately from the container's writable layer."

For a database, this makes sense:

```text
MySQL container
      │
      ↓
/var/lib/mysql
      │
      ↓
Volume
      │
      ↓
Persistent database data
```

You can also define multiple locations:

```dockerfile
VOLUME ["/data", "/logs"]
```


# One important distinction about `VOLUME`

`VOLUME` doesn't mean:

> "This automatically creates a named volume called `/data`."

The path:

```dockerfile
VOLUME /data
```

specifies the **container-side mount point**.

When running a container, you can explicitly attach a named volume:

```bash
podman run -v mydata:/data myimage
```

Now:

```text
Podman volume: mydata
          ↓
Container: /data
```



# Put all six together

Imagine:

```dockerfile
FROM python:3.12

LABEL version="1.0"

ENV APP_PORT=8080

ARG APP_ENV=production

RUN useradd -m appuser

COPY app.py /app/app.py

EXPOSE 8080

VOLUME /app/data

USER appuser

CMD ["python", "/app/app.py"]
```

Each instruction has a different job:

```text
FROM
 ↓
Choose the foundation

LABEL
 ↓
Add image information

ARG
 ↓
Build-time variable

ENV
 ↓
Runtime environment variable

COPY
 ↓
Put application files into image

EXPOSE
 ↓
Document container port

VOLUME
 ↓
Declare data location

USER
 ↓
Choose who runs the application

CMD
 ↓
Default command when container starts
```

### The most important distinctions to memorize

| Instruction | Main idea               | When?          |
| ----------- | ----------------------- | -------------- |
| `USER`      | Who runs the process    | Runtime        |
| `LABEL`     | Image metadata          | Image          |
| `EXPOSE`    | Document container port | Image metadata |
| `ENV`       | Environment variable    | Runtime        |
| `ARG`       | Build variable          | Build time     |
| `VOLUME`    | Data mount location     | Runtime        |

And especially remember:

```text
ARG    → build time
ENV    → runtime

EXPOSE → documentation
-p     → actually publishes the port

USER   → security / process identity
VOLUME → data outside the container's writable layer
```

----------

The important idea is:

> **Each instruction creates a new image layer based on the result of the previous instruction.**

Let's see it step by step.

### Example Containerfile

```dockerfile
FROM ubuntu:24.04

RUN apt update

RUN apt install -y curl

COPY app.py /app/app.py

CMD ["python3", "/app/app.py"]
```

Podman doesn't execute all of this as one giant operation.

Conceptually, it does:

```text
FROM ubuntu
      ↓
Intermediate image 1
      ↓
RUN apt update
      ↓
Intermediate image 2
      ↓
RUN apt install curl
      ↓
Intermediate image 3
      ↓
COPY app.py
      ↓
Intermediate image 4
      ↓
Final image
```

So you can imagine:

```text
Layer 4 → COPY app.py
Layer 3 → install curl
Layer 2 → apt update
Layer 1 → Ubuntu
```



## What does "independent container" mean?

During the build, Podman uses temporary/intermediate containers to execute instructions.

For example:

```dockerfile
RUN apt install -y curl
```

Podman creates a temporary environment based on the previous image, executes the command, and commits the result as a new image layer.

Then the next instruction starts from that resulting image.

Conceptually:

```text
Previous image
      ↓
Temporary container
      ↓
RUN command
      ↓
New image layer
      ↓
Temporary container is no longer needed
```

Then the next instruction uses the **new image**.



## Why does this matter?

Because the result of previous instructions is available to later instructions.

For example:

```dockerfile
RUN touch /hello.txt
RUN cat /hello.txt
```

The second instruction can see `/hello.txt` because the first instruction created it and that result became part of the intermediate image.

```text
RUN touch /hello.txt
        ↓
Layer contains /hello.txt
        ↓
RUN cat /hello.txt
        ↓
Can see /hello.txt
```

So "independent" **doesn't mean the instructions have no relationship**.

It means each instruction is executed separately, with the **previous result becoming the starting point for the next one**.



## Why are layers useful?

One major reason is **caching**.

Suppose:

```dockerfile
FROM python:3.12

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY . .
```

The build might produce:

```text
Layer 1 → Python base
Layer 2 → requirements.txt
Layer 3 → pip install
Layer 4 → application source
```

If you change only your Python source code:

```text
app.py
```

Podman can potentially reuse:

```text
Layer 1 ✓
Layer 2 ✓
Layer 3 ✓
```

and rebuild only:

```text
Layer 4 ← changed
```

That's why the order of instructions in a Containerfile matters.

### Simple mental model

Think of building an image like **stacking LEGO blocks**:

```text
       ┌──────────────┐
       │ COPY app.py  │  ← Layer 4
       ├──────────────┤
       │ pip install  │  ← Layer 3
       ├──────────────┤
       │ requirements │  ← Layer 2
       ├──────────────┤
       │ Python base  │  ← Layer 1
       └──────────────┘
```

Each instruction adds another layer.

**Previous instruction → intermediate image → next instruction → another layer → final image.**

That's what your course means when it says each Containerfile instruction is applied using an intermediate image built from the previous instructions.

-----------

## 1. Set a default value with `ARG`

In your `Containerfile`:

```dockerfile
ARG APP_VERSION=1.0
```

This means:

> If nobody gives me a different value, use `1.0`.

So if you simply run:

```bash
podman build -t myapp .
```

Podman uses:

```text
APP_VERSION = 1.0
```



## 2. Change it with `--build-arg`

You don't have to edit the `Containerfile`.

You can run:

```bash
podman build --build-arg APP_VERSION=2.0 -t myapp .
```

Now:

```text
APP_VERSION = 2.0
```

So:

```text
Containerfile:
ARG APP_VERSION=1.0
             ↓
       default value

podman build
(no --build-arg)
             ↓
        uses 1.0

podman build --build-arg APP_VERSION=2.0
             ↓
        uses 2.0
```



## 3. Why is this useful?

Imagine you have:

```dockerfile
ARG NODE_VERSION=22

FROM node:${NODE_VERSION}
```

Normally:

```bash
podman build -t myapp .
```

uses:

```text
NODE_VERSION=22
```

But you can build with another version:

```bash
podman build \
  --build-arg NODE_VERSION=20 \
  -t myapp .
```

Now the same `Containerfile` builds using Node 20.

You **didn't modify the file**.



## 4. Another simple example

```dockerfile
ARG APP_ENV=development

RUN echo "Building for $APP_ENV"
```

Default:

```bash
podman build -t myapp .
```

Output conceptually:

```text
Building for development
```

Change it:

```bash
podman build \
  --build-arg APP_ENV=production \
  -t myapp .
```

Now:

```text
Building for production
```



## The key idea

`ARG` gives you a **variable whose value can be changed when building the image**.

```text
                 ARG
                  ↓
        ┌──────────────────┐
        │ default = 1.0    │
        └──────────────────┘
                  │
       ┌──────────┴──────────┐
       ↓                     ↓
 no --build-arg        --build-arg
       ↓                     ↓
      1.0                   2.0
```

----


> A volume is stored **outside the container**, but it is **made visible inside the container at a path**.

Think of it like plugging an external USB drive into your computer.



## 1. Outside vs inside

Imagine Podman has a volume called:

```
mydata
```

The actual data is stored somewhere managed by Podman **outside the container**.

But your application doesn't need to know that location.

Inside the container, Podman makes that volume appear at:

```
/data
```

So:

```
                 OUTSIDE                    INSIDE
              the container              the container

              Podman volume
                 mydata
                    │
                    │ mounted
                    ↓
             ┌─────────────────┐
             │    CONTAINER     │
             │                  │
             │  /app            │
             │  /etc            │
             │  /data  ◄───────┼── mydata
             │                  │
             └─────────────────┘
```

`/data` is **not the physical storage location**.

It is the **door/path through which the application accesses the external storage**.

---

# Example 1 — AFTER `VOLUME` → change is ignored

```
FROM ubuntu:24.04

VOLUME /data

RUN echo "HELLO" > /data/hello.txt
```

Build:

```
podman build -t test1 .
```

The important order is:

```
FROM ubuntu
   ↓
VOLUME /data
   ↓
RUN echo "HELLO" > /data/hello.txt
```

The `RUN` tries to create:

```
/data/hello.txt
```

But `/data` is already a volume location.

So you **cannot rely on that file becoming part of the image**.

When you later run:

```
podman run test1
```

you should not expect:

```
cat /data/hello.txt
```

to give you:

```
HELLO
```

The change made after `VOLUME` wasn't stored as part of the image's normal filesystem layers.



# Example 2 — BEFORE `VOLUME` → change is preserved

Now change the order:

```
FROM ubuntu:24.04

RUN mkdir -p /data
RUN echo "HELLO" > /data/hello.txt

VOLUME /data
```

Now:

```
FROM ubuntu
   ↓
RUN create /data
   ↓
RUN create /data/hello.txt
   ↓
VOLUME /data
```

The file is created **before** the volume is declared.

So the file can become part of the image.

Then when you run:

```
podman run test2
```

the volume mounted at `/data` can be initialized from the image's existing contents, depending on how the volume is created/mounted.

So you can get:

```
/data/hello.txt
```

with:

```
HELLO
```



# The key difference

### ❌ After VOLUME

```
VOLUME /data

RUN echo "HELLO" > /data/hello.txt
```

Think:

```
/data
  ↓
already designated as volume
  ↓
later build changes aren't stored in image normally
```

-----

# 1. Exec form

Example:

```dockerfile
CMD ["echo", "Hello"]
```

This is called **exec form** because it is written as a JSON array.

Notice the **double quotes**:

```text
["echo", "Hello"]
 ↑             ↑
double quotes
```

Not:

```dockerfile
CMD ['echo', 'Hello']
```

because the exec form is parsed as JSON.

### How does it run?

Podman essentially executes:

```text
echo
```

with:

```text
Hello
```

as its argument.

So:

```text
CMD ["echo", "Hello"]
       ↓
   executable
             ↓
          argument
```



# 2. Shell form

You can also write:

```dockerfile
CMD echo Hello
```

This is called **shell form**.

Here the command is interpreted through a shell.

Conceptually:

```text
CMD echo Hello
      ↓
   /bin/sh
      ↓
   echo Hello
```

The shell can do things such as:

- environment variable expansion
    
- `&&`
    
- pipes `|`
    
- redirection `>`
    
- wildcards
    
- other shell features
    



# 3. The `$HOME` example

This is the most important part of your notes.

Suppose:

```dockerfile
CMD ["echo", "$HOME"]
```

This is **exec form**.

When the container runs, you might get:

```text
$HOME
```

instead of:

```text
/root
```

### Why?

Because exec form does **not automatically start a shell**.

Podman essentially executes:

```text
echo
```

and gives it the literal argument:

```text
$HOME
```

It doesn't ask Bash/sh:

> "What does `$HOME` mean?"

Therefore no variable expansion happens.



# 4. Shell form does expand `$HOME`

Now:

```dockerfile
CMD echo $HOME
```

This is shell form.

The shell sees:

```text
echo $HOME
```

and expands:

```text
$HOME
   ↓
/root
```

So the result could be:

```text
/root
```

The process is conceptually:

```text
CMD echo $HOME
       ↓
     /bin/sh
       ↓
shell sees $HOME
       ↓
expands it
       ↓
echo /root
```



# 5. You can use exec form AND explicitly start a shell

Your notes show:

```dockerfile
CMD ["sh", "-c", "echo $HOME"]
```

This is still **exec form**.

But now **you explicitly told it to run `sh`**.

Break it down:

```text
["sh", "-c", "echo $HOME"]
  ↑     ↑       ↑
 shell   │      command
         │
      execute command
```

So:

```text
Podman
  ↓
executes sh
  ↓
sh -c "echo $HOME"
  ↓
shell expands $HOME
  ↓
echo /root
```

The important point is:

> **The shell is responsible for expanding `$HOME`, not Podman itself.**



# 6. Compare all three

Assume:

```text
HOME=/root
```

### A. Exec form

```dockerfile
CMD ["echo", "$HOME"]
```

Result:

```text
$HOME
```

No shell → no variable expansion.



### B. Shell form

```dockerfile
CMD echo $HOME
```

Result:

```text
/root
```

Shell → variable expansion.



### C. Exec form + explicitly run shell

```dockerfile
CMD ["sh", "-c", "echo $HOME"]
```

Result:

```text
/root
```

You explicitly started the shell.



# 7. Why do developers often prefer exec form?

For applications, you'll commonly see:

```dockerfile
CMD ["python", "app.py"]
```

rather than:

```dockerfile
CMD python app.py
```

or:

```dockerfile
ENTRYPOINT ["node", "server.js"]
```

rather than:

```dockerfile
ENTRYPOINT node server.js
```

The exec form directly starts the application instead of going through a shell.

This can make **signal handling and process behavior** cleaner, especially for containers running one main application.



# 8. One more example with `&&`

This demonstrates why shell processing matters.

### Shell form

```dockerfile
CMD echo hello && echo world
```

The shell understands:

```text
&&
```

and executes:

```text
echo hello
    ↓
echo world
```

Result:

```text
hello
world
```

### Exec form

```dockerfile
CMD ["echo", "hello", "&&", "echo", "world"]
```

There is no shell interpreting `&&`.

It effectively means:

```text
echo "hello" "&&" "echo" "world"
```

So you don't get the same shell behavior.

If you really want shell features with exec form:

```dockerfile
CMD ["sh", "-c", "echo hello && echo world"]
```



# 9. Why must exec form use double quotes?

Because:

```dockerfile
CMD ["echo", "Hello"]
```

is interpreted as a **JSON array**.

JSON requires:

```text
"double quotes"
```

not:

```text
'single quotes'
```

So:

```dockerfile
CMD ["echo", "Hello"]
```

✅ Correct

```dockerfile
CMD ['echo', 'Hello']
```

❌ Not valid JSON exec form.

---

# 1. Create a file containing the secret

```
echo "R3d4ht123" > dbsecretfile
```

This creates a file:

```
dbsecretfile
```

containing:

```
R3d4ht123
```

So on your **host**:

```
Fedora
└── dbsecretfile
      └── R3d4ht123
```



# 2. Create a Podman secret

```
podman secret create dbsecret dbsecretfile
```

There are two important parts:

```
podman secret create
       ↓
    dbsecret
       ↓
  secret name

dbsecretfile
       ↓
file containing the secret
```

So:

```
dbsecretfile
      ↓
Podman stores it as
      ↓
dbsecret
```

Now the secret is managed by Podman.



# 3. List your secrets

```
podman secret ls
```

You might see:

```
ID        NAME        DRIVER
abc123    dbsecret    file
```

The important part is:

```
dbsecret
```


# 4. Inspect the secret

```
podman secret inspect dbsecret
```

This gives metadata about the secret.

**Important:** inspecting a secret doesn't mean you should expect the actual password to be displayed in plaintext. The point is to keep the secret value protected.



# 5. Give the secret to a container

Your course uses:

```
podman run -it \
  --secret dbsecret \
  --name myapp \
  registry.access.redhat.com/ubi8/ubi \
  /bin/bash
```

Let's break it apart:

```
podman run
     ↓
create/start container

-it
     ↓
interactive terminal

--secret dbsecret
     ↓
give the container access to the secret

--name myapp
     ↓
container name = myapp

ubi8/ubi
     ↓
container image

/bin/bash
     ↓
start Bash
```



# 6. Where does the secret appear inside the container?

This is the really important part.

Podman makes the secret available at:

```
/run/secrets/dbsecret
```

So inside the container:

```
Container
│
├── /bin
├── /etc
├── /usr
└── /run
     └── secrets
          └── dbsecret   ← your secret
```

The secret's **filename is the secret name**:

```
dbsecret
```



# 7. Read the secret

Inside the container, run:

```
cat /run/secrets/dbsecret
```

You get:

```
R3d4ht123
```

The flow is:

```
HOST
│
│ dbsecretfile
│
│ "R3d4ht123"
↓
Podman Secret
│
│ dbsecret
↓
CONTAINER
│
└── /run/secrets/dbsecret
             │
             ↓
        R3d4ht123
```



# 8. Why not just use `ENV`?

You might wonder:

> Why don't I just do `ENV DB_PASSWORD=R3d4ht123`?

Because secrets should **not normally be placed directly into an image or ordinary environment configuration**.

For example:

```
ENV DB_PASSWORD=R3d4ht123
```

puts the password into the image configuration.

That's a bad practice for sensitive credentials.

Instead:

```
Podman Secret
     ↓
mounted into container at runtime
     ↓
/run/secrets/dbsecret
```

Your application can read the file when it needs the password.

---
#  What does `--squash` do?

Normally:

```bash
podman build -t myapp .
```

creates something conceptually like:

```text
Ubuntu base
   ↓
Layer A
   ↓
Layer B
   ↓
Layer C
   ↓
Layer D
```

Now build with:

```bash
podman build --squash -t myapp .
```

Podman combines the **new layers created by your Containerfile** into one layer.

So:

```text
Before:

Ubuntu base
   ↓
A
   ↓
B
   ↓
C
   ↓
D
```

becomes:

```text
After --squash:

Ubuntu base
   ↓
A+B+C+D
```

### Important:

The base image layers are **not** squashed.

That's exactly what your course means by:

> `--squash`: Squash all of the image's new layers into a single new layer; preexisting layers are not squashed.



#  What does `--squash-all` do?

Now:

```bash
podman build --squash-all -t myapp .
```

This goes further.

It squashes:

```text
base image layers
+
your new layers
```

into one layer.

Conceptually:

```text
Before:

Ubuntu layer 1
Ubuntu layer 2
Ubuntu layer 3
      ↓
Your layer A
Your layer B
Your layer C
```

After:

```text
--squash-all

Single layer
└── everything
```



# 5. Visual comparison

Suppose:

```text
Base image:
┌──────────────┐
│ Ubuntu L3    │
├──────────────┤
│ Ubuntu L2    │
├──────────────┤
│ Ubuntu L1    │
└──────────────┘

Your Containerfile:
┌──────────────┐
│ COPY         │
├──────────────┤
│ RUN mkdir    │
├──────────────┤
│ RUN install  │
└──────────────┘
```

### Normal

```text
Ubuntu L3
Ubuntu L2
Ubuntu L1
COPY
RUN mkdir
RUN install
```

### `--squash`

```text
Ubuntu L3
Ubuntu L2
Ubuntu L1
      ↓
┌───────────────────┐
│ COPY + mkdir +    │
│ install            │
└───────────────────┘
```

### `--squash-all`

```text
┌─────────────────────────┐
│ Ubuntu + COPY + mkdir + │
│ install                  │
└─────────────────────────┘
```



# Why would we squash?

One reason is to reduce the number of layers.

For example:

```text
Normal:
10 layers

--squash:
base layers + 1 new layer
```

It can also be useful when you want the resulting image to have a simpler layer structure.

But **squashing isn't automatically better**.

Remember that layers provide caching and reuse.

For example, if you have:

```dockerfile
RUN apt install ...
COPY requirements.txt .
RUN pip install ...
COPY . .
```

Podman can reuse unchanged layers during future builds.

If you squash everything, you may lose some of those caching benefits.

That's why your course says:

> Chained commands are more difficult to debug and cache.

and why layer organization matters.

---

# Rootless does NOT necessarily mean the container process is not root

This is where people often get confused.

You could run:

```
podman run -it ubuntu bash
```

as your normal user:

```
ola
```

That is **rootless Podman**.

But inside the container, you might see:

```
root@container:/#
```

and:

```
whoami
```

returns:

```
root
```

How can that be?

Because there are **two different environments**:

```
HOST
User = ola
      ↓
   Podman
      ↓
CONTAINER
User = root
```

The `root` inside the container is isolated from the host's root account through Linux namespaces and other container isolation mechanisms.

So:

> **Rootless refers primarily to how the container runtime is launched on the host, not simply to the username inside the container.**

----------------
## "Podman starts each container as a new process"

When you run:

```
podman run nginx
```

Podman creates a container and starts the program inside it.

Think:

```
Your terminal
     │
     ↓
  Podman
     │
     ↓
Container process
     │
     ↓
nginx
```

For example, you could run:

```
podman run -d --name myapp nginx
```

Podman starts the container's main process.



# Why doesn't Podman need root?

Traditional container tools used a daemon that often ran as root.

Podman is different.

There is **no permanent Podman daemon that must run as root**.

When you do:

```
podman run ...
```

Podman performs the work needed to create/start the container and then exits.

For example:

```
You
 │
 │ podman run
 ↓
Podman process
 │
 │ creates/starts container
 ↓
Container process
 │
 ↓
nginx
```

Then the Podman command finishes.



# "The Podman process exits"

Suppose you run:

```
podman run -d --name web nginx
```

You may see a container ID:

```
abc123...
```

The `podman` command itself doesn't stay running forever.

You can think of it as:

```
Before:
podman process
      ↓
creates container

After:
podman process → exits

container process → continues running
```

This is different from a traditional daemon-based architecture where a central daemon stays running to manage containers.



# What is PID?

**PID = Process ID.**

Linux gives every running process a number.

For example:

```
PID 1     systemd
PID 5000  Firefox
PID 7000  Podman-related process
PID 7100  container application
```

You can see processes with:

```
ps aux
```

or:

```
ps -ef
```

---

# What does "systemd parent process" mean?

This is the part that sounds scary but is actually simple.

Linux processes form a **parent-child tree**.

For example:

```
systemd (PID 1)
   │
   ├── Firefox
   │
   ├── Terminal
   │
   └── container process
```

A process can have a **parent process**.

For example:

```
Parent
  │
  └── Child
```

When the original parent disappears, Linux needs someone to take care of the child process.

In the situation described by your course, the container process can become attached/re-parented under the system's `systemd` process.

Conceptually:

```
Initially:

Podman
   │
   └── Container process


Podman exits:

systemd
   │
   └── Container process
```

So the container **doesn't stop just because the `podman run` command has finished**

--------
### ps -ef | grep -i nginx-cont 

```
ps     → processes
-e     → everything
-f     → full details
|      → send output to next command
grep   → search
-i     → ignore case
nginx-cont → what to search for
```

-------


> **The user inside the Containerfile is not necessarily the same as the user running Podman on your Fedora host.**

### Example

Suppose:

```dockerfile
FROM ubuntu:24.04

RUN apt update
RUN apt install -y curl
```

By default, the image may start with:

```text
USER = root
```

So when Podman executes:

```dockerfile
RUN apt install -y curl
```

the command has the permissions needed to install software.

Think:

```text
Container build
       │
       ↓
   root user
       │
       ├── apt install
       ├── create directories
       └── modify system configuration
```



## Why does it need root?

Some operations are restricted to privileged users.

For example:

```bash
apt install curl
```

needs to modify system directories such as:

```text
/usr
/etc
/var
```

A normal user usually cannot modify these locations.

So during the **build**, you commonly start as `root`.



# But you don't have to keep root

This is the important security practice.

You can do:

```dockerfile
FROM ubuntu:24.04

RUN apt update && apt install -y curl

RUN useradd -m appuser

USER appuser

CMD ["bash"]
```

Notice the order:

```text
FROM
 ↓
root
 ↓
install packages
 ↓
create user
 ↓
USER appuser
 ↓
application runs as appuser
```

So you use root **when you need it**, then switch to a less-privileged user.



# Build vs running

This distinction is very important:

### During build

```dockerfile
RUN apt install ...
```

Usually:

```text
root
```

because you need to install/configure things.

### During runtime

You can specify:

```dockerfile
USER appuser
```

so the application runs as:

```text
appuser
```

rather than root.



## And this is separate from rootless Podman

You might have:

```text
Fedora host
    │
    │ Ola runs Podman (rootless)
    ↓
Container
    │
    │ build operations
    ↓
root
```

That's possible.

So:

**Rootless Podman** ≠ **container runs as non-root user**.

They refer to different things:

```text
ROOTLESS
→ Podman runtime on the HOST runs as a normal user

USER root/appuser
→ user INSIDE the container
```

---
