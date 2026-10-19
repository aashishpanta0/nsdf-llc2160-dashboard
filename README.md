# NSDF NASA LLC2160 Dashboard

Interactive dashboard for the NASA DYAMOND LLC2160 ocean simulation (salinity,
temperature, and u/v/w velocity), streamed with
[OpenVisus](https://github.com/sci-visus/OpenVisus).

The dashboard is published as a Docker image. Everything below runs that image;
you do not need to clone this repository or install Python.

| | |
| --- | --- |
| Image | `ghcr.io/aashishpanta0/nsdf-llc2160-dashboard` ([package page](https://github.com/aashishpanta0/nsdf-llc2160-dashboard/pkgs/container/nsdf-llc2160-dashboard)) |
| Tags | `latest` (newest build of `main`) and `X.Y.Z` (one per build of `main`; each stays fixed) |
| Platform | `linux/amd64` (runs under emulation on Apple Silicon and other ARM hosts) |
| Port | `11957` |
| Dashboard URL | `http://<host>:11957/nasa-llc2160` |

## Run with Docker

You need [Docker](https://docs.docker.com/get-docker/).

```bash
mkdir -p visus_cache_can_be_erased && chmod 1777 visus_cache_can_be_erased
docker run -d --name nasa-llc2160 -p 11957:11957 \
  -v "$PWD/visus_cache_can_be_erased:/var/cache/visus" \
  ghcr.io/aashishpanta0/nsdf-llc2160-dashboard:latest --cached
```

Open <http://localhost:11957/nasa-llc2160>. The first load can take a minute while
data is fetched. Stop and remove it with `docker rm -f nasa-llc2160`.

`--cached` keeps the data it reads in `./visus_cache_can_be_erased`, so it loads
faster next time; delete that folder whenever you like. To read everything from
the server instead, leave out both the `-v` line and `--cached` (see
[Caching](#caching)).

## Defaults and how to change them

The image saves a default for everything, so it runs with no arguments. Pass
only what you want to change; everything else keeps its default.

| Setting | Default | Change it with |
| --- | --- | --- |
| Address | `0.0.0.0` | `--address <ip>`, or `-e ADDRESS=<ip>` |
| Port | `11957` | `--port <port>`, or `-e PORT=<port>` |
| Dataset | `/opt/openvisuspy/json/nasa.json` (the five LLC2160 fields) | `--args <dataset>`, the dataset as the first argument, or `-e DATASET=<dataset>` |
| Caching | off | `--cached` to turn it on (`--no-cached` turns it off), or `-e CACHED=true` |

Arguments go after the image name. For example, to serve on port 9000 (publish
the same port with `-p`):

```bash
docker run -d --name nasa-llc2160 -p 9000:9000 ghcr.io/aashishpanta0/nsdf-llc2160-dashboard:latest --port 9000
```

A dataset can be an OpenVisus `.idx` URL or path, or a JSON scene list. For local
files, mount their directory at `/data`:

```bash
docker run -d --name nasa-llc2160 -p 11957:11957 \
  -v /path/to/datasets:/data:ro \
  ghcr.io/aashishpanta0/nsdf-llc2160-dashboard:latest \
  --args /data/my-dataset/visus.idx
```

### Caching

Caching is off by default: every view is read from the remote server. With
`--cached`, the dashboard adds `cached=arco` to each remote `.idx` URL, so
OpenVisus saves the blocks it reads under `/var/cache/visus` and reads them
from there the next time. Local paths are never cached. To keep the cache on
your machine, mount a folder there; you can delete it at any time:

```bash
mkdir -p visus_cache_can_be_erased && chmod 1777 visus_cache_can_be_erased
docker run -d --name nasa-llc2160 -p 11957:11957 \
  -v "$PWD/visus_cache_can_be_erased:/var/cache/visus" \
  ghcr.io/aashishpanta0/nsdf-llc2160-dashboard:latest --cached
```

The `chmod` matters on Linux: the container runs as UID 10001, and a folder
that Docker creates for you is owned by root and cannot be written.

The folder and the container share the same files, and they stay after the
container is removed, so the next run reuses them. To clear the cache, stop the
dashboard and delete the folder:

```bash
docker rm -f nasa-llc2160
rm -rf visus_cache_can_be_erased   # on Linux: sudo rm -rf visus_cache_can_be_erased
```

On Linux the cached files belong to UID 10001, which is why `sudo` may be
needed. Create the folder again (the `mkdir` and `chmod` above) before the next
cached run.

Any other [`panel serve` option](https://panel.holoviz.org/how_to/server/commandline.html)
is passed through, e.g. `--num-procs 4` or `--prefix /nasa-llc2160`.

| Environment variable | Default | Meaning |
| --- | --- | --- |
| `BOKEH_ALLOW_WS_ORIGIN` | `*` | Host names browsers may use to reach the dashboard, comma-separated. Set it to your public host name in production |
| `CACHED` | `false` | Whether remote `.idx` datasets are cached (see [Caching](#caching)). `--cached` and `--no-cached` set it |
| `VISUS_CACHE` | `/var/cache/visus` | Where OpenVisus keeps the cache. Mount a folder or volume there to keep it across restarts |

## Run with Docker Compose

Save this as `docker-compose.yml`, then run `docker compose up -d`. It turns
caching on and keeps the cache in `./visus_cache_can_be_erased`:

```yaml
# NSDF NASA LLC2160 Dashboard: run `docker compose up -d`, then open http://localhost:11957/nasa-llc2160
services:
  nasa-llc2160:
    image: ghcr.io/aashishpanta0/nsdf-llc2160-dashboard:latest
    platform: linux/amd64
    restart: unless-stopped
    ports:
      - "11957:11957"
    # Defaults are saved in the image. Remove "--cached" to read everything
    # from the server; to change the dataset, add e.g. "--args", "/data/my-dataset/visus.idx"
    command: ["--cached"]
    volumes:
      # The cache, on the host; safe to delete at any time.
      - ./visus_cache_can_be_erased:/var/cache/visus
```

On Linux, create the folder first with
`mkdir -p visus_cache_can_be_erased && chmod 1777 visus_cache_can_be_erased`
(see [Caching](#caching)). In a clone of this repository, `make up` does that and
starts the repository's `docker-compose.yml` (on port 8080); `make clean-cache`
deletes the cache.

## Run on Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nasa-llc2160
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nasa-llc2160
  template:
    metadata:
      labels:
        app: nasa-llc2160
    spec:
      containers:
        - name: nasa-llc2160
          image: ghcr.io/aashishpanta0/nsdf-llc2160-dashboard:latest
          # Defaults are saved in the image; override any of them with args, e.g.
          # args: ["--port", "11957", "--args", "/data/my-dataset/visus.idx"]
          ports:
            - containerPort: 11957
---
apiVersion: v1
kind: Service
metadata:
  name: nasa-llc2160
spec:
  selector:
    app: nasa-llc2160
  ports:
    - port: 11957
      targetPort: 11957
```

- Route your Ingress path `/nasa-llc2160` to the Service. The page also loads its
  JavaScript from `/static/`, so route that too, or start the dashboard with
  `--prefix /<path>` and route only that prefix. The ingress controller must
  allow WebSocket upgrades.
- Keep `replicas: 1`, or enable session affinity: each browser session lives in
  one pod.
- Add probes as you need, e.g. a `tcpSocket` probe on port `11957`.

## Update to the newest image

Docker keeps using the image already on your machine, so pull first:

```bash
docker pull ghcr.io/aashishpanta0/nsdf-llc2160-dashboard:latest
docker rm -f nasa-llc2160
```

Then run the same `docker run` command again. With Compose, run
`docker compose pull && docker compose up -d`. To stay on a fixed release instead
of `latest`, use one of the version tags on the [package page](https://github.com/aashishpanta0/nsdf-llc2160-dashboard/pkgs/container/nsdf-llc2160-dashboard).

## Troubleshooting

- **Nothing answers on the port**: the port in `-p` must match the port the
  dashboard listens on (`11957` unless you passed `--port`).
  `docker logs nasa-llc2160` shows it, e.g.
  `Bokeh app running at: http://0.0.0.0:11957/nasa-llc2160`.
- **Warning: `requested image's platform (linux/amd64) does not match`**:
  harmless on Apple Silicon and other ARM machines. OpenVisus has no Linux ARM
  build, so the image runs under emulation, which is slower. Add
  `--platform linux/amd64` to hide the warning. On ARM Linux without Docker
  Desktop, enable emulation once with
  `docker run --privileged --rm tonistiigi/binfmt --install amd64`.
- **Page loads but stays blank**: the browser's WebSocket connection is being
  refused. Behind a proxy or ingress, allow WebSocket upgrades and set
  `BOKEH_ALLOW_WS_ORIGIN` to the host name in the address bar.

## For maintainers

[`.github/workflows/docker.yml`](.github/workflows/docker.yml) builds the image,
starts it twice (with no arguments, and with only `--port`), loads the dashboard
page each time, and fails if the dashboard logs an error. Only then is the image
published:

| Event | Published tags |
| --- | --- |
| Push to `main` | `latest`, plus the next patch version (e.g. `1.0.3`), which is also pushed as the git tag `v1.0.3` |
| Push a `vX.Y.Z` tag | `X.Y.Z` |
| Pull request | none (build and test only) |

The first push to `main` publishes `1.0.0`. Each version tag stays on the image
it was built from; later pushes add new versions and move only `latest`. To
start a new minor or major version, push its tag yourself, and the following
pushes to `main` count up from it:

```bash
git tag v1.1.0
git push origin v1.1.0
```

To build and run it locally:

```bash
docker build --platform linux/amd64 -t nsdf-llc2160-dashboard .
docker run --rm -p 11957:11957 nsdf-llc2160-dashboard
```

The defaults live in the `ENV` block of the [`Dockerfile`](Dockerfile), and
[`docker-entrypoint.sh`](docker-entrypoint.sh) fills them in. The image runs this
repository's own copy of openvisuspy (from [sci-visus/openvisuspy](https://github.com/sci-visus/openvisuspy/tree/test_region_extraction), branch `test_region_extraction`); the dashboard itself is
in [`app/`](app). For notebooks, local Python installs, and other dashboards, see
[openvisuspy](https://github.com/sci-visus/openvisuspy).
