#!/bin/bash
# Run BEFORE starting a backup, with the drive connected.
# Confirms the drive is usable and reports the standing risk level.
set -uo pipefail
cd "$(dirname "$0")" && . ./lib.sh
require_env

hdr "Destination"
echo "volume:    $TM_MNT"
/usr/sbin/diskutil info "$TM_MNT" 2>/dev/null | grep -Ei "Device / Media Name|Protocol|Mounted|Volume Read-Only"
echo "free:      $(tm_free_g) GiB"

hdr "Time Machine config"
/usr/bin/tmutil destinationinfo 2>&1 | sed 's/^/  /'
echo
echo "  scheduler: $(/usr/bin/defaults read /Library/Preferences/com.apple.TimeMachine.plist AutoBackup 2>/dev/null || echo '?')  (0 = off, manual only)"

hdr "Existing backups"
n=$(/usr/bin/tmutil listbackups 2>/dev/null | wc -l | tr -d ' ')
echo "registered: ${n}"
/usr/bin/tmutil listbackups 2>/dev/null | sed 's|.*/||' | tail -5 | sed 's/^/  /'
echo "latest:     $(/usr/bin/tmutil latestbackup 2>/dev/null | sed 's|.*/||')"

hdr "Disk hygiene"
echo "interrupted folders: $(tm_count_interrupted)"
echo "  (1 per successful backup is NORMAL — that is pass 1's session.)"
echo "  (Do NOT rm -rf them. Time Machine reclaims them itself.)"
tm_folders | sed 's/^/  /'

hdr "Current exclusions"
/usr/bin/plutil -p /Library/Preferences/com.apple.TimeMachine.plist 2>/dev/null \
  | sed -n '/SkipPaths/,/]/p' | grep '=>' | grep -v 'SkipPaths' \
  | sed -E 's/.*=> "(.*)"/  \1/' || echo "  (none readable)"

hdr "Verdict"
if tm_running; then
  ylw "A backup is ALREADY RUNNING (phase: $(tm_phase)). Do not start another."
else
  grn "Idle. Ready to start."
  echo
  echo "Next:  make sure the Mac is UNLOCKED, then:"
  echo "         tmutil startbackup"
  echo "       and immediately:"
  echo "         scripts/watch.sh"
fi
