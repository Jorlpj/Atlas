# EclipseOS lab method

Status: documented from the completed ATL-1 and ATL-2 runs (2026-11-02). The lab used Windows 11 26H2 build 26300.9457 and updated guests to 26300.9711. The lane reports and source artifacts live outside this repository; see [lane A](lane-a.md), [lane B](lane-b.md), and [comparison](comparison.md).

## Test environment

| | Lane A | Lane B |
|---|---|---|
| Guest | Hyper-V Generation 2 `eclipse-lab-a`; 4 vCPU, 8 GB RAM, virtual TPM, Secure Boot | Hyper-V Generation 2 `eclipse-lab-b`; nested virtualization, virtual TPM, Secure Boot |
| Builder | Not applicable; post-install playbook application through AME CLI 0.8.4 | Separate builder VM `eclipse-lab-b0`; AME Wizard 0.8.4 GUI ISO mode |
| Image and playbook | Windows installed from 26300.9457; WU and Store fully updated before applying local lab playbook | Local lab playbook injected into stock 26300.9457 ISO before install; WU and Store updated after first boot |
| Options | One minimal run, then GUI defaults (11 options) | GUI defaults plus `ame-drivers-network` |
| Instrumentation | Common guest check script, launch probes, WU install test, and Store/winget scans | Common guest check script, launch probes, WU cycles, Store/winget scans, and screenshots |

The local lab copy temporarily added 26300 to the playbook's supported builds. This was test setup only; the normal support declaration did not include 26300. The CLI and GUI paths are not equivalent: CLI applied a playbook to an installed, updated guest; lane B used GUI ISO injection. AME's ISO mode was GUI-only in the tested version. Refer to archived reports for exact test inputs and deviations.

## Checkpoint map

### Lane A

- **A0** — stock system after WU and Store updates reached a fixed point.
- **A0v** — A0 with nested virtualization, VBS and HVCI enabled as a separate baseline.
- **A1** — post-apply with RadioPage defaults only.
- **A1f** — post-apply with all GUI defaults.
- **A2 / A2f** — after the corresponding post-apply WU and Store checks; A2f is the full-defaults checkpoint.

### Lane B

- **B1** — first desktop after AME ISO injection and Windows setup, before WU/Store updates.
- **B2** — after WU and Store scans reached the observed fixed point (0 WU updates pending).

Checkpoints are VM snapshots, not independent clean installations. Lane B used a lab-only password deviation because PowerShell Direct rejected the empty-password account. The AME OOBE flow produced a UAC prompt that delayed the first-logon script until answered. These deviations are documented in ATL-2's archived report.

## Common checks and JSON keys

`C:\EclipseLab\checks\eclipse-checks.ps1` is the common, read-only guest probe. It runs inside an `eclipse-lab-*` guest and writes `<Lane>-<Point>.json` to the selected output directory. If a probe fails, it records an `error` field rather than aborting the full collection. `-InstallApps` is the explicit mutation: it invokes winget against the fixed Store app IDs and records exit codes and resulting package state.

Every full checkpoint JSON uses these top-level keys:

| Key | Captured evidence |
|---|---|
| `meta` | Guest/build and collection metadata |
| `updates` | Windows Update state and scan information |
| `store` | Store packages, versions and package status |
| `apps` | App install attempt and package results when requested |
| `services` | Start mode/state for servicing, Store, Xbox, Defender and selected system services |
| `security` | Secure Boot, TPM, VBS/HVCI, Defender, UAC, SmartScreen, firewall and mitigations |
| `performance` | Power scheme, process/service/task counts, memory, commit, disk usage and startup items |
| `gaming` | Game Mode, Game DVR policy, hardware-accelerated GPU scheduling, MMCSS, DirectX and VC++ runtime probes |
| `events` | Recent AppX, Store, WU, System and Application error events |
| `edge` | Edge executable and WebView2 runtime/folder state, when collected |
| `ame` | Atlas folders/registry and discovered AME log error lines |

Separate launch JSON files record each tested app, `alive`, errors and notes. WU cycle/install JSON and winget scan JSON capture their respective commands and results. The check script source is at `C:\EclipseLab\checks\eclipse-checks.ps1`; run output is in `C:\EclipseLab\lane-a\out\` and `C:\EclipseLab\lane-b\out\`.

## Reading and reporting results

Compare the same metrics at the same checkpoints, and keep the lane, build, option set, update order and test action attached to each result. A WU scan at zero pending updates does not by itself establish Store or Xbox health: inspect Store/Xbox versions and registration, AppX install outcomes, relevant service states, launch probes, and event evidence together. A winget exit code or success message is not proof that a package registered; check the resulting package list as well.

The two completed lanes differ in more than update order, so their comparison is correlational. Do not assign the cause to a registry policy, service, or AME step without a controlled follow-up. Sign-in, Game Pass and purchase flows were deliberately not exercised; no conclusion about those flows follows from launch probes.

## Evidence locations

- Lane A artifacts: `C:\EclipseLab\lane-a\out\`; report: `C:\Atlas\.handoff\archive\ATL-1\ATL-1.report.md`.
- Lane B artifacts: `C:\EclipseLab\lane-b\out\`, screenshots under `C:\EclipseLab\lane-b\shots\`; report: `C:\Atlas\.handoff\archive\ATL-2\ATL-2.report.md`.
- Common check script: `C:\EclipseLab\checks\eclipse-checks.ps1`.
