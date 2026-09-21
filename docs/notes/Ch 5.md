
#  Building an image creates layers

Suppose your `Containerfile` is:

```dockerfile
FROM ubuntu:24.04

RUN apt install -y curl

COPY app.py /app/app.py
```

Podman builds something conceptually like:

```text
              IMAGE
┌──────────────────────────┐
│ Layer 3                  │ ← COPY app.py
├──────────────────────────┤
│ Layer 2                  │ ← apt install curl
├──────────────────────────┤
│ Layer 1                  │ ← Ubuntu
└──────────────────────────┘
```

These layers are **read-only**.

That means once Podman creates:

```text
Layer 2
```

you don't go back and change Layer 2.

Instead, if you make another change, Podman creates another layer.



#  What does "diff" mean?

A **diff** simply means:

> What changed compared with the previous layer?

For example:

### Layer 1

```text
/
├── bin
├── etc
└── usr
```

Then:

```dockerfile
RUN mkdir /app
```

Layer 2 doesn't need to contain the entire Ubuntu filesystem again.

It essentially records:

```text
DIFF:
+ /app
```

Then:

```dockerfile
COPY app.py /app/
```

creates another layer:

```text
DIFF:
+ /app/app.py
```

So conceptually:

```text
Layer 1:
Ubuntu files

Layer 2:
+ /app

Layer 3:
+ /app/app.py
```

That's what your notes mean by:

> each layer contains a set of changes, or diffs, from the previous layer.



#  Now you run the image

You have:

```text
IMAGE
┌─────────────────┐
│ Layer 3         │
├─────────────────┤
│ Layer 2         │
├─────────────────┤
│ Layer 1         │
└─────────────────┘
```

Then:

```bash
podman run myimage
```

Podman does **not modify those image layers**.

Instead, it adds a new writable layer:

```text
             CONTAINER
┌──────────────────────────┐
│ Read-write layer         │ ← container-specific
├──────────────────────────┤
│ Layer 3                  │ ← read-only
├──────────────────────────┤
│ Layer 2                  │ ← read-only
├──────────────────────────┤
│ Layer 1                  │ ← read-only
└──────────────────────────┘
```

That top layer belongs to **this particular container**.



# What happens if the application creates a file?

Suppose the image contains:

```text
/app/app.py
```

When the container runs:

```bash
echo "hello" > /tmp/test.txt
```

The new file goes into:

```text
READ-WRITE CONTAINER LAYER
```

It does **not** modify the image.

So:

```text
IMAGE
├── Layer 3  🔒
├── Layer 2  🔒
└── Layer 1  🔒

CONTAINER
└── Read-write layer
      └── /tmp/test.txt
```



#  What if you modify an existing file?

Suppose the image contains:

```text
/app/config.txt
```

and inside the running container you do:

```bash
echo "new configuration" > /app/config.txt
```

Podman doesn't modify the read-only image layer.

Instead, the container's writable layer records the change.

Conceptually:

```text
Image layer:
config.txt = "old"

Container layer:
config.txt = "new"
```

The container sees:

```text
config.txt = "new"
```

but the original image still has:

```text
config.txt = "old"
```

This is part of the **copy-on-write** idea.



# Now the really important part: two containers

Suppose you have:

```bash
podman run -d --name container1 myimage
podman run -d --name container2 myimage
```

Both containers use the **same image**.

So Podman doesn't need two copies of the read-only layers.

Conceptually:

```text
                  myimage
              ┌─────────────┐
              │ Layer 3     │
              ├─────────────┤
              │ Layer 2     │
              ├─────────────┤
              │ Layer 1     │
              └──────┬──────┘
                     │
             shared read-only
                  layers
                /         \
               /           \
              ↓             ↓
      Container 1      Container 2
      ┌──────────┐      ┌──────────┐
      │ RW layer │      │ RW layer │
      └──────────┘      └──────────┘
```

Each container gets its **own writable layer**.



#  Example

Container 1 creates:

```bash
echo "A" > /data/file.txt
```

Container 2 creates:

```bash
echo "B" > /data/file.txt
```

They don't conflict because they have different writable layers.

```text
             SAME IMAGE
          ┌──────────────┐
          │ Layer 3      │
          │ Layer 2      │
          │ Layer 1      │
          └──────┬───────┘
                 │
        ┌────────┴────────┐
        ↓                 ↓
  Container 1        Container 2
  RW layer           RW layer
  file.txt = A       file.txt = B
```



# Now delete Container 1

You run:

```bash
podman rm container1
```

What happens?

Its writable layer disappears:

```text
             SAME IMAGE
          ┌──────────────┐
          │ Layer 3      │
          │ Layer 2      │
          │ Layer 1      │
          └──────┬───────┘
                 │
                 ↓
          Container 2
          RW layer
          file.txt = B
```

Container 1's:

```text
file.txt = A
```

is gone.

That's why your notes say:

> **container runtime data is ephemeral.**

**Ephemeral = temporary; it disappears when the container is removed.**



#  But wait — what about volumes?

This is where you need to connect this lesson to what we discussed earlier.

There are **two different places for data**:

### Container writable layer

```text
Container
└── RW layer
      └── temporary data
```

Delete container → **data disappears**

### Volume

```text
Container
└── /data
      ↓
   Volume
      ↓
Host storage
```

Delete container → **volume can remain**

So:

|Storage|Survives container deletion?|
|---|---|
|Image read-only layers|✅ Yes|
|Container writable layer|❌ No|
|Named volume|✅ Yes|
|Bind mount|✅ Yes|

-------

Imagine the image has:

```text
Image layer 🔒
└── /app/config.txt
```

You start a container and run:

```bash
echo "new" > /app/config.txt
```

Podman does roughly this:

```text
1. Find config.txt
       ↓
2. Copy it from the read-only image layer
       ↓
3. Put the copy in the container's RW layer
       ↓
4. Modify the copy
```

So:

```text
IMAGE (read-only)
└── config.txt = old
          ↓
       copy
          ↓
CONTAINER RW LAYER
└── config.txt = new
```

The original image is **not changed**.



### Why is this called Copy-on-Write?

Because Podman only copies the file **when you try to write to it**.

```text
Only READ:
Image file ─────────→ container reads it
(no copy needed)

WRITE:
Image file
    ↓
copy to RW layer
    ↓
modify copy
```

This is called **copy-on-write (CoW)**.



### What happens when the container is deleted?

The modified copy in the RW layer disappears:

```text
Container deleted
      ↓
RW layer deleted
      ↓
modified file disappears
```

The original image file remains unchanged.



### What is the storage driver?

The **storage driver** is the mechanism Podman uses to manage:

* image layers
* the container's writable layer
* how files are read/written between those layers

For example, **Overlay/OverlayFS** is commonly used.

**Overlay** is a storage technology that lets Podman make several filesystem layers **look like one filesystem** to the container.

Think of it as **stacking transparent sheets** on top of each other.



### Why can writing be slower?

Because with copy-on-write storage, modifying an existing file may require extra work:

```text
find file
   ↓
copy file
   ↓
modify copy
```

So it can be slower than directly writing to a normal filesystem.

---


Podman can connect storage **outside the container** in two main ways:

- **Volume** → storage managed by Podman
    
- **Bind mount** → directly use a directory/file from your host
    

Example:

```bash
podman run -v mydata:/data myimage
```

or:

```bash
podman run -v /home/ola/data:/data myimage
```

### Why is this useful?

Normally, writing inside the container uses the **copy-on-write (COW)** layer:

```text
Container write
     ↓
COW layer
     ↓
may be slower
```

But with a volume or bind mount:

```text
Container
    ↓
external mount
    ↓
host filesystem
```

The data is written directly to the mounted storage instead of the container's COW layer.

So **write-heavy applications** such as databases can benefit from better write performance.

----


You create a volume:

```bash
podman volume create mydata
```

Then:

```bash
podman run -v mydata:/data myimage
```

Think:

```text
Podman manages storage
        ↓
     mydata
        ↓
container:/data
```

You don't choose the actual host directory. **Podman chooses and manages it.**



# Bind mount = YOU choose the host folder

This is the only new idea you need.

Suppose you have a folder on your Fedora computer:

```text
/home/ola/project
```

You want the container to see that exact folder.

You run:

```bash
podman run -v /home/ola/project:/app myimage
```

Now:

```text
YOUR FEDORA
/home/ola/project
       │
       │ directly connected
       ↓
CONTAINER
/app
```

That's a **bind mount**.

### The difference from volume:

Volume:

```text
podman volume create mydata

mydata
  ↓
Podman decides where it physically lives
  ↓
/data inside container
```

Bind mount:

```text
/home/ola/project
  ↓
YOU choose this exact host directory
  ↓
/app inside container
```

That's it.



# Why would I use a bind mount?

Imagine you're developing an application.

Your project is:

```text
/home/ola/myapp
```

Inside the container, your application expects:

```text
/app
```

You can connect them:

```bash
podman run \
  -v /home/ola/myapp:/app \
  myimage
```

Now when you edit:

```text
/home/ola/myapp/app.py
```

on Fedora, the container immediately sees:

```text
/app/app.py
```

because they're connected to the same files.

This is why bind mounts are very common for **development/testing**.



#  What is `--mount`?

This is **NOT a new type of storage**.

It's just another way to write `-v`.

These two can do the same thing:

### Short form

```bash
podman run -v /home/ola/myapp:/app myimage
```

### Long form

```bash
podman run \
  --mount type=bind,source=/home/ola/myapp,destination=/app \
  myimage
```

Both mean:

```text
Host:
/home/ola/myapp
       ↓
Container:
/app
```

So don't think:

> "`--mount` is something different from `-v`."

It is just a **more explicit syntax**.



# Then what is `tmpfs`?

Forget this for now if you're learning the basics.

Just know:

```text
tmpfs = temporary storage in RAM
```

For example:

```bash
podman run --mount type=tmpfs,destination=/tmp myimage
```

The data is temporary and disappears when the container stops/is removed depending on the lifecycle.



# The only comparison you need right now

Imagine you want `/data` inside your container.

### Volume

```text
Podman-managed
       ↓
    mydata
       ↓
 /data in container
```

Command:

```bash
podman run -v mydata:/data myimage
```

### Bind mount

```text
YOU choose
       ↓
/home/ola/data on Fedora
       ↓
 /data in container
```

Command:

```bash
podman run -v /home/ola/data:/data myimage
```

### tmpfs

```text
RAM
 ↓
/data in container
```

---

