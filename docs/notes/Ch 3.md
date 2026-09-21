`podman pull` means:

> **Download an image from a container registry to your computer.**

The general syntax is:

```bash
podman pull <registry>/<repository>/<image>:<tag>
```

Your example:

```bash
podman pull registry.redhat.io/ubi8/ubi:8.6
```

Let's break it apart:

```text
registry.redhat.io   /   ubi8   /   ubi   :   8.6
       │                  │          │        │
       │                  │          │        └── tag/version
       │                  │          └────────── image name
       │                  └───────────────────── repository
       └──────────────────────────────────────── registry
```

### What is a registry?

A **registry** is a place on the internet that stores container images.

Think of it like an **app store for container images**.

For example:

```text
Docker Hub
quay.io
registry.redhat.io
```

### What does `pull` do?

When you run:

```bash
podman pull registry.redhat.io/ubi8/ubi:8.6
```

Podman does roughly this:

```text
Internet
   │
   │ download image
   ↓
registry.redhat.io
   │
   │ UBI 8.6 image
   ↓
Your Fedora computer
   │
   ↓
Podman local image storage
```

You can then check it:

```bash
podman images
```

You might see:

```text
REPOSITORY                         TAG
registry.redhat.io/ubi8/ubi       8.6
```

And then create a container from it:

```bash
podman run -it registry.redhat.io/ubi8/ubi:8.6
```

---

### What does `:8.6` mean?

That's the **tag**.

It identifies which version/variant of the image you want.

For example:

```bash
podman pull python:3.12
```

means:

> Download the Python image with tag `3.12`.

And:

```bash
podman pull mysql:8.0
```

means:

> Download the MySQL image with tag `8.0`.

If you leave the tag out:

```bash
podman pull mysql
```

Podman normally uses the default tag:

```text
latest
```

So:

```bash
podman pull mysql
```

is essentially asking for:

```bash
podman pull mysql:latest
```

----------
**Skopeo** is another tool in the container ecosystem, but unlike `podman`, it is mainly used to **inspect and move images without running them**.

Think of it like this:

```
Podman  → build / run / manage containers
Skopeo  → inspect / copy / transfer images
```

-----------
Yes. This means **giving an existing local image another name/tag** without rebuilding or copying the image.

The syntax is:

```bash
podman image tag <existing-image>:<old-tag> <new-name>:<new-tag>
```

### Simple example

Suppose you already have:

```bash
podman images
```

and see:

```text
REPOSITORY    TAG
myapp         latest
```

You can create another tag:

```bash
podman image tag myapp:latest myapp:v1
```

Now:

```bash
podman images
```

might show:

```text
REPOSITORY    TAG
myapp         latest
myapp         v1
```

**Important:** You did **not** create another copy of the image. Both tags point to the same underlying image.

```text
             Same image
                 │
          ┌──────┴──────┐
          ↓             ↓
     myapp:latest    myapp:v1
```

### Why is this useful?

The most important use is when you want to **push your local image to a registry**.

For example, you built:

```bash
podman build -t eventhub-frontend:latest .
```

Now you want to put it on Quay under your account:

```bash
podman image tag \
  eventhub-frontend:latest \
  quay.io/myuser/eventhub-frontend:v1
```

Then push:

```bash
podman push quay.io/myuser/eventhub-frontend:v1
```

So the workflow is:

```text
Build
  ↓
eventhub-frontend:latest
  ↓
podman image tag
  ↓
quay.io/myuser/eventhub-frontend:v1
  ↓
podman push
  ↓
Quay.io
```

### `tag` does NOT mean "make a new image"

This is the key point:

```bash
podman image tag old:new new:new
```

doesn't rebuild the image.

It basically gives the **same image another label/name**.

Think of it like having a file:

```text
report.pdf
```

and giving it another reference/name:

```text
final-report.pdf
```

The contents haven't changed.

**Remember:**

> `podman image tag` = **add another name/tag to an existing local image.**

---------------
Sure. The important word here is **"unqualified"**.

### 1. What does `podman search` do?

When you run:

```bash
podman search <image-name>
```

Podman searches container registries for an image with that name.

For example:

```bash
podman search nginx
```

You might get results like:

```text
NAME                              DESCRIPTION
docker.io/library/nginx           Official Nginx image
quay.io/someuser/nginx             Nginx image
...
```

---

### 2. What does "unqualified image name" mean?

Compare these two:

```text
nginx
```

and:

```text
docker.io/library/nginx
```

`nginx` is an **unqualified image name** because you didn't specify a registry.

`docker.io/library/nginx` is a **qualified image name** because you specified where the image comes from.

Think:

```text
nginx
 ↓
"Find nginx for me."

docker.io/library/nginx
 ↓
"Get nginx specifically from Docker Hub."
```

---

### 3. Where does Podman search?

Podman has a configuration file called:

```text
/etc/containers/registries.conf
```

It can contain something like:

```toml
unqualified-search-registries = ["registry.access.redhat.com", "docker.io", "quay.io"]
```

This tells Podman:

> "When the user gives me an image name without a registry, these are the registries I should consider."

So when you run:

```bash
podman search nginx
```

Podman can search those registries.

Conceptually:

```text
                 podman search nginx
                         │
          ┌──────────────┼──────────────┐
          ↓              ↓              ↓
    Red Hat Registry  Docker Hub      Quay.io
          │              │              │
          ↓              ↓              ↓
       nginx?          nginx?         nginx?
```

That's what your course means by:

> "This enables you to search different registries in one go."

---

Yes. This section is teaching you the **complete workflow for building an image, putting it in Quay, and inspecting it**.

Think of it as:

```text
Containerfile
     ↓
podman build
     ↓
Local image
     ↓
podman login
     ↓
podman push
     ↓
Quay.io
```

## 1. `podman login`

```bash
podman login <REGISTRY>
```

This logs your Podman client into a container registry.

For Quay:

```bash
podman login quay.io
```

Podman will ask for your username and password/token.

Why do you need this?

Because Quay needs to know:

> "Who is trying to upload this image?"

---

# 2. `podman build`

The command in your notes is:

```bash
podman build --file Containerfile --tag quay.io/YOUR_QUAY_USER/IMAGE_NAME:TAG .
```

Let's break it down:

```text
podman build
     │
     ├── --file Containerfile
     │       ↑
     │       use this Containerfile
     │
     ├── --tag quay.io/YOUR_QUAY_USER/IMAGE_NAME:TAG
     │       ↑
     │       give the image this name/tag
     │
     └── .
             ↑
             build context = current directory
```

### Example

Suppose your Quay username is `ola` and your project is:

```text
eventhub-frontend/
├── Containerfile
├── package.json
└── src/
```

From inside `eventhub-frontend`:

```bash
podman build \
  --file Containerfile \
  --tag quay.io/ola/eventhub-frontend:v1 .
```

Podman reads your `Containerfile` and builds the image.

You can then check it:

```bash
podman images
```

You might see:

```text
REPOSITORY                         TAG
quay.io/ola/eventhub-frontend     v1
```

---

# 3. Why do we put `quay.io/...` in the tag?

This is very important.

If you build:

```bash
podman build -t eventhub-frontend:v1 .
```

the image is just named locally:

```text
eventhub-frontend:v1
```

But if you build:

```bash
podman build -t quay.io/ola/eventhub-frontend:v1 .
```

you are giving it the **name it will have in Quay**.

```text
quay.io
   │
   └── ola
        │
        └── eventhub-frontend
                    │
                    └── v1
```

That makes it ready to push.

---

# 4. `podman push`

After logging in and building:

```bash
podman push quay.io/ola/eventhub-frontend:v1
```

This means:

> Take my local image and upload it to Quay.

The flow is:

```text
Your Fedora computer
        │
        │ podman push
        ↓
     Quay.io
        │
        ↓
ola/eventhub-frontend:v1
```

So:

```text
podman build → create image locally
podman push  → upload image to registry
```

---

# 5. Inspecting an image

Now the second section.

```bash
podman image inspect <image-name>
```

This gives you **detailed information about an image**.

For example:

```bash
podman image inspect quay.io/ola/eventhub-frontend:v1
```

The output can be very large because it contains things such as:

- image ID
    
- created time
    
- architecture
    
- OS
    
- environment variables
    
- entrypoint
    
- command
    
- layers
    
- configuration
    

---

# 6. Why use `--format`?

Instead of displaying everything, you can tell Podman:

> "Show me only the information I want."

For example:

```bash
podman image inspect quay.io/ola/eventhub-frontend:v1 \
  --format "{{.Config.Cmd}}"
```

Instead of a huge JSON-like output, you might get:

```text
["npm","run","start"]
```

The `{{.Config.Cmd}}` part tells Podman **which field you want**.

Think of it as:

```text
podman image inspect
        ↓
lots of information
        ↓
--format
        ↓
only the information I want
```

### Another example

You can inspect the image's architecture:

```bash
podman image inspect quay.io/ola/eventhub-frontend:v1 \
  --format "{{.Architecture}}"
```

Output:

```text
amd64
```

Or the operating system:

```bash
podman image inspect quay.io/ola/eventhub-frontend:v1 \
  --format "{{.Os}}"
```

Output:

```text
linux
```

---

## What is a dangling image?

This is an important DevOps term.

A **dangling image** is basically an image layer/image reference that is no longer associated with a useful tag and isn't referenced by another image.

For example, you build:

```bash
podman build -t myapp:v1 .
```

Then you change the `Containerfile` and rebuild:

```bash
podman build -t myapp:v1 .
```

The old image may become dangling.

You might see something like:

```text
REPOSITORY    TAG       IMAGE ID
myapp         v1        abc123
<none>        <none>    xyz789
```

The:

```text
<none>  <none>
```

is a common indication of a dangling image.

## Remove dangling images

Use:

```bash
podman image prune
```

This cleans up dangling images.

Think:

```text
Dangling images
      ↓
podman image prune
      ↓
Deleted
```

It is basically a **cleanup operation**.


|Command|What it removes|
|---|---|
|`podman rmi IMAGE`|One image|
|`podman rmi -f IMAGE`|Force-remove one image|
|`podman rmi --all`|All local images|
|`podman image prune`|Dangling images|
|`podman image prune -a`|All unused images|

----------
```
podman export -o mytarfile.tar <container-id>
podman import mytarfile.tar <image-name>
```

means:

**Take a container's filesystem → package it → later turn that filesystem into a new image.**


|Command|Takes|Produces|Restore with|
|---|---|---|---|
|`podman save`|**Image**|Image `.tar`|`podman load`|
|`podman export`|**Container**|Filesystem `.tar`|`podman import`|

Think:

```
SAVE / LOAD
Image → TAR → Image
```

```
EXPORT / IMPORT
Container → TAR → New Image
```

# `podman load`

Later, maybe you move:

```
httpd-image.tar
```

to another computer.

You can restore it with:

```
podman load --input httpd-image.tar
```

or:

```
podman load -i httpd-image.tar
```

Podman reads the image information **from the tar file itself**.

So you don't need to say:

```
podman load httpd-image.tar myimage:v1
```

❌ That's not necessary.

Why?

Because the image's name and tag are already stored in its metadata.

For example:

```
httpd-image.tar
       │
       │ contains
       ↓
registry.access.redhat.com/ubi8/httpd-24:latest
```

Then:

```
podman load -i httpd-image.tar
```

restores that image.

You can verify:

```
podman images
```

--------
