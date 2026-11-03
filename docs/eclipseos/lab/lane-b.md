# Lab lane B: AME ISO injection on 26300 (ATL-2)

Orchestrator summary, 2026-11-02. Source: the ATL-2 report (rounds 1 and 2), the JSON in `C:\EclipseLab\lane-b\out\`
and the screen captures in `C:\EclipseLab\lane-b\shots\`. Same lab build and options as lane A
([lane-a.md](lane-a.md)), with the full GUI defaults plus `ame-drivers-network`. AME Wizard 0.8.4 ISO mode ran
in builder VM `eclipse-lab-b0` (a worker drove the GUI). Windows was installed from the injected 26300.9457 ISO into
`eclipse-lab-b` (nested virtualization, vTPM, Secure Boot). Then came Windows Update and the Store update to a fixed
point. Findings: problem catalog G18-G25 ([../research/problem-catalog.md](../research/problem-catalog.md)).

## Result: the injection order reproduces the maintainer's Store/Xbox regression
| item | B1 (first desktop) | B2 (after WU + Store) | lane A A2f |
|---|---|---|---|
| WindowsStore | 22506.1400.2.0 | same (never updated) | 22609.1401.8.0 |
| GamingApp (Xbox) | 2605.900.13.0 | same | 2611.1001.10.0 |
| GamingServices | absent | absent; winget says "Successfully installed", package absent | 39.118.21002.0 |
| To Do install | - | winget exit 0, package absent | installed |
| Xbox app | - | "Xbox needs an update, but we're unable to apply the update right now" | sign-in page |
| WU | 5 pending | 0 pending, build 26300.9711 | 0 |
| Store, Settings, Terminal, Brave launches | alive | alive | alive |
| VBS / HVCI | off | off | off |
| Edge / WebView2 | removed / 156 | same | same |
| processes / services / tasks | 90 / 90 / 196 | 93 / 89 / 198 | 94 / 93 / 202 |
| used RAM MB | 2397 | 2181 | 2099 |

The cause is not isolated yet. Each candidate below is an inference to test:
- Atlas Store policy (AutoDownload=2) and `auto-updates-disable`, applied before the Store ever updated itself;
- InstallService left Manual/Stopped;
- AME's first-boot `!appx` work.

## AME ISO mode as observed
- There is no headless path: ISO mode exists only in the GUI. The local lab `.apbx` is tagged "Malicious" in the
  sidebar (unsigned local build, inference).
- The ISO-mode requirement check covers only the build and system status. There are no Defender, Internet,
  antivirus or power checks.
- Pages: Include Drivers (network ticked by default), then credentials (user name, optional password, autologin).
  There is no TPM/BitLocker page.
- AME's own OOBE has 3 pages (EULAs, Installation Summary, Post Install Setup). The `ameoobe` service runs for about
  4 min on first boot.
- A UAC consent prompt blocks the Atlas first-logon script until it is answered.
