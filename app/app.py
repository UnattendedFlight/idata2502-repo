"""Starter app.

A small Flask app to build on. It is intentionally tiny - the interesting
work is the infrastructure around it, not the app itself.
"""
import json
import logging
import os
import uuid

import redis
from flask import Flask, g, jsonify, request

# Configuration comes from environment variables (twelve-factor style).
# Defaults let the app run standalone on your laptop without Redis.
REDIS_HOST = os.environ.get("REDIS_HOST", "localhost")
REDIS_PORT = int(os.environ.get("REDIS_PORT", "6379"))


def read_build():
    """read the env variables for build information, injected at build time"""
    keys = ("VERSION", "TYPE", "TIME", "COMMIT", "BRANCH", "DIRTY")
    # will not be set in developer environment, so use "debug" tto indicate
    # its a debug version running
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


@app.before_request
def assign_request_id():
    # Reuse the caller's correlation ID if present, otherwise create one.
    # This lets you follow one request across several services.
    g.request_id = request.headers.get("X-Request-ID", uuid.uuid4().hex[:8])


@app.after_request
def log_request(response):
    response.headers["X-Request-ID"] = g.request_id
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
        "<h1>Welcome to the starter app!</h1>"
        f"<p>{visits}</p>"
        f"<p><small>{BUILD['TYPE']} build: {BUILD['VERSION']} ({BUILD['COMMIT']}, {BUILD['TIME']})</small></p>"
    )


@app.route("/health")
def health():
    return jsonify(status="ok", build=BUILD)


@app.route("/hello/<name>")
def hello(name):
    return f"Hello, {name}!"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
