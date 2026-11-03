# ADR-002: EclipseOS is one public repository built from Atlas, the open AME engine and Rufus's answer-file logic

Status: accepted for the direction (maintainer, 2026-11-03); decisions 2 and 4 superseded by ADR-003. The component choices below are proposed until the
cards land. Author: orchestrator.

## Context
The maintainer wants EclipseOS to be the union of three public code bases, and to stay public:
- AtlasOS (`Atlas-OS/Atlas`, GPL-3.0): the playbook, in this fork (`Jorlpj/Atlas`).
- Ameliorated-LLC: the AME playbook engine.
- Rufus (`pbatard/rufus`, GPL-3.0): makes the install USB.

The target flow is the Rufus scenario in [../research/rufus-scenario.md](../research/rufus-scenario.md):
1. A Rufus USB installs Windows 11 26H2 (build 26300) with a local passwordless account, no Microsoft account, and
   TPM and Secure Boot kept.
2. Windows Update and the Microsoft Store are fully updated, with reboots.
3. The playbook runs post-install. ISO injection is never used.

Sources (static reading, orchestrator spot-checks marked "verified"):
- `.handoff/research/ameliorated-repos.md`
- `.handoff/research/rufus-import.md`
- [../research/rufus/rufus-wue.md](../research/rufus/rufus-wue.md)

## Facts
- Licenses:
  - `Ameliorated-LLC/trusted-uninstaller-cli` (TUC), the AME engine: MIT. The orchestrator read the LICENSE.md
    text (verified).
  - `appfetch` and `jumper`: MIT (verified, GitHub license API).
  - The other Ameliorated-LLC repos have no license, so they cannot be copied: privacy_plus, AME-10,
    ame-settings-*, ame-assassin, ame-sfc-interface (GitHub detects none).
  - The AME Wizard GUI has no public source; it is binary-only (AME-Beta).
  - Rufus: GPL-3.0 (verified). MIT code may be combined into a GPL-3.0 work if the MIT notice is kept.
- TUC at `f325e9d9`:
  - Projects: Core, Interprocess, TrustedUninstaller.Shared, TrustedUninstaller.CLI; .NET Framework 4.7.2.
  - Binary blobs (verified):
    - `CLI-Resources.7z` and `ProcessInformer.7z` (kernel driver);
    - `7za.exe`, `7za.dll`, `7zxa.dll` and `Shared/7z.dll`;
    - `ManagedWimLib` native `libwim-15.dll`.
  - The GUI project is referenced but absent.
  - The CLI runs `TrustedUninstaller.CLI.exe "<playbook dir>" [options]`.
  - Its `NoPendingUpdates` check is weak (offline search, passes on errors), and the CLI enforces only `Internet`.
- Rufus v4.15:
  - It has no option to load a custom answer file and no command line for the Windows User Experience options.
  - Its answer file goes to `sources\$OEM$\$$\Panther\unattend.xml` on the USB (Rufus `wue.c` lines 1328-1337 at v4.15, verified).
  - It sets an empty password, then forces a password change at first logon (Rufus `wue.c` lines 363-382, verified).

## Decision
1. **Repository.** This repository (`Jorlpj/Atlas`) becomes EclipseOS and stays public under GPL-3.0. Imported code
   keeps its notices: `engine/LICENSE.md` (MIT, Ameliorated LLC) and Rufus attribution in the media tool. A
   `THIRD_PARTY.md` lists every import with its upstream commit.
2. **Engine (`engine/`).**
   - Import TUC source at a pinned commit as plain files, not a subtree, so its binary blobs never enter history.
   - Keep Core, Interprocess, Shared and CLI. Drop the ISO-injection, USB and wimlib paths, because Rufus covers the
     media.
   - Replace or remove the blobs: 7-Zip from its LGPL source or a NuGet package; ProcessInformer and CLI-Resources
     only if a playbook action needs them, otherwise removed.
   - Remove online endpoints that are not needed (ameliorated.io downloads, update lookups).
   - Rename the binary: no "AME" or "Ameliorated" branding, because MIT grants no trademark rights.
3. **Update gate.** EclipseOS adds its own "Windows Update and Store fully updated" gate: online scan, no pending
   reboot, Store app updates applied. It runs before the engine, instead of trusting `NoPendingUpdates`.
4. **Media (`media/`).**
   - Stock Rufus makes the USB.
   - An EclipseOS script then replaces `sources\$OEM$\$$\Panther\unattend.xml` with the EclipseOS preset:
     - the maintainer's Rufus options;
     - no `logonpasswordchg` and no `maxpwage` change, so the account stays passwordless;
     - a limited-count AutoLogon for the update chain.
   - The script also adds `sources\$OEM$\$1\EclipseOS\` (engine, playbook, first-logon launcher).
   - The answer-file logic is ported from Rufus `wue.c` (GPL-3.0) with attribution.
   - Rufus is not forked; it changed its answer-file code in 4.6, 4.12, 4.14 and 4.15.
5. **First-logon chain (`media/firstboot/`).** In order:
   1. wait for the network;
   2. loop Windows Update with reboots until nothing is pending;
   3. update Store apps;
   4. pass the update gate;
   5. run the engine with the EclipseOS playbook;
   6. remove the AutoLogon;
   7. write a report.
6. **Playbook.** Apply the EclipseOS design defaults in separate cards:
   - VBS on;
   - no `DefenderToggled`;
   - Windows Update notify;
   - Store, Xbox and WebView2 protected;
   - 26300 declared;
   - own Name and UniqueId;
   - no ISO block.

## Consequences
- The maintainer gets one public toolchain: Rufus USB, then the EclipseOS media script, then an unattended install
  that ends with the playbook applied after full updates.
- Maintenance of the engine is ours after the fork, since the vendor's GUI is closed.
- Unsigned binaries that launch as TrustedInstaller may be flagged by antivirus; signing is an open question.
- Every behaviour is validated only in `eclipse-lab-*` guests, never on the maintainer's PC.
