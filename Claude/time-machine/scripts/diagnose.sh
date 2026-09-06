#!/bin/bash
# Run after a FAILED backup. Identifies the failure mode and, for the
# device-locked failure, prints the exact paths to exclude.
set -uo pipefail
cd "$(dirname "$0")" && . ./lib.sh
require_env
SINCE="${1:-24h}"

hdr "Failure events (last $SINCE)"
/usr/bin/log show --predicate 'subsystem == "com.apple.TimeMachine"' --last "$SINCE" --style compact 2>/dev/null \
  | grep -E "Backup failed|Backup cancelled|BACKUP_FAILED" \
  | sed -E 's/.*\[com.apple.TimeMachine:[A-Za-z]*\]//' | tail -10 | sed 's/^/  /'

locked=$(/usr/bin/log show --predicate 'subsystem == "com.apple.TimeMachine"' --last "$SINCE" --style compact 2>/dev/null \
         | grep -c "BACKUP_FAILED_DEVICE_LOCKED")

hdr "Diagnosis"
if [ "$locked" -gt 0 ]; then
  red "  BACKUP_FAILED_DEVICE_LOCKED (80) x${locked}  <-- the known Tahoe bug"
  echo
  echo "  backupd samples lock state ONCE, ~5 min into a session. If locked then,"
  echo "  it skips all Data-Protection-class paths for the WHOLE run, copies for"
  echo "  hours, then discards everything at the end."
  echo
  echo "  Its two-pass design does not save you: pass 1 and pass 2 are SEPARATE"
  echo "  sessions, and pass 2 always starts with the keybag assertion dropped"
  echo "  (Device unlocked: false) even with the screen unlocked. So keeping the"
  echo "  Mac awake CANNOT fix this. Exclusion is the fix."
else
  ylw "  No device-locked failure found. Look at the events above —"
  echo "  out-of-space, drive disconnect and user cancel all look different."
  echo "  Note: 'TMStructure / Expected SnapshotInProgressContainer' errors are"
  echo "  NOISE. They fire against every folder including healthy ones."
fi

hdr "Offending paths"
paths=$(tm_protected_paths_failure "$SINCE")
[ -z "$paths" ] && paths=$(tm_protected_paths_early "$SINCE")
if [ -z "$paths" ]; then
  ylw "  None found. Logs may have rotated — backupd's own progress spam evicts"
  ylw "  TimeMachine log data within hours. Re-run a backup and use watch.sh."
  exit 0
fi
echo "$paths" | while read -r p; do
  [ -z "$p" ] && continue
  printf '  %-72s [%s]\n' "${p:0:72}" "$(tm_identify "$p")"
done
echo
echo "  total: $(echo "$paths" | grep -c .)"

hdr "Parents to exclude (covers all children)"
echo "$paths" | tm_parents_of | while read -r p; do
  [ -z "$p" ] && continue
  printf '  %-72s [%s]\n' "$p" "$(tm_identify "$p")"
done

hdr "Next"
echo "  Review the list above — exclusion means these are NOT backed up."
echo "  It is ALL-OR-NOTHING: one remaining protected path still trips the failure."
echo
echo "  Apply with:   scripts/exclude.sh --apply"
