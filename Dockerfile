# NSDF LLC2160 Dashboard, served as "nasa-oceanic" (ghcr.io/aashishpanta0/nsdf-llc2160-dashboard).
# The address and port are not baked in; pass them at run time (see README.md):
#   docker run -p 11957:11957 <image> --address 0.0.0.0 --port 11957 --args <dataset>

# Build stage: install the Python dependencies into a virtualenv.
FROM python:3.12-slim-bookworm AS build

# OpenVisus ships Linux wheels for x86_64 only, so the image is linux/amd64.
# OpenVisusNoGui is OpenVisus without the Qt viewer, which the dashboard never uses.
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir --no-warn-script-location --only-binary=:all: \
        panel bokeh param numpy requests xmltodict colorcet \
        ipywidgets ipywidgets-bokeh ipykernel OpenVisusNoGui \
        boto3 \
    && /opt/venv/bin/pip uninstall -y pip

# Runtime stage: only the virtualenv and the dashboard code.
FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/opt/venv/bin:$PATH \
    PYTHONPATH=/opt/openvisuspy/src \
    BOKEH_ALLOW_WS_ORIGIN=* \
    VISUS_CACHE=/var/cache/visus

COPY --from=build /opt/venv /opt/venv
COPY src /opt/openvisuspy/src
COPY app /opt/openvisuspy/nasa-oceanic
COPY json /opt/openvisuspy/json

RUN python -c "import OpenVisus, openvisuspy" \
    && useradd --create-home --uid 10001 dashboard \
    && mkdir -p /var/cache/visus /data \
    && chown dashboard:dashboard /var/cache/visus /data

WORKDIR /opt/openvisuspy
USER dashboard

ENTRYPOINT ["python", "-m", "panel", "serve", "nasa-oceanic"]
CMD ["--args", "json/nasa.json"]
