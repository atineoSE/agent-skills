#!/usr/bin/env bash
# Verify this project's MongoDB Atlas cluster is reachable FROM INSIDE the sbx
# sandbox. Read-only. Runs the probe with `sbx exec` so it tests the real task
# network namespace (deny-by-default), not the host.
#
# Usage: check-sandbox.sh [project_dir] [sandbox_name]
set -euo pipefail
cd "$(dirname "$0")"; . ./lib.sh

mv_load_env "${1:-$PWD}" || exit $?
sandbox="${2:-$(basename "$MV_PROJECT_DIR")}"

command -v sbx >/dev/null 2>&1 || { echo "FAIL: 'sbx' not found on PATH (run on the host)."; exit 2; }

first_shard="$(mv_shard_hosts | head -1)"
[[ -z "$first_shard" ]] && { echo "FAIL: could not resolve any shard host"; echo "RESULT: FAIL"; exit 1; }
echo "sandbox: $sandbox    cluster shard: $first_shard"

# TLS edge probe from inside the sandbox. Connect to the shard hostname (DNS is
# unblocked by the bare-hostname allow rule) with SNI (Atlas M0 routes by SNI).
# A completed handshake proves the raw wire-protocol path is carried; a 0-byte
# read is the failure the bug report saw before the allow rule existed.
probe="$(sbx exec "$sandbox" sh -c \
  "echo QUIT | openssl s_client -connect '$first_shard:27017' -servername '$first_shard' 2>&1" 2>&1 || true)"

if echo "$probe" | grep -qiE 'Verify return code: 0|subject=.*mongodb\.net'; then
  echo "TLS edge (in sandbox): handshake accepted — wire protocol is carried."
  echo "RESULT: PASS"; exit 0
fi

if echo "$probe" | grep -qiE 'handshake has read 0 bytes|No address associated|default deny|no applicable'; then
  echo "FAIL: connection blocked or DNS unresolved inside the sandbox."
  echo "  -> run scripts/add-sandbox.sh \"$MV_PROJECT_DIR\" \"$sandbox\" (adds the bare-hostname allow rules),"
  echo "     and make sure the host VPN-bypass route is in place (derive.sh + add.sh)."
  echo "RESULT: FAIL"; exit 1
fi

echo "FAIL: unexpected probe result:"; echo "$probe" | sed 's/^/  /' | head -8
echo "RESULT: FAIL"; exit 1
