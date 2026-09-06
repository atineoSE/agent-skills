#!/usr/bin/env bash
# Enable this project's MongoDB Atlas cluster INSIDE an sbx sandbox.
# Adds ONE rotation-proof allow rule for the cluster-subdomain wildcard
# (<subdomain>,*.<subdomain>), which unblocks BOTH the sandbox's DNS A lookup and
# the raw TCP connect on :27017 for every shard — and survives Atlas relocation,
# since only the leading shard label changes. Then prints the seedlist URI the
# in-sandbox app must use (a mongodb+srv:// string cannot work in-sandbox — SRV is
# a UDP DNS query and UDP can never be unblocked).
#
# The sandbox's egress still leaves via the host-side sbx proxy, so the host
# VPN-bypass route must already be in place (derive.sh + add.sh). This step is
# the sandbox counterpart of add.sh, not a replacement for it.
#
# Usage: add-sandbox.sh [project_dir] [sandbox_name]
#   sandbox_name defaults to the basename of project_dir (override if the sbx
#   sandbox was created under a different name).
set -euo pipefail
cd "$(dirname "$0")"; . ./lib.sh

mv_load_env "${1:-$PWD}" || exit $?
sandbox="${2:-$(basename "$MV_PROJECT_DIR")}"

if ! command -v sbx >/dev/null 2>&1; then
  echo "FAIL: 'sbx' not found on PATH — this step runs on the host, not inside the sandbox."; exit 2
fi

# Cluster-subdomain wildcard (e.g. abc1234.mongodb.net,*.abc1234.mongodb.net): a
# bare-hostname/wildcard allow authorizes the sandbox DNS resolver to answer A for
# the shard hosts AND permits the raw TCP connect on :27017. A :27017 suffix or an
# IP rule does NOT work — with SNI present the proxy matches on the hostname. The
# wildcard covers every shard and survives Atlas relocation (only the leading
# shard label rotates), so no shard list or re-derive is needed for the rule.
sub="$(mv_cluster_subdomain)"
if [[ -z "$sub" || "$sub" != *.* ]]; then
  echo "FAIL: could not derive the cluster subdomain from the connection string ($sub)"; exit 1
fi
echo "Allowing '$sub,*.$sub' for sandbox '$sandbox' (covers all shards, rotation-proof)..."
if ! sbx policy allow network --sandbox "$sandbox" "$sub,*.$sub"; then
  echo "FAIL: 'sbx policy allow network --sandbox $sandbox ...' failed (is the sandbox name right?)."; exit 1
fi

echo
echo "Seedlist connection string for use INSIDE the sandbox (SRV bypassed):"
echo "  (set MONGO_DB_CONNECTION_STRING to this in the sandbox / project .env)"
echo
mv_seedlist_uri || { echo "FAIL: could not build seedlist URI"; exit 1; }
echo
echo "Verify with:  scripts/check-sandbox.sh \"$MV_PROJECT_DIR\" \"$sandbox\""
