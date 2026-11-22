"""Hello World web application served by gunicorn on EKS.

Serves "Hello, World!" on / and a JSON health check on /healthz.
The pod and node names come from the Kubernetes Downward API so you can
see which pod and node answered each request while HPA and the
Cluster Autoscaler scale the deployment.
"""
import os
import socket

from flask import Flask, jsonify

app = Flask(__name__)

POD_NAME = os.getenv("POD_NAME", socket.gethostname())
NODE_NAME = os.getenv("NODE_NAME", "local")
APP_VERSION = os.getenv("APP_VERSION", "dev")

PAGE = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Hello, World!</title>
  <style>
    body {{ font-family: system-ui, sans-serif; display: grid; place-items: center;
           min-height: 100vh; margin: 0; background: #0f172a; color: #e2e8f0; }}
    main {{ text-align: center; }}
    h1 {{ font-size: 3rem; margin-bottom: .5rem; }}
    p {{ color: #94a3b8; margin: .25rem 0; }}
  </style>
</head>
<body>
  <main>
    <h1>Hello, World!</h1>
    <p>pod: {pod}</p>
    <p>node: {node}</p>
    <p>version: {version}</p>
  </main>
</body>
</html>
"""


@app.get("/")
def index():
    return PAGE.format(pod=POD_NAME, node=NODE_NAME, version=APP_VERSION)


@app.get("/healthz")
def healthz():
    return jsonify(status="ok", pod=POD_NAME, node=NODE_NAME, version=APP_VERSION)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
