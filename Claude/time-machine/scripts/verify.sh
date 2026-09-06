#!/bin/bash
# Run AFTER the backup, BEFORE ejecting the drive.
# The ONLY thing that authorises disconnecting the disk.
set -uo pipefail
cd "$(dirname "$0")" && . ./lib.sh
require_env

fail=0

hdr "1. Is the session finished?"
if tm_running; then
  red "  NO — still running (phase: $(tm_phase), $(tm_pct)%)."
  red "  DO NOT EJECT. Post-backup thinning alone took ~3h on this drive."
  exit 1
fi
grn "  Yes — Running = 0."

hdr "2. Did it fail?"
f=$(/usr/bin/log show --predicate 'subsystem == "com.apple.TimeMachine"' --last 24h --style compact 2>/dev/null \
    | grep -E "Backup failed|BACKUP_FAILED" | tail -3)
if [ -n "$f" ]; then
  ylw "  Failure events in the last 24h:"
  echo "$f" | sed -E 's/.*BackupDispatching\]//' | sed 's/^/    /'
  echo "    (may belong to an earlier attempt — check the timestamp)"
else
  grn "  No failure events in the last 24h."
fi

hdr "3. Is the new backup REGISTERED?"
latest=$(/usr/bin/tmutil latestbackup 2>/dev/null | sed 's|.*/||; s|\.backup$||')
echo "  tmutil latestbackup : ${latest:-NONE}"
if [ -z "$latest" ]; then
  red "  FAIL — no backups registered."
  fail=1
else
  age_d=$(( ( $(date +%s) - $(date -j -f "%Y-%m-%d-%H%M%S" "$latest" +%s 2>/dev/null || echo 0) ) / 86400 ))
  if [ "$age_d" -le 1 ]; then
    grn "  Latest backup is from today/yesterday."
  else
    red "  FAIL — latest backup is ${age_d} days old. This run did NOT register."
    fail=1
  fi
fi

hdr "4. Does it have an APFS snapshot?"
snaps=$(/usr/sbin/diskutil apfs listSnapshots "$TM_MNT" 2>/dev/null | grep -c "Name:")
echo "  snapshots on destination: ${snaps}"
if [ -n "$latest" ] && /usr/sbin/diskutil apfs listSnapshots "$TM_MNT" 2>/dev/null | grep -q "$latest"; then
  grn "  Snapshot exists for $latest"
else
  red "  FAIL — no snapshot matching the latest backup. Not committed."
  fail=1
fi

hdr "5. Disk state"
echo "  free: $(tm_free_g) GiB   interrupted folders: $(tm_count_interrupted)"
tm_folders | sed 's/^/    /'

hdr "VERDICT"
if [ "$fail" -eq 0 ]; then
  grn "  BACKUP CONFIRMED — safe to eject."
  echo
  echo "  Eject with:   diskutil eject $TM_MNT"
else
  red "  NOT CONFIRMED — do not rely on this backup."
  echo
  echo "  Diagnose with: scripts/diagnose.sh"
  exit 1
fi
