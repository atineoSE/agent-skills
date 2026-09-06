#!/bin/bash
# Shared helpers for the time-machine skill.
# Every script here needs an UNSANDBOXED shell with Full Disk Access.

TM_VOL="${TM_VOL:-TM_MBA}"
TM_MNT="/Volumes/${TM_VOL}"

red()  { printf '\033[31m%s\033[0m\n' "$*"; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
ylw()  { printf '\033[33m%s\033[0m\n' "$*"; }
hdr()  { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }

# log show refuses to run sandboxed; tmutil/diskutil silently degrade.
require_env() {
  if ! /usr/bin/log show --last 1m --style compact >/dev/null 2>&1; then
    red "FATAL: 'log show' cannot run here (sandboxed?)."
    red "Run these scripts from a normal Terminal with Full Disk Access."
    exit 1
  fi
  if ! /usr/bin/find "$TM_MNT" -maxdepth 0 >/dev/null 2>&1; then
    red "FATAL: cannot read $TM_MNT — drive not mounted, or no Full Disk Access."
    red "System Settings > Privacy & Security > Full Disk Access > add Terminal, then RESTART it."
    exit 1
  fi
}

tm_running() { /usr/bin/tmutil status 2>/dev/null | grep -q 'Running = 1'; }
tm_phase()   { /usr/bin/tmutil status 2>/dev/null | grep -o 'BackupPhase = [A-Za-z]*' | awk '{print $3}'; }
tm_pct()     { /usr/bin/tmutil status 2>/dev/null | grep -o 'Percent = "[0-9.]*"' | head -1 | sed -E 's/.*"([0-9.]*)".*/\1/'; }
tm_free_g()  { /bin/df -g "$TM_MNT" 2>/dev/null | awk 'NR==2{print $4}'; }

tm_folders() {
  /usr/bin/find "$TM_MNT" -maxdepth 1 -mindepth 1 -name '20*' 2>/dev/null | sed 's|.*/||' | sort
}
tm_count_interrupted() { tm_folders | grep -c '\.interrupted$'; }

# The offending paths, as enumerated by backupd at the START of a run (debug level).
# Available ~10s into any backup — no need to wait for the failure.
tm_protected_paths_early() {
  local since="${1:-10m}"
  /usr/bin/log show --predicate 'subsystem == "com.apple.TimeMachine" AND category == "EventCollection"' \
    --last "$since" --style compact --debug 2>/dev/null \
    | grep -i "inaccessible while device is locked" \
    | grep -oE "'[^']+'" | tr -d "'" | sed -E 's|^|/|' | sort -u
}

# The offending paths, as reported AT the failure (only exists after a failed run).
tm_protected_paths_failure() {
  local since="${1:-24h}"
  /usr/bin/log show --predicate 'subsystem == "com.apple.TimeMachine" AND category == "FileProtection"' \
    --last "$since" --style compact --info 2>/dev/null \
    | grep "Failed to backup" | tail -1 \
    | grep -oE '"[^"]+"' | tr -d '"' | sed -E 's/^\\134n//; s|^|/|' | sort -u
}

# Map a path to the owning app when it is a UUID-named container.
tm_identify() {
  local p="$1" base id
  base=$(printf '%s' "$p" | sed -E 's|(.*/Containers/[^/]+).*|\1|')
  id=$(/usr/bin/plutil -p "$base/.com.apple.containermanagerd.metadata.plist" 2>/dev/null \
       | grep MCMMetadataIdentifier | sed -E 's/.*=> "(.*)"/\1/')
  [ -n "$id" ] && printf '%s' "$id" || printf '%s' "$(basename "$p")"
}

# Collapse the long child list down to the container/parent dirs worth excluding.
tm_parents_of() {
  sed -E 's|(/Users/[^/]+/Library/Containers/[^/]+).*|\1|; s|(/Users/[^/]+/Library/[^/]+).*|\1|' \
    | sort -u
}
