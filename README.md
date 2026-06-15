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
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml            # optional
└── .github/workflows/ci.yaml   # build + push image to GHCR on push to main
```

## Run locally

```bash
docker build --build-arg APP_VERSION=$(cat VERSION) -t simple-app:dev .
docker run --rm -p 8080:8080 simple-app:dev
# open http://localhost:8080  and  http://localhost:8080/version
```

## Deploy to Kubernetes

1. In `k8s/deployment.yaml`, set the image to your repo (lowercase) and tag:
   `ghcr.io/<owner>/<repo>:0.1.0`
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
2. Bump `VERSION` (e.g. `0.1.0` -> `0.2.0`).
3. Commit + push -> CI builds `ghcr.io/<owner>/<repo>:<VERSION>`.
4. Update the tag in `k8s/deployment.yaml` to the new VERSION, commit, and:
   `kubectl apply -f k8s/deployment.yaml`
5. `kubectl -n simple-app rollout status deploy/simple-app` and refresh the page.

> Note: the deployment uses `readOnlyRootFilesystem: true` with writable
> `emptyDir` mounts for `/tmp` and `/var/cache/nginx`. If your nginx variant
> needs another writable path, either add a mount or set
> `readOnlyRootFilesystem: false`.
