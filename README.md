# NSDF LLC2160 Dashboard

Interactive dashboard for the NASA DYAMOND LLC2160 ocean simulation (salinity,
temperature, and u/v/w velocity), streamed with
[OpenVisus](https://github.com/sci-visus/OpenVisus).

The dashboard is published as a Docker image. Everything below runs that image;
you do not need to clone this repository or install Python.

| | |
| --- | --- |
| Image | `ghcr.io/aashishpanta0/nsdf-llc2160-dashboard` ([package page](https://github.com/aashishpanta0/nsdf-llc2160-dashboard/pkgs/container/nsdf-llc2160-dashboard)) |
| Tags | `latest` (newest build of `main`) and `X.Y.Z` (releases) |
| Platform | `linux/amd64` (runs under emulation on Apple Silicon and other ARM hosts) |
| Port | `11957`, passed at run time |
| Dashboard URL | `http://<host>:11957/nasa-oceanic` |

## Run with Docker

You need [Docker](https://docs.docker.com/get-docker/).

```bash
docker run -d --name nsdf-llc2160 -p 11957:11957 \
  ghcr.io/aashishpanta0/nsdf-llc2160-dashboard:latest \
  --address 0.0.0.0 --port 11957 --args json/nasa.json
```

Open <http://localhost:11957/nasa-oceanic>. The first load can take a minute while
data is fetched. Stop and remove it with `docker rm -f nsdf-llc2160`.

### How the container starts

The image runs `python -m panel serve nasa-oceanic`, and everything after the image
name is appended to that command. The image does not fix an address or port, so
pass them every time:

| Argument | Meaning |
| --- | --- |
| `--address 0.0.0.0` | Listen on all interfaces, so traffic from outside the container reaches the server |
| `--port 11957` | Port to listen on; publish the same one with `-p 11957:11957`. Without it, Panel uses `5006` |
| `--args <dataset>` | Dataset to open; must come last. With no arguments at all, the image opens `json/nasa.json`, the five LLC2160 fields |

Other [`panel serve` options](https://panel.holoviz.org/how_to/server/commandline.html)
go before `--args`, for example `--num-procs 4` or `--prefix /llc2160`.

| Environment variable | Default | Meaning |
| --- | --- | --- |
| `BOKEH_ALLOW_WS_ORIGIN` | `*` | Host names browsers may use to reach the dashboard, comma-separated. Set it to your public host name in production |
| `VISUS_CACHE` | `/var/cache/visus` | Where OpenVisus caches downloaded data. Mount a volume there to keep it across restarts |

## Run with Docker Compose

Save this as `docker-compose.yml` (the same file is in this repository), then run
`docker compose up -d`:

```yaml
# NSDF LLC2160 Dashboard: run `docker compose up -d`, then open http://localhost:11957/nasa-oceanic
services:
  llc2160:
    image: ghcr.io/aashishpanta0/nsdf-llc2160-dashboard:latest
    platform: linux/amd64
    restart: unless-stopped
    ports:
      - "11957:11957"
    command:
      - --address
      - "0.0.0.0"
      - --port
      - "11957"
      - --args
      - "json/nasa.json"
    volumes:
      - cache:/var/cache/visus

volumes:
  cache:
```

## Run on Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nasa-oceanic
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nasa-oceanic
  template:
    metadata:
      labels:
        app: nasa-oceanic
    spec:
      containers:
        - name: nasa-oceanic
          image: ghcr.io/aashishpanta0/nsdf-llc2160-dashboard:latest
          args:
            - --address
            - "0.0.0.0"
            - --port
            - "11957"
            - --args
            - "json/nasa.json"
          ports:
            - containerPort: 11957
---
apiVersion: v1
kind: Service
metadata:
  name: nasa-oceanic
spec:
  selector:
    app: nasa-oceanic
  ports:
    - port: 11957
      targetPort: 11957
```

- Route your Ingress path `/nasa-oceanic` to the Service. The page also loads its
  JavaScript from `/static/`, so route that too, or start the dashboard with
  `--prefix /<path>` and route only that prefix. The ingress controller must
  allow WebSocket upgrades.
- Keep `replicas: 1`, or enable session affinity: each browser session lives in
  one pod.
- Add probes as you need, e.g. a `tcpSocket` probe on port `11957`.

## Use your own dataset

Pass it after `--args`. For local files, mount their directory at `/data`:

```bash
docker run -d --name nsdf-llc2160 -p 11957:11957 \
  -v /path/to/datasets:/data:ro \
  ghcr.io/aashishpanta0/nsdf-llc2160-dashboard:latest \
  --address 0.0.0.0 --port 11957 --args /data/my-dataset/visus.idx
```

`--args` accepts an OpenVisus `.idx` URL or path, or a JSON scene list.

## Update to the newest image

Docker keeps using the image already on your machine, so pull first:

```bash
docker pull ghcr.io/aashishpanta0/nsdf-llc2160-dashboard:latest
docker rm -f nsdf-llc2160
```

Then run the same `docker run` command again. With Compose, run
`docker compose pull && docker compose up -d`. To stay on a fixed release instead
of `latest`, use one of the version tags on the [package page](https://github.com/aashishpanta0/nsdf-llc2160-dashboard/pkgs/container/nsdf-llc2160-dashboard).

## Troubleshooting

- **Nothing answers on port 11957**: pass `--address 0.0.0.0 --port 11957`
  and publish the same port with `-p`. `docker logs nsdf-llc2160` should show
  `Bokeh app running at: http://0.0.0.0:11957/nasa-oceanic`.
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
starts it with `--address 0.0.0.0 --port 5006` and the default dataset, loads
the dashboard page, and fails if the dashboard logs an error. Only then is the
image published:

| Event | Published tags |
| --- | --- |
| Push to `main` | `latest` |
| Push a `vX.Y.Z` tag | `X.Y.Z` |
| Pull request | none (build and test only) |

```bash
git tag v1.0.0
git push origin v1.0.0
```

To build and run it locally:

```bash
docker build --platform linux/amd64 -t nsdf-llc2160-dashboard .
docker run --rm -p 11957:11957 nsdf-llc2160-dashboard --address 0.0.0.0 --port 11957 --args json/nasa.json
```

The image runs this repository's own copy of openvisuspy (from [sci-visus/openvisuspy](https://github.com/sci-visus/openvisuspy/tree/test_region_extraction), branch `test_region_extraction`); the
dashboard itself is in [`app/`](app). For notebooks, local Python installs, and
other dashboards, see [openvisuspy](https://github.com/sci-visus/openvisuspy).
