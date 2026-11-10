#!/usr/bin/env python3

import json
import re
import subprocess
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "gitops/generated"

result = subprocess.run(
    ["terraform", f"-chdir={ROOT / 'infra'}", "output", "-json"],
    check=True,
    capture_output=True,
    text=True,
)

data = json.loads(result.stdout)

def get(name):
    return str(data[name]["value"])

mq = urlsplit(get("rabbitmq_endpoint"))

if not mq.hostname or not mq.port:
    raise ValueError("Invalid RabbitMQ endpoint")

variables = {
    "RDS_SECRET_ARN": get("rds_secret_arn"),
    "RDS_ENDPOINT": get("rds_endpoint"),
    "RDS_DATABASE_NAME": get("rds_database_name"),
    "RABBITMQ_HOST_PORT": f"{mq.hostname}:{mq.port}",
    "VALKEY_ENDPOINT": get("valkey_endpoint"),
    "VALKEY_PORT": get("valkey_port"),
    "S3_BUCKET_NAME": get("s3_bucket_name"),
}

templates = {
    "kubernetes/external-secrets/externalsecret.yaml": "externalsecret.yaml",
    "kubernetes/external-secrets/plane-url.yaml": "plane-url.yaml",
    "helm/values/plane.yaml": "plane-values.yaml",
}

rendered = {}

for source, destination in templates.items():
    content = (ROOT / source).read_text()

    for key, value in variables.items():
        content = content.replace("${" + key + "}", value)

    unresolved = re.findall(r"\$\{[^}]+\}", content)

    if unresolved:
        raise ValueError(
            f"Unresolved placeholders in {source}: {unresolved}"
        )

    rendered[destination] = content

OUTPUT.mkdir(parents=True, exist_ok=True)

for name, content in rendered.items():
    (OUTPUT / name).write_text(content)
    print(f"Generated: gitops/generated/{name}")

print("Configuration generation completed.")
