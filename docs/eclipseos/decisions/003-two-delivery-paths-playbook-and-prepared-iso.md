# ADR-003: Two delivery paths, an AME Wizard playbook and a prepared ISO, without copying the AME engine

Status: accepted for the direction (maintainer, 2026-11-03); the order and component choices below are proposed until
their cards land. Author: orchestrator. Supersedes ADR-002 decision 2 (engine import) and decision 4 (media input).
The rest of [ADR-002](002-public-union-atlas-engine-rufus.md) stands.

## Context
The maintainer narrowed ADR-002 on 2026-11-03: the goal is not to copy Ameliorated's code. EclipseOS must offer
one of two alternatives:
- **A. Prepared ISO.** The user supplies a supported ISO (Windows 11 26H2, build 26300). EclipseOS prepares the
  install so that, after the user boots it, every preset is already in place, with no error and no broken or
  corrupted app.
- **B. Playbook.** An EclipseOS playbook (`.apbx`) that the user runs with AME Wizard.

Constraints that both paths must keep:
- Windows Update and the Microsoft Store are fully updated, with reboots, before any playbook action
  (ADR-001; lab lanes ATL-1 and ATL-2).
- No offline servicing of `install.wim` or `boot.wim`. The ISO-injection lane broke Store and Xbox in the lab
  (problem catalog G18-G20).

## Facts
- Rufus v4.15 skips its Windows User Experience dialog when the ISO already contains
  `/sources/$OEM$/$$/Panther/unattend.xml`, and logs "A '/sources/$OEM$/$$/Panther/unattend.xml' was detected on the
  ISO" (Rufus rufus.c at tag v4.15, function BootCheckThread, verified by the orchestrator). A prepared ISO therefore
  keeps its own answer file when the user writes it with stock Rufus.
- Windows Setup copies `sources\$OEM$\$$\*` into `%WINDIR%` and `sources\$OEM$\$1\*` into the system drive root.
  This is documented Setup behaviour; no image is serviced.
- The Atlas playbook uses 11 action types, counted over `src/playbook/Configuration`: registryValue 386,
  powerShell 53, appx 41, registryKey 35, run 29, cmd 22, service 13, scheduledTask 8, taskKill 7, file 1, and
  writeStatus 36. `!task` (181) is an include, not an action. The hard parts of an engine are TrustedInstaller
  impersonation and provisioned-package removal. Rewriting an engine is more scope than importing one, so neither
  path does it.

## Decision
1. **One playbook serves both paths.** `src/playbook` becomes the EclipseOS playbook with the ADR-002 decision 6
   defaults: VBS on, no `DefenderToggled`, Windows Update notify, Store, Xbox and WebView2 protected, 26300 declared,
   own Name and UniqueId, and no ISO block.
2. **Path B first.** It reuses what exists: the `.apbx` build and AME Wizard, run post-install after a Rufus install
   with the maintainer's options and full WU and Store updates. Its acceptance test is a lab run with stock AME
   Wizard.
3. **Path A second.** A media tool takes the user's ISO path and writes a new ISO:
   - It checks that the ISO is supported, reading the image metadata only.
   - It adds `sources\$OEM$\$$\Panther\unattend.xml`, the EclipseOS preset ported from Rufus `wue.c` with
     attribution:
     - the maintainer's options;
     - no `logonpasswordchg` and no `maxpwage` change;
     - a limited-count AutoLogon.
   - It adds `sources\$OEM$\$1\EclipseOS\`: the playbook, the first-logon chain and the engine.
   - It never modifies a WIM.
   - The user writes the ISO with stock Rufus, which then shows no options dialog, or with any other USB writer.
4. **Engine for path A, not vendored.** The first-logon chain runs the open trusted-uninstaller-cli (MIT) as an
   external dependency. A build script compiles it from the pinned upstream commit, or fetches a pinned
   hash-verified artifact, at media-build time. No AME source and no AME binary enter this repository. The MIT
   notice ships with the payload, and nothing is published under the AME name.
5. **What "ready at first boot" means.** The first boot of path A is a single unattended session:
   1. the network wait;
   2. the WU loop with reboots;
   3. Store updates;
   4. the update gate;
   5. the playbook;
   6. AutoLogon removal;
   7. a report.

   The user sees a progress screen, then the desktop with EclipseOS applied. Presets that are safe before the
   updates go in the answer file. Everything else waits for the gate, because applying it earlier is the
   Store/Xbox regression.

## Consequences
- The ADR-002 cards that imported and hardened the engine source in `engine/` are dropped.
- Paths A and B share the playbook and its lab checks: Store install, Xbox and Gaming Services, WU, Defender and
  Tamper, VBS, and a passwordless account. A defect fixed for one path is fixed for both.
- Path A depends on the engine's CLI behaviour. Its `NoPendingUpdates` check stays unused, and the EclipseOS gate
  replaces it.
- Every behaviour is validated only in `eclipse-lab-*` guests. The media tool is tested only on an ISO copy inside
  a guest, never on the host's ISO.
