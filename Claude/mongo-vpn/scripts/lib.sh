#!/usr/bin/env bash
# Shared helpers for the mongo-vpn skill. Sourced by check.sh / derive.sh / add.sh.

# Resolve the project directory (arg 1, or current dir) and read the connection
# string from its .env. We extract ONLY MONGO_DB_CONNECTION_STRING rather than
# `source` the whole file: a seedlist value contains '&'/'?' and bash `source`
# would treat '&' as a background operator and fail (and sourcing arbitrary .env
# is an unwanted side effect). Handles optional surrounding single/double quotes.
mv_load_env() {
  local dir="${1:-$PWD}"
  MV_PROJECT_DIR="$(cd "$dir" && pwd)"
  if [[ ! -f "$MV_PROJECT_DIR/.env" ]]; then
    echo "FAIL: no .env in $MV_PROJECT_DIR (need MONGO_DB_CONNECTION_STRING)"; return 2
  fi
  local v
  v="$(grep -E '^[[:space:]]*(export[[:space:]]+)?MONGO_DB_CONNECTION_STRING=' "$MV_PROJECT_DIR/.env" | tail -1)"
  v="${v#*=}"
  v="${v%$'\r'}"                       # strip a trailing CR (CRLF files)
  case "$v" in
    \"*\") v="${v#\"}"; v="${v%\"}";;   # strip surrounding double quotes
    \'*\') v="${v#\'}"; v="${v%\'}";;   # or single quotes
  esac
  MONGO_DB_CONNECTION_STRING="$v"; export MONGO_DB_CONNECTION_STRING
  if [[ -z "${MONGO_DB_CONNECTION_STRING:-}" ]]; then
    echo "FAIL: MONGO_DB_CONNECTION_STRING not set in $MV_PROJECT_DIR/.env"; return 2
  fi
  MV_STATE_FILE="$MV_PROJECT_DIR/.mongo-vpn-route"
}

# Parse the connection string into the host portion (between @ and the first / or ?).
# Sets MV_IS_SRV=1 for mongodb+srv://, and MV_HOSTPART to the host(:port)[,host...] list.
mv_parse_uri() {
  local uri="$MONGO_DB_CONNECTION_STRING"
  MV_IS_SRV=0
  [[ "$uri" == mongodb+srv://* ]] && MV_IS_SRV=1
  local rest="${uri#*://}"
  [[ "$rest" == *@* ]] && rest="${rest#*@}"   # drop credentials if present
  rest="${rest%%/*}"                          # drop path
  rest="${rest%%\?*}"                         # drop query
  MV_HOSTPART="$rest"
}

# Print the cluster's shard hostnames, one per line.
# SRV: look up _mongodb._tcp.<host>. Standard: split the comma list, strip :port.
mv_shard_hosts() {
  mv_parse_uri
  if [[ "$MV_IS_SRV" == 1 ]]; then
    dig +short SRV "_mongodb._tcp.${MV_HOSTPART}" | awk '{h=$4; sub(/\.$/,"",h); print h}'
  else
    echo "$MV_HOSTPART" | tr ',' '\n' | sed 's/:.*$//' | sed '/^$/d'
  fi
}

# Resolve a hostname to its first A record.
mv_ip_of() { dig +short "$1" | grep -E '^[0-9]+\.' | head -1; }

# Fold an IP into its /24 network.
mv_slash24() { awk -F. '{print $1"."$2"."$3".0/24"}'; }

# Build a seedlist mongodb:// URI from the connection string + shard hosts, for
# use INSIDE an sbx sandbox (where mongodb+srv:// cannot work — SRV is UDP DNS,
# which sbx can never unblock). Preserves the userinfo and query options, drops
# +srv, appends the shard seedlist, and ensures tls=true + authSource are set.
# Emits credentials inline on stdout — callers must NOT persist it to disk.
mv_seedlist_uri() {
  mv_parse_uri
  local uri="$MONGO_DB_CONNECTION_STRING" rest userinfo="" query=""
  rest="${uri#*://}"
  [[ "$rest" == *@* ]] && userinfo="${rest%%@*}@"   # user:pass@ (pass @ is %-encoded)
  [[ "$uri" == *\?* ]] && query="${uri#*\?}"
  local seed="" h
  while read -r h; do
    [[ -z "$h" ]] && continue
    seed="${seed:+$seed,}${h}:27017"
  done < <(mv_shard_hosts)
  [[ -z "$seed" ]] && return 1
  case "$query" in *tls=*|*ssl=*) ;; *) query="${query:+$query&}tls=true";; esac
  case "$query" in *authSource=*) ;; *) query="${query:+$query&}authSource=admin";; esac
  printf 'mongodb://%s%s/?%s\n' "$userinfo" "$seed" "$query"
}

# Print the Atlas cluster subdomain: the connection-string host with its first DNS
# label dropped. cluster0.abc1234.mongodb.net -> abc1234.mongodb.net, and a shard
# host ac-..-shard-00-00.abc1234.mongodb.net -> abc1234.mongodb.net too. Used to
# build the rotation-proof wildcard allow rule (*.<subdomain>) that covers every
# shard: an sbx wildcard matches exactly one label, and only the leading label
# rotates. Atlas-shaped (assumes <x>.<subdomain>.mongodb.net); not for arbitrary
# self-hosted hosts.
mv_cluster_subdomain() {
  mv_parse_uri
  local h="${MV_HOSTPART%%,*}"   # first host
  h="${h%%:*}"                   # drop :port
  echo "${h#*.}"                 # drop the first label
}
