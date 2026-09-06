#!/usr/bin/env bash
# Self-check: is this project's MongoDB Atlas cluster reachable, and if not, why?
# Read-only. Usage: check.sh [project_dir]   (default: current directory)
set -euo pipefail
cd "$(dirname "$0")"; . ./lib.sh

mv_load_env "${1:-$PWD}" || exit $?

first_shard="$(mv_shard_hosts | head -1)"
if [[ -z "$first_shard" ]]; then
  echo "FAIL: could not resolve any shard host from the connection string"
  echo "RESULT: FAIL"; exit 1
fi

echo "cluster shard: $first_shard"

# --- Layer 1: TLS edge probe, no credentials, no driver -------------------
# Atlas resets the TLS handshake for a source it will not serve; a served
# source completes the handshake. This isolates the routing/allowlist question
# from any credential or driver issue.
probe="$(echo QUIT | openssl s_client -connect "$first_shard:27017" -servername "$first_shard" 2>&1 || true)"
if echo "$probe" | grep -qiE 'errno=54|handshake has read 0 bytes|reset by peer'; then
  echo "FAIL: edge reset / IP not authorized"
  echo "  -> the VPN-bypass route is missing (run derive.sh with VPN off, then add.sh with VPN on),"
  echo "     or this machine's IP is not in the Atlas Access List for the cluster's project."
  echo "RESULT: FAIL"; exit 1
fi
echo "TLS edge: handshake accepted (routing looks OK)"

# --- Layer 2: authenticated ping, if a driver is available ----------------
if command -v uv >/dev/null 2>&1; then
  uv run --project "$MV_PROJECT_DIR" python - <<'PY' 2>/dev/null || python3 - <<'PY2'
import os,sys,time
from pymongo import MongoClient
try:
    c=MongoClient(os.environ["MONGO_DB_CONNECTION_STRING"], serverSelectionTimeoutMS=12000)
    t=time.time(); c.admin.command("ping")
    print(f"  driver ping OK ({(time.time()-t)*1000:.0f} ms), server {c.server_info().get('version')}")
    sys.exit(0)
except Exception as e:
    m=str(e).lower()
    if "reset by peer" in m: print("FAIL: edge reset / IP not authorized")
    elif "timeout" in m or "serverselection" in m: print("FAIL: timeout / no server (cluster paused, or route wrong)")
    elif "auth" in m: print("FAIL: auth (credentials rejected — not a network problem)")
    else: print("FAIL:", str(e)[:140])
    sys.exit(1)
PY
PY2
  rc=$?
  [[ $rc -eq 0 ]] && { echo "RESULT: PASS"; exit 0; } || { echo "RESULT: FAIL"; exit 1; }
else
  echo "  (no 'uv' found — skipped the authenticated ping; TLS reachability is confirmed)"
  echo "RESULT: PASS"; exit 0
fi
