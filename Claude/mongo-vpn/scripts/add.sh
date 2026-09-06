#!/usr/bin/env bash
# Install the VPN-bypass route(s) for this project's cluster.
# Run with the VPN ON (it uses the physical gateway cached by derive.sh, so it
# does not matter that the tunnel is up). Uses sudo. Usage: add.sh [project_dir]
set -euo pipefail
cd "$(dirname "$0")"; . ./lib.sh

project_dir="$(cd "${1:-$PWD}" && pwd)"
state="$project_dir/.mongo-vpn-route"
if [[ ! -f "$state" ]]; then
  echo "FAIL: no $state — run derive.sh (with the VPN OFF) first."; exit 2
fi
# shellcheck disable=SC1090
. "$state"
: "${RANGES:?no RANGES in state file}"; : "${GATEWAY:?no GATEWAY}"; : "${IFACE:?no IFACE}"

echo "Installing route(s) for: $RANGES"
echo "  via physical gateway $GATEWAY ($IFACE)"

for range in $RANGES; do
  net="${range%/*}"
  # Replace any stale route for this network so a moved cluster or old value
  # cannot leave a wrong route in place.
  if netstat -rn | grep -qE "^${net%.*}\.[0-9]+/24|^${net%.*}/24"; then
    sudo route delete -net "$range" >/dev/null 2>&1 || true
  fi
  sudo route add -net "$range" "$GATEWAY" -ifp "$IFACE"
done

echo
echo "Routes now installed for these ranges:"
for range in $RANGES; do
  net3="$(echo "${range%/*}" | awk -F. '{print $1"."$2"."$3}')"
  netstat -rn | grep -E "$net3" | awk '{printf "  %-18s via %-14s %s\n",$1,$2,$NF}' || echo "  (missing — add failed for $range)"
done
echo
echo "Verify with:  scripts/check.sh \"$project_dir\""
