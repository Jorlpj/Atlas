# AME Wizard playbooks for Windows 11 26H2 (build 26300) vs AtlasOS

Survey snapshot dated 2026-11-02 by the orchestrator, from three read-only research passes. Rechecked by atl-lib-2 on 2026-11-02 against the accompanying raw-source inventories in `apbx/group-a.md`, `apbx/group-b.md` and `apbx/group-c.md`, plus Microsoft's 26H2 release-health page. The comparison remains a snapshot of those repository reads, not an independent clean-install test of every listed playbook.

Rechecked 2026-11-03: ReviOS `playbook.conf` lists build 26300; closed PR [#235](https://github.com/meetrevision/playbook/pull/235) records its contributor's report of archive loading and task execution on 26300.9457, but the PR was closed without merging. Privacy+ 0.8.3 is confirmed by the [source commit changing the conf version from 0.8.2 to 0.8.3](https://github.com/Ameliorated-LLC/privacy_plus/commit/dd95d12); the latest release tag remains 0.8.2 per the group-A inventory. The passes read GitHub (`playbook.conf`,
README, issues, releases) and vendor and Microsoft pages. No `.apbx` or binary was downloaded or run. Librarians:
re-verify each row before you rely on it, and grade the sources in `sources.json`. Claims marked (inference) are not
sourced. The problems are collected in [problem-catalog.md](problem-catalog.md).

## Which playbooks list 26300

- **Listed in `playbook.conf`:**
  - ReviOS 26.10;
  - Chamber 1.3.3, where the conf itself says "declared ahead of validation";
  - SynergyOS 1.7, "26H2 experimental";
  - NOVA 1.0.1, ISO injection only;
  - UltraOS 1.2.1;
  - ShimmerOS 1.5.2;
  - LexBoosT OS 26.10.1;
  - KiyomizuOS 3.0.1 Preview.
  - Source: `gh search code "26300" --filename playbook.conf` plus a read of each conf.
- **Not listed:**
  - AtlasOS 0.5.0 (26100 and 26200). Upstream PR [#1750](https://github.com/Atlas-OS/Atlas/pull/1750), opened
    2026-10-26, adds 26300. Its author had no 26H2 machine to test on.
  - AME 11 / Privacy+ 0.8.3 (stale since 2025-10; version cross-checked against the group-A source inventory).
  - RapidOS, GamerzOS, SapphireOS, RivalsOS, AtmosphereOS and others (they stop at 26200).
- **Unknown:** Nexus (paid, closed source; "23H2 and above"), FSOS-X (no source found) and Z-LAG-OS (no build list).

## Comparison (defaults unless noted)

| Playbook | 26300 | Install methods | Defender | VBS / HVCI | Windows Update | Store | Xbox / Game Pass | Edge | Revert | License | Red flags |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **AtlasOS 0.5.0** (baseline) | no (PR #1750 open) | post-install (ISO via AME) | kept (option to disable) | **off by default** | auto-updates off; Store AutoDownload=2 | kept, but Store servicing failures recur (#1556, #1591, #1675) | kept; Xbox sign-in 0x89235107 fixed earlier (#1633) | removed | documented uninstall | GPL-3.0 | `StoreFixer.exe` binary runs silently on every upgrade |
| ReviOS 26.10 | listed in `playbook.conf`; contributor-reported test on 26300.9457 in unmerged PR #235 | post-install + ISO | **off by default** | off (`revitool`, not an option) | not disabled by policy; paused to 2038; `NoAutoUpdate` commented out because it once broke Xbox sign-in; Store AutoDownload=4 | kept | kept by default; new WinSxS Xbox-removal package (default not verified) | removed | not documented | CC-BY-SA-4.0 | `.apbx` now only on an ad-link host |
| AME 11 / Privacy+ 0.8.3 | no | post-install + ISO | **deleted** | not checked | **deleted** | **removed** | **removed** | removed | none ("irretrievable") | none listed | stale; not a servicing-compatible base |
| Chamber 1.3.3 | declared, one author ISO test (2026-10-07) | post-install; ISO experimental | kept (Defender-off option dropped on 26300) | optional off; Secure Boot kept | notify-only option | kept (with winget) | kept unless the option is ticked | not verified | `Restore-Chamber.ps1`, snapshot | custom ("Other") | bundles `nvidiaProfileInspector.exe`; hosts and firewall telemetry blocks; paid service upsell |
| SynergyOS 1.7 | "experimental" | post-install; ISO in development | permanent-removal checkbox (`NoDefender.cab` + test root certificate) | optional off; UAC option | paused to 2038, `DoNotConnectToWindowsUpdateInternetLocations` | not verified | **disabled by default** | **removed by default** | partial | none declared | closed binaries (`NoDefender.cab`, MinSudo, PowerRun); Microsoft account, Store and Xbox sign-in failure (#11) |
| NOVA 1.0.1 | yes (conf) | **ISO injection only** | radio option | **on by default** | README advises against updating | not verified | option to remove | option | none (reinstall) | Apache-2.0 | ships NSudo, CRU and other binaries; v1.0.0 BSOD from its power plan (fixed) |
| UltraOS 1.2.1 | yes (primary target) | post-install + ISO | not verified | opt-in off ("not recommended") | automatic (recommended) or notify-only | not verified | Balanced keeps it; Extreme removes it | opt-in | restore point, one-click undo, HTML report | GPL-3.0 | none found in the tree |
| ShimmerOS 1.5.2 | yes | post-install | must be disabled first | not verified | removed or disabled (README) | not verified | not verified | not verified | not verified | none | **UAC and mitigations off by default** |
| LexBoosT OS 26.10.1 | yes | post-install | not verified | not verified | not verified | ClipSVC and TokenBroker kept; "update Store apps first" | Game Bar removed | optional | backup option | none | issues disabled; bundled xperf DLLs |
| KiyomizuOS 3.0.1 Preview | yes | post-install + ISO | not verified | not verified | paused | not verified | **Xbox app, Identity Provider and TCUI removed** | removed | not verified | AGPL-3.0 | only requirement checked is Internet |

## What this means for EclipseOS

- **The inspected public source set does not establish a maintainer-verified clean-install result for every listed playbook.** ReviOS lists 26300 in `playbook.conf`; a contributor reported testing 26300.9457 in unmerged PR #235. Chamber reports one ISO test by its author. These are different levels of evidence. The EclipseOS lab lanes (ATL-1 and ATL-2) are first-hand 26300 results for the Atlas line.
- **Closest to the EclipseOS goal of keeping Store, Xbox and anti-cheats working:** Chamber (Defender kept, Store
  kept, Xbox kept, Secure Boot kept, notify-only updates) and UltraOS Balanced (automatic updates, Xbox kept, VBS-off
  only as an opt-in). Both are a design reference, not a code source: check license compatibility before reusing any
  file (Chamber's license is custom).
- **Windows Update:** ReviOS's approach (pause instead of a `NoAutoUpdate` policy, kept because the policy once broke
  Xbox sign-in) is a lead to test against Atlas's auto-updates-off default.
- **Patterns to avoid:** Defender or Windows Update deletion (AME 11, SynergyOS), Xbox identity removal (KiyomizuOS),
  UAC and mitigations off by default (ShimmerOS), closed binaries inside the playbook (SynergyOS, NOVA, Atlas
  StoreFixer), and "do not update" advice (NOVA).


## Recheck notes (atl-lib-2, 2026-11-02)

The comparison metadata and build claims were checked against the read-only inventories in `apbx/group-a.md`, `apbx/group-b.md` and `apbx/group-c.md`; current 26H2 build context was checked against Microsoft's [release-health page](https://learn.microsoft.com/en-us/windows/release-health/status-windows-11-26h2). The Privacy+ version reference was corrected to 0.8.3. Product behavior, defaults and license statements remain sourced to the repository/API reads summarized in those inventories; explicitly marked inferences and unverified cells remain provisional. Graded source records are in the worker file `sources.atl-lib-2.json` for merge by `atl-lead`.
