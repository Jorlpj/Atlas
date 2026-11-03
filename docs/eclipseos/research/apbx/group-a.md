# AME Wizard playbooks, group A, vs AtlasOS (for EclipseOS)

Date 2026-11-02. Read-only: every playbook file was read as text through `gh api` (GitHub contents API). No `.apbx`, `.exe`
or `.zip` was downloaded or run. Atlas baseline = `C:\Atlas\src\playbook` (cited as `A:<path>`). Prior survey:
`C:\Atlas.librarian\docs\eclipseos\research\26h2-playbooks.md`. Claims marked (inference) are not in the source text.
Every row was read from the repo file named in its section header; unread bodies (ReviOS WinSxS CABs, RapidOS `.ps1`
helpers, Chamber snapshot scripts) are flagged.

## 0. Summary matrix

| | ReviOS 26.10 | Chamber 1.3.3 | UltraOS 1.2.1 | RapidOS 1.3 | AME 11 / Privacy+ 0.8.3 |
|---|---|---|---|---|---|
| Lists 26300 | yes | yes (declared, 1 author ISO test) | yes (primary target) | no (max 26200) | no (max 26200) |
| Defender default | **off** (revitool, `--force`) | kept (policy keys deleted) | kept (no off option in conf) | kept (opt-in off) | **files deleted** |
| VBS/HVCI default | **off** (revitool) | on (opt-in off) | on (opt-in off) | **off, unconditional** | not touched (inference: no key found) |
| Windows Update | pause to 2038 via revitool; no `NoAutoUpdate` | untouched (opt-in notify-only) | auto default (opt-in notify-only) | `AUOptions=2` (notify) | **services deleted** |
| Store | kept (AutoDownload=4) | kept | kept | kept (opt-in AutoDownload=2) | **removed** |
| Xbox | kept (opt-in removal) | kept (opt-in removal) | app kept; legacy XboxApp removed; Extreme removes GamingApp | Game Bar removed (non dual-CCD X3D) | **removed incl. identity** |
| License | CC-BY-SA-4.0 | CC BY-NC-SA 4.0 (non-commercial) | GPL-3.0 | AGPL-3.0 | none found |
| Binary bundled | `revitool` + vc_redist downloaded at runtime; WinSxS removal packages | `nvidiaProfileInspector.exe` (post-install folder) | none (YAML + PS only, by design) | `PolFileEditor.dll` | 7za, NSudoLC, ame-hexer, install_wim_tweak, OpenShell, UGC chrome, etc. |

## 1. ReviOS 26.10

Sources: `https://github.com/meetrevision/playbook` (`src/playbook.conf`, `src/Configuration/Tasks/**`, `src/Executables/*`);
release list (`gh api repos/meetrevision/playbook/releases`).

### 1.1 Metadata
- Release 26.10 (2026-10-09); last push 2026-10-21; license CC-BY-SA-4.0 (GitHub API `license.spdx_id`).
- `playbook.conf`: Version `1.0` (conf string; release tag is 26.10), `SupportedBuilds` 19044, 19045, 22631, 26100, 26200,
  28000, **26300**. Requirements: `DefenderToggled`, `NoPendingUpdates`, `NoAntivirus`, `Internet`, `PluggedIn`.
  `SupportsISO` true (`DisableBitLocker`, `DisableHardwareRequirements` true).
- Options (defaults): browser Brave (or Firefox); Defender radio `disable-defender` **default**; hibernate `disable-hibernate`
  default (also disables Fast Startup); checked: remove Edge, OneDrive, AI (Recall/Copilot), Teams, Photos, Dev Home,
  Your Phone, wallpaper, dark mode, legacy context menu, no transparency, clear Start pins; **unchecked**: remove Xbox apps,
  disable automatic maintenance.
- Bundled/downloaded: no exe in repo; `start.yml` downloads `vc_redist.x64.exe` (aka.ms) and `RevisionTool-Setup.exe`
  (`github.com/meetrevision/revision-tool/releases/latest`, unpinned "latest") and runs them; most tweaks are `revitool.exe`
  calls whose logic is not in this repo. WinSxS removal packages (`winpackage --install system-components-removal | ai-removal |
  onedrive-removal | xbox-removal | telemetry-removal`) are fetched by revitool (contents not readable here).

### 1.2 Change table

| Area | What it changes | Diff vs Atlas | Positive | Negative / risk | Impact |
|---|---|---|---|---|---|
| Windows Update | `revitool tweaks updates wu-pause-updates enable` (pause to 2038-01-19, `FlightSettingsMaxPauseDays`); `NoAutoUpdate` commented out ("used to break Xbox sign-in"); `DisableOSUpgrade=1`; `DODownloadMode=0`; `UpgradeAvailable=0`; hides MCT link; rollback deletes `HKLM\...\Policies\WindowsUpdate` (`revert.yml`) | Looser in effect (updates paused to 2038) but mechanism differs: Atlas `AUOptions=2` notify (`A:Executables/AtlasDesktop/3. General Configuration/Automatic Updates/Disable Automatic Updates (default).cmd`, `NoAutoUpdate` also commented) | Avoids policy that broke Xbox sign-in; clears old policy keys on upgrade | Pause to 2038 = no security updates unless user resumes; pause semantics may also hold Store/OS servicing (inference) | Store/Xbox servicing: risk; security: worse than Atlas |
| Store | `WindowsStore\AutoDownload=4` (HKLM policy, `updates/ms-store.yml`); `DisableOSUpgrade=1`; `revitool msstore-apps --id 9NBLGGH3FRZM,9NBLGGH4RV3K -r RP` re-installs VCLibs/UWPDesktop (issue #219) | Atlas writes `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate\AutoDownload=2` (non-policy key, `A:Configuration/tweaks/qol/disable-store-auto-updates.yml`); ReviOS writes the policy key `Policies\Microsoft\WindowsStore\AutoDownload=4` (ADMX: 4 = always on, inference) | Store kept; reinstalls frameworks that removals can break | AutoDownload=4 forces auto updates (positive for Store health) | Store servicing: better than Atlas (inference from ADMX meaning) |
| AppX removals | One batch via `revitool appx --all-users --remove`: WebExperience, WidgetsPlatformRuntime, StickyNotes, People, Bing*, Solitaire, FeedbackHub, GetHelp, Todos, PowerAutomate, Cortana, Quick Assist, Family, Zune*, SoundRecorder, Clipchamp, Whiteboard, Office*, Outlook, Spotify, 3D Viewer, MSPaint, StartExperiencesApp; options Photos, DevHome, YourPhone/CrossDevice | Similar scope to Atlas appx removal, plus Widgets runtime and Start experience app | Light | Removing `StartExperiencesApp`/`WebExperience` can change Start/Widgets behaviour (inference); `!systemPackage` removal "one of the main causes of #49" per its own comment | Store/Xbox untouched by default |
| Xbox / Gaming Services | Default: **kept**. Option `remove-appx-xbox` runs `winpackage --install xbox-removal` and neuters `ms-gamebar` protocol; `revert.yml` re-enables background apps and clears `AppCaptureEnabled` because it broke Game Bar KGL update (#74) | Atlas keeps Xbox by default (same); ReviOS option removes at WinSxS level | Option is off by default; its own issues are documented in `revert.yml` | WinSxS-level removal is hard to revert (inference) | Store/Xbox: safe by default, destructive if ticked |
| Defender / SmartScreen | Default `revitool tweaks security defender disable --force` (needs `DefenderToggled` = Tamper Protection off); option `enable-defender`. Also SmartScreen policy tweaks, hides Security systray, deletes `SecurityHealth` Run value | **Looser** (Atlas default `defender-enable`, `A:playbook.conf` L57-66) | Max perf gain | No AV/Smart App Control; anti-cheats that require Defender WMI (some) at risk (inference) | Security/anti-cheat: worse |
| VBS / HVCI / mitigations | `revitool tweaks security vbs disable` (also disables HVCI) always, **not an option** (`security/vbs.yml`); `intel-tsx enable` (`kernel.yml`); `revert.yml` removes old `FeatureSettings*Override` and ProcessMitigationOptions keys, and restores `VulnerableDriverBlocklistEnable=1` ("setting 0 breaks THE FINALS"); `fixes.yml` sets per-exe `MitigationOptions` for `vgc.exe` and `osu!.exe` | VBS off matches the Atlas `disable-core-isolation` option (`A:Configuration/tweaks/scripts/script-core-isolation.yml` runs `ConfigVBS.ps1 -DisableAllVBS`; option declared at `A:playbook.conf` L111; default state per lab note, not re-checked here); Atlas has per-option mitigations (`A:playbook.conf` L71-80). CPU mitigations left at default after revert (same as Atlas default) | Reverts earlier harmful mitigation tweaks | VBS off with no UI choice; TSX enable re-opens a CPU side-channel class (own comment says disabled "for security reasons"); `vgc.exe` mitigation edit is an anti-cheat process | Perf +; anti-cheat: Vanguard/FACEIT require HVCI per UltraOS research |
| Services | Disabled (startup 4): `dam`, `GpuEnergyDrv`, `NetBT`, `Telemetry` (Intel), `diagnosticshub.standardcollector.service`, `WerSvc`, `DiagTrack`, `wisvc`, `PcaSvc`, `WdiServiceHost`, `WdiSystemHost`, `tcpipreg`, `Wecsvc`, `UCPD`; `edgeupdate` Manual; `condrv` Auto; `bam`, `Beep`, `Ndu`, `DPS`, `GraphicsPerfSvc` restored by `revert.yml` | Atlas services in `A:Configuration/atlas/services.yml`; ReviOS disables `UCPD` (Atlas needs `UCPDDisabled` requirement, same) and `dam`/`Wecsvc`/`tcpipreg` extra | Fewer background services | `dam` off, `WdiService*` off: minor; reverted `bam` to keep Efficiency Mode | Neutral for Store/Xbox |
| Scheduled tasks | `Disable-ScheduledTask` for `UCPD velocity`; IFEO `Debugger=taskkill.exe` on `CompatTelRunner`, `AggregatorHost`, `DeviceCensus`, `FeatureLoader`, `BingChatInstaller`, `BGAUpsell`, `BCILauncher` (`ifeo.yml`) | Atlas disables tasks via `A:Configuration/tweaks/debloat/disable-scheduled-tasks.yml`; Atlas has no IFEO debugger blocks (grep for CompatTelRunner: none) | Hard-blocks telemetry binaries | IFEO Debugger hijack is a malware-like pattern some AV/anti-cheat may flag (inference) | Low |
| Telemetry / privacy | `AllowTelemetry=0` in 7 locations, `AllowCommercialDataPipeline=0`, `LimitDiagnosticLogCollection`, `AllowExperimentation=0`, Autologgers `Diagtrack-Listener`/`SQMLogger`/`SetupPlatformTel` Start=0; WinSxS `telemetry-removal`; WER off; `DisableWpbtExecution=1` | Atlas `A:Configuration/tweaks/privacy/telemetry/disallow-data-collection.yml` (similar); ReviOS deeper (CPSS/PolicyManager shadows, WinSxS removal) | Thorough | `AllowTelemetry=0` is a Home/Pro no-op (becomes 1) (inference); WinSxS removal not reversible | Neutral |
| Power / CPU / timer | `revitool tweaks performance powerplan enable`; hibernate+Fast Startup off (default); `Win32PrioritySeparation=38`; `NetworkThrottlingIndex=10` (default value, not removal); IFEO PerfOptions: `lsass`, `sihost`, `fontdrvhost` CpuPriorityClass=1/IoPriority=0, `SearchIndexer`/`ctfmon`=5; superfetch re-enabled (`revert.yml`) | `Win32PrioritySeparation=38` same (`A:Configuration/tweaks/performance/system/win32-priority-separation.yml`); Atlas has no NetworkThrottlingIndex edit | Small, low-risk set | Lowering `lsass` priority class is odd (value 1 = idle, inference from IFEO PerfOptions docs) | Perf: marginal |
| Network | Reverted bbr2 congestion provider (`netsh ... congestionprovider=default`), `condrv` Auto, `NetBT` disabled; `hosts` file in Executables | Atlas: no hosts blocking | Reverts a harmful tweak | `hosts` entries (not read in full) may block telemetry hosts | Neutral |
| UI / shell | Dark mode, legacy context menu, no transparency, clean Start pins, wallpaper, `LayoutModification`, taskbar/search registry | Atlas has equivalents | - | - | None |
| Edge / browsers | `EDGE.ps1` uninstalls Edge with a spoofed `sihost.exe` (copy of cmd.exe) parent, `AllowUninstall`; removes `NoRemove`; WebView kept; Brave/Firefox installed with preferences | Atlas `uninstall-edge` option (`A:playbook.conf` L124) | Works around the uninstall block | Spoofing a trusted parent is a fragile hack and may break on 26300 servicing | Neutral |
| OneDrive | WinSxS `onedrive-removal`, `ONED.cmd`, policy `DisableFileSyncNGSC` deleted on upgrade | Atlas has OneDrive removal | - | - | None |
| Revert path | `revert.yml` (`onUpgrade: true`) undoes older ReviOS tweaks only; no uninstall; Revision Tool GUI can toggle individual tweaks (README) | Atlas has documented uninstall | Per-tweak toggles via revitool | No restore point/snapshot; WinSxS removals irreversible | - |

### 1.3 Ideas
- **Adopt**: `revert.yml` pattern (`onUpgrade` section that deletes keys prior versions set), including the lesson that
  `VulnerableDriverBlocklistEnable=0` breaks THE FINALS and `SvcHostSplitThresholdInKB` break `XboxGipSvc` (#34); the
  Store frameworks reinstall step (VCLibs/UWPDesktop) as a post-removal check; `AutoDownload=4`-vs-2 comparison in the lab.
- **Test**: "pause" instead of policy; confirm in the lab whether pause-to-2038 blocks Store/Gaming Services updates (inference: unknown).
- **Avoid**: Defender off by default, VBS off without an option, TSX enable, closed WinSxS removal packages, IFEO `taskkill`
  debugger hijacks, unpinned `latest` downloads executed as admin, spoofed-parent Edge removal.

## 2. Chamber 1.3.3

Sources: `https://github.com/ChamberTechFPS/Playbook` (`playbook.conf`, `Configuration/Tasks/0..10`, `Executables/*`, `CHANGELOG.md`, `LICENSE`).

### 2.1 Metadata
- Version 1.3.3 (changelog 2026-10-25); last push 2026-11-02; **license CC BY-NC-SA 4.0** (`LICENSE`; GitHub reports NOASSERTION).
  Non-commercial and share-alike: cannot copy code into a GPL-3.0 fork.
- `SupportedBuilds` 26100, 26200, **26300** ("declared ahead of validation"; changelog 1.3.0: first ISO test 9800X3D 26300
  2026-10-07, 9 verify failures then fixed). Requirements: `NoPendingUpdates`, `NoAntivirus` (no `DefenderToggled`).
  `SupportsISO` true, `DisableBitLocker` true, **`DisableHardwareRequirements` not set** (keeps TPM/Secure Boot checks for anti-cheat).
- Options (defaults): browser Chrome/Brave/none (Chrome default); **unchecked**: remove Xbox apps and services, OLED safety,
  disable BitLocker, **disable VBS/Memory Integrity**, **stop automatic updates**, disable Smart App Control; **checked**: turn off Game Bar overlay/recording.
- Bundled: `PostInstall/Drivers/NVIDIA/Nvidia Settings/nvidiaProfileInspector.exe` (+ `.nip` profiles), VC++ redist
  fetched in release workflow, driver `.url` shortcuts, `Verify-Chamber.ps1`, `Restore-Chamber.ps1`.

### 2.2 Change table

| Area | What it changes | Diff vs Atlas | Positive | Negative / risk | Impact |
|---|---|---|---|---|---|
| Windows Update | Untouched by default. Option `disable-updates`: `NoAutoUpdate=1` + `AUOptions=2` (`7-security.yml`). Deletes `DisableAntiSpyware`/`DisableRealtimeMonitoring` policy values | Looser than Atlas default only if ticked (Atlas default already `AUOptions=2`); Chamber default = **stock auto updates** (stricter than Atlas) | Keeps servicing intact | `NoAutoUpdate` option has Xbox sign-in history (ReviOS note; catalog C02) | Store/Xbox: best default of the group |
| Store | Not touched; debloat summary says "Preserved by default: Store, App Installer/winget, Windows Security, Calculator, Notepad, Snipping Tool, Photos, Paint" (`Invoke-BalancedDebloat.ps1`) | Stricter (Atlas edits `AutoDownload`) | Store/winget intact | None | Servicing: good |
| AppX removals | `Invoke-BalancedDebloat.ps1`: Outlook/Mail, Solitaire, Teams consumer, Clipchamp, Copilot, Widgets (`WebExperience`, `WidgetsPlatformRuntime`), Phone Link, Bing*, FeedbackHub/GetHelp/Getstarted, Zune*, Family/People/Todos, PowerAutomate/Whiteboard/Maps, OfficeHub/PowerBI, Spotify, DevHome, LinkedIn/Skype, Cortana/MixedReality, StickyNotes, Alarms | Similar to Atlas | Smaller than ReviOS; protected list | Removes Widgets platform (inference: fine) | None |
| Xbox / Gaming Services | Default **kept**. Option `remove-xbox`: services `XblAuthManager`, `XblGameSave`, `XboxNetApiSvc`, `XboxGipSvc`, **`GamingServices`** startup 4; appx `Microsoft.GamingApp`, `XboxApp`, `XboxGameOverlay`, `XboxGamingOverlay`, **`XboxIdentityProvider`**, `XboxSpeechToText...` (`-XboxOnly`). Game Bar overlay/recording off by default (`AllowGameDVR=0`, `GameDVR_Enabled=0`, `UseNexusForGameBarEnabled=0`) but `AutoGameModeEnabled=1` | Atlas default keeps Xbox (same); Game Bar policy same family (`A:Configuration/tweaks/performance/disable-game-bar.yml`) | Option clearly separated and default off | Removing `XboxIdentityProvider`/`GamingServices` breaks sign-in and Game Pass installs | Avoid option |
| Defender | Kept. Deletes policy values that disable Defender; Verify checks it (catalog D06: on 26300 Defender self-restores, which is why Chamber dropped its off option) | **Stricter** than ReviOS, same as Atlas default | AV kept; no `DefenderToggled` needed | None | Anti-cheat: good |
| VBS / HVCI / CPU mitigations | VBS/HVCI stay **on** by default; option `disable-vbs` writes `EnableVirtualizationBasedSecurity=0`, `RequirePlatformSecurityFeatures=0`, `HypervisorEnforcedCodeIntegrity\Enabled=0`; option `disable-sac` (`VerifiedAndReputablePolicyState=0`). No CPU mitigation edits. Secure Boot/TPM untouched and Verify warns | **Stricter** than Atlas lab default (Atlas default turned VBS/HVCI off) | Matches EclipseOS goal | Option `disable-vbs` writes only 3 keys; on 24H2+ Windows may re-arm scenarios (UltraOS comment on forced-value pattern) | Anti-cheat: good |
| Services | Disabled: `DiagTrack`, `WerSvc`, `DiagnosticsHub...`, `dmwappushservice`, `wisvc`, **`WSearch`**, **`SysMain`**, `WMPNetworkSvc`, **`TabletInputService`**, `MapsBroker`, `PcaSvc`, `RemoteRegistry`, `TapiSrv`, `Fax`, `RetailDemo` | Atlas keeps `WSearch`/`SysMain` default and toggles via Toolbox (`A:Executables/AtlasDesktop/6. Advanced Configuration/Services/Superfetch/`) | Lower idle load | `SysMain`+`WSearch` off unconditionally: slower Start search and cold launches on HDD (inference); `TabletInputService` off breaks touch keyboard/ink | Neutral for gaming |
| Scheduled tasks | Compatibility Appraiser, ProgramDataUpdater, PcaPatchDbTask, MareBackup, CEIP Consolidator/UsbCeip, DiskDiagnostic collector, `Siuf\DmClient*` disabled; `Complete-ChamberSetup.ps1` re-applies because Windows re-enabled `PcaPatchDbTask` | Atlas similar | Re-apply script handles Windows undoing tweaks (a real 26300 behaviour) | - | None |
| Telemetry / privacy | `AllowTelemetry=0` (2 keys), Autologgers off, Advertising ID off, activity feed off, Copilot/AI (`WindowsAI`) off, ContentDeliveryManager keys, IFEO `taskkill` on `CompatTelRunner`/`AggregatorHost`/`DeviceCensus`, **hosts telemetry blocks** (`Update-HostsTelemetryBlocks.ps1`: vortex, settings-win, telemetry, watson, statsfe*), DO off, `LetAppsRunInBackground=2`, Edge StartupBoost/Background off | Atlas has no hosts blocks or IFEO debuggers | Cheap, reversible (hosts) | `LetAppsRunInBackground=2` can break background features of Store apps (inference); hosts entries for `settings-win` can break Store/Windows sync (inference) | Store: watch |
| Power / CPU / timer / latency | Ultimate Performance plan (falls back High then Balanced), `PowerThrottlingOff=1`; USB `DisableSelectiveSuspend` deleted; BCD `tscsyncpolicy Enhanced`, `bootux disabled`, `timeout 0`; `SystemResponsiveness=10`, Games task `Priority=6`, `Scheduling Category=High`, `SFIO Priority=High`; `Win32PrioritySeparation=38`; `HwSchMode=2`; windowed-game optimizations script; `WaitToKillServiceTimeout=1500`, `AutoEndTasks=1`, `HungAppTimeout=2000`; paging/`DisablePagingExecutive` by RAM check (`4-registry.yml`) | Same as Atlas for 38/10 (`A:Configuration/tweaks/performance/config-mmcss.yml`); Atlas has `disable-paging.yml` too; BCD `tscsyncpolicy`/`bootux` not found anywhere under `A:` by grep | Gaming-focused; each BCD edit fails soft (`|| echo [WARN]`) | `AutoEndTasks=1` can kill unsaved apps at logoff; Ultimate plan increases idle power | Perf: modest |
| Network | `NetworkThrottlingIndex=0xFFFFFFFF`; removes `TcpNoDelay`/AFD window values; `netsh int tcp set global autotuninglevel=normal`, `ecncapability=disabled`; IFEO PerfOptions to deprioritise `SearchIndexer`, `WerFault`, `CompatTelRunner` | Atlas does not set `NetworkThrottlingIndex` (grep: none) | Removes placebo values | `NetworkThrottlingIndex=ffffffff` is widely debated (inference) | Neutral |
| UI / shell | Classic context menu, visual effects, taskbar via `Complete-ChamberSetup.ps1 -Mode User` | Similar | - | - | None |
| Edge / browsers | Installs Chrome or Brave from cached payload; option "None - keep Microsoft Edge"; Edge not in debloat list (inference: Edge not removed) | Stricter than Atlas (`uninstall-edge`) | Edge update/WebView intact | - | Store/Widgets deps intact |
| OneDrive | Deletes Default-profile `OneDriveSetup` Run value; removes per-user OneDrive in debloat | Similar | - | - | None |
| Revert path | **Best in group**: `0-snapshot.yml` pre-install snapshot, `PostInstall/Verify/Restore-Chamber.ps1` (`-Apply`), deployment receipt, `Verify-Chamber.ps1` + `verification-manifest.json` | Better than Atlas (uninstall doc only) | Snapshot -> verify -> restore loop | Restore bugs fixed in 1.3.0 (partial restore); depends on manifest completeness | Safe to test in lab |

### 2.3 Ideas
- **Adopt (design, not code)**: Verify/Restore/receipt model; "re-apply after Windows undoes it" task (Windows re-armed
  `Diagtrack-Listener` and `PcaPatchDbTask` at first sign-in); BCD edits that fail soft; `DisableHardwareRequirements` left unset;
  hosts file blocks as reversible telemetry layer (verify they do not hit Store/Xbox hosts).
- **Avoid**: copying code (CC BY-NC-SA 4.0 conflicts with GPL-3.0); `SysMain`+`WSearch`+`TabletInputService` off by default;
  `LetAppsRunInBackground=2`; shipping `nvidiaProfileInspector.exe`.

## 3. UltraOS 1.2.1

Sources: `https://github.com/UltraOS-Project/playbook` (`src/playbook/playbook.conf`, `src/playbook/Configuration/**`,
`CHANGELOG.md`, `research/*.md` which are the authors' own AI-assisted dossiers; treat their claims as unverified).

### 3.1 Metadata
- v1.2.1 (tag 2026-10-28); license GPL-3.0 (same as Atlas, so code reuse is legal with attribution).
  `SupportedBuilds` 26100, 26200, **26300** (primary target; `research/windows-26h2-analysis.md` documents 26300.9550 GA).
  Requirements: `Internet`, `NoPendingUpdates`, `PluggedIn` (no `DefenderToggled`, no `NoAntivirus`). `SupportsISO` true; ISO:
  `DisableBitLocker`, `DisableHardwareRequirements` true; `Overhaul` true.
- Options: preset **Safe / Balanced (default) / Extreme**; restore point `rp-on` default; updates `wu-auto` (default) /
  `wu-notify`; **unchecked** extras: remove Edge, disable CPU mitigations, disable VBS, max-performance power, disable
  hibernation, strip Recall, disable sticky keys, disable SysMain, disable Search indexing, disable memory compression,
  disable HAGS; browser Brave/Firefox/LibreWolf (Brave default).
- Bundled: no binaries (CHANGELOG: "plain YAML, zero executables, no WinSxS amputation"); PS scripts for backup/undo/report;
  `default-user.reg`.

### 3.2 Change table

| Area | What it changes | Diff vs Atlas | Positive | Negative / risk | Impact |
|---|---|---|---|---|---|
| Windows Update | `wu-auto` default: no change. `wu-notify` (`qol/updates.yml`): `NoAutoUpdate=1` + `AUOptions=2` on policy only; services (`wuauserv`, `UsoSvc`, `DoSvc`, `TrustedInstaller`) on a validator-enforced never-touch list (`scripts/validate-playbook.py --strict`) | Stricter default than Atlas (Atlas default notify) | Never disables update services; CI check enforces it | Own doc notes `NoAutoUpdate` stops "other Microsoft products" updates | Store/Xbox servicing: good |
| Store | Not touched. Protected app families (`Microsoft.WindowsStore*`, `WebView2`, `XboxIdentityProvider*`, `Xbox.TCUI*`) enforced by CI validator; `reinstall-blockers.yml`: Outlook/DevHome `workCompleted=1`, `ConfigureChatAutoInstall=0` | Stricter than Atlas (no `AutoDownload` edit) | Store never at risk by design | - | Servicing: good |
| AppX removals | Safe: `Teams`, Cortana, Skype, OneNote, MSPaint, 3DViewer, MixedReality, Mail/Calendar, Getstarted, **legacy `XboxApp`**; Balanced+: Copilot, Clipchamp, Disney, Spotify, Zune, Family, DevHome, Bing*, Outlook, GetHelp, OfficeHub, StickyNotes, People, PowerAutomate, Todos, Alarms, Camera, FeedbackHub, Maps, SoundRecorder, News, PCManager, TikTok/Facebook/Instagram/Netflix/PrimeVideo/king.com; Extreme adds Widgets, `Microsoft.GamingApp`, `XboxGamingOverlay`, `XboxGameOverlay`, `XboxSpeechToTextOverlay` | Similar scope; tiered | Extreme warns about Game Pass and keeps identity/TCUI | Extreme removes GamingApp | Safe/Balanced: neutral |
| Xbox / Gaming Services | Balanced keeps app and services; `ms-gamebar` neutralised only when Game Bar app is removed (v1.2.0). Services list comment: `XblAuthManager` needed for Xbox app/Game Pass; `GamingServices` installs Game Pass titles; never touched | Atlas keeps (same) | Explicit rationale per service | Extreme loses Xbox app | Safe/Balanced: good |
| Defender | No Defender disable in conf (`opt-disable-defender` was planned in `research/01-architecture.md`, then dropped; `defender.ps1` toggle exists only as post-install script) | Stricter than Atlas (no option) | - | Defender can still be toggled by user script | Anti-cheat: good |
| VBS / HVCI / mitigations | Opt-in only. `vbs.yml` forces `HypervisorEnforcedCodeIntegrity`, `KernelShadowStacks`, `CredentialGuard` `Enabled=0`, clears `ChangedInBootCycle`/`WasEnabledBy`, `RunAsPPL=0`, `EnableVirtualizationBasedSecurity=0` (the 24H2 forced-value pattern derived from Atlas `ConfigVBS.ps1`). `mitigations.yml`: `FeatureSettingsOverride=3`/`Mask=3`, `DisableExceptionChainValidation=1`, `Set-ProcessMitigation -System -Disable CFG`, `ProtectionMode=0`; deliberately omits Atlas's all-2s nibble mask and `nx OptIn` | VBS on by default = stricter than Atlas lab default; mitigations opt-in matches Atlas default (`A:playbook.conf` L71-80) | Warnings cite Vanguard/FACEIT HVCI requirement and EAC 0xEAC02014 (Atlas #1532); per-feature toggles in `UltraOSFolder/1. Security/` | Own research cites issues, not independently verified | Anti-cheat: good |
| Services | Balanced: `OneSyncSvc`, `TrkWks`, `PcaSvc`, `MapsBroker`, `lfsvc`, `RetailDemo`, `Fax`, `WMPNetworkSvc`, `diagnosticshub...`, `wercplsupport`, `RemoteRegistry`, `DiagTrack`, `WerSvc`, `wermgr` startup 4; Extreme adds `SysMain`, `WSearch`, `NDU`, `NetBT`, `GpuEnergyDrv`, `Telemetry`; opt-in `SysMain`/`WSearch` | Similar to Atlas; no `UCPD` entry | Tiered, backed up (`BACKUP.ps1`) | `lfsvc`/`OneSyncSvc` off affects location/Mail sync | Neutral |
| Scheduled tasks | Safe: CEIP trio, Appraiser, ProgramDataUpdater, QueueReporting, DiskDiagnostic, Autochk/Chkdsk Proxy; Balanced: `PcaPatchDbTask`, `UCPD velocity`, `UsageDataReporting`; Edge update tasks when Edge removed; all `ignoreErrors` | Similar to `A:Configuration/tweaks/debloat/disable-scheduled-tasks.yml` | Only "well-sourced, non-contested" tasks | - | None |
| Telemetry / privacy | `AllowTelemetry=0` (Balanced), `MaxTelemetryAllowed=0`, DataCollection depth (commercial pipeline, enterprise proxy, opt-in UX), `SQMLogger`/`SetupPlatformTel`/`Diagtrack-Listener` Autologger off, CPSS/PolicyManager shadows, WerSvc off, `DODownloadMode=1`, `DisableAIDataAnalysis`, Copilot off, `WindowsAI\AllowRecallEnablement=0` (opt-in strip), search hardening | Atlas `disallow-data-collection.yml` similar; UltraOS adds CPSS/PolicyManager shadow keys | Parity with ReviOS depth without WinSxS removal | `DODownloadMode=1` allows LAN peering (looser than Atlas `0`, `A:Configuration/tweaks/qol/windows-update/disable-delivery-optimization.yml`) | Neutral |
| Power / CPU / timer | Safe+: `HiberbootEnabled=0`; Balanced: `Win32PrioritySeparation=38`, `fsutil disablelastaccess 1`, `8dot3name 1`, FTH off (`rundll32 fthsvc.dll,FthSysprepSpecialize`), `SystemResponsiveness=10`, mouse accel off; GameDVR/AppCapture off, Game Mode **kept on**; opt-in `PowerThrottlingOff`, `StorageD3InModernStandby=0`, `stornvme IdlePowerMode=0`, HAGS off; Extreme: `GlobalTimerResolutionRequests=1`, FSE behaviour keys, `__COMPAT_LAYER=~ DISABLEDXMAXIMIZEDWINDOWEDMODE`, MMCSS Games `Priority 6`/`High` | `38`/`10` same as Atlas; `GlobalTimerResolutionRequests` is an Atlas toggle default off (`A:Executables/AtlasDesktop/3. General Configuration/Timer Resolution/Disable timer resolution (default).cmd`); UltraOS applies in Extreme only | Honest labelling ("near-zero gain on modern CPUs") | `__COMPAT_LAYER` is machine-wide (inference: may affect every game) | Perf: modest |
| Network | Balanced: `EnableMulticast=0` (DNS client), `RestrictNullSessAccess`, `RestrictAnonymous(SAM)=1`, `DisableBandwidthThrottling=1`; Extreme: `NetworkThrottlingIndex=0xFFFFFFFF`; NIC config script | Atlas: no `NetworkThrottlingIndex`; `RestrictAnonymous` is security hardening | Small hardening | `EnableMulticast=0` breaks mDNS/LLMNR discovery | Neutral |
| UI / shell | Context menu, taskbar, explorer, shortcuts folder `C:\Windows\UltraOS` | Atlas similar | - | - | None |
| Edge / browsers | Opt-in `opt-uninstall-edge` via `EDGE-UNLOCK.ps1`, deprovisioning keys (`Appx\AppxAllUserStore\Deprovisioned\...MicrosoftEdge...`, `Edge.GameAssist`), tasks off; "WebView2 is never touched"; reinstall script in `UltraOSFolder/5. Software/` | Similar to Atlas option, with WebView2 guarantee | Reversible via shipped reinstall script | Edge.GameAssist deprovision: no known game dependency (inference) | Neutral |
| OneDrive | Not in the files read (inference: not removed by default) | Atlas removes | - | - | None |
| Revert path | **Strong**: restore point (`RESTOREPOINT.ps1`, default on), `BACKUP.ps1` of services/appx/tasks to `C:\Windows\UltraOS\Backups`, `UNDO.ps1`/`Undo.cmd`, HTML `install-report.html`, per-feature toggle `.cmd` in `UltraOSFolder`, `onUpgrade` revert.yml | Better than Atlas | One-click undo; Windows-native restore point | Registry-only undo does not restore removed appx (inference) | Good for lab loop |

### 3.3 Ideas
- **Adopt** (GPL-3.0 allows reuse): Safe/Balanced/Extreme tiering with option gates; CI `validate-playbook.py --strict`
  (never-touch services list, protected appx families, duplicate-write check, option-gate names); HTML install report +
  BACKUP of services/appx/tasks; the 24H2 forced-value VBS pattern (already derived from Atlas); `docs/` honesty labels
  ("near-zero gain on modern CPUs"); `reinstall-blockers.yml`.
- **Verify before reuse**: the `research/` dossiers are AI-agent output; re-check each claim (e.g. Vanguard/FACEIT HVCI requirement).
- **Avoid**: `__COMPAT_LAYER` machine-wide, `EnableMulticast=0`, Extreme GamingApp removal.

## 4. RapidOS 1.3

Sources: `https://github.com/rapid-community/RapidOS` (`RapidOS Sources/playbook.conf`, `Configuration/Core/**`, `Executables/*`).

### 4.1 Metadata
- v1.3 (release 2026-06-28; last push 2026-06-28); AGPL-3.0. `SupportedBuilds` 19045, 22621, 22631, 26100, 26200 (**no 26300**).
  Requirements: `NoAntivirus`, `DefenderToggled`, `NoTweakware`. `SupportsISO` true (BitLocker/hardware-requirements off). OOBE Internet Request.
- Options (defaults): unchecked: remove Edge, install another browser (Brave/Firefox/Thorium/Chrome), .NET 3.5, **disable Store updates**,
  **disable Defender**, **disable firewall**, disable location, disable sync; checked: DirectX, VCRedist, remove Teams/OneDrive/Office/Your Phone,
  RapidOS theme, clear Start/Taskbar templates, classic context menu.
- Bundled: `PolFileEditor.dll`, "RapidOS Toolbox" `.bat` scripts (incl. toggles for Store autoupdates, WU, MPO, MMCSS); `Defender.ps1` runs as TI.

### 4.2 Change table

| Area | What it changes | Diff vs Atlas | Positive | Negative / risk | Impact |
|---|---|---|---|---|---|
| Windows Update | `AUOptions=2` (notify), `ReserveManager` reserves off, Outlook/DevHome/CrossDevice orchestrator keys; Toolbox has Disable/Enable/Pause (default pause) scripts | Same as Atlas default notify (`A:Executables/AtlasDesktop/3. General Configuration/Automatic Updates/`) | Reversible toggles | Pause default (Toolbox) not read in detail | Neutral |
| Store | Default untouched; option `disable-store-updates`: `WindowsStore\AutoDownload=2` + `WindowsStore\WindowsUpdate\AutoDownload=2` | Same values as Atlas (`A:Configuration/tweaks/qol/disable-store-auto-updates.yml` writes the non-policy key =2); RapidOS also writes the policy key, and only when ticked | Store updatable by default (stricter than Atlas) | - | Servicing: good |
| AppX removals | `AppX.ps1 -Packages`: PowerBI, PowerAutomate, SurfaceHub Mail, Todos, Skype, People, PeopleExperienceHost, Cortana, Mail/Calendar, Solitaire, Disney, Spotify, Yandex.Music, Flipgrid, DevHome, FeedbackHub, Getstarted, QuickAssist, ParentalControls, 3DViewer, Family, **MSPaint**, MixedReality, Clipchamp, Whiteboard, SecureAssessmentBrowser, ZuneVideo, Advertising, BingNews, BingWeather, Maps; clears `SecHealthUI`/`CBS`/`Search` caches | Similar to Atlas | Smaller than ReviOS | `MicrosoftWindows.Client.CBS` cache clear touches shell package (inference) | None |
| Xbox / Gaming Services | **`XboxGamingOverlay` and `Edge.GameAssist` removed unless CPU is AMD dual-CCD X3D** (7900X3D, 7950X3D, 9900X3D, 9950X3D, detected via `Get-Specs -CPU`) (the source only prints "AMD Dual-CCD processor with 3D-Cache found" and skips removal; the reason, that the X3D scheduler relies on Game Bar detection, is an inference); other Xbox packages kept; no Xbox services touched | Atlas keeps Game Bar | CPU-aware | Removing GamingOverlay removes Game Bar (Xbox app/Gaming Services stay) | Store/Xbox: low risk |
| Defender / firewall | Opt-in `disable-defender` (confirmation dialog) runs `Defender.ps1 -disable_av` as TI; deferred flag at first boot (`HKLM\SOFTWARE\RapidOS\Installation\Deferred`); opt-in `disable-firewall` writes `EnableFirewall=0` for 3 profiles | Same as Atlas default (Defender on), firewall disable has no Atlas equivalent | Both opt-in with warning | Firewall off is a real exposure | Anti-cheat: neutral by default |
| VBS / HVCI / SAC / UAC / MOTW | **Unconditional**: `EnableVirtualizationBasedSecurity=0`, `HypervisorEnforcedCodeIntegrity\Enabled=0`, Smart App Control `VerifiedAndReputablePolicyState=0`, `PromptOnSecureDesktop=0`, FTH off, `SaveZoneInformation=1` (Mark-of-the-Web off), `LowRiskFileTypes` includes `.exe;.bat;.cmd;.vbs;.msi;.reg;.ps1`, `net accounts /maxpwage:unlimited` (`System/Security.yml`) | **Looser** than Atlas (VBS off like Atlas default but without option; MOTW/SAC off extra) | Perf | Removes download warnings and SAC; HVCI-requiring anti-cheats (Vanguard) fail | Security/anti-cheat: bad |
| Services | Disabled: `AppMgmt`, `MSDTC`, `PcaSvc`, `SEMgrSvc`, `TrkWks`, `DiagTrack`, `diagsvc`, `NvTelemetryContainer`, `Telemetry`, `TroubleshootingSvc`, `uhssvc`, `NetBT`; Manual: `DoSvc`, `LanmanServer`, `MapsBroker`, `SSDPSRV`; Auto `ShellHWDetection` | Similar to Atlas; `NvTelemetryContainer` extra | Small set | `SEMgrSvc` off breaks NFC/payments (inference) | Neutral |
| Scheduled tasks | CEIP (4), Application Experience (7 incl. `StartupAppTask`, `AitAgent`, `PcaWallpaperAppDetect`), DiskDiagnostic (2), Autochk Proxy, Siuf DmClient (2), WER QueueReporting, Device Information (2) via Schedule.Service COM | Similar | - | - | None |
| Telemetry / privacy | CEIP off, Cortana consent off, activity feed off, ink/typing personalisation off, appDiagnostics Deny, Recall (`Recall.yml`), WER, location (opt-in), `POWERSHELL_TELEMETRY_OPTOUT`, `DOTNET_CLI_TELEMETRY_OPTOUT` setx | Similar to Atlas | Includes dev-tool telemetry | `setx` machine env vars | Neutral |
| Power / CPU / timer | `DisablePageCombining=1`; MMCSS (`SystemResponsiveness=10`, Audio/Pro Audio/Playback priority 1/Medium, Games `Scheduling Category=High`; desktops only `NetworkThrottlingIndex=0xFFFFFFFF`, `SchedulerPeriod=1000000`, `LazyModeTimeout=25000`); duplicated Balanced plan "Balanced (RapidOS)" for AC; IFEO PerfOptions: `MoUsoCoreWorker`, `PhoneExperienceHost`, `SearchIndexer`, `SearchProtocolHost` = 5, `spoolsv` = 1; boot: `bootmenupolicy Legacy`, `debug no`, `timeout 15`, Explorer `StartupDelayInMSec=0` | MMCSS `10` same as Atlas (`A:Configuration/tweaks/performance/config-mmcss.yml`); laptop detection (`Test-Laptop`) is absent in Atlas | Laptop-aware; backs up MMCSS to JSON (`MMCSS.json`) | Lowering `MoUsoCoreWorker` priority may slow Windows Update installs (inference) | Perf: modest |
| Network | `netsh int tcp set global initialRto=2000`, `pacingprofile=off`, heuristics disabled; network hardening (`Security.ps1`: ciphers, key exchange, SMB, renegotiation, NET security); adapters config | Atlas has no TLS/cipher hardening | Security hardening of TLS/SMB | Cipher changes may break legacy/game services (inference) | Neutral |
| UI / shell | Theme, Start/Taskbar templates, classic context menu, Task Manager, visual effects | Similar | - | - | None |
| Edge / browsers | Opt-in remove Edge (`Edge.yml` + `Software.ps1 -Software Optimize-Edge`); `edgeupdate*` Manual when not removed; Brave/Firefox/Thorium/Chrome installs | Similar to Atlas | Services restored to Manual if Edge kept | - | None |
| OneDrive / Teams / Office | Options removal | Similar | - | - | None |
| Revert path | MMCSS JSON backup; Toolbox "Revert changes" scripts per feature (MMCSS, Store autoupdates, WU, driver updates, MPO) | Comparable to Atlas AtlasDesktop toggles | Per-feature toggles | No full rollback | Moderate |

### 4.3 Ideas
- **Adopt**: laptop detection (`Test-Laptop`) before network/scheduler tweaks; MMCSS JSON backup before editing; X3D-aware
  Game Bar handling (inference: EclipseOS targets gaming hardware, dual-CCD scheduler detection is a real concern); confirmation dialog on risky options.
- **Avoid**: unconditional VBS/SAC/UAC secure-desktop/MOTW off, network cipher hardening without a lab test, firewall-off option.

## 5. AME 11 / Privacy+ (Ameliorated-LLC/privacy_plus)

Sources: `https://github.com/Ameliorated-LLC/privacy_plus` (`src/playbook.conf`, `src/Configuration/tasks/*.yml`). Playbook Git link points to `AME-11`.

### 5.1 Metadata
- Version `0.8.3` in conf (mirror push 2025-10-22), latest GitHub release 0.8.2 (2025-10-03); **no license file** (GitHub API 404);
  `SupportedBuilds` 22000, 22621, 22631, 22635, 26100, 26200 (**no 26300**). Requirements: `Internet`, `NoPendingUpdates`,
  `NoTweakware`, `Activation`, **`DefenderDisabled`**, **`UCPDDisabled`**, `NoAntivirus`, **`LocalAccounts`**,
  **`AdministratorPasswordSet`**, `PluggedIn`.
- Options: browsers (Firefox/UGC Chromium/LibreWolf/Brave), email, media, office, `ame-tools`, `security-enhanced` (UAC/LUA
  hardening + `ADMIN.bat`); full list not read.
- Bundled binaries: `7za.exe`, `NSudoLC.exe`, `ame-hexer.exe`, `appfetch.exe`, `install_wim_tweak.exe`, `sfc.exe`,
  `OpenShellSetup`, `privacy+_settings.exe`, UGC `chrome.exe`/`chrlauncher.exe`, `.dll` association stubs, `UsrClass.dat`.

### 5.2 Change table

| Area | What it changes | Diff vs Atlas | Positive | Negative / risk | Impact |
|---|---|---|---|---|---|
| Windows Update | `!service delete`: `UsoSvc`, `WaaSMedicSvc`, `wuauserv`, `InstallService`, `LicenseManager` stop; `BITS` Manual; kills `MoUsoCoreWorker`, `wuauclt`; removes Update Health Tools | **Absent** (update stack removed; Atlas keeps) | No unwanted updates | No security patches; no way to update Store apps or OS; blocks Gaming Services install | Servicing: fatal |
| Store | AppX removed: `*WindowsStore*`, `*StorePurchaseApp*`, `*ConnectivityStore*`, `*Wallet*`; services `ClipSVC` stop, `InstallService` delete; `appfetch.exe` offered as Store-less downloader | **Absent** | Self-consistent for a no-Store design | Store and Store installs gone | Store: fatal |
| Xbox / Gaming Services | AppX removed: `*GamingApp*`, `*XboxApp*`, `*Xbox.TCUI*`, `*XboxGameCallableUI*`, `*XboxGameOverlay*`, `*XboxGamingOverlay*`, `*XboxIdenitity*` (sic; the typo means `XboxIdentityProvider` probably survives, inference), `*XboxSpeechToTextOverlay*`; services `XblAuthManager`, `XblGameSave`, `XboxNetApiSvc` stop | **Absent** | - | Game Pass / Xbox sign-in impossible | Xbox: fatal |
| Defender | `components.yml`: deletes `Windows Defender` program files and data folders, Defender scheduled tasks; `Sense`, `wscsvc`, `SecurityHealthService`/`Systray` services removed; `SecHealthUI` appx removed; SmartScreen off (`SmartScreenEnabled=Off`) | **Absent** (requires `DefenderDisabled` first) | - | Irretrievable (own OOBE text: "rendering them irretrievable") | Security: bad; anti-cheats needing Defender WMI: broken (inference) |
| VBS / HVCI / mitigations | No DeviceGuard/HVCI or mitigation keys found in `regedits.yml` (grep) | Not touched (inference) | - | - | n/a |
| Services | Deletes/stops: `applockerfltr`, `devicecensus`, `WpcMonSvc`, `WMPNetworkSvc`, `StorSvc`, `wisvc`, `webthreatdef*`, `UevAgentService`, `cloudidsvc`, `wscsvc`, `BITS`, `DoSvc`, `iphlpsvc`, `Winmgmt` (stop), `DiagTrack`, `RetailDemo`, `dmwappushservice`, `lfsvc`, `MapsBroker`, `NetTcpPortSharing`, `RemoteAccess`, `RemoteRegistry`, `SharedAccess` (Firewall/ICS), `TrkWks`, `WbioSrvc` (Hello) | Absent; far more destructive | - | `StorSvc`, `iphlpsvc`, `SharedAccess` removal breaks Store/UWP networking features (inference) | Servicing: bad |
| Scheduled tasks | Defender tasks removed (`Cache Maintenance`, `Cleanup`, `Scheduled Scan`, `Verification`); others in `files.yml` (not read) | Absent | - | - | - |
| Telemetry / privacy | `AllowTelemetry=0`, SmartScreen off, DiagTrack deleted; large `regedits.yml` | Similar scope, harsher | - | - | - |
| Power / CPU / timer | Not a performance playbook; `w32tm` NTP set to `pool.ntp.org`; `manage-bde -off C:` decrypts the system drive | Absent | Time sync | **BitLocker decrypt unconditional** | n/a |
| Network | `iphlpsvc`, `SharedAccess` deleted; `w32tm` | Absent | - | IPv6 transition tunnelling gone | Xbox Live Teredo: broken (inference) |
| UI / shell | OpenShell, Fluent skin, `Layout*.xml`, wallpaper | Differs | - | - | None |
| Edge / browsers | Full Edge removal: services `edgeupdate*`, `MicrosoftEdgeElevationService` deleted; `HKCR\MSEdge*`; `Microsoft-Windows-Internet-Browser-Deployment` system package; EdgeUpdate/EdgeCore/EdgeWebView folders deleted | Stricter than Atlas | - | **WebView2 deleted**, breaking Store/Widgets/Xbox hosted UI | Store/Xbox: fatal |
| OneDrive | `OneDrive*` killed and removed; `OneSyncSvc*` deleted | Similar | - | - | None |
| Revert path | None ("irretrievable"); `UpgradableFrom 0.6-0.7` only | Absent | - | - | - |
| Account / UAC | `security-enhanced`: `ConsentPromptBehaviorAdmin=5`, `PromptOnSecureDesktop=1`, `EnableLUA=1`, `FilterAdministratorToken=0`, `ADMIN.bat`; requirements `LocalAccounts`, `AdministratorPasswordSet` | Differs; conflicts with EclipseOS "local account without password" | Hardening | Requirement forces an Administrator password | Conflicts with goals |

### 5.3 Ideas
- **Adopt**: nothing at the code level; the only design lesson is the explicit "irretrievable" disclosure (EclipseOS should state
  the opposite: everything reversible).
- **Avoid**: all of it as a base: deletion of Defender, Update, Store, Xbox, WebView2; `AdministratorPasswordSet` and
  `LocalAccounts` requirements (conflict with passwordless local account); unlicensed code (cannot be reused).

## 6. Cross-playbook recommendations for EclipseOS

| Idea | Source | Verdict | Reason |
|---|---|---|---|
| Tiered presets (Safe/Balanced/Extreme) with option gates and a CI validator for never-touch services and protected appx families | UltraOS (`scripts/validate-playbook.py`, `research/01-architecture.md` section 7.7) | Adopt | GPL-3.0; directly enforces Store/Xbox goal; reuse the protected list: `Microsoft.WindowsStore*`, `WebView2`, `XboxIdentityProvider*`, `Xbox.TCUI*`, `GamingServices`, `wuauserv`, `UsoSvc`, `DoSvc`, `TrustedInstaller` |
| Pre-install snapshot + Verify + Restore + deployment receipt | Chamber (design only; code is CC BY-NC-SA) | Adopt (rewrite) | Gives the lab loop a measurable pass/fail per option |
| Backup of services/appx/tasks plus HTML report plus restore point | UltraOS | Adopt | GPL-compatible, small |
| `onUpgrade` revert.yml that deletes keys earlier versions set; record regressions (VulnerableDriverBlocklist=0, SvcHostSplitThreshold) | ReviOS | Adopt | Real regression history (THE FINALS, XboxGipSvc) |
| "Windows re-arms telemetry at first sign-in" re-apply task | Chamber 1.3.0 | Test in 26300 lab | Observed on 26300 ISO install; check whether it also hits Atlas |
| Keep VBS/HVCI on by default; option only, with warning | Chamber, UltraOS | Adopt | Meets stated goal; UltraOS and Chamber cite Vanguard/FACEIT requirement (not independently verified) |
| Forced-value pattern for disabling VBS (explicit `Enabled=0`, clear `WasEnabledBy`) | UltraOS (derived from Atlas) | Adopt for the opt-in path | Needed on 24H2+ builds |
| Leave `DisableHardwareRequirements` unset in ISO block | Chamber | Adopt | Anti-cheat needs TPM/SB |
| CPU-aware Game Bar logic (dual-CCD X3D) | RapidOS | Consider | Inference that scheduler detection depends on Game Bar; check AMD docs before relying on it |
| `AutoDownload=4` (Store auto-update on) vs Atlas value 2 | ReviOS | Test | Cheap lab A/B on Store app updates |
| WU pause to 2038 | ReviOS | Avoid | Disables security updates; contradicts "WU fully updated" rule |
| Defender off, VBS off, SAC off, MOTW off, UAC secure desktop off by default | ReviOS, RapidOS | Avoid | Security and anti-cheat |
| WinSxS removal packages, IFEO `taskkill` debugger hijacks, spoofed-parent Edge uninstall, unpinned `latest` runtime downloads | ReviOS | Avoid | Opaque, unrevertable, flagged by AV, supply-chain risk |
| Deleting Defender/Update/Store/WebView2/Xbox identity | AME 11, KiyomizuOS (prior survey) | Avoid | Breaks the core goal |
| `SysMain`/`WSearch`/`TabletInputService` disabled unconditionally | Chamber | Avoid as default | Make opt-in as in UltraOS |
| `LetAppsRunInBackground=2` | Chamber | Avoid as default | Can break Store app background tasks (inference) |
| Hosts-file telemetry blocks | Chamber | Test | Confirm no Store/Xbox/Windows Update host is blocked in the lab |

## 7. Gaps and caveats
- Cross-checked against `C:\Atlas.librarian\docs\eclipseosesearch\problem-catalog.md`: ReviOS `NoAutoUpdate`/pause = C02; ReviOS `ms-gamebar` handler = B06 (#139); VCLibs reinstall = B08 (#219); `AutoDownload` 2 vs 4 = B07; Chamber `remove-xbox` and AME 11 Store/Xbox/WebView removal = B05; AME 11 WU deletion = D05; VBS-off defaults (ReviOS, RapidOS) = D01/E05; RapidOS SAC/MOTW/mitigations and UltraOS mitigations opt-in = D04; Chamber hosts blocks = C04 (Chamber's list was spot-checked for six telemetry hosts only, no Store/login host seen, but the full file was not read); Chamber USB selective suspend = E04; Chamber BCD/timer = E02/E03.
- ReviOS `revitool` internals (what `defender disable --force`, `vbs disable`, `wu-pause-updates`, WinSxS packages write) are not in the
  playbook repo; claims above come from the playbook comments and arguments.
- Not read in full: ReviOS `registry/**` remaining files, `hosts`, `FINALIZE.cmd`; Chamber `0-snapshot.yml`, `8-configure-windows.yml`,
  `Set-ChamberPowerPlan.ps1`; RapidOS `Updates`/`Toolbox` `.bat`, `Security.ps1`, `Recall.yml`, `Adapters.yml`;
  AME `regedits.yml` (676-line `files.yml`, 405-line `software.yml`).
- No source here verifies any playbook on a clean 26300 install except Chamber's single author ISO test (`CHANGELOG.md` 1.3.0) and
  the ReviOS PR noted in the prior survey; none of this was run.
- UltraOS dossiers (`research/*.md`) are the authors' own AI-agent output; treat as leads.
