# simple-app

A minimal nginx web app for demonstrating deployments to Kubernetes.

- `/` — content page (headline, text, "what's new" list) — the bits you change to show updates
- `/version` — returns the current version (from the `VERSION` file)
- `/healthz` — health check used by Kubernetes probes

## Layout

```
simple-app/
├── VERSION                     # single source of truth for the version
├── app/                        # static site (edit these to change content)
│   ├── index.html
│   └── styles.css
├── nginx/default.conf          # nginx routing (/, /version, /healthz)
├── Dockerfile                  # builds the image, bakes in VERSION
├── k8s/                        # Kubernetes manifests (namespace simple-app)
│   ├── namespace.yaml
│   ├── deployment.yaml         # Helm-templated: image comes from Harness
│   ├── service.yaml
│   ├── values.yaml             # image: <+artifact.image>  (Harness expression)
│   └── ingress.yaml            # optional
└── kosli/                      # Kosli compliance config — see KOSLI-SETUP.md
```

CI/CD is **Harness**, not GitHub Actions — there is no `.github/workflows/` in this repo.
The image is pushed to Docker Hub as `docker.io/soniabou/simpleapp:<VERSION>`.

## Run locally

```bash
docker build --build-arg APP_VERSION=$(cat VERSION) -t simple-app:dev .
docker run --rm -p 8080:8080 simple-app:dev
# open http://localhost:8080  and  http://localhost:8080/version
```

## Deploy to Kubernetes

Normally Harness does this. To apply by hand, note that `k8s/deployment.yaml` is
Helm-templated (`image: {{ .Values.image }}`) and `k8s/values.yaml` holds a Harness
expression, so plain `kubectl apply` will not resolve the image — substitute it first, e.g.
`docker.io/soniabou/simpleapp:0.1.4`.

1. Set the image to the tag you want to run.
2. Apply:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/
kubectl -n simple-app rollout status deploy/simple-app
```

3. Check it:

```bash
kubectl -n simple-app port-forward svc/simple-app 8080:80
# http://localhost:8080  and  /version
```

## Showing a change (the demo loop)

Each visible change is one cycle:

1. Edit content in `app/` (or bump a feature).
2. Bump `VERSION` (e.g. `0.1.4` -> `0.1.5`).
3. Commit + push -> Harness builds `docker.io/soniabou/simpleapp:<VERSION>` and deploys it.
4. `kubectl -n simple-app rollout status deploy/simple-app` and refresh the page.

> **Always bump `VERSION`.** The tag is derived from it, so two commits at the same version
> re-push the same tag over a different digest. That breaks artifact provenance in Kosli —
> see [KOSLI-SETUP.md](KOSLI-SETUP.md) §10 gap 8.

> Note: the deployment uses `readOnlyRootFilesystem: true` with writable
> `emptyDir` mounts for `/tmp` and `/var/cache/nginx`. If your nginx variant
> needs another writable path, either add a mount or set
> `readOnlyRootFilesystem: false`.
