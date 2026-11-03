# KT-TWEAKS APBX catalog vs AtlasOS (input for EclipseOS)

Research date: 2026-11-02. Read-only, public sources only. No `.apbx`, `.exe`, `.zip` or binary was downloaded or executed.
Atlas baseline: local `C:\Atlas\src\playbook` (`playbook.conf`, `Configuration/**`), version 0.5.0, SupportedBuilds 26100 and 26200 only (`playbook.conf` lines 15-20).

## 0. Key findings

1. **KT-TWEAKS publishes no playbook of its own.** `KT-TWEAKS/KT-TWEAKS-APBX` is an Astro website plus `public/catalog.json` ("catalog of verified .apbx playbooks of KT WIRZADE", GitHub license field GPL-3.0, but README badge says MIT). It repackages third-party playbooks as GitHub Release assets: https://github.com/KT-TWEAKS/KT-TWEAKS-APBX , README: https://raw.githubusercontent.com/KT-TWEAKS/KT-TWEAKS-APBX/main/README.md
2. The catalog lists 9 playbooks (`catalog.json`, https://raw.githubusercontent.com/KT-TWEAKS/KT-TWEAKS-APBX/main/public/catalog.json): Atlas v0.5.0, Atom, FSOS-X R11H2, RapidOS 1.3, ReviOS 26.04, SapphireOS 0.0.3, SynergyOS 1.6.0, Vain 1.4.0, XOS 0.777. A 10th release exists, UltraOS 1.1.1 (`apbx-64-v1.1.1`, 166,424 bytes), but is not in `playbooks[]`: it shares `productCode` 64 with Atlas and `update-upload-catalog.mjs` replaces entries by `productCode`; `changes[]` shows both published the same day (inference).
3. The `.apbx` contents are only available as release assets. Therefore the "KT analysis" fields in `catalog.json` (`analysis.*`: action counts, `supportedBuilds`, `risks`) are the only KT-side text. Where an upstream public source repo exists I read its YAML as text (Atlas local, ReviOS, RapidOS, Atom, SynergyOS). No public source was found for FSOS-X, Vain, XOS, SapphireOS, UltraOS (searched GitHub search and the vendor sites vain.zone, atom-os.com, framesynclabs.com): these rows rely on KT's own `risks` strings and are marked "apbx-only".
4. **Integrity claim is real for Atlas:** KT's `AtlasPlaybook_v0.5.0-hotfix.apbx` sha256 `13c4d8e7...602d8` equals the digest of the same asset in the upstream release `Atlas-OS/Atlas` tag `0.5.0-hotfix` (`gh api repos/Atlas-OS/Atlas/releases`). For the other 8 playbooks the hash only proves "file unchanged since KT uploaded it", not that it matches the vendor (no vendor digest compared; Revi/Rapid/Atom builds not cross-checked).
5. **No catalog playbook is suitable as a base for EclipseOS goals.** Every one that I could read disables VBS/HVCI, and 8 of 9 disable or gut Defender or Windows Update by default (details below). Useful only as a source of individual tweaks (ReviOS and RapidOS are the most conservative, both license-compatible).
6. **KT WIRZADE (the tool) is a proprietary-derived fork of AME Wizard** (see section 11), not a playbook.

## 1. Catalog-level metadata

| Field | Value | Source |
|---|---|---|
| Repo license | GPL-3.0 (GitHub field); README badge MIT; LICENSE file 35 KB (GPL text) | `gh api repos/KT-TWEAKS/KT-TWEAKS-APBX`, README |
| Last push | 2026-10-22 | same |
| Install method | Post-install through KT WIRZADE or AME Wizard; ISO mode exists in the tool, per-playbook `SupportsISO` varies | WIRZADE README |
| Integrity | SHA-256 recorded in catalog, re-verified in GitHub Actions (`publish-apbx.yml`: reassemble parts, compare sha256 and size to manifest); no Authenticode/signature | https://raw.githubusercontent.com/KT-TWEAKS/KT-TWEAKS-APBX/main/.github/workflows/publish-apbx.yml |
| Quality CI | `npm audit`, actionlint, gitleaks only; no scan of playbook content in CI (the content analysis happens in a private panel) | `.github/workflows/quality.yml` |
| Issues | 7 (all PRs by the maintainer, none about playbook safety) | `gh api repos/.../issues?state=all` |

Catalog `analysis` summary (KT static analyzer, `engineVersion` 1.0.1; severity and score are KT's, treat as heuristic):

| Playbook | Version | Published | Size | `supportedBuilds` includes 26300 | Actions (reg/svc/cmd/apps/dl) | KT severity (score) | sha256 (first 12) |
|---|---|---|---|---|---|---|---|
| Atlas | 0.5.0 (hotfix) | 2026-10-08 (upstream 2025-10-21) | 48.0 MB | no (26100, 26200) | 421/13/104/49/0 | high (45) | 13c4d8e7fc0e |
| Atom | 0.0.8 | 2026-10-08 | 125 MB | no (…26100, 26200, 27000-28000) | 527/174/76/187/0 | high (100) | c790ef47d089 |
| FSOS-X R11H2 | 11.2 | 2026-10-08 | 436 MB | **yes** | 739/105/215/158/0 | high (100) | 75d0e6a716f7 |
| RapidOS | 1.3 | 2026-10-08 | 2.5 MB | no | 289/29/93/5/0 | high (49) | 73bc95cbfd04 |
| ReviOS | 26.04 | 2026-10-08 | 1.2 MB | no in catalog build (source `main` does list 26300) | 838/21/67/6/4 | medium (4) | 03c74cf3baec |
| SapphireOS | 0.0.3 | 2026-10-08 | 24.6 MB | no | 493/246/55/72/3 | high (100) | 6188b89c1eac |
| SynergyOS | 1.6.0 | 2026-10-08 | 19.7 MB | no | 189/60/37/67/2 | high (43) | 3a940cedf063 |
| Vain | 1.4.0 | 2026-10-08 | 33.5 MB | **yes** (also 28000) | 1178/79/231/291/21 | high (100) | bdcce57c970f |
| XOS | 0.777 | 2026-10-08 | 9.4 MB | **yes** (also 28000) | 516/52/146/1/0 | high (82) | 3d65dd63cfe8 |
| UltraOS | 1.1.1 | 2026-10-08 | 166 KB | unknown (not in catalog.json) | unknown | unknown | a5617ab2278f |

"Published" is KT's upload date, not the vendor's release date. Sizes and builds: `analysis.sizeBytes`, `analysis.supportedBuilds`.

---

## 2. Atlas v0.5.0 (control, repackaged unchanged)

- Metadata: author Atlas, GPL-3.0 (upstream), `optionsCount` 0 per KT (the analyzer does not parse Atlas FeaturePages; the local `playbook.conf` has radio pages for Defender, mitigations, auto-updates plus checkboxes), requirements `DefenderToggled, NoAntivirus, Internet, NoPendingUpdates, UCPDDisabled, PluggedIn` (local `playbook.conf` 22-29).
- Hash identical to the upstream release asset (finding 4). So this is the same artifact as `C:\Atlas`, nothing new to compare.
- KT `risks`: `bcdedit /timeout 10`, `bootmenupolicy legacy`, DiagTrack ETL deletion in `Configuration/tweaks/privacy/telemetry/disallow-data-collection.yml` (KT flags these as "reboot/shutdown" or "boot data" commands; benign).
- Baseline facts used for the comparisons below (local files): Defender default enabled (`defender-enable`, `playbook.conf` 57-67); mitigations default (`mitigations-default`); `auto-updates-disable` option (`Configuration/tweaks/qol/windows-update/disable-auto-updates.yml`); VBS/HVCI off via checkbox `disable-core-isolation` (`Configuration/tweaks/scripts/script-core-isolation.yml`, `Executables/AtlasModules/Scripts/ScriptWrappers/ConfigVBS.ps1`); Store kept, `Microsoft.XboxApp*` (deprecated console companion only) removed in `src/playbook/Configuration/atlas/appx.yml:42`; Store auto-update disable is a separate QoL tweak (`Configuration/tweaks/qol/disable-store-auto-updates.yml`); `Win32PrioritySeparation` 0x26 (`Configuration/tweaks/performance/system/win32-priority-separation.yml`).

---

## 3. ReviOS Playbook 26.04 (the closest to Atlas, best documented)

Source (text): https://github.com/meetrevision/playbook (`src/playbook.conf`, `src/Configuration/**`). Repo `main` is newer (release 26.10 on 2026-10-09) than the catalog build (26.04): findings below are from `main` and may differ from the 26.04 asset (inference).

**Metadata**
- Author Revision (revi.cc), version in conf `1.0`, catalog 26.04; repo license **CC-BY-SA-4.0** (`gh api repos/meetrevision/playbook`; the FSF/CC list treats CC BY-SA 4.0 as one-way compatible into GPLv3, so code can be adapted, derivative must stay GPL; check before copying (inference)). Last push 2026-10-21.
- SupportedBuilds in source `main`: 19044, 19045, 22631, 26100, 26200, 28000, **26300**; catalog build lists up to 26200.
- Requirements: `DefenderToggled, NoPendingUpdates, NoAntivirus, Internet, PluggedIn`. `UpgradableFrom any`. `SupportsISO` true (ISO: DisableBitLocker true, DisableHardwareRequirements true).
- Options (`playbook.conf`): browser radio (Brave default, Firefox, none); Defender radio **default `disable-defender`**; hibernate radio default disable (also kills Fast Startup); checkboxes default on: remove Edge, OneDrive, AI (Recall/Copilot), Teams, Photos, Dev Home, Your Phone; **remove Xbox apps default off**; wallpaper, dark mode, legacy context menu, no transparency, clear Start pins on; Disable automatic maintenance off.
- Bundled/downloaded binaries: downloads and silently runs `RevisionTool-Setup.exe` from `github.com/meetrevision/revision-tool/releases/latest/download` (no hash, "latest") and `vc_redist.x64.exe` from `aka.ms` (`Tasks/start.yml`); Brave from GitHub latest; a prebuilt `hosts` file overwrites `%WINDIR%\System32\drivers\etc\hosts` (blocks 39 Microsoft/telemetry hostnames; no Store/Xbox/WU names seen in the first lines, count of lines matching `xbox|microsoft|windowsupdate|store` is 39, all telemetry-looking in the head sample; full audit not done).

| Area | What it changes | Difference vs Atlas | Positive | Negative / risk | Impact (gaming / security / Store-Xbox) |
|---|---|---|---|---|---|
| Windows Update | `revitool tweaks updates wu-pause-updates enable`; drivers via WU disabled (`wu-drivers disable`); `DODownloadMode=0`; `AllowBuildPreview=0`; disables tasks `UpdateOrchestrator\Schedule Scan`, `Start Oobe Expedite Work`, `WindowsUpdate\Scheduled Start`; deletes `HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate` key in `revert.yml` (`registry/updates/updates.yml`, `final.yml` via FINALIZE.cmd, `revert.yml`) | Stricter than Atlas default (Atlas only sets notify-only policy); pause end date set by closed-source tool (inference) | Fewer surprise reboots/driver swaps | Scheduled scan disabled means no automatic security patches; pause duration controlled by an opaque binary | Security: worse patch cadence; Store/Xbox: depends on WU being refreshed by the user before use |
| Store/AppX removals | ~42 packages removed through `revitool appx --all-users --remove` (Camera, Alarms, Maps, Sticky Notes, Mail, People, Bing*, Solitaire, Feedback Hub, Get Help, To Do, Clipchamp, Teams, Office hub, Paint 3D, Edge game assist, etc.) plus Photos/Dev Home/Your Phone; **Store, App Installer, Gaming App, Xbox identity are not in the list**; then restores VCLibs via `revitool msstore-apps --id 9NBLGGH3FRZM,9NBLGGH4RV3K` (`packages/appx.yml`) | Stricter than Atlas (Atlas keeps Camera/Maps etc., `Configuration/atlas/appx.yml`) | Store framework deps explicitly re-installed (good pattern) | Removing `Microsoft.WindowsCamera`, Photos breaks apps expecting them; `MicrosoftWindows.Client.WebExperience` removal kills widgets | Store/Xbox: intact by default. Re-install of VCLibs requires Store reachable |
| Xbox / Gaming Services | Optional (default off) `winpackage --install xbox-removal` + `ms-gamebar` protocol stub to `systray.exe`; `GameDVR_FSEBehaviorMode=0`; reverts `GameDVR AppCaptureEnabled` delete (`packages/win-sxs.yml`, `final.yml`, `revert.yml`) | Looser default than Atlas? Same intent (Atlas `disable-game-bar.yml` disables Game Bar); Revi adds destructive WinSxS Xbox removal as opt-in | Opt-in; Xbox kept by default | Opt-in path removes WinSxS Xbox packages, unrecoverable without reinstall | Gaming Services not touched by default (not in lists) |
| Defender | **Default disabled**: `revitool tweaks security defender disable --force`; hides tray, reporting off, SmartScreen off for Edge/apps, `HideSystray`; UI option `enable-defender` exists (`packages/win-sxs.yml`, `registry/security/security.yml`) | **Looser** than Atlas (Atlas default `defender-enable`) | User can choose Enable | Default insecure, implemented by closed-source tool | Security: negative; anti-cheat: some (Vanguard/EAC) accept it, but Defender-off + HVCI-off combination fails FACEIT-style checks (general knowledge (inference)) |
| VBS/HVCI/Core Isolation, CPU mitigations | `revitool tweaks security vbs disable` ("automatically disables Memory Integrity (HVCI)") with comment "Disabling VBS improves gaming performance" (`registry/security/vbs.yml`, unconditional, no option); `revert.yml` deletes legacy `FeatureSettings*` (mitigations back to default) and re-enables `VulnerableDriverBlocklistEnable=1`; ISO `bypass-requirements.yml` sets `LabConfig` Bypass TPM/SecureBoot/CPU/RAM | **Looser** than Atlas (Atlas has `disable-core-isolation` as an option, ticked by default per project lab facts; Revi is unconditional with no UI choice) | Mitigations left default, blocklist kept on | VBS/HVCI forced off | Anti-cheat: Vanguard-class titles need HVCI/Secure Boot; forced off is a regression for EclipseOS goals |
| Services | Disabled (start=4): `dam, GpuEnergyDrv, NetBT, Telemetry, diagnosticshub.standardcollector.service, WerSvc, DiagTrack, wisvc, PcaSvc, WdiServiceHost, WdiSystemHost, tcpipreg, Wecsvc, UCPD`; `edgeupdate` manual; `condrv` auto; service grouping `recommended` via revitool (`services.yml`, `final.yml`) | Similar to Atlas; `wisvc` (Insider) and `UCPD` additional (Atlas has `UCPDDisabled` as a requirement, i.e. user pre-disables UCPD) | Fewer background services | `WerSvc/PcaSvc` off hides crash diagnostics | Neutral for Store/Xbox (no AppXSvc/ClipSVC/InstallService/GamingServices touched) |
| Scheduled tasks | Disables CEIP (`Consolidator, UsbCeip, KernelCeipTask`), Compatibility Appraiser, AitAgent, WER QueueReporting, MemoryDiagnostic, Power Efficiency Diagnostics, DiskDiagnostic, UpdateOrchestrator tasks, Office tasks, `UCPD velocity` (`FINALIZE.cmd`, `services.yml`, `final.yml`) | Similar / slightly stricter than Atlas | Less telemetry | UpdateOrchestrator disables reduce update reliability | Neutral |
| Telemetry/privacy | IFEO `Debugger=taskkill.exe` for `CompatTelRunner, AggregatorHost, DeviceCensus, FeatureLoader, BingChatInstaller, BGAUpsell, BCILauncher` (`registry/system/ifeo.yml`); removes telemetry WinSxS package (`winpackage --install telemetry-removal`); hosts blocklist; `registry/privacy/*`; `setx *_TELEMETRY_OPTOUT` | Stricter (Atlas uses policy and service settings, not IFEO, not WinSxS removal) | Strong telemetry suppression | IFEO debugger hijack and component-store removal are fragile across feature updates; hosts overwrite wipes user entries | Neutral; the WinSxS removal hits servicing (CBS) and could break cumulative updates (inference) |
| Power/CPU/timer/latency | `revitool tweaks performance powerplan enable`; `intel-tsx enable`; NTFS last-access and 8.3 names off; `Disable-MMAgent -mc`; `NetworkThrottlingIndex=10`; IFEO `PerfOptions` CPU/IO priority (SearchIndexer/ctfmon low, lsass/fontdrvhost/sihost); Superfetch re-enabled in revert; bcdedit `bootmenupolicy Legacy`; `useplatformclock` and `disabledynamictick` **deleted** (commented out `useplatformtick/disabledynamictick` because of a laptop sleep bug, issue #167) (`FINALIZE.cmd`, `final.yml`, `kernel.yml`, `power.yml`, `multimedia.yml`) | Roughly same as Atlas; Revi explicitly does **not** force timer tweaks | Conservative timer handling; `intel-tsx enable` re-enables TSX (disabled by default by Windows for security on some CPUs) | TSX re-enable reintroduces a speculative-execution attack surface (inference) | Gaming: small; Hibernate/Fast Startup off default (radio) |
| Network | `ipconfig /flushdns`, hosts overwrite; `netsh int tcp ... congestionprovider=default` revert | Weaker than Atlas networking tweaks | Few risks | Hosts overwrite | Neutral |
| UI/shell/Explorer | Legacy context menu, dark mode, no transparency, Start pins cleared, taskbar/search/notifications registry, wallpaper, deprovisioned apps list (`registry/explorer/*`, `registry/misc/deprovisioned-apps.yml`) | Similar to Atlas QoL | Cosmetics opt-out | Many defaults on | Neutral |
| Edge/browsers | Edge removed by default via `EDGE.ps1` which creates fake `SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdge.exe`, sets `windir=""` and runs uninstaller with `--force-uninstall --delete-profile`; Brave/Firefox installed | Atlas: uninstall-edge optional (`playbook.conf` 124) | Browser choice | Hack-based removal; WebView2 handling mode exists; can break apps relying on Edge | Store: Store UI uses WebView2, keep it (inference) |
| OneDrive | Removed by default (ONED.cmd, WinSxS `onedrive-removal`) | Same as Atlas option | | WinSxS removal not reversible | Neutral |
| Revert/uninstall path | `revert.yml` (`onUpgrade: true`) rolls back legacy tweaks of older playbook versions only; no user-facing uninstall; some tweaks via `revitool` have enable/disable CLI | Weaker than Atlas (Atlas ships revert via AtlasDesktop scripts) | | WinSxS removals have no revert | Rollback must be a reinstall/restore |

**Red flags (ReviOS):** relies on `revitool.exe` downloaded from GitHub "latest" with no pinned hash, run as elevated (TrustedInstaller chain); Revision Tool source is public at github.com/meetrevision/revision-tool (not audited here); defaults disable Defender and VBS; installer pulls VCRedist over `aka.ms` (HTTPS Microsoft, acceptable). No ad-host downloads. KT `risks`: only "5 downloads need internet" (severity medium, score 4).

---

## 4. RapidOS 1.3 (Rapid Team)

Source (text): https://github.com/rapid-community/RapidOS (`RapidOS Sources/`). License **AGPL-3.0** (GPL-3.0 compatible via AGPL section 13). Repo push 2026-06-28; `playbook.conf` is Version 1.3 (matches catalog).

**Metadata:** SupportedBuilds 19045, 22621, 22631, 26100, 26200 (no 26300; description claims 22H2-25H2). Requirements `NoAntivirus, DefenderToggled, NoTweakware`. `Overhaul true`, `SupportsISO true` (DisableBitLocker, DisableHardwareRequirements). `UpgradableFrom 1.1`.
Options: **opt-in defaults off** for Edge removal, other browser, .NET 3.5, Store updates off, Defender off, firewall off, location off, sync off; default on: DirectX, VCRedist, remove Teams/OneDrive/Office/Your Phone, theme, clear templates, classic context menu.
Bundled binaries (listed in repo tree): `PolFileEditor.dll`, `YamlDotNet.dll`, `NetBlock.exe` (closed? source unknown), 64 KB `Defender.ps1`, a Toolbox with many `.bat` files.

| Area | What it changes | Difference vs Atlas | Positive | Negative / risk | Impact |
|---|---|---|---|---|---|
| Windows Update | Pause feature/quality/updates for **10 years** via `HKLM\...\WindowsUpdate\UX\Settings`; `AUOptions=2` (notify); DevHome/Outlook orchestrator updates blocked; ReserveManager off (`Core/System/Updates.yml`); Toolbox `.bat` to enable/disable (`3. System Settings/Windows Updates`) | Looser than Atlas default | Toggle scripts provided | 10-year pause = no patches unless user resets | Security: negative; Store/Xbox: WU not blocked at service level |
| Store/AppX removals | `AppX.ps1` list: PowerBI, PowerAutomate, Todo, Skype, People, Cortana, Mail/Calendar, Solitaire, Disney, Spotify, Yandex.Music, DevHome, Feedback Hub, QuickAssist, ParentalControls, 3D Viewer, Family, **Paint**, MixedReality, Clipchamp, Whiteboard, SecureAssessment, ZuneVideo, Advertising, BingNews/Weather, Maps (`Debloat/AppX.yml`); **Store untouched** | Similar to Atlas | Store kept | Removes Paint, Maps | Store OK |
| Xbox / Gaming Services | Removes `Microsoft.XboxGamingOverlay` and `Microsoft.Edge.GameAssist` on **everything except AMD dual-CCD X3D CPUs** (7900X3D/7950X3D/9900X3D/9950X3D, where Game Bar is needed for core parking) (`Debloat/AppX.yml`); Game Bar startup panel off | Stricter than Atlas (Atlas disables, not removes, Game Bar) | CPU-aware exception is a good idea | Gamebar removal breaks Game Bar overlays, `ms-gamebar` links and Xbox capture | Xbox app (`GamingApp`) and Gaming Services kept (not listed) |
| Defender | **Opt-in** (`disable-defender`, default off): `Defender.ps1 -disable_av -delayedrestart` guarded by a MessageBox "at your own risk" (`System/Security.yml`); also sets `VerifiedAndReputablePolicyState=0` unconditionally | Same default as Atlas (Defender stays on), plus disable path | Safe default | `Defender.ps1` is 64 KB, not reviewed; unconditional `VerifiedAndReputablePolicyState=0` weakens Smart App Control | Security: neutral by default |
| VBS/HVCI/CPU mitigations | **Unconditional** `EnableVirtualizationBasedSecurity=0`, `HypervisorEnforcedCodeIntegrity Enabled=0` (`System/Security.yml`); Toolbox has "Disable Core Isolation (Default)" and enable script; FTH disabled; Vulnerable Driver Blocklist toggle script (`5. Security Settings`) | Looser than Atlas default (Atlas needs the checkbox) | Reversible via Toolbox | Forced off | Anti-cheat: negative |
| Services | disables `AppMgmt, MSDTC, PcaSvc, SEMgrSvc, TrkWks, DiagTrack, diagsvc, NvTelemetryContainer, Telemetry, TroubleshootingSvc, uhssvc, NetBT`; manual `DoSvc, LanmanServer, MapsBroker, SSDPSRV`; `LimitNetwork` on `UdkUserSvc, pla, Wecsvc, WerSvc, wercplsupport`; `GpuEnergyDrv` off on desktops only (`System/Services.yml`) | Similar | Laptop awareness | `DoSvc` manual impacts WU/Store download speed? (Delivery Optimization is used by Store; inference) | Neutral |
| Scheduled tasks | CEIP, Appraiser, MareBackup, ProgramDataUpdater, StartupAppTask, AitAgent, etc. via COM Task Scheduler (`Privacy/Tasks.yml`) | Same | | | Neutral |
| Telemetry/privacy | `Privacy/Core, IFEO, Location, Recall, AppCompat, WER, Console`; advertising module; `Advertisements.ps1` | Similar | | | Neutral |
| Power/CPU/timer | `DisablePageCombining=1`; MMCSS: `SystemResponsiveness=10`, Games `Scheduling Category=High`, desktop-only `NetworkThrottlingIndex=0xFFFFFFFF`, `SchedulerPeriod`, `LazyModeTimeout` (state exported to JSON for revert); bcdedit `bootmenupolicy Legacy`, `debug no`, `timeout 15`; startup delay 0 (`System/Kernel.yml`, `Boot.yml`); MPO toggle in Toolbox | Similar to Atlas `config-mmcss.yml` | MMCSS state saved for revert | | Gaming: small positive |
| Network | Firewall off (opt-in), SChannel cipher/key-exchange/renegotiation/SMB hardening, NetBT off (`Network/*`, `Network/Security/*`) | Atlas has less TLS/ciphers hardening | Hardening is a plus | Disabling TLS ciphers can break legacy servers | Neutral |
| UI/shell | Theme, taskbar, start, explorer, context menu | Same | | | Neutral |
| Edge/browsers | Edge removal opt-in; Brave, Firefox, Thorium, Chrome installers (`Software/Browsers/*.yml`) | Same as Atlas | | | |
| OneDrive | Removed default | Same | | | |
| Revert/uninstall | Toolbox batch pairs (enable/disable) for updates, Store updates, location, UAC, firewall, core isolation, driver blocklist, MPO, AI, widgets; `Maintenance/Main.yml` repair tasks; description: "after installing you can undo it" | **Stronger than Atlas** (Atlas has AtlasDesktop scripts but fewer pairs) | Best revert story in the catalog | Toolbox includes "Disable UAC", "Disable Firewall" scripts | |

**Red flags (RapidOS):** `NetBlock.exe` in `RapidScripts` (closed binary, purpose unclear), unconditional UAC change `PromptOnSecureDesktop=0` and `LowRiskFileTypes=.exe;.bat;.cmd;.vbs;.msi;.reg;.ps1` (weakens the Attachment Manager warnings) and `SaveZoneInformation=1` in `Security.yml`; `net accounts /maxpwage:unlimited` (password never expires, security-negative); VBS/HVCI forced off. Smallest package (2.5 MB) so easy to audit.

---

## 5. Atom Playbook 0.0.8 (Project Atom)

Source (text): https://github.com/ProjectAtomOS/Atom-Playbook (MIT, last push 2026-10-05). Repo `playbook.conf` says Version **0.0.5** vs catalog **0.0.8**: source may lag the asset; findings below are from the repo (inference for 0.0.8). KT risks for 0.0.8 mention `Final (10-final.yml)` schtasks delete of `AppxAllUserStore\UScheduler`.

**Metadata:** author Project Atom; description "Strip Windows to the best possible. Lowest CPU, RAM and disk usage."; SupportedBuilds in catalog: 19044, 19045, 22000, 22621, 22631, 23620, 26100, 26200, 27000-28000 (**not 26300**); requirements `Internet, DefenderToggled, NoAntivirus, PluggedIn`; options: Defender radio (disable/enable), remove Edge (on), disable updates (on), LZX compression apply/skip. Bundled binary: `NSudoLC.exe` (140 KB); PostInstall folder with many `.reg`/`.bat`/`.lnk` (e.g. "4 Disable UAC.reg", "Disable Windows Defender.bat", "Disable Xbox.bat"). 125 MB package.

| Area | What it changes | Difference vs Atlas | Positive | Negative / risk | Impact |
|---|---|---|---|---|---|
| Windows Update | `option: disable-updates` (default on): `NoAutoUpdate=1`, `AUOptions=1`, **services `wuauserv, UsoSvc, WaaSMedicSvc, BITS` start=4**, deletes tasks `WindowsUpdate\Scheduled Start` and `sih` (`08-updates.yml`) | **Far stricter** than Atlas (Atlas leaves services runnable) | | WU and BITS dead = no patches, no driver updates, **Store installs and updates rely on BITS/WU infrastructure (inference)** | Store/Xbox: breaks updates; security: negative |
| Store/AppX removals | `13-store.yml` (**unconditional**, included in `main.yml`): kills Store processes, disables `InstallService, TokenBroker, WalletService, WSService, AppXSvc, ClipSVC`, removes `Microsoft.WindowsStore*, StorePurchaseApp*, DesktopAppInstaller*, XboxIdentityProvider*, Xbox.TCUI*, XboxGamingOverlay*, Xbox*, StoreExtensions*`, **deletes `WindowsApps\Microsoft.WindowsStore*` folders**, sets `RemoveWindowsStore=1`, `DisableStoreApps=1` (title "Fully remove Windows Store and all its components") | **Opposite of EclipseOS goal** | | Store, winget (DesktopAppInstaller) and Xbox identity permanently removed; `AppXSvc`/`ClipSVC` off breaks all UWP/MSIX | Store/Xbox: destroyed |
| Xbox / Gaming Services | `02-appx.yml` also removes `Microsoft.Xbox*`, `GamingApp`, `XboxApp`, `Edge.GameAssist`; PostInstall "Disable Xbox.bat"; README lists `XboxGipSvc` as removable | Far stricter | | Xbox app, Game Pass and Gaming Services-dependent titles unusable | Gaming: breaks MS Store/Xbox titles |
| Defender | `03-defender.yml` (option `disable-defender`): **deletes** services `WinDefend, Sense, WdNisSvc, SecurityHealthService, SgrmBroker, SgrmAgent, MsSecCore, webthreat*, MDCoreSvc`; removes SecHealthUI and files `SecurityHealth*.exe`; SmartScreen off everywhere, `VulnerableDriverBlocklistEnable=0`, PUA off, DISM disables default definitions (comment: "user-mode services only, zero kernel driver changes") | Far stricter than Atlas | | Irreversible without repair; SmartScreen and Vulnerable Driver Blocklist off | Security: very negative |
| VBS/HVCI/CPU mitigations | `05-performance.yml`: `bcdedit hypervisorlaunchtype off`, `EnableVirtualizationBasedSecurity=0`, `HyperVVirtualizationBasedSecurityOptout=1`, HVCI/CredentialGuard/SystemGuard/KernelShadowStacks Enabled=0, `Set-ProcessMitigation -System -Disable`, `FeatureSettingsOverride=3` / Mask 3 (disables Spectre/Meltdown mitigations), `SCMConfig EnableSvchostMitigationsPolicy=0`, `nx optin`, `disableelamdrivers yes`, `recoveryenabled no` | **Far looser** than Atlas (Atlas' mitigations option is off by default) | | Everything security-related off, unconditional | Anti-cheat: fails VBS/HVCI/ELAM/Secure Boot-adjacent checks |
| Services | `01-services.yml` (13 KB) disables a large set (README lists examples such as XboxGipSvc) | Stricter | | Not enumerated here | Unknown |
| Scheduled tasks | Deletes many (Defender, InstallService SmartRetry, WS `WSRefreshBannedAppsListTask`, WU) | Stricter | | Deleting rather than disabling prevents re-enable | |
| Telemetry/privacy | `04-privacy.yml` | Similar | | | |
| Power/CPU/timer | `SystemResponsiveness=0`, `Win32PrioritySeparation=38 (0x26)`, `PowerThrottlingOff=1`, `CsEnabled=0` (Modern Standby off), `HiberbootEnabled=0`, hibernate off, `stornvme IdlePowerMode=0`, `bcdedit disabledynamictick yes` + `useplatformclock` deleted, `Disable-MMAgent -mc`, RSS queues=2; `12-gaming.yml` adds `useplatformtick yes`, `tscsyncpolicy enhanced` (per KT risks) | Same Win32PS as Atlas; much more aggressive otherwise | Timer tweaks are common gaming practice | `disabledynamictick` / `useplatformtick` have known power/sleep side effects (Revi comment above) | Gaming: marginal |
| Network | `11-networking.yml` (22 KB) | Stricter | | not read | |
| UI/shell | `06-ui.yml`, wallpaper; README "Set Start menu to left" etc. | Similar | | | |
| Edge/browsers | `07-edge.yml` removes Edge by default | Same as Atlas option, but default on | | | |
| OneDrive | Deprovisioned via AppxAllUserStore keys | Same | | | |
| Revert/uninstall | README: "revert via System Restore" only (recommends restore point first) | **Weaker** than Atlas | | | |

**Red flags (Atom):** removes Store/winget/Xbox identity by default; deletes AppX package folders and Windows Update services; `NSudoLC.exe` bundled (NSudo is a legitimate tool but is a binary run as TrustedInstaller); "4 Disable UAC.reg" shipped; MIT license (compatible, but the sources lag the asset). KT severity: high (100).

---

## 6. SynergyOS 1.6.0 (Kwanteks)

Source (text): https://github.com/Synergy-Tweaks/SynergyOS (no `LICENSE` file, GitHub license field null, so **unlicensed = all rights reserved**; cannot copy), last push 2026-11-02. Version in conf not checked; catalog 1.6.0. Builds: 19044...26100, 26200, 22635 (**not 26300**). Options: UAC enable/disable, Defender disable (`disable-defender`), others. 19.7 MB.
Bundled binaries (repo): `Autoruns.exe` (2.5 MB), `DeviceCleanup.exe`, `GoInterruptPolicy.exe` (7.4 MB), `PowerRun.exe`, `RunAsTI.reg`, plus a `PROVENANCE.md` for the tools; `Synergy.nip` Nvidia profile.

| Area | What it changes | Difference vs Atlas | Positive | Negative / risk | Impact |
|---|---|---|---|---|---|
| Windows Update | Pauses feature/quality updates to **2038-01-19**; `NoAutoUpdate=1`, `AUOptions=2`, **`DoNotConnectToWindowsUpdateInternetLocations=1`**, `AutomaticMaintenanceEnabled=0`; Store `AutoDownload=2`, `DisableOSUpgrade=1`; driver updates disabled (`updates/update.yml`, `updates/driver.yml`) | Stricter than Atlas | | `DoNotConnectToWindowsUpdateInternetLocations` blocks the WU endpoint for all online scans (inference: also hits Store's WU-based app updates) | Store/Xbox updates unreliable |
| Store/AppX removals | `package/appx.yml`, `package/components.yml` (not read in detail) | Unknown | | | Needs a check before any reuse |
| Xbox / Gaming Services | SOS "Xbox / Disable Xbox Services.bat" toggle | Opt-in script | | | |
| Defender | `DisableDefender.ps1`: installs `C:\Windows\NoDefender.cab` after **adding a root certificate** (`8A334AA8052DD244A647306A76B8178FA215F344`) to `HKLM\...\SystemCertificates\ROOT` and `Add-WindowsPackage -IgnoreCheck`; plus `DisableDefenderServices.bat` (Z-AME NoDefender package, same family as the KT WIRZADE `Z-AME-NoDefender-Package` cab) | Far stricter | | **Installs a trusted root CA on the machine** to sideload a CAB (the CA stays trusted afterwards) | Security: very negative |
| VBS/HVCI/CPU mitigations | SOS `VBS/Disable VBS (default).bat`: `EnableVirtualizationBasedSecurity=0`, HVCI 0, also disables CFG XFG/export-suppression/exception-chain validation; `Mitigations/off.bat` sets all `Set-ProcessMitigation -System -Disable`, kernel `MitigationOptions`, `FeatureSettingsOverride=3`, FTH off | **Far looser** | Toggle scripts "on.bat" exist | Default OFF | Anti-cheat: negative |
| Services | `services.yml`; "Default Services" and "SynergyOS Services" `.lnk` imports as TrustedInstaller | Stricter | Revert via default services import | | |
| Scheduled tasks / telemetry | `registry/privacy.yml` | Similar | | | |
| Power/CPU/timer | Win32PrioritySeparation variants (16-28, default 24); GoInterruptPolicy for MSI interrupts; Nvidia profile | Extra | | Userland tools unaudited | |
| Network / UI / Edge | `custom.yml`, `settings.yml`, `software.yml` (installs .NET 8 Desktop Runtime via `aka.ms/dotnet/...` per KT risks) | Similar | | | |
| Revert/uninstall | SOS folder toggles for Bluetooth, Print, UAC, VBS, Wi-Fi, Xbox, mitigations (enable/disable pairs) | Stronger than Atom | | | |

**Red flags (Synergy):** unlicensed repo; sideloaded NoDefender CAB with a root cert; mitigations/VBS off by default; `UAC` option can set `EnableLUA=0`, `ConsentPromptBehaviorAdmin=0` (`custom.yml`); 2038 pause; bundled binaries (provenance doc exists but not verified); "enable-uac" branch also sets `ValidateAdminCodeSignatures=0`. KT severity: high (43), only flags .NET downloads.

---

## 7. FSOS-X R11H2 (FrameSync Labs)  (apbx-only)

No public source found; website https://framesynclabs.com (no repo link). Facts below come only from KT `analysis` (https://raw.githubusercontent.com/KT-TWEAKS/KT-TWEAKS-APBX/main/public/catalog.json) and the visible head of scripts in `risks`. 436 MB, 199 files, tasks `phase2-strip`, `phase3-harden`, `phase4-gaming`, `phase5-apply`. SupportedBuilds include **26300**. `optionsCount` 0.

| Area | What it changes (per KT `risks` text) | Difference vs Atlas | Impact |
|---|---|---|---|
| Store/AppX | `phase2-strip.yml`: PowerShell with `$patterns = @('Microsoft.WindowsStore','Microsoft.StorePurchaseApp')` + `Get-AppxPackage -AllUsers` (removal intent, tail truncated: inference); `phase5-apply.yml` handles `MicrosoftWindows.Client.CBS`, `Microsoft.UI.Xaml.CBS` packages | Opposite of EclipseOS goal | Store likely removed (inference) |
| Defender | `$svcList = @('Sense','WinDefend','MsSecCore','wscsvc','WdFilter','WdNisDrv','WdNisSvc','MsSecWfp','MsSecFlt','wtd','webt...')` (includes **kernel drivers WdFilter/WdNisDrv/MsSecFlt/MsSecWfp**); removes `System32\SecurityHealth`, Defender scheduled task folder, files in `System32\drivers`; `Take-ClsidOwnership` takes ownership of CLSID keys | Far stricter than Atlas | Security: removal of kernel-mode Defender components |
| VBS/HVCI | `bcdedit /set hypervisorlaunchtype off` in phase2; `phase3-harden` has a `$stock` table of Hyper-V services (`HvHost=3, hvservice=0, hvcrash=3, hyperkbd=3 ...`) (intent unclear: reset to stock or disable; inference) | Looser | Anti-cheat negative |
| NIC / gaming | `phase4-gaming`: loops `HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-...}` (NIC class: interrupt moderation/power registry values) | Extra | Neutral |
| Autoruns | clears `HKU\.DEFAULT\...\Run` | | |
| Others | 739 registry, 105 services, 158 apps actions | Larger than Atlas | |

**Red flags (FSOS-X):** 436 MB closed package, commercial upsell ("Pro-level PC optimizations available now. Visit framesynclabs.com"), cannot be audited; removes Defender kernel drivers and (likely) Store. KT severity: high (100).

---

## 8. Vain playbook 1.4.0 (vain.zone)  (apbx-only)

No public source found. 33.5 MB, 54 files, `Configuration/custom.yml` (1,178 registry, 291 apps, 21 downloads). SupportedBuilds include **26300** and 28000.

| Area | What it changes (per KT `risks`) | Difference vs Atlas | Impact |
|---|---|---|---|
| Defender | file removal in `ProgramData\Microsoft\Windows Defender` and `System32\drivers` | Far stricter | Security: negative |
| VBS/HVCI/mitigations | `bcdedit hypervisorlaunchtype off`, `vm no`, `vsmlaunchtype Off`, `integrityservices disable`, `nx optin`, `disableelamdrivers yes`, `recoveryenabled no` | **Far looser** | Anti-cheat: fails |
| Timer | `disabledynamictick yes`; `useplatformclock`/`useplatformtick` deleted | Common | Marginal |
| Downloads (21) | VC++ redists (2005-2013/14 from `download.microsoft.com` and `aka.ms`), DirectX June 2010 redist, 7-Zip and Open-Shell (GitHub), Firefox/Firefox Dev (mozilla.org), Chrome MSI (dl.google.com), Brave (laptop-updates.brave.com), Mercury, Helium (GitHub) | Atlas downloads fewer items | All HTTPS from vendor hosts |
| NIC | Loops NIC class registry | | |
| Store/Xbox | not visible in KT `risks` | Unknown | Needs evidence |

**Red flags (Vain):** no source, 1,178 registry + 291 app actions; Defender driver deletion; many third-party installers (no hash). KT severity: high (100).

---

## 9. XOS Playbook v0.777  (apbx-only)

No public source found (Discord-only vendor). 9.4 MB, 30 files, `Configuration/custom.yml`. SupportedBuilds very broad (17763 ... 26200, **26300**, 28000).
- Defender: script `sc.exe stop MDCoreSvc; sc.exe stop WinDefend; sc.exe stop WdNisSvc; ... reg add HKLM\...` (KT flagged as "removes scheduled tasks"); `runasti.reg` imported to `HKCR\RunAsTI` (TrustedInstaller launcher).
- Boot: `bcdedit /deletevalue useplatformclock, useplatformtick`; `bootmenupolicy legacy`; `timeout 10`; description string.
- 516 registry, 52 services, 146 commands. Store/Xbox/VBS: not visible in `risks`.

**Red flags (XOS):** unreadable; Defender service shutdown plus registry. KT severity: high (82).

---

## 10. SapphireOS 0.0.3 and UltraOS 1.1.1  (apbx-only)

**SapphireOS** (24.6 MB, `Configuration/SapphireOS/tweaks/commands.yml`, 246 services, 3 downloads): bcdedit `disabledynamictick yes`, `recoveryenabled no`, `disableelamdrivers yes`, `integrityservices disable`, `hypervisorlaunchtype off`, `vm off`, `vsmlaunchtype off`; installs .NET Desktop Runtime 8.0.20 (`builds.dotnet.microsoft.com`), VC++ AIO (`github.com/abbodi1406/vcredist` unofficial third-party repack, no hash) and Open-Shell. No website. Red flags: unofficial VC++ AIO repack; VBS/integrity off.

**UltraOS 1.1.1**: only a release asset (166 KB), no catalog analysis (displaced by Atlas productCode collision). Not analyzable.

---

## 11. KT WIRZADE (the tool) and its trust model

Source (text, MIT, "Author kelvenapk"): https://github.com/KT-TWEAKS/KT-WIRZADE ; releases v1.0.1 (2026-09-07) and v1.0.2 (2026-10-22): single x64 `.exe` (31.7 MB), `SHA256SUMS.txt`, manifest JSON.

- It is "a customized and expanded version of AME Wizard" (README). AME Wizard (Ameliorated LLC) is not open source; the repo contains `Core/`, `Interprocess/`, `KTWirzade.Shared/` with the AME-style User -> Administrator -> TrustedInstaller IPC chain, which suggests derived from decompiled or leaked code (inference; license status of that reuse is unclear and I would not depend on it).
- Prebuilt binaries committed in source: `Core/Helper/x64/Release/client-helper.dll`, `KTWirzade.CLI/Properties/Z-AME-NoDefender-Package*.cab` (x64 and ARM64), `7za.exe/dll`, `NSudoLC.exe`, many .NET dlls under `KTWirzade.GUI/src/Resources/`, `ProcessInformer.7z`, `CLI-Resources.7z`. Several are opaque.
- Verification model: before use the app sends the SHA-256 (and ProductCode) to `licensing-site.vercel.app/api/verify` (private Vercel service) and shows verified/malicious/unverified; README admits "SHA-256 verifies file integrity but does not replace an Authenticode signature". The EXE itself is unsigned (no signature claim in README).
- Extra features that matter for risk: ISO mode with "fresh install bypass" and version-bypass prompts, rollback sessions in `C:\ProgramData\AME\Rollbacks` (arbitrary commands not reversible), updater that downloads an EXE from GitHub releases and checks hashes (`SHA256SUMS.txt` fallback), CLI option-merge bug fixed in 1.0.1 ("CRITICAL: CLI options overwrite").
- Relevance for EclipseOS: EclipseOS targets AME Wizard (project facts); KT WIRZADE is not a dependency and should not be recommended to users.

---

## 12. Cross-playbook summary vs EclipseOS goals

| Goal | Atlas | ReviOS | RapidOS | Atom | Synergy | FSOS/Vain/XOS/Sapphire |
|---|---|---|---|---|---|---|
| Store + Xbox keep working | yes (Store kept; Xbox console companion removed) | yes by default (Xbox removal opt-in; VCLibs restored) | yes (Game Bar removed except X3D CPUs) | **no** (Store/winget/Xbox removed, AppXSvc/ClipSVC off) | unknown (appx.yml unread), WU endpoint blocked | FSOS likely removes Store; others unknown |
| VBS/HVCI default on | ticked off (checkbox) | forced off | forced off | forced off + mitigations off | off by default | all hypervisor/VBS off (bcdedit) |
| TPM/Secure Boot checks | untouched | ISO bypass registry in `bypass-requirements.yml` | ISO option | `disableelamdrivers yes` | n/a | `disableelamdrivers yes` |
| Defender default | on | **off** | on | off (deleted) | off (CAB + rootCA) | removed |
| Windows Update | notify | paused by closed tool | paused 10 years | services disabled | paused to 2038, WU URLs blocked | unknown |
| License usable for GPL-3.0 fork | GPL-3.0 | CC-BY-SA-4.0 (one-way into GPLv3, verify) | AGPL-3.0 | MIT | **none** | none found |
| Revert path | AtlasDesktop scripts | thin | **best** (Toolbox pairs) | restore point only | toggle scripts | none visible |

Ideas worth borrowing (all small, license-aware): RapidOS' CPU-aware Game Bar exception for dual-CCD X3D, laptop-aware MMCSS/GpuEnergyDrv (`Test-Laptop`), MMCSS state export to JSON for revert, SChannel hardening list, "enable/disable" paired scripts; ReviOS' explicit re-install of VCLibs after AppX removal, and the issue-driven note that `disabledynamictick`/`useplatformtick` break some laptops' sleep (Revi `FINALIZE.cmd`, issue #167).

Things to avoid (negative for EclipseOS): any unconditional VBS/HVCI or process-mitigation disable (all of them), Store/AppXSvc/ClipSVC/InstallService/BITS service disables (Atom), WU endpoint block (Synergy `DoNotConnectToWindowsUpdateInternetLocations`), sideloaded NoDefender CAB with a root-CA (Synergy/WIRZADE), WinSxS component removals (ReviOS, uninstallable), IFEO taskkill debuggers (fragile), downloading "latest" binaries without hash (ReviOS `revitool`, RapidOS browsers), unofficial repacks (`abbodi1406/vcredist`, SapphireOS).

## 13. Open items / what I could not verify

- Contents of the `.apbx` for FSOS-X, Vain, XOS, SapphireOS, UltraOS (no public source; only KT analyzer strings). Hash comparison to vendors only done for Atlas.
- ReviOS 26.04 and Atom 0.0.8 assets vs the GitHub sources (source revisions differ from catalog versions).
- RapidOS `Defender.ps1`, `NetBlock.exe`; ReviOS `revitool` behaviour; Synergy `appx.yml`/`components.yml`/`services.yml`; Atom `01-services.yml`, `11-networking.yml` not read line by line.
- Whether the Defender-off + HVCI-off combos actually fail specific anti-cheats was not tested (general knowledge only). 26300 compatibility of any tweak is not tested (only `SupportedBuilds` strings).
