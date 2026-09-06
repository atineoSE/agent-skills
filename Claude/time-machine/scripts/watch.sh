#!/bin/bash
# Run IMMEDIATELY after `tmutil startbackup`.
# Answers within ~3 minutes whether this run is worth waiting hours for.
set -uo pipefail
cd "$(dirname "$0")" && . ./lib.sh
require_env

hdr "Waiting for pass 1 (usually ~2 min after session start)"
deadline=$((SECONDS + 600))
result=""
while [ $SECONDS -lt $deadline ]; do
  result=$(/usr/bin/log show \
      --predicate 'subsystem == "com.apple.TimeMachine" AND category == "FileProtection"' \
      --last 15m --style compact --info 2>/dev/null \
    | grep -E "Starting backup pass|Device unlocked:|Prioritizing|Finished backing up paths" \
    | sed -E 's/backupd\[[0-9:a-z]+\] \[com.apple.TimeMachine:FileProtection\]//')
  echo "$result" | grep -q "Starting backup pass 1" && break
  sleep 15
done

if ! echo "$result" | grep -q "Starting backup pass 1"; then
  red "No pass 1 seen in 10 min. Is a backup actually running?  tmutil status"
  exit 1
fi

echo "$result" | sed 's/^/  /'

unlocked=$(echo "$result" | grep -m1 "Device unlocked:" | grep -o 'Device unlocked: [a-z]*' | awk '{print $3}')
count=$(echo "$result" | grep -m1 "count of items inaccessible" | grep -oE '[0-9]+$')

hdr "Assessment"
echo "  device unlocked at pass 1 : ${unlocked:-?}"
echo "  protected items in scope  : ${count:-?}"
echo
echo "  NOTE: this count does NOT drop to 0 when exclusions are working."
echo "        It enumerates protected items on the SYSTEM, not in the backup set."
echo "        It is NOT a failure signal. The only verdict is the end of the run."

if [ "${unlocked:-false}" != "true" ]; then
  red "RISK: pass 1 ran with the device locked — those items were skipped for the WHOLE session."
  red "Unless they are excluded, this run will fail with BACKUP_FAILED_DEVICE_LOCKED (80) at the end."
  echo
  echo "  Stop it now and restart while unlocked:  tmutil stopbackup"
else
  grn "Pass 1 ran unlocked and banked the protected items."
fi

hdr "Paths currently in scope (for exclusion, if this run fails)"
tm_protected_paths_early 15m | while read -r p; do
  [ -z "$p" ] && continue
  printf '  %-70s  [%s]\n' "${p:0:70}" "$(tm_identify "$p")"
done

hdr "Next"
echo "  Let it run. Expect HOURS (copy + post-backup thinning)."
echo "  Then:  scripts/verify.sh    <-- MUST pass before ejecting the drive"
