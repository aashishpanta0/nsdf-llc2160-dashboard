# NSDF LLC2160 Dashboard (ghcr.io/aashishpanta0/nsdf-llc2160-dashboard).
# Runtime defaults are the ENV values below; README.md documents how to run it.

FROM python:3.12-slim-bookworm AS builder

# OpenVisus publishes Linux wheels for x86_64 only, so the image is linux/amd64.
RUN python -m venv /opt/venv \
    && /opt/venv/bin/python -m pip install --no-cache-dir --no-warn-script-location --only-binary=:all: \
        bokeh panel ipywidgets OpenVisus ipywidgets_bokeh ipykernel \
        boto3 xmltodict aiohttp colorcet \
    && /opt/venv/bin/python -m pip uninstall -y pip

FROM python:3.12-slim-bookworm

# Shared libraries the OpenVisus wheel links against.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libgl1 libglu1-mesa libglib2.0-0 libgomp1 libxrender1 libxext6 libsm6 \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/opt/venv/bin:$PATH \
    PYTHONPATH=/opt/dashboard/src \
    VISUS_CACHE=/var/cache/visus \
    DASHBOARD_APP=/opt/dashboard/llc2160 \
    DATASET="/opt/dashboard/json/nasa.json" \
    PORT=8080 \
    BOKEH_ALLOW_WS_ORIGIN=*

COPY --from=builder /opt/venv /opt/venv
COPY src /opt/dashboard/src
COPY app /opt/dashboard/llc2160
COPY json /opt/dashboard/json
COPY --chmod=0755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Fail the build early if the dashboard cannot be imported.
RUN python -c "import OpenVisus, openvisuspy, panel" \
    && test -f "$DASHBOARD_APP/main.py" \
    && useradd --create-home --uid 10001 dashboard \
    && mkdir -p /var/cache/visus /data \
    && chown dashboard:dashboard /var/cache/visus

WORKDIR /opt/dashboard
USER dashboard
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD python -c "import os, urllib.request; urllib.request.urlopen('http://127.0.0.1:%s/liveness' % os.environ['PORT'], timeout=4)"

ENTRYPOINT ["docker-entrypoint.sh"]
