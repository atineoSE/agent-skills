---
name: time-machine
description: Get a confirmed Time Machine backup onto the manually-connected external drive, and fix it when it fails. Use when the user connects the TM drive and wants a backup, when a backup "never finishes" or keeps restarting, when Time Machine reports BACKUP_FAILED_DEVICE_LOCKED / "some files were unavailable", when .interrupted folders pile up on the backup disk, or before ejecting the drive to confirm the backup actually committed. Covers the macOS 26.x (Tahoe) data-protection bug that silently discards completed multi-hour backups.
version: 1.0.0
---

# Time Machine on the manually-connected drive

The backup disk (`TM_MBA`, a WD Elements **USB spinning HDD**) is connected only
occasionally. Long gaps between backups are **normal and expected** — staleness is
not a fault signal here. The real risk is different and specific:

> Connect the drive → start a backup → walk away → come back to **nothing**,
> having burned the whole connection window.

Everything in this skill serves one goal: **leave with a confirmed backup, fast.**

Three properties of this machine make that harder than it should be:

1. A macOS 26.x bug discards completed multi-hour backups over ~200 MB of
   data-protected cache files (details below). Currently worked around by exclusions.
2. It is a spinning USB disk. A full run took **~3.7 h of copying plus ~3 h of
   post-backup thinning** — nearly 7 hours end to end.
3. **The backup is not safe to eject when it looks done.** The `.inprogress`
   folder is renamed to `.backup` *hours* before the session actually finishes.

## Environment requirement

Every script needs an **unsandboxed Terminal with Full Disk Access**. Without it:

- `log show` → `Cannot run while sandboxed`
- `tmutil status` → silently reports `Running = 0` **even when a backup is running**
- `ls /Volumes/TM_MBA` → `Operation not permitted`

Grant FDA in System Settings → Privacy & Security, then **fully quit and reopen**
Terminal. `sudo` does not substitute for FDA.

## The normal run

```bash
scripts/preflight.sh          # drive present, config sane, disk state
# --- UNLOCK the Mac ---
tmutil startbackup
scripts/watch.sh              # verdict within ~3 min: is this run worth waiting for?
# --- walk away for several hours ---
scripts/verify.sh             # the ONLY thing that authorises ejecting
diskutil eject /Volumes/TM_MBA
```

Start the backup **manually while unlocked**. The scheduler is currently off
(`AutoBackup = 0`) and starting unlocked is part of the known-good configuration.

### Do not eject early — this is the important one

`verify.sh` must pass. It checks four things, and a `.backup` folder existing is
**none of them**:

| Check | Why |
|---|---|
| `tmutil status` → `Running = 0` | `.inprogress`→`.backup` rename happens hours before the session ends |
| no `BACKUP_FAILED` in the last 24 h | the failure comes *after* a fully completed copy |
| `tmutil latestbackup` is today | the folder can exist without ever being registered |
| an APFS snapshot matches it | registration = snapshot + `listbackups`, and it lands last |

On the successful run the `.backup` folder appeared at **00:13** and registration
completed at **03:19**. Ejecting anywhere in that three-hour window would have
produced an unregistered, unusable backup that looked finished.

## When it fails

```bash
scripts/diagnose.sh           # failure mode + the exact offending paths
scripts/exclude.sh            # dry run — review what you would lose
scripts/exclude.sh --apply    # applies tmutil addexclusion -p
# --- UNLOCK, retry ---
tmutil startbackup && scripts/watch.sh
```

### The bug, precisely

`BACKUP_FAILED_DEVICE_LOCKED (80)`, emitted **after** `Finished copying items` —
i.e. after hours of successful work, all of which is thrown away.

- `backupd` samples lock state **once**, ~5 min into a session. If locked at that
  instant, every Data-Protection-class path is written off for the entire run.
  There is **no re-arm**: one run sat unlocked for 66 minutes mid-flight and it
  changed nothing.
- The two-pass design looks like it should save you — pass 1 takes a MobileKeyBag
  assertion, grabs the protected files in ~11 s, drops the assertion, pass 2 does
  the bulk — but **pass 1 and pass 2 are separate sessions**. Pass 1's work lands
  in its own folder that is then abandoned, and pass 2 *always* begins with the
  assertion released, reporting `Device unlocked: false` even with the screen
  demonstrably unlocked (observed 6 s apart, screen unlocked throughout).
- Therefore **keeping the Mac awake cannot fix this.** Only exclusion can.

Correlates with **macOS 26.5.2** (installed 2026-07-05). Last good backup before
the fix: 2026-06-14. Fixed 2026-08-11.

### Reading the logs

The offending paths are available **~10 s into any run** at debug level — no need
to wait hours for the failure:

```bash
log show --predicate 'subsystem == "com.apple.TimeMachine" AND category == "EventCollection"' \
  --last 10m --style compact --debug | grep "inaccessible while device is locked"
```

At failure, the same list appears in one line under `FileProtection`. UUID-named
containers resolve via
`plutil -p ~/Library/Containers/<UUID>/.com.apple.containermanagerd.metadata.plist`.

**Log retention is short.** `backupd`'s per-minute progress dumps evict
TimeMachine log data within hours — evidence from the previous evening was
already gone. Capture what you need during or immediately after a run.

## What worked

- **`sudo tmutil addexclusion -p <parent>`** on 8 parent paths covering 31 children.
  This is the fix. Stored in `SkipPaths` in `/Library/Preferences/com.apple.TimeMachine.plist`.
- **Starting the backup manually while unlocked.** Part of the confirmed-good
  configuration (see open question below).
- **Letting Time Machine clean up after itself.** It reclaimed all 10
  `.interrupted` folders unattended via "interrupted backup thinning", and freed
  112 → 241 GiB in the process.

## What did NOT work — do not retry these

| Attempt | Outcome |
|---|---|
| The `fix_tm_tahoe.md` procedure (delete TM plist, reboot, reset destination) | Wrong bug. That doc targets `TMStructureErrorDomain Code=7`; this is error 80. Would have destroyed the destination config for nothing. |
| Keeping the Mac unlocked / awake during the run | **Cannot work.** Pass 2 never attempts the protected files regardless of screen state. |
| `tmutil delete -p <folder>.interrupted` | `Invalid deletion target (error 22)` — they are not registered backups. |
| `sudo rm -rf <folder>.interrupted` | Works but pointless: **44 minutes for one folder** on this HDD. Time Machine reclaims them itself, roughly twice as fast, for free. |
| Waiting for the protected-item count to reach 0 after exclusions | It **never** drops. That counter enumerates protected items on the *system*, not in the backup set. Not a failure signal. |
| Monitoring via `tmutil status` from a sandboxed shell | Returns `Running = 0` for a running backup. Caused two false "session ended" calls; a 3-consecutive-readings guard just confirmed the artefact 3 times. |
| Estimating ETA from a 30-minute window | Throughput swings ~30×. Produced a "22–64 hours" estimate for a run that finished the same night, and a space-exhaustion prediction that never happened. |
| Treating `TMStructure / Expected SnapshotInProgressContainer` as the cause | Pure noise. Fires against every folder including healthy ones, thousands of times, while the backup proceeds normally. |

## Facts worth not relearning

- **One `.interrupted` folder per successful backup is normal** — that is pass 1's
  session. The signal is steady *growth*, not non-zero.
- Lifecycle is `.inprogress` → `.backup` → `.previous`. The `.previous` tree is the
  live baseline for the next incremental.
- Time Machine thins interrupted backups *during* a run when space gets tight, so
  a run that looks doomed on space can rescue itself. It does **not** touch
  registered snapshots to do so.
- A healthy incremental shows `Propagated` ≫ `Copied` in `CopyProgress`. If
  `Propagated` is near zero, it has lost its baseline and is writing a full copy —
  ~700 GB here, which does not fit.

## Reference: the 31 paths on this Mac

8 parents, ~214 MB total, **24 of them empty directories**:

| Parent | Size | What |
|---|---|---|
| `~/Library/DuetExpertCenter` | 202 MB | Siri Suggestions / app-prediction models |
| `~/Library/Containers/com.apple.Maps` | 11 MB | Maps recents, favourites |
| `~/Library/Containers/013ECAC0-82FE-4D25-A7FA-B437B53A4B50` | 572 KB | **me.proton.authenticator — TOTP seeds** |
| `~/Library/Containers/128AD158-4630-4593-B18B-C44DDCC238E0` | 12 KB | com.hswIosDevel.zehnderController |
| `~/Library/Containers/com.apple.findmy.FindMyWidget{Items,People}` | ~0 | Find My widgets |
| `~/Library/Containers/com.apple.findmy.FindMyWidgetIntents{Items,People}` | 104 KB | Find My App Intents |

**Exclusion is all-or-nothing** — one remaining protected path still trips the
failure, so Proton Authenticator cannot be kept without losing the fix.
Its container is currently excluded: **TOTP seeds are not in the backup.**
Confirm Proton account sync covers them.

## Open question

The successful run had **both** exclusions *and* a manual unlocked start. These
were never isolated. It is plausible that exclusions alone are sufficient, which
would allow re-enabling the scheduler (`sudo tmutil enable`) and unattended
backups whenever the drive is connected.

To test: with exclusions in place, let a backup start while the Mac is locked and
run `verify.sh` afterwards. If it passes, the manual choreography is unnecessary.
Record the result here.
