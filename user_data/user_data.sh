
#!/bin/bash
set -euxo pipefail
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

dnf update -y
dnf install -y python3-pip
python3 -m pip install --no-input flask pymysql boto3

mkdir -p /opt/rdsapp

cat >/opt/rdsapp/app.py <<'PY'
import json
import os
import boto3
import pymysql
from flask import Flask, request, make_response
import logging
from logging.handlers import RotatingFileHandler
from datetime import datetime, timezone
import uuid

REGION = os.environ.get("AWS_REGION", "us-east-1")
SECRET_ID = os.environ.get("SECRET_ID", "lab3/rds/mysql")

secrets = boto3.client("secretsmanager", region_name=REGION)

def get_db_creds():
    resp = secrets.get_secret_value(SecretId=SECRET_ID)
    return json.loads(resp["SecretString"])

def get_conn():
    c = get_db_creds()
    return pymysql.connect(
        host=c["host"],
        user=c["username"],
        password=c["password"],
        port=int(c.get("port", 3306)),
        database="lab3db",
        autocommit=True,
    )

app = Flask(__name__)

def utc_now_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

@app.get("/api/public-feed")
def public_feed():
    # This should change on *every* origin request:
    server_time_utc = utc_now_iso()
    origin_request_id = str(uuid.uuid4())

    # “Message of the minute” changes each minute (nice human-visible signal)
    minute_key = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%MZ")
    message = f"hello from minute {minute_key}"

    body = {
        "server_time_utc": server_time_utc,          # changes every origin hit
        "origin_request_id": origin_request_id,      # changes every origin hit
        "message_of_the_minute": message             # changes each minute
    }

    resp = make_response(jsonify(body), 200)

    # Shared cache TTL: CloudFront uses s-maxage for shared caches (CDN)
    # Browser TTL: max-age=0 prevents browser caching (viewer side)
    resp.headers["Cache-Control"] = "public, s-maxage=30, max-age=0"

    # Extra app-visible evidence (also appears in cached responses)
    resp.headers["X-Origin-Generated-At"] = server_time_utc
    return resp
    
@app.get("/api/list")
def private_list():
    # Simulate user-specific/dynamic content
    body = {
        "server_time_utc": utc_now_iso(),
        "note": "this endpoint must never be cached by shared caches"
    }

    resp = make_response(jsonify(body), 200)

    # Never cache in shared caches; prevents user mixups / stale reads
    resp.headers["Cache-Control"] = "private, no-store"
    return resp

@app.route("/")
def home():
    return """
    <h2>EC2 → RDS Notes App</h2>
    <p>POST /add?note=hello</p>
    <p>GET /list</p>
    """

@app.route("/init")
def init_db():
    c = get_db_creds()
    conn = pymysql.connect(
        host=c["host"], user=c["username"], password=c["password"],
        port=int(c.get("port", 3306)), autocommit=True
    )
    cur = conn.cursor()
    cur.execute("CREATE DATABASE IF NOT EXISTS lab3db;")
    cur.execute("USE lab3db;")
    cur.execute("""
        CREATE TABLE IF NOT EXISTS notes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            note VARCHAR(255) NOT NULL
        );
    """)
    cur.close()
    conn.close()
    return "Initialized lab3db + notes table."

@app.route("/add", methods=["POST", "GET"])
def add_note():
    note = request.args.get("note", "").strip()
    if not note:
        return "Missing note param. Try: /add?note=hello", 400
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("INSERT INTO notes(note) VALUES(%s);", (note,))
    cur.close()
    conn.close()
    return f"Inserted note: {note}"

@app.route("/list")
def list_notes():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT id, note FROM notes ORDER BY id DESC;")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return "<h3>Notes</h3><ul>" + "".join([f"<li>{r[0]}: {r[1]}</li>" for r in rows]) + "</ul>"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
PY

cat >/etc/systemd/system/rdsapp.service <<'SERVICE'
[Unit]
Description=EC2 to RDS Notes App
After=network.target

[Service]
WorkingDirectory=/opt/rdsapp
Environment=SECRET_ID=lab3/rds/mysql
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now rdsapp
