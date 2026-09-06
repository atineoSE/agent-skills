#!/usr/bin/env bash
# Derive the cluster's IP range(s) and the physical gateway/interface.
# MUST run with the VPN OFF. Writes <project_dir>/.mongo-vpn-route for add.sh.
# Usage: derive.sh [project_dir]
set -euo pipefail
cd "$(dirname "$0")"; . ./lib.sh

mv_load_env "${1:-$PWD}" || exit $?

# --- Guard: refuse to run over a VPN tunnel -------------------------------
# The whole point is to capture the PHYSICAL gateway. Read over a tunnel and we
# capture the VPN's gateway and build a route that bypasses nothing.
iface="$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')"
gateway="$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}')"
# Check the tunnel case FIRST: a VPN default route (utun*) often has no gateway
# line at all, so testing for a missing gateway before this would misreport an
# up tunnel as "no network".
case "$iface" in
  utun*|ppp*|ipsec*|tun*|tap*)
    echo "FAIL: the active interface ($iface) looks like a VPN tunnel."
    echo "  Turn the VPN OFF and re-run — this step must capture the physical gateway."
    exit 1;;
esac
if [[ -z "$iface" ]]; then
  echo "FAIL: no default route found — are you connected to any network?"; exit 1
fi
if [[ -z "$gateway" ]]; then
  echo "FAIL: default route on $iface has no gateway — cannot build a bypass route."; exit 1
fi
echo "physical gateway: $gateway via $iface"

# --- Resolve shard hosts -> IPs -> /24 ranges -----------------------------
shards="$(mv_shard_hosts)"
[[ -z "$shards" ]] && { echo "FAIL: could not resolve shard hosts (is the VPN really off?)"; exit 1; }

ranges=""
while read -r h; do
  [[ -z "$h" ]] && continue
  ip="$(mv_ip_of "$h")"
  if [[ -z "$ip" ]]; then echo "  war: no A record for $h"; continue; fi
  r="$(echo "$ip" | mv_slash24)"
  echo "  $h -> $ip  (${r})"
  ranges="$ranges $r"
done <<< "$shards"

ranges="$(echo "$ranges" | tr ' ' '\n' | sed '/^$/d' | sort -u | tr '\n' ' ' | sed 's/ *$//')"
[[ -z "$ranges" ]] && { echo "FAIL: resolved no IP ranges"; exit 1; }

# --- Persist for add.sh ---------------------------------------------------
{
  echo "# mongo-vpn derived values (VPN off). Machine/network-specific; do not commit."
  echo "RANGES=\"$ranges\""
  echo "GATEWAY=\"$gateway\""
  echo "IFACE=\"$iface\""
  echo "SHARDS=\"$(echo "$shards" | tr '\n' ' ' | sed 's/ *$//')\""
} > "$MV_STATE_FILE"

# Keep the cache out of version control.
if [[ -f "$MV_PROJECT_DIR/.gitignore" ]] && ! grep -qxF ".mongo-vpn-route" "$MV_PROJECT_DIR/.gitignore"; then
  echo ".mongo-vpn-route" >> "$MV_PROJECT_DIR/.gitignore"
fi

echo
echo "Wrote $MV_STATE_FILE:"
echo "  RANGES = $ranges"
echo "Next: re-enable the VPN, then run  scripts/add.sh \"$MV_PROJECT_DIR\""
