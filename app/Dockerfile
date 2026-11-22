# syntax=docker/dockerfile:1

# ---- base: dependencies only -------------------------------------------
FROM python:3.12-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

# ---- test: runs the unit tests at build time ----------------------------
# Build with: docker build --target test .
# The build fails if any test fails.
FROM base AS test
COPY app.py .
COPY tests/ tests/
RUN python -m unittest discover -s tests -v

# ---- runtime: the image that ships ---------------------------------------
FROM base AS runtime
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION}
RUN useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin appuser
COPY app.py .
USER 10001
EXPOSE 8080
# --worker-tmp-dir /dev/shm lets the container run with a read-only root filesystem
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--threads", "2", \
     "--worker-tmp-dir", "/dev/shm", "--access-logfile", "-", "app:app"]
