# Phase 4 — Deployment to OpenShift

Part of the **DevOps Event Booking System** project (Red Hat DO188 training, Cairo University).

## Goal

Deploy the containerized **EventHub** application (built in Phases 2-3) to **OpenShift**, moving from local Podman/Docker Compose orchestration to a production-style cluster deployment.

## What Changed from Phase 3

- Application and services deployed as OpenShift resources (Deployments, Services, Routes) instead of running locally via Compose
- Image pushed to a container registry accessible by the OpenShift cluster
- External access exposed via an OpenShift **Route**

## Prerequisites

- Access to an OpenShift cluster (e.g. via `oc login`)
- `oc` CLI installed
- Built and pushed container image (from Phase 2) available in a registry

## Login to OpenShift

```bash
oc login --token=<TOKEN> --server=<CLUSTER_URL>
```

## Create/Select Project (Namespace)

```bash
oc new-project event-booking-app
```

## Deploy the Application

```bash
oc new-app <IMAGE_NAME>:<TAG>
```

Or, if using YAML manifests:

```bash
oc apply -f openshift/deployment.yaml
oc apply -f openshift/service.yaml
oc apply -f openshift/route.yaml
```

## Expose the Application

```bash
oc expose service <SERVICE_NAME>
```

## Verify Deployment

```bash
oc get pods
oc get svc
oc get routes
```

Once the route is created, the app will be accessible at the generated OpenShift route URL.

## Useful Commands

```bash
oc logs <POD_NAME>          # view pod logs
oc describe pod <POD_NAME>  # debug pod issues
oc delete project event-booking-app   # tear down when done
```

## Related Commit

[Deploy EventHub application to OpenShift](https://github.com/OlaGhoneim/Devops-event-booking-system/commit/0b77999ec4ed39e8da55e6e708a925b5f03c911b)
