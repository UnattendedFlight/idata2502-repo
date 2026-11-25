"""Starter app.

A small Flask app to build on. It is intentionally tiny - the interesting
work is the infrastructure around it, not the app itself.
"""
import hmac
import json
import logging
import os
import pathlib
import subprocess
import time
import uuid

import redis
from flask import Flask, g, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

# Configuration comes from environment variables (twelve-factor style).
# Defaults let the app run standalone on your laptop without Redis.
REDIS_HOST = os.environ.get("REDIS_HOST", "localhost")
REDIS_PORT = int(os.environ.get("REDIS_PORT", "6379"))
# secret for admin endpoints, not set means disabled
API_KEY = os.environ.get("API_KEY")


def read_build():
    """read the env variables for build information, injected at build time"""
    keys = ("VERSION", "TYPE", "TIME", "COMMIT", "BRANCH", "DIRTY")
    # env not present would need the app to run the build_env script itself
    # only really relevant on local developement, but more useful than
    # ambiguous "debug" values for all build info fields
    script = pathlib.Path(__file__).resolve().parent.parent / "scripts/build_env.sh"
    if "BUILD_VERSION" not in os.environ and script.exists():
        out = subprocess.run([script], capture_output=True, text=True, check=False)
        for line in out.stdout.splitlines():
            key, _, value = line.partition("=")
            os.environ[key] = value
    # fall back to "debug" for values on local running instance if script not there
    return {k: os.environ.get(f"BUILD_{k}", "debug") for k in keys}

BUILD = read_build()

app = Flask(__name__)

# ignore attributes that log records carry normally, so any different keys
# are added to the output in the formatter as extra keys on a log record
RESERVED = set(logging.LogRecord("", 0, "", 0, "", (), None).__dict__) | {
    "message",
    "asctime",
    "taskName",
}

class JsonFormatter(logging.Formatter):
    """Emit each log record as one JSON line (structured logging)."""

    def format(self, record):
        entry = {
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%S%z"),
            "level": record.levelname,
            "message": record.getMessage(),
        }
        # kvs in "extra" passed at logger callsites to be added to the outgoing record
        entry.update(
            {k: v for k, v in record.__dict__.items() if k not in RESERVED}
        )
        return json.dumps(entry)


# Log to stdout - in a container, that is where logs are collected from.
handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
logger = logging.getLogger("starter-app")
logger.setLevel(logging.INFO)
logger.addHandler(handler)
# Silence Flask's built-in (non-JSON) per-request log lines.
logging.getLogger("werkzeug").setLevel(logging.WARNING)
# log build information on boot
logger.info("starting starter-app", extra={k.lower(): v for k, v in sorted(BUILD.items())})


def get_redis():
    """Return a Redis client, or None if Redis is unreachable."""
    try:
        client = redis.Redis(
            host=REDIS_HOST, port=REDIS_PORT, socket_connect_timeout=1
        )
        client.ping()
        return client
    except redis.exceptions.RedisError:
        return None


# --- metrics ---------------------------------------------------------------
# metrics app implementation by Claude (Anthropic) not really important for the portfolio, so didnt want to spend time on it.
# A counter only goes up; Prometheus turns it into a rate later. The labels
# are what let you ask "requests per second to /hello/<name> that returned 500".
REQUESTS = Counter(
    "http_requests_total",
    "HTTP requests handled",
    ["service", "method", "path", "status"],
)
# A histogram counts requests into duration buckets - that is how Grafana
# can draw the 95th percentile later.
LATENCY = Histogram(
    "http_request_duration_seconds",
    "Time spent handling a request",
    ["service", "method", "path"],
    buckets=(0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10),
)

# Nobody wants a log line and a counter tick for every Prometheus scrape.
QUIET_PATHS = ("/metrics", "/health")


@app.before_request
def assign_request_id():
    g.started = time.perf_counter()
    # Reuse the caller's correlation ID if present, otherwise create one.
    # This lets you follow one request across several services.
    g.request_id = request.headers.get("X-Request-ID", uuid.uuid4().hex[:8])


@app.after_request
def log_request(response):
    response.headers["X-Request-ID"] = g.request_id
    if request.path in QUIET_PATHS:
        return response
    # The route pattern (/hello/<name>), not the URL (/hello/Ada): labels
    # must have few distinct values, or Prometheus drowns in series.
    route = request.url_rule.rule if request.url_rule else "(unmatched)"
    duration = time.perf_counter() - g.started
    REQUESTS.labels("app", request.method, route, response.status_code).inc()
    LATENCY.labels("app", request.method, route).observe(duration)
    logger.info(
        "request handled",
        extra={
            "method": request.method,
            "path": request.path,
            "status": response.status_code,
            "request_id": g.request_id,
        },
    )
    return response


@app.route("/")
def index():
    client = get_redis()
    if client is None:
        visits = "Redis not connected - visit counter unavailable."
    else:
        visits = f"You are visitor number {client.incr('visits')}."
    return (
        "<h1>IDATA2502 app - deployed by CD</h1>"
        f"<p>{visits}</p>"
        f"<p><small>{BUILD['TYPE']} build: {BUILD['VERSION']} ({BUILD['COMMIT']}, {BUILD['TIME']})</small></p>"
    )


@app.route("/health")
def health():
    return jsonify(status="ok", build=BUILD)


@app.route("/metrics")
def metrics():
    # The text format Prometheus pulls - open it in a browser once.
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


@app.route("/reset", methods=["POST"])
def reset():
    given = request.headers.get("X-API-Key", "")
    if not API_KEY or not hmac.compare_digest(given, API_KEY):
        return jsonify(error="unauthorized"), 401
    client = get_redis()
    if client is None:
        return jsonify(error="redis unavailable"), 503
    client.set("visits", 0)
    return jsonify(status="reset")


@app.route("/hello/<name>")
def hello(name):
    return f"Hello, {name}!"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
