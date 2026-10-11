# NSDF LLC2160 Dashboard

Docker packaging for the NASA LLC2160 oceanic dashboard, built on
[OpenVisus](https://github.com/sci-visus/OpenVisus) and
[openvisuspy](https://github.com/sci-visus/openvisuspy).

Image: `ghcr.io/aashishpanta0/nsdf-llc2160-dashboard:latest` (public, no login needed).

For local Python installation, notebooks, and other dashboards, see the original
[openvisuspy repository](https://github.com/sci-visus/openvisuspy).

## Prerequisites

- [Docker Desktop](https://docs.docker.com/get-docker/) (macOS/Windows) or Docker
  Engine with the Compose plugin (Linux).
- Check it works:

  ```sh
  docker --version
  docker compose version
  ```

The image is `linux/amd64`. On Apple Silicon it runs under emulation, which is
slower but works.

## Option A: Docker Compose (recommended)

**1. Get the code**

```sh
git clone https://github.com/aashishpanta0/nsdf-llc2160-dashboard.git
cd nsdf-llc2160-dashboard
```

**2. Create your config**

```sh
cp .env.example .env
```

The defaults work as-is. Edit `.env` to change the port (`LLC2160_PORT`), the
dataset (`LLC2160_DATASET`), or to expose the dashboard on all interfaces
(`LLC2160_BIND_ADDRESS=0.0.0.0`).

**3. Pull the latest image**

```sh
docker compose pull
```

**4. Start the dashboard**

```sh
docker compose up -d
```

**5. Open it**

<http://localhost:11957/nasa-oceanic>

The first load can take a minute while data is fetched.

**6. Check logs (optional)**

```sh
docker compose logs -f
```

**7. Stop it**

```sh
docker compose down             # stop
docker compose down --volumes   # stop and clear the data cache
```

**Update to a newer version**

```sh
git pull
docker compose pull
docker compose up -d
```

## Option B: Docker only

**1. Pull the latest image**

```sh
docker pull --platform linux/amd64 ghcr.io/aashishpanta0/nsdf-llc2160-dashboard:latest
```

**2. Run it**

```sh
docker run --rm --name llc2160 --platform linux/amd64 -p 11957:11957 \
    ghcr.io/aashishpanta0/nsdf-llc2160-dashboard:latest \
    --address 0.0.0.0 --port 11957 --args json/nasa.json
```

**3. Open it**

<http://localhost:11957/nasa-oceanic>

**4. Stop it**

Press `Ctrl+C`, or from another terminal run `docker stop llc2160`.

## Using a local dataset

1. Put the dataset under `./data`, e.g. `./data/my-dataset/visus.idx`.
2. In `.env`, set `LLC2160_DATASET=/data/my-dataset/visus.idx`
   (`./data` is mounted read-only at `/data` inside the container).
3. Restart: `docker compose up -d`.

## Building from source

```sh
docker compose up --build -d
```

Or without Compose:

```sh
docker build --platform linux/amd64 -t nsdf-llc2160-dashboard .
docker run --rm --platform linux/amd64 -p 11957:11957 nsdf-llc2160-dashboard \
    --address 0.0.0.0 --port 11957 --args json/nasa.json
```

## Troubleshooting

- **Running an old version:** `docker compose up` and `docker run` reuse the image
  already on your machine. Run `docker compose pull` (or `docker pull ...:latest`)
  first to get the newest build.
- **`no matching manifest for linux/arm64/v8` (Apple Silicon Mac):** the image is
  `linux/amd64` only, because OpenVisus publishes no Linux ARM wheels. Add
  `--platform linux/amd64` to `docker pull`/`docker run` (Compose already sets it).
- **Port already in use:** change `LLC2160_PORT` in `.env`. With `docker run`,
  change both sides of `-p` and `--port` together, e.g. `-p 8080:8080 ... --port 8080`.
- **Blank page or WebSocket errors behind a proxy/hostname:** set
  `LLC2160_ALLOW_WS_ORIGIN` in `.env` to the hostname you browse to.

## Publishing (maintainers)

`.github/workflows/docker.yml` builds and pushes the image to GHCR:

| Trigger         | Tags published                             |
|-----------------|--------------------------------------------|
| Push to `main`  | `latest`                                   |
| Push a `v*` tag | `<version>` (e.g. `1.0.0`)                 |
| Pull request    | built only, not pushed                     |

To cut a release:

```sh
git tag v1.0.0
git push origin v1.0.0
```
