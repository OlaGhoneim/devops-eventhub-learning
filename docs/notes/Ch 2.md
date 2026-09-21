# "Podman is daemonless"

This is the **most important part** of this slide.

### What is a daemon?

A **daemon** is a background process that keeps running and waits for requests.

Imagine:

You

 ↓

Docker command

 ↓

Docker daemon

 ↓

Container

With Docker, traditionally, a background process called the **Docker daemon** manages containers.

---

### Podman doesn't require that central daemon

Podman works more like:

You

 ↓

Podman command

 ↓

Container

There isn't one central daemon that must always be running to handle your requests.

--------------

# "A daemon might require elevated privileges"

**Elevated privileges** means **higher permissions**, often **root/administrator permissions**.

Why can this be a security concern?

Imagine:

User

 ↓

Daemon

 ↓

Containers

If the daemon is running with powerful permissions and someone manages to exploit it, that could potentially give them access to things they shouldn't have.

Podman supports **rootless containers**, meaning containers can often be run as a normal user without requiring the container engine itself to run as root.

---------


> **Along with the CLI, Podman provides two additional ways to interact with your containers and automate processes:**
> 
> 1. **RESTful API**
>     
> 2. **Desktop application called Podman Desktop**
>     

Let's understand them.



## First: What is CLI?

You've already seen commands like:

```bash
podman ps
podman run nginx
podman stop mycontainer
```

This is the **CLI** = **Command-Line Interface**.

You interact with Podman by typing commands:

```text
You
 ↓
Terminal
 ↓
Podman CLI
 ↓
Containers
```

But Podman gives you other ways too.



# 1. RESTful API

An **API** is basically a way for **one program to communicate with another program**.

Instead of you typing:

```bash
podman ps
```

another application can send a request to Podman:

```text
Application
     ↓
  REST API
     ↓
   Podman
     ↓
 Containers
```

For example, imagine you build a website called **My Container Manager**.

Your website could have a button:

```text
┌────────────────────────┐
│  My Container Manager  │
│                        │
│  Containers: 3         │
│                        │
│  [ Start Container ]   │
│  [ Stop Container ]    │
└────────────────────────┘
```

When the user clicks **Start Container**, your application can communicate with Podman through its API.

So:

> **REST API = allows other programs to communicate with and control Podman programmatically.**

You don't have to manually type every Podman command.



# 2. Podman Desktop

This one is much easier.

**Podman Desktop** is a **graphical user interface (GUI)** for Podman.

Instead of:

```text
Terminal
   ↓
podman ps
podman run ...
podman stop ...
```

you can use a graphical application:

```text
Podman Desktop
      ↓
┌─────────────────────┐
│ Containers          │
│                     │
│ nginx       Running │
│ postgres    Running │
│ my-app      Stopped │
│                     │
│ [Start] [Stop]      │
└─────────────────────┘
```

You can visually manage containers, images, pods, and other resources.



# So there are 3 ways

Think about it like this:

```text
                    Podman
                      │
          ┌───────────┼───────────┐
          ↓           ↓           ↓
         CLI         REST API   Podman Desktop
          │           │           │
       Commands    Programs       GUI
```

### CLI

You type:

```bash
podman ps
```

### REST API

Another program communicates with Podman:

```text
My application → API → Podman
```

### Podman Desktop

You use a graphical interface:

```text
You → Click buttons → Podman
```

### ⭐ Easy way to remember

> **CLI = you talk to Podman using commands.**  
> **REST API = programs talk to Podman.**  
> **Podman Desktop = you talk to Podman using a graphical interface.**

-------


## 1. What is CNI?

**CNI = Container Network Interface.**

It is basically a **standard for connecting containers to networks**.

Think of CNI as a set of rules/tools that say:

> "When a container starts, how do we give it a network connection?"

For example:

```text
Container starts
      ↓
CNI networking
      ↓
Give container:
- IP address
- network connection
- connection to other containers
```

So **CNI is about container networking**.



## 2. Think of CNI as a "networking system"

Imagine you have:

```text
Container A
Container B
Container C
```

You want:

```text
A ←→ B ←→ C
```

Something needs to create the network and connect those containers.

CNI provides the **standard/plugin mechanism** for doing that.

```text
             CNI
              ↓
       ┌──────┼──────┐
       ↓      ↓      ↓
   Container Container Container
       A        B        C
```



# 3. What is a CNI network?

A **CNI network** is a network configured using CNI-compatible networking components.

For example, a Podman network might provide:

```text
        Podman network
             │
      ┌──────┴──────┐
      ↓             ↓
    API           Database
```

The networking system gives them things like:

- IP addresses
    
- network interfaces
    
- connectivity between containers
    



# 4. Now the confusing part: `slirp4netns`

You learned:

> Rootless Podman commonly uses `slirp4netns`.

Think of two different approaches.

### Approach A — `slirp4netns`

```text
Normal user
     ↓
   Podman
     ↓
Container
     ↓
slirp4netns
     ↓
Network
```

It allows a rootless container to get network connectivity **without needing the normal privileged networking setup**.



### Approach B — CNI network

```text
Podman
   ↓
CNI networking
   ↓
Shared network
   ↓
┌───────────────┐
│               │
API          Database
```

This is designed for containers to participate in a configured container network.



# 5. Why does the slide say `slirp4netns` "cannot attach to CNI networks"?

This is the key sentence.

It means:

> A container using the `slirp4netns` networking mode isn't simultaneously attached to a CNI-created network in the normal way.

Imagine:

```text
Container
   │
   └── slirp4netns
```

You can't simply say:

```text
Container
   ├── slirp4netns
   └── CNI network
```

and expect those to be the same networking setup.

Instead, if you want the container to participate in a shared Podman/CNI-style network, you configure it to use that network.



# 6. Why would I want a CNI network?

Because you might have:

```text
API
 ↓
Database
```

and you want both containers on the same network:

```text
             app-network
            /           \
           ↓             ↓
         API          Database
```

Then the API can communicate with the database through that network.



# 7. The easiest analogy

Imagine **CNI is a road system**.

You have:

```text
🚗 Container A
🚗 Container B
🚗 Container C
```

CNI provides the mechanism for creating the roads:

```text
        Road system
       /     |      \
      ↓      ↓       ↓
     A       B       C
```

Now `slirp4netns` is a **different way of giving a container network access**, especially useful for rootless containers.

```text
Container
    ↓
slirp4netns
    ↓
outside network
```

So don't think:

> "`slirp4netns` is a type of CNI."

Instead, for what you're learning here, think:

> **CNI and `slirp4netns` are different networking approaches/mechanisms used to give containers network connectivity.**

---
Yes. This paragraph is actually much easier than the previous one. It is explaining **how Podman networking changes depending on whether you run a container as root or as a normal user.**

Let's go sentence by sentence.

---

## 1. Root vs. rootless containers

The paragraph starts by saying:

> Podman networking behaves differently when you run containers as the root user versus when you run them as a non-root user.

So there are two situations:

```text
ROOT
  ↓
Podman container

NORMAL USER
  ↓
Podman container
```



# 2. Rootful container

**Rootful** means:

> You are running the container with root privileges.

For example:

```bash
sudo podman run nginx
```

Conceptually:

```text
root
 ↓
Podman
 ↓
container
```

The paragraph says that when you run containers as **root**, Podman uses a **pre-configured `podman` network** by default.

Think:

```text
          podman network
         /             \
        ↓               ↓
   Container A     Container B
```

So the containers can communicate through that network.



# 3. Rootless container

Now suppose you're a normal user:

```text
normal user
     ↓
   Podman
     ↓
 container
```

The paragraph says that the **default rootless network is different**.

It uses:

```text
slirp4netns
```

So:

```text
Rootless container
        ↓
   slirp4netns
        ↓
     Network
```



# 4. What does "without DNS" mean?

This is an important part.

Suppose you have:

```text
API container
Database container
```

With a proper shared Podman network, containers can communicate using **container names**.

For example:

```text
API → database
```

The API can say:

> "Connect to `database`."

The network's DNS helps translate:

```text
database
   ↓
IP address of database container
```

So:

```text
API → "database" → DNS → Database IP
```



## But rootless `slirp4netns` doesn't give you this same shared-network behavior.

So you can't necessarily do:

```text
API → "database"
```

just because both are rootless containers.

That's why your notes say:

> "without DNS, containers attached to a network cannot reach other containers by using the container's IP address..."

The exact wording in your corrupted slide is awkward, but the important concept is:

**A shared container network provides container-to-container name resolution.**



# 5. What happens with a rootless container?

The notes say:

> If you run a rootless container, the non-root user cannot create networking bridges or manage virtual interfaces on the host.

This is because those operations normally require **higher privileges**.

Remember:

```text
Root
 ↓
Can configure powerful networking things
```

while:

```text
Normal user
 ↓
Limited permissions
```

So Podman uses `slirp4netns` instead.


# 6. Why does Podman create a network namespace?

This part sounds scary but isn't.

A **network namespace** is basically:

> A separate network environment for a process/container.

Think:

```text
Host network
     │
     │
     ├── Container A → its own network environment
     │
     └── Container B → its own network environment
```

Podman creates the required networking environment for the container.



# 7. What if I want rootless containers to communicate?

This is the final important part.

Suppose you have:

```text
API
Database
```

and you want:

```text
API ←→ Database
```

You need to create a **Podman network** and attach both containers to it.

Conceptually:

```text
             my-network
            /          \
           ↓            ↓
         API          Database
```

Now they can communicate.



# 8. The paragraph's main idea

Your entire slide can be reduced to this:

### Rootful

```text
root
 ↓
Podman
 ↓
podman network
 ↓
┌───────────┐
│ Container │
│ Container │
└───────────┘

Shared network
+ container-to-container communication
```

### Rootless

```text
normal user
     ↓
   Podman
     ↓
 slirp4netns
     ↓
 container
```

This is easier for running a single rootless container, but it doesn't behave like a shared Podman bridge network.



## ⭐ The most important thing to memorize

|Situation|Typical networking in your notes|
|---|---|
|**Rootful**|`podman` network|
|**Rootless**|`slirp4netns`|
|Want multiple containers to communicate|Put them on the **same Podman network**|

And the key distinction:

> **`slirp4netns` → gives a rootless container network access.**

> **Podman/bridge network → gives multiple containers a shared network so they can communicate.**

That's the whole paragraph. You **do not need to memorize the details about virtual interfaces or network namespaces yet**.

------------
`podman network inspect` **shows you the detailed configuration and current state of a Podman network**. It does **not** change anything.

Think of it as:

> **"Tell me everything about this network."**

For example:

podman network inspect mynetwork

It will show information such as:

- **Network name** → `mynetwork`
- **Network ID**
- **Driver** → usually `bridge`
- **Subnet** → e.g. `10.89.0.0/24`
- **Gateway** → e.g. `10.89.0.1`
- **IP range**
- **DNS settings**
- **Connected containers** and their network information

--------------


### 1. `podman run -d --name cont1 --net mynet nginx`

**Breakdown:**

- `podman run` → create and start a new container.
    
- `-d` → **detached mode**; run in the background.
    
- `--name cont1` → give the container the name `cont1`.
    
- `--net mynet` → connect the container to the `mynet` network.
    
- `nginx` → the image to run.
    

So:

> **Start an Nginx container in the background, call it `cont1`, and connect it to `mynet`.**

---

### 2. `podman run -d --name cont2 --net mynet nginx`

Same idea, but creates another container:

```text
cont1 ─┐
       ├── mynet
cont2 ─┘
```

Because both containers are on `mynet`, they can communicate through that network.

---

### 3. `podman exec -it cont1 /bin/bash`

This is very important.

- `podman exec` → execute a command **inside an already-running container**.
    
- `-i` → interactive; keep input open.
    
- `-t` → give you a terminal (TTY).
    
- `cont1` → the container where the command will run.
    
- `/bin/bash` → start a Bash shell.
    

So:

> **Open a Bash terminal inside `cont1`.**

You'll get something like:

```text
[root@cont1 /]#
```

Now commands you type are being executed **inside the container**, not directly on your host.

---

### 4. `dnf install curl`

This installs `curl` using the **DNF package manager**.

```text
dnf
 ↓
package manager

install
 ↓
install a package

curl
 ↓
the package to install
```

So:

> **Install curl inside the container.**

This is commonly done so you can test networking from inside the container.

For example:

```bash
curl http://cont2
```

---

### 5. `curl http://cont2`

This sends an HTTP request to the host named `cont2`.

The interesting part is that you don't need to write its IP address:

```text
curl http://10.89.0.3
```

Instead, you can use:

```text
curl http://cont2
```

because Podman's DNS on the custom network can resolve:

```text
cont2
  ↓
DNS
  ↓
10.89.0.3
```

So this command is basically **testing whether `cont1` can reach `cont2` by its container name**.

---

### 6. "If you want to another container with different network to talk to cont, should curl with container IP address as DNS is not enabled."

This is explaining an important limitation.

Suppose:

```text
Network A                 Network B

cont1                     cont3
  |                         |
  └── mynet                 └── othernet
```

`cont1` and `cont3` are on **different networks**.

If Podman's DNS is only providing name resolution within `mynet`, then `cont1` cannot simply do:

```bash
curl http://cont3
```

because `cont3`'s name isn't necessarily resolvable from `mynet`.

You may instead need to use the container's IP:

```bash
curl http://<cont3-IP>
```

### The big picture

These commands are demonstrating this:

```text
                mynet
        ┌───────────────────┐
        │                   │
     cont1                cont2
        │                   │
        └─────── DNS ───────┘
             cont2 → IP

     cont1 can do:
     curl http://cont2
```

The **custom Podman network** gives containers a way to communicate and provides DNS-based container-name resolution.

So the main lesson is:

> **Same custom network → you can generally use the container name.**  
> **Different networks → container-name DNS resolution may not work; you may need another networking setup or an IP/address that is reachable from both networks.**


-------------
this command is the basic syntax for **publishing a container's port to your host machine**:

```bash
podman run -p <host-ip>:<host-port>:<container-port> <image-name>
```

For example:

```bash
podman run -p 127.0.0.1:8080:8080 my-app
```

It means:

* `127.0.0.1` → the **host IP** (your Fedora machine)
* first `8080` → the **host port**
* second `8080` → the **container port**
* `my-app` → the **image name**, not usually the container name

### Important correction

The syntax you wrote says:

```bash
podman run -p host-ip:host-port:container-port <container-name>
```

But `podman run` normally creates a **new container from an image**, so the last argument should be an **image name**:

```bash
podman run -p 127.0.0.1:8080:8080 my-image
```

-----------------------------

This command gets the **IP address of a specific container inside a specific Podman network**.

The general form is:

```bash
podman inspect <container-name> -f '{{.NetworkSettings.Networks.<network-name>.IPAddress}}'
```

### Example from your project

Suppose you have:

- Container: `auth-service`
    
- Network: `eventhub-net`
    

First, you can see your containers:

```bash
podman ps
```

You might see:

```text
CONTAINER ID  NAMES
abc123        auth-service
def456        mysql
```

And your network:

```bash
podman network ls
```

might show:

```text
NETWORK ID    NAME
123456        eventhub-net
```

Then run:

```bash
podman inspect auth-service -f '{{.NetworkSettings.Networks.eventhub-net.IPAddress}}'
```

You might get:

```text
10.89.0.5
```

That means **inside `eventhub-net`**, the `auth-service` container has IP `10.89.0.5`.

--------------------
This section is explaining **container image layers vs. the container's writable layer**. The key idea is:

> **An image is mostly read-only and reusable; a running container gets a temporary writable layer on top of it.**

Let's break it down.

### 1. Images are immutable and layered

Suppose your `Containerfile` has:

```dockerfile
FROM python:3.12
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
```

Podman doesn't store this as one giant file. The image is built from **layers**:

```text
Python image
    ↓
Layer: COPY requirements.txt
    ↓
Layer: pip install
    ↓
Layer: COPY application
```

Those image layers are **read-only / immutable**.

So if you start two containers from the same image:

```text
             eventhub-booking image
                    │
             ┌──────┴──────┐
             ↓             ↓
       Container A    Container B
       writable       writable
       layer          layer
```

Both containers share the same underlying image layers.

---

### 2. What happens when you run a container?

When you do:

```bash
podman run eventhub-booking
```

Podman takes the image and adds a **new writable layer** on top:

```text
┌──────────────────────────┐
│ Container writable layer │ ← changes made by this container
├──────────────────────────┤
│ Application image layer  │ ← read-only
├──────────────────────────┤
│ Python base image        │ ← read-only
└──────────────────────────┘
```

If your application creates:

```text
/tmp/test.txt
```

that file goes into the container's writable layer.

---

### 3. Why is it called ephemeral?

Because the writable layer belongs to that **particular container**.

For example:

```bash
podman run --name test-container alpine
```

Inside it:

```bash
echo "hello" > /test.txt
```

Now:

```text
test-container
    └── /test.txt
```

If you remove the container:

```bash
podman rm test-container
```

the writable layer is removed too.

So `/test.txt` disappears.

If you create another container from the same image:

```bash
podman run --name another-container alpine
```

it **doesn't have `/test.txt`**.

That's what the paragraph means by:

> each container's runtime data are isolated from other containers.

---

### 4. But what about databases?

This is where **volumes** become important.

You don't want your MySQL data to disappear every time you delete the MySQL container.

So instead of:

```text
MySQL container
    ↓
writable layer
    ↓
database files
```

you use:

```text
MySQL container
    ↓
/var/lib/mysql
    ↓
Podman volume
    ↓
mysql-data
```

For example:

```bash
podman volume create mysql-data
```

Then:

```bash
podman run \
  --name mysql \
  -v mysql-data:/var/lib/mysql \
  mysql:8.0
```

Now the important database files are stored in the **volume**, not the container's temporary writable layer.

You can delete the container:

```bash
podman rm mysql
```

and the volume remains:

```text
mysql-data
    ↓
database files still exist
```

Then create another MySQL container using the same volume:

```bash
podman run \
  --name mysql-new \
  -v mysql-data:/var/lib/mysql \
  mysql:8.0
```

and your database data is still there.

**Container = disposable. Volume = persistent. Image = reusable template.**

---

### Why `-it` is usually together

`-i` alone doesn't give you a nice terminal.

`-t` gives you the terminal interface.

So:

```
podman run -it alpine
```

means:

```
-i  → keep listening to my keyboard
-t  → give me a terminal to interact through
```

Then you get:

```
/ #
```

-----------
