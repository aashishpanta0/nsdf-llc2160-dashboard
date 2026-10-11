# NSDF LLC2160 Dashboard

Docker packaging for the NASA LLC2160 oceanic dashboard, built on
[OpenVisus](https://github.com/sci-visus/OpenVisus) and
[openvisuspy](https://github.com/sci-visus/openvisuspy).

The image is published to `ghcr.io/aashishpanta0/nsdf-llc2160-dashboard`.

For local Python installation, notebooks, and other dashboards, see the original
[openvisuspy repository](https://github.com/sci-visus/openvisuspy).

## Run the published image

The image is public; no login is needed.

```sh
docker run --rm -p 11957:11957 ghcr.io/aashishpanta0/nsdf-llc2160-dashboard:latest \
    --address 0.0.0.0 --port 11957 --args json/nasa.json
```

Open <http://localhost:11957/nasa-oceanic>.

## Run with Docker Compose

```sh
cp .env.example .env           # then edit .env
docker compose up -d           # pull the published image
docker compose up --build -d   # or build from local source
```

Open <http://localhost:11957/nasa-oceanic>. Stop with `docker compose down`
(add `--volumes` to drop the cache).

To use a local dataset, place it under `./data` (mounted at `/data`) and set
`LLC2160_DATASET=/data/my-dataset/visus.idx` in `.env`.

## Build locally

```sh
docker build --platform linux/amd64 -t nsdf-llc2160-dashboard .
docker run --rm -p 11957:11957 nsdf-llc2160-dashboard \
    --address 0.0.0.0 --port 11957 --args <dataset>
```

## Publishing

`.github/workflows/docker.yml` builds and pushes the image:

| Trigger         | Tags published                             |
|-----------------|--------------------------------------------|
| Push to `main`  | `latest`, `sha-<commit>`                   |
| Push a `v*` tag | `<version>` (e.g. `1.0.0`), `sha-<commit>` |
| Pull request    | built only, not pushed                     |

Cut a release:

```sh
git tag v1.0.0
git push origin v1.0.0
```
