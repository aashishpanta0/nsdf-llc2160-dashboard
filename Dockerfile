FROM python:3.12-slim-bookworm AS builder

RUN python -m venv /opt/venv \
    && /opt/venv/bin/python -m pip install --no-cache-dir --only-binary=OpenVisus \
        bokeh panel ipywidgets OpenVisus ipywidgets_bokeh ipykernel \
        boto3 xmltodict aiohttp colorcet

FROM python:3.12-slim-bookworm AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/opt/openvisuspy/src \
    PATH=/opt/venv/bin:$PATH \
    BOKEH_ALLOW_WS_ORIGIN=* \
    VISUS_CACHE=/var/cache/visus

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libgl1 libglu1-mesa libglib2.0-0 libgomp1 libxrender1 libxext6 libsm6 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/venv /opt/venv
COPY src /opt/openvisuspy/src
COPY json /opt/openvisuspy/json
COPY app /opt/openvisuspy/nasa-oceanic

RUN python -c "import OpenVisus; import openvisuspy"

RUN useradd --create-home --uid 10001 dashboard \
    && mkdir -p /var/cache/visus /data \
    && chown dashboard:dashboard /var/cache/visus /data

WORKDIR /opt/openvisuspy
USER dashboard

ENTRYPOINT ["python", "-m", "panel", "serve", "nasa-oceanic"]
CMD ["--args", "json/nasa.json"]
