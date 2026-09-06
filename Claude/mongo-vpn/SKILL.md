---
name: mongo-vpn
description: Restore MongoDB Atlas access on a machine whose VPN blocks it, by adding a per-cluster static route that bypasses the tunnel. Use when a project's Mongo connection times out or fails the TLS handshake ("connection reset by peer") only while the VPN is connected, when setting up Atlas access on a new project or after a reboot, or when the user mentions a VPN blocking Mongo / a route workaround. Also covers enabling a cluster INSIDE an sbx sandbox (the ola task network) — bare-hostname allow rules plus a seedlist connection string — when a sandboxed task or ola run cannot reach Atlas.
version: 1.1.0
---

# MongoDB over VPN — the per-cluster route bypass

On this network the VPN swallows traffic to MongoDB Atlas: the tunnel does not
route to Atlas's IP blocks, so the driver either times out or the Atlas edge
resets the TLS handshake (`[Errno 54] Connection reset by peer`, `SSL handshake
has read 0 bytes`). TCP to port 27017 may still *appear* open — that is Atlas's
front door accepting the connection before the database refuses it — so a plain
port check is misleading.

The fix is a **static route** that sends traffic for the cluster's IP range out
the physical LAN interface instead of the VPN. Two facts make this fiddly, and
the whole skill exists to get them right:

1. **It is per-cluster.** Every Atlas cluster sits in its own `/24`, so a route
   added for one project's cluster does nothing for another's. A machine that
   already reaches one Mongo cluster over the VPN will still fail on a *new*
   cluster until that cluster's own range is added.
2. **The route must point at the *physical* gateway.** That gateway and
   interface can only be read reliably while the **VPN is off** — read them with
   the VPN up and you capture the tunnel's gateway and build a route that
   bypasses nothing.

Routes added this way are **not persistent**: a reboot wipes every one of them,
including any a previous project added. After a reboot, re-adding is a one-step
`add.sh` (the derived values are cached), not a full re-derive.

## The self-check first

Do not add a route blind. Start by asking what is actually wrong:

```
scripts/check.sh [project_dir]      # default: current directory
```

It reads the project's `.env` for `MONGO_DB_CONNECTION_STRING`, probes the
cluster, and prints one of:

- **`PASS`** — Mongo is reachable. Nothing to do. (If the user expected it to be
  broken, the VPN is probably off, or the route is already in.)
- **`FAIL: edge reset / IP not authorized`** — the routing bypass is missing or,
  less often, the Atlas IP Access List does not include this machine. This skill
  addresses the routing half; the allowlist half is an Atlas-UI action.
- **`FAIL: timeout / no server`** — no server answered: the cluster may be
  paused, or the route points the wrong way.
- **`FAIL: auth`** — reachable but the credentials in the connection string were
  rejected. Not a network problem; this skill cannot help.

Only a routing-shaped failure is this skill's job.

## The workflow

### 1. Derive the cluster's range — **VPN OFF**

```
# turn the VPN OFF first — this step refuses to run over a tunnel interface
scripts/derive.sh [project_dir]
```

It parses the connection string (both `mongodb+srv://` and plain `mongodb://`
forms), resolves the cluster's shard hosts to IPs, folds them into `/24`
range(s), captures the physical gateway and interface, and writes them to
`<project_dir>/.mongo-vpn-route` for the next step. It **aborts if the active
interface is a VPN tunnel** (`utun*`, `ppp*`) — that is the guard against
capturing the wrong gateway.

### 2. Add the route — **VPN ON**

```
# re-enable the VPN, then:
scripts/add.sh [project_dir]        # uses sudo; needs your password
```

It reads `.mongo-vpn-route`, removes any stale route for the same range, installs
the new one against the *physical* gateway captured in step 1, and prints the
resulting routing entries. Because it uses the cached physical gateway, it does
not matter that the VPN is up when it runs.

### 3. Verify — **VPN ON**

```
scripts/check.sh [project_dir]
```

Expect `PASS`. If it still fails with an edge reset, the cluster's IP range has
probably moved (Atlas does relocate clusters); re-run the derive step (VPN off)
to pick up the new range.

## After a reboot

Routes are ephemeral. To restore access for a project whose range was already
derived, just re-run step 2 (`add.sh`, VPN on) — no VPN-off derive needed,
because `.mongo-vpn-route` still holds the range and gateway. If several projects
need Mongo, run `add.sh` in each. A `launchd` login job can automate this; write
one only if the user asks.

## Inside an sbx sandbox (the ola task network)

The host route above fixes the **host**. An ola task runs in an **sbx sandbox** —
a separate network namespace with its own deny-by-default policy and a DNS
resolver that answers only `A`/`AAAA` (`SRV`/`TXT` → `NOTIMP`). A `mongodb+srv://`
connection therefore fails at construction, and even a plain `mongodb://` is
refused until the shard is allowlisted the right way. It is **not** structurally
impossible (a common misconception) — it needs two moves, and the host route
still has to be in place because the sandbox's egress leaves through the sbx
host-side proxy, which uses the host routing table.

The verified recipe (proved end-to-end with a live authenticated ping):

```
# 1. host route first, as above:
scripts/derive.sh <project_dir>     # VPN OFF (also caches the shard hostnames)
scripts/add.sh    <project_dir>     # VPN ON

# 2. enable the cluster inside the sandbox:
scripts/add-sandbox.sh   <project_dir> [sandbox_name]   # adds allow rules, prints seedlist URI
scripts/check-sandbox.sh <project_dir> [sandbox_name]   # probes from INSIDE the sandbox
```

`add-sandbox.sh` adds ONE **cluster-subdomain wildcard** allow rule
(`sbx policy allow network --sandbox <sb> "<sub>,*.<sub>"`, where `<sub>` is the
connection host minus its first label, e.g. `abc1234.mongodb.net`) and prints the
**seedlist** URI to use in-sandbox. Three mechanics from the `sbx` skill make this
work, and getting them wrong is why it looks impossible:

- **A bare-hostname / wildcard allow does double duty** — it unblocks the sandbox
  DNS `A` lookup *and* permits the raw TCP connect on :27017. No `/etc/hosts` pin
  and no IP tracking are needed.
- **A wildcard matches exactly ONE label**, so `*.mongodb.net` does NOT cover a
  shard host `ac-…-shard-00-00.abc1234.mongodb.net`, but `*.abc1234.mongodb.net`
  does. Allowing the **cluster subdomain** therefore covers all shards with one
  rule that **survives shard rotation** (only the leading `ac-…` label changes) —
  no re-derive needed for the policy.
- **Do not use a `:port` suffix or an `IP:port` rule.** When the driver sends SNI
  (Atlas M0 requires it for tenant routing), the proxy matches on the SNI
  *hostname*, so an IP:port or host:port rule never applies and the connect is
  denied. The rule must be the bare hostname/wildcard.
- **The app must use a seedlist URI**, not `mongodb+srv://` — `SRV`/`TXT` are UDP
  DNS, which sbx can never unblock. `add-sandbox.sh` emits the seedlist string
  (`mongodb://h1,h2,h3/?tls=true&authSource=admin…`); it works on the host too,
  so a project can adopt one string for both places.
- **In an ola run specifically**, the same effect comes for free by putting the
  cluster subdomain (`abc1234.mongodb.net`) — one line — in the agent folder's
  `allowlist.txt`; ola expands it to `<sub>,*.<sub>`. Still requires the seedlist.

Only the **seedlist** names individual shard hosts, so it is the one piece that
can go stale on a full relocation — refresh it with `derive.sh` (which re-caches
`SHARDS`) then rebuild. The wildcard allow rule does not. Credentials are never
cached: the seedlist URI is printed at apply time from the project `.env`, not
written to `.mongo-vpn-route`.

## Gotchas worth stating to the user

- **A working cluster and a broken cluster on the same machine is normal** — it
  just means only the first cluster's `/24` was ever routed. Not a regression.
- **`.mongo-vpn-route` is a cache, not a secret** — it holds IP ranges and the
  LAN gateway, no credentials. Safe to keep in the repo, but it is machine- and
  network-specific, so `.gitignore` it rather than commit it.
- **The Atlas IP Access List is a separate wall.** The route gets your packets to
  Atlas; the Access List decides whether Atlas answers. If `check.sh` reports an
  edge reset even with the route confirmed in `netstat -rn`, verify in the Atlas
  UI that this machine's public IP (or `0.0.0.0/0` for a test) is allowed on the
  *same project* that owns the cluster.

## Versioning

Semantic: **patch** for wording/robustness fixes that do not change the workflow,
**minor** for a new capability (e.g. a persistence job) or option, **major** if
the workflow or file contract changes. Bump the `version` and add a changelog
line on every edit.

### Changelog

- **1.1.0** — Add a **sandbox mode**: `add-sandbox.sh` / `check-sandbox.sh` and
  the `mv_seedlist_uri` + `mv_cluster_subdomain` helpers enable a cluster inside
  an sbx sandbox via a single rotation-proof cluster-subdomain wildcard allow rule
  (`<sub>,*.<sub>`) + a seedlist URI. Encodes the sbx mechanics (bare/wildcard
  hostname unblocks DNS *and* the raw connect; a wildcard matches one label so the
  cluster subdomain — not `*.mongodb.net` — covers the shards; `:port`/IP rules
  fail under SNI; SRV/TXT are permanently UDP-blocked; host route still required)
  and the ola `allowlist.txt` shortcut. Refutes the "sandbox structurally cannot
  reach Mongo" belief with a proven recipe. Also hardens `mv_load_env` to extract
  the connection string without `source`-ing `.env` (a seedlist value contains
  `&`, which bash `source` would choke on); seedlist values in `.env` are quoted.
- **1.0.0** — Initial version: self-checking `check.sh`, VPN-off `derive.sh`
  (with a tunnel-interface guard), VPN-on `add.sh` reading a cached
  `.mongo-vpn-route`. Encodes that the bypass is per-cluster and that routes are
  ephemeral across reboots.
