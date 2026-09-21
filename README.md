# devops-eventhub-learning

A hands-on training project completed as part of **Red Hat OpenShift Development I: Introduction to Containers with Podman (DO188 - RHA)**, taken through the Faculty of Computers and Artificial Intelligence, Cairo University.

📜 **Certificate of Attendance:** [Verify on Credly](https://www.credly.com/badges/6dd43b42-9dd3-473f-b614-d97d61e84bc1)
Issued August 29, 2026 · 24 credit hours

## About the Course

This repository documents a 4-phase DevOps assignment that progressively containerizes and orchestrates an event booking application — from a plain, non-containerized app to a full OpenShift deployment.

## Project Phases

| Phase | Description | Reference |
|-------|-------------|-----------|
| **Phase 1** | Build the application to run without containers or Docker — a plain baseline setup | `event-booking-app/` |
| **Phase 2** | Containerize the application using **Podman** | [Complete Phase 2 containerization with Podman](https://github.com/OlaGhoneim/Devops-event-booking-system/commit/f94f5e08ee8306b18ee86542be18c41dbbae3a8) |
| **Phase 3** | Add **Docker Compose** orchestration for multi-service coordination | Add Docker Compose orchestration for Phase 3 |
| **Phase 4** | Deploy the application to **OpenShift** | [Deploy EventHub application to OpenShift](https://github.com/OlaGhoneim/Devops-event-booking-system/commit/0b77999ec4ed39e8da55e6e708a925b5f03c911b) |

## Repository Structure

```
Devops-event-booking-system/
├── event-booking-app/     # Application source code (Phase 1 baseline)
├── docs/
│   ├── notes/              # Course notes (Ch1-9)
│   ├── slides/              # Chapter slide decks
│   └── exercises/           # Chapter exercises
└── README.md
```

## Tech Stack

- **Containers:** Podman
- **Orchestration:** Docker Compose, OpenShift
- **Languages:** Python, JavaScript, Java, Go

## Author

**Ola Ghoneim** — CS Student, Faculty of Computers and Artificial Intelligence, Cairo University
