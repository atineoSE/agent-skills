#!/bin/bash
# Applies tmutil path exclusions for the protected paths that break backups.
# Dry-run by default. Pass --apply to actually change anything.
set -uo pipefail
cd "$(dirname "$0")" && . ./lib.sh
require_env

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

paths=$(tm_protected_paths_failure 24h)
[ -z "$paths" ] && paths=$(tm_protected_paths_early 24h)
if [ -z "$paths" ]; then
  red "No protected paths found in the logs."
  red "Start a backup and run watch.sh first, or pass paths on stdin."
  exit 1
fi
parents=$(echo "$paths" | tm_parents_of)

hdr "Would exclude ($(echo "$parents" | grep -c .) parents covering $(echo "$paths" | grep -c .) paths)"
echo "$parents" | while read -r p; do
  [ -z "$p" ] && continue
  sz=$(du -sh "$p" 2>/dev/null | cut -f1)
  printf '  %-68s %6s  [%s]\n' "${p:0:68}" "${sz:-?}" "$(tm_identify "$p")"
done

hdr "Cost"
ylw "  These will NOT be backed up. Check the list for anything that matters —"
ylw "  password/2FA app containers in particular. On this Mac that means"
ylw "  me.proton.authenticator (TOTP seeds); confirm account sync covers them."

if [ "$APPLY" -eq 0 ]; then
  hdr "Dry run"
  echo "  Re-run with --apply to make these changes."
  exit 0
fi

hdr "Applying"
echo "$parents" | while read -r p; do
  [ -z "$p" ] && continue
  if sudo /usr/bin/tmutil addexclusion -p "$p" 2>&1; then
    grn "  excluded: $p"
  else
    red "  FAILED:   $p"
  fi
done

hdr "Verify"
echo "$parents" | while read -r p; do
  [ -z "$p" ] && continue
  printf '  %s -> %s\n' "$(basename "$p")" "$(/usr/bin/tmutil isexcluded "$p" 2>&1 | awk '{print $1}')"
done
echo
echo "  Stored in /Library/Preferences/com.apple.TimeMachine.plist under SkipPaths."

hdr "Next"
echo "  Unlock the Mac, then:  tmutil startbackup && scripts/watch.sh"
echo
echo "  REMINDER: pass 1 will STILL report the same non-zero count. That is"
echo "  expected and is not a failure. Only the end of the run decides."
