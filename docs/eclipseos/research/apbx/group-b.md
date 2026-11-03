# AME Wizard playbooks, group B, vs AtlasOS (for EclipseOS)

Read-only research, 2026-11-02. All files were read as text through `gh api` (repo contents). No `.apbx`, `.exe` or `.zip` was downloaded or run.
Atlas baseline = `C:\Atlas\src\playbook` (`playbook.conf`: builds 26100/26200 only; options include `mitigations-default` default, `auto-updates-disable` default, `disable-core-isolation`, `uninstall-edge`; no WU pause dates; Defender via `Z-Atlas-NoDefender-Package`, `src/playbook/Configuration/atlas/components.yml:46`).
Prior survey: `C:\Atlas.librarian\docs\eclipseos\research\26h2-playbooks.md`. Claims marked "(inference)" are unverified. Repo raw paths are relative to the repo root on `main`.

Repos: SynergyOS `Synergy-Tweaks/SynergyOS`; NOVA `synoxvf/NOVA`; KiyomizuOS `KiyomizuSuzu/KiyomizuOS`; ShimmerOS `u-chr/ShimmerOS`; LexBoosT OS `LexBoosT/LexBoosT_OS`; GamerzOS `GamerzOS-Playbook/GamerzOS`.

## 0. Metadata summary

| | SynergyOS | NOVA | KiyomizuOS | ShimmerOS | LexBoosT OS | GamerzOS |
|---|---|---|---|---|---|---|
| Version (conf) | **1.8.0** on main (release tag 1.7, 2026-10-23); survey said 1.7 | 1.0.1 (2026-10-17) | 3.0.1 Preview (2026-10-10) | 1.5.2 (2026-10-28) | 26.10.1 (2026-10-23) | 0.2 (release 2025-08-29, last push 2026-09-03) |
| License (GitHub) | none declared | Apache-2.0 | AGPL-3.0 | none declared | none declared | GPL-3.0 |
| 26300 in SupportedBuilds | yes (also 19044/45, 22000/22621/22631/22635, 26100/26200) | yes (26100, 26200, 26300, 22631) | yes (26300, 26200 only) | yes (19042..26300) | yes (26200, 26300, **28000**) | **no** (19045, 26100 only) |
| Requirements | DefenderToggled, NoPendingUpdates, NoAntivirus, Internet, PluggedIn, **PasswordSet** | DefenderToggled, UCPDDisabled, NoAntivirus, **FreshInstall**, Internet, PluggedIn | Internet only | **DefenderDisabled**, NoAntivirus, Internet | DefenderToggled, Internet, NoPendingUpdates, NoAntivirus, PluggedIn | DefenderToggled, NoAntivirus, Internet, NoPendingUpdates, PluggedIn, FreshInstall |
| Install method | post-install + ISO (`SupportsISO` true) | ISO injection only (README warning; FreshInstall) | post-install + ISO | post-install | post-install (`Overhaul`, `UpgradableFrom 26.10`) | post-install (Atlas fork) |
| Options and defaults | browser (default Brave); SynToolkit **on**; Remove Edge **on**; Disable Xbox services **on**; Disable VBS/HVCI off; Disable Defender off; Disable mitigations off; UAC radio default enable | all checkbox pages `IsRequired`, no `IsChecked` (unchecked by default (inference from AME semantics)); Defender radio default **disable-defender**; VBS radio default **enable-vbs**; context menu default legacy | browser LibreWolf default (or Helium or none); theme dark default; no security options | Disable Power Saving **on**; Disable Mitigations **on**; Disable UAC **on**; StartAllBack **on**; OLED theme off | backup radio (default none); Remove Edge off; Install Browser off; 6 browsers | browser radio (default Brave); Atlas-style options |
| Bundled/downloaded binaries | `NoDefender.cab` (test-signed), `MinSudo.exe`, `PowerRun.exe`, `GoInterruptPolicy.exe`, `DeviceCleanup.exe`, `Autoruns.exe`, `skin.skin*`; Syn `PROVENANCE.md` | `NSudo.exe`, CRU, DevManView, GoInterruptPolicy, MSI Util, Autoruns, procexp64, MouseTester, xperf 7z, ReservedCpuSets.7z | none in repo; downloads PowerShell 7.6.6 MSI, 7-Zip-zstd, VC++ redist, LibreWolf/Helium installers, `Bluetooth.exe` + `FileOrFolderInUse.exe` from the author's own GitHub, Sysinternals Handle | none big; downloads VCRedist AIO, DirectX 2010, 7-Zip, StartAllBack, "Shimmer Software" | **~48 MB `INSTALLSOFTS.exe`**, xperf DLL set, DWMManager, DevManView, ViVeTool, SetTimerResolution, NilesoftShell, 1-sPowers, PasswordGenerator (25 MB), `winver.exe` | `BS_THEME_CHANGER.exe` (2.2 MB); Atlas-style NoDefender package |
| Revert path | Post-install `SOS\2. Configuration\*` batches (UAC, VBS, mitigations, Xbox, services), `Default Services.lnk`; Defender removal **permanent** (cab); Edge removal "irreversible" | `Post-Install\*` Enable/Disable batches incl. Defender `Enable.ps1`, VBS, Xbox | none declared; Edge/Xbox apps removed (store reinstall) | per-tweak `on.bat`/`off.bat` under `Executables/Shimmer/Software/Tweaks/*`; `Default Services.lnk`; services backup | `ROLLBACK.PS1`, `BACKUP.PS1` (optional backup radio), Settings module Enable/DisableMitigations | `winServices.reg` backup + desktop folder toggles (same as Atlas) |

Sources: `playbook.conf` at repo root of each (NOVA: `src/playbook.conf`, GamerzOS: `src/playbook.conf`); license from `gh api repos/<r>`.

Extra points not in the prior survey:
- SynergyOS main requires `PasswordSet`. This blocks EclipseOS's local account without password (needs patching or a different fork base).
- SynergyOS README says UAC off (`EnableLUA=0`) makes UWP/Store apps stop working (README, "Disable User Account Control" row). ShimmerOS applies exactly that by default.
- LexBoosT supports build 28000 (future-proof) and is the only playbook in this group that explicitly sets Store service startups.

---

## 1. SynergyOS (1.8.0 main)

Files: `Configuration/custom.yml`, `Configuration/Tasks/{services,updates/update,updates/driver,package/appx,package/components,registry/settings,registry/privacy}.yml`, `Executables/{xbox,vbs,mitigations,final,updhealth,power,network,DisableDefender}*`.

| Area | What it changes | Diff vs Atlas | Positive | Negative/risk | Impact |
|---|---|---|---|---|---|
| Windows Update | `PauseUpdates*`, `PauseFeature/QualityUpdates*End = 2038-01-19`; policy `NoAutoUpdate=1`, `AUOptions=2`, `AutomaticMaintenanceEnabled=0`; **`DoNotConnectToWindowsUpdateInternetLocations=1`**; `WindowsStore\DisableOSUpgrade=1`; `ExcludeWUDriversInQualityUpdate=1`; `DriverSearching\DontSearchWindowsUpdate=1`; DO off; `updhealth.bat` deletes Update Health Tools MSI entries (`Tasks/updates/*.yml`, `Executables/updhealth.bat`) | stricter than Atlas (`Configuration/tweaks/qol/windows-update/disable-auto-updates.yml` only stops auto-install, no pause date, no internet-location block) | fewer surprise reboots | `DoNotConnectToWindowsUpdateInternetLocations` plus pause to 2038 make manual WU and Store-dependent servicing (Gaming Services, Store runtime) hard; cannot patch the OS | Servicing: bad. Security: no cumulative updates |
| Store/AppX removals | removes `ContentDeliveryManager`, **`ConnectivityStore`**, `Client.WebExperience`, `Photos`, `Calculator`, `Todos`, `OneDrive`, `Clipchamp`, `Bing*`, Teams, Outlook, etc.; keeps Store, `GamingApp`, `GamingServices` (`Tasks/package/appx.yml`) | broader than Atlas `Configuration/atlas/appx.yml` | most removals are cosmetic | `ConnectivityStore` and `ContentDeliveryManager` removal is non-standard; Calculator/Photos removal hurts basic use | Store: mostly OK, `ContentDeliveryManager` removal is unverified for Store (inference) |
| Xbox/Gaming Services | option `disable-xbox` **default on**: `XblAuthManager`, `XblGameSave`, `XboxGipSvc`, `XboxNetApiSvc` `Start=4` (`Executables/xbox.bat`); `BcastDVRUserService` disabled; `ms-gamebar` protocol hijacked to `systray.exe` (`registry/settings.yml`) | stricter than Atlas (Atlas does not disable Xbl services by default; `Configuration/tweaks/performance/system/disable-service-host-split.yml` explicitly excludes `Xbl\|Xbox`) | less background load | `XblAuthManager` disabled breaks Xbox app sign-in and Game Pass auth; breaks Store game install of Xbox titles (inference) | Servicing: **high risk** |
| Defender | option `disable-defender` (default off): adds `NoDefender.cab` with an injected **test root certificate** via `Add-WindowsPackage -IgnoreCheck`, removes `SecHealthUI`, `SecurityHealth` Run entries (`Executables/DisableDefender.ps1`) | same family as Atlas (`Z-Atlas-NoDefender-Package`) but the cert stays in the ROOT store ("isn't cleared later") and removal is permanent | optional, off by default | untrusted root certificate on the machine; closed binary | Security: high if chosen |
| VBS/HVCI/mitigations | `disable-vbs` default **off** (`vbs.bat` sets `EnableVirtualizationBasedSecurity=0`, HVCI 0, `LsaCfgFlags=0`, `RunAsPPL=0`); `disable-mitigations` default **off** (kernel `MitigationOptions=0x2222...`, CFG-XFG off, `FeatureSettingsOverride=3`, `FeatureSettingsOverrideMask=3`, `mitigations.bat`); `bcdedit /set nx optin`, `disabledynamictick yes` (`final.bat`) | looser by default than Atlas: both options are off by default, whereas the lab shows Atlas `disable-core-isolation` (`playbook.conf` l.111) turns VBS/HVCI off | VBS/HVCI stay on by default: matches EclipseOS goal | `nx optin` weakens DEP for non-opt-in apps; `RunAsPPL=0` in the VBS option also disables LSA protection | Anti-cheat: OK by default |
| Services | disables ~50 incl. `BDESVC`, `LanmanServer`, **`SharedAccess`**, `Spooler`, `sysmain` (later set back to Manual in settings.yml), `bam`, `CldFlt`, `SEMgrSvc`, `NetBT`, `WerSvc`, `DiagTrack`, `pcasvc`, `wsearch`, `dps`, `WdiServiceHost` (`Tasks/services.yml`, `final.bat`) | stricter than Atlas (`Configuration/atlas/services.yml` is shorter) | lower RAM/boot time | `SharedAccess` off breaks Windows Firewall/ICS pieces (inference); `BDESVC` off blocks device encryption; no Store services touched | Servicing: neutral; Security: firewall risk |
| Scheduled tasks | `Power Efficiency Diagnostics\AnalyzeSystem` disabled; WindowsAI tasks deleted (`Tasks/package/components.yml`) | narrower than NOVA/Shimmer | low risk | none | neutral |
| Telemetry/privacy | privacy registry set, settingSync disabled (policy `DisablesettingSync=2`), Copilot/Recall tasks deleted | similar to Atlas `Configuration/tweaks/privacy/*` | fine | none | neutral |
| Power/CPU/timer | imports `SOS.pow` (Windows/SOS.pow, 32 KB, `power.bat`); `Win32PrioritySeparation=36`; `HwSchMode=2`; `disabledynamictick yes`; deletes `useplatformclock/tick`; `powercfg /h off`; memory compression off | roughly Atlas-like plus dynamic tick | proven low-latency set | `Disable-MMAgent -MemoryCompression` hurts low-RAM systems | gaming perf: positive |
| Network | `TcpAckFrequency=1` per interface, `timestamps=disabled` (`network.bat`) | similar to Atlas `Configuration/tweaks/networking/*` | fine | `TcpAckFrequency=1` is a placebo on modern stacks (inference) | neutral |
| UI/shell | taskbar left, no widgets/search box, dark theme, wallpaper, custom `.skin`; Taskband favorites cleared | like Atlas | fine | `.skin`/`.skin7` binaries (0.5 to 0.7 MB) | neutral |
| Edge/browsers | option `remove-edge` **default on** (irreversible, deletes `edgeupdate*`, `MicrosoftEdgeElevationService`, Deprovisioned keys) via `edge.bat`; Brave/Chrome/Firefox choice | stricter than Atlas (`uninstall-edge`, unchecked) | gone | **WebView2** removal risk not checked (Store/Xbox/Widgets use it; inference); default on is risky | Store: WebView2 loss would break Store/Xbox UI parts (inference) |
| OneDrive | `oned.bat`, `OneSyncSvc*` delete, setup exe deleted (iso) | same as Atlas | ok | none | neutral |
| Revert path | `SOS\2. Configuration` has Default Services, UAC, VBS, mitigations, Xbox, Wi-Fi, Bluetooth, Print batches | comparable to Atlas folder (`AtlasDesktop`) | good revert for toggles | Defender cab and Edge removal irreversible | n/a |

---

## 2. NOVA 1.0.1 (ISO injection only)

Files: `src/playbook.conf`, `src/Configuration/main.yml`, `Tasks/{security,windows,registry}/*.yml`, `src/Executables/{GAMEBAR,EDGE,POWERPLAN,MSI,DEFENDER}*`.

| Area | What it changes | Diff vs Atlas | Positive | Negative/risk | Impact |
|---|---|---|---|---|---|
| Windows Update | `NoAutoUpdate=1`, `AUOptions=1`, `ExcludeWUDriversInQualityUpdate=1`, `WindowsStore\AutoDownload=2`, `DODownloadMode=99`, pause to 2030-12-31, Insider off (`Configuration/main.yml`) | stricter than Atlas auto-updates-disable | no forced reboots | README says use UUP Dump with updates; pause to 2030 locks Store-driven servicing | Servicing: risk |
| Store/AppX | removes `Microsoft.Windows.DevHome`, `Copilot`, `BingSearch`, `Paint`, `OutlookForWindows`, `WindowsCamera`, `Edge.GameAssist`, `OneDrive`, wildcard `*Bing*`, `*Parental*`, etc.; Store, StorePurchaseApp, AppInstaller, VCLibs kept (`Tasks/windows/appx.yml`) | broader than Atlas `Configuration/atlas/appx.yml` | clean | wildcard `*Bing*` | Store ok |
| Xbox/Gaming Services | option `uninstall-xbox` (unchecked, `GAMEBAR.ps1 -UninstallXbox`): removes `GamingApp`, `XboxApp`, `XboxIdentityProvider`, `Xbox.TCUI`, overlays, **`Microsoft.GamingServices`**; sets `XblAuthManager`, `XblGameSave`, `XboxGipSvc`, `XboxNetApiSvc` disabled; PresenceWriter | stricter than Atlas, but optional | explicit opt-in | removing Gaming Services + Identity Provider breaks Xbox/Game Pass/PC-game installs | Servicing: breaks if chosen |
| Defender | radio default **disable-defender** (`Tasks/security/defender.yml` runs `Scripts/DEFENDER.ps1` as TI): sets `TamperProtection=0`, services `WinDefend`, `Sense`, `wscsvc`, `SecurityHealthService` Start=4, SmartScreen off incl. Edge/Store apps; also disables LSA PPL ("Defender and LSA Protected Process Light") | stricter than Atlas default (Atlas default also removes Defender; `Configuration/atlas/components.yml`) | revert script `Post-Install/3 - Security/Windows Defender/Enable.ps1` | `StoreAppsSmartScreenOff` disabled; `wscsvc` off | Security: no AV by default |
| VBS/HVCI | radio default **enable-vbs** ("Required for Valorant and FaceIT"); `disable-vbs` sets HVCI, KernelShadowStacks, `EnableVirtualizationBasedSecurity`, `RequirePlatformSecurityFeatures` to 0 (`Tasks/security/vbs.yml`) | looser option set but safer default: VBS stays on (lab: Atlas default turns it off) | explicit anti-cheat guidance | n/a | Anti-cheat: good |
| Services | `DiagTrack`, `dmwappushservice` Start=4; `OneSyncSvc*`, `WSAIFabricSvc` deleted; Edge services deleted (option); DISM disables `WindowsMediaPlayer`, `SMBDirect`, `MSRDC-Infrastructure`, `Workfolders-client`, `SearchEngine-Client-Package` | stricter | small | `SearchEngine-Client-Package` removal changes Start search (inference) | neutral |
| Scheduled tasks | WindowsAI, `OneDrive Standalone Update Task`, Sustainability telemetry, Edge update tasks | similar to Atlas | fine | none | neutral |
| Telemetry/privacy | `AllowTelemetry=0`, CEIP, Recall tasks deleted, WindowsAI policies, hosts file (`src/Executables/hosts`) | similar plus hosts | hosts block is a robust no-service approach | hosts block can break connectivity checks (inference) | neutral |
| Power/CPU/timer | `Win32PrioritySeparation=24`, `SystemResponsiveness=10`, `NetworkThrottlingIndex=0xFFFFFFFF`, IFEO `CpuPriorityClass=5` for `MoUsoCoreWorker`, `CompatTelRunner`, `RuntimeBroker`, `spoolsv`; `HwSchMode=2`; NOVA.pow plan (v1.0.0 BSOD, fixed per survey); NVMe `stornvme` APST/coalescing off; bcdedit `x2apicpolicy enable`, `quietboot`, `bootmenupolicy legacy`; `powercfg /h off` (option); FTH off; ReservedCpuSets 7z; MSI auto script | broader than Atlas | rich tuning | IFEO priority on `RuntimeBroker` (used by Store apps) is Idle-ish priority 5 = Below Normal; `encryptpagingfile 0` | gaming perf: positive; servicing: `RuntimeBroker` slow (inference) |
| Network | LLMNR/mDNS off, NetBIOS off, WPAD override, `rss`, `rsc=disabled`, `fastopen`, `uro=disabled`, `uso=enabled` (`registry/network.yml`) | broader than Atlas `networking/` | privacy/latency | `rsc=disabled` raises CPU at 1 Gbps+ | gaming: neutral/positive |
| UI/shell | taskbar left, transparency off, legacy context menu default, NOVA theme; `start2.bin` | similar | fine | none | neutral |
| Edge/browsers | option `uninstall-edge` (unchecked): `EDGE.bat`, deletes `EdgeUpdate`, policies, `MicrosoftEdgeCP/SH/BCHost`, HKCR classes; `EdgeWebView` dirs also deleted (`rmdir ...\EdgeWebView`, `file: ...\EdgeWebView`) | broader than Atlas | thorough | **deletes WebView2 runtime** under `Program Files (x86)\Microsoft\EdgeWebView` | Store/Xbox UI: risk (inference) |
| OneDrive | AppX + registry + Run key removal | same | fine | none | neutral |
| Revert path | `Post-Install\*` batches only for post items; ISO changes (Edge, Xbox, Defender) have no way back except reinstall | weaker than Atlas | n/a | README: ISO injection only | n/a |

---

## 3. KiyomizuOS 3.0.1 Preview

Files: `playbook.conf`, `Configuration/main.yml`, `Executables/{BloatRemoval,Service,ScheduledTask,Registry,PowerPlan,EdgeRemoval,OneDriveRemoval,LiveSystem}.ps1`.

| Area | What it changes | Diff vs Atlas | Positive | Negative/risk | Impact |
|---|---|---|---|---|---|
| Windows Update | `PauseUpdatesExpiryTime=2051-12-31`, `FlightSettingsMaxPauseDays=10023`, `PausedFeatureStatus=1`, driver search off; no `NoAutoUpdate` policy (`Registry.ps1` ~l.857) | looser than Atlas/Synergy (UX pause only, services untouched) | WU stays functional if the user unpauses | pause to 2051 stops patching unless reset | Servicing: manual unpause works |
| Store/AppX | removes `WindowsCalculator`, `WindowsCamera`, `WindowsTerminal`, `Windows.Notepad`, `RemoteDesktopConnection`, `PowerAutomateDesktop`, `Client.WebExperience`; Store kept (`BloatRemoval.ps1`) | broader than Atlas (Calc/Terminal/Notepad) | lean | Terminal, Notepad removal annoys users | Store ok |
| Xbox/Gaming Services | removes **`GamingApp`, `XboxIdentityProvider`, `Xbox.TCUI`, `XboxGamingOverlay`, `XboxSpeechToTextOverlay`**; `XblAuthManager`, `XblGameSave`, `XboxNetApiSvc` set Manual (not disabled); Game DVR registry applied only if Xbox packages remain | stricter than Atlas on apps, looser on services | services are only Manual, so Store-installed Xbox titles can still restore the apps | no Xbox app, no Identity Provider: no Xbox/Game Pass sign-in until reinstall | Servicing: **breaks Xbox app and sign-in** |
| Defender | not touched | looser than Atlas (Atlas removes Defender; `Configuration/atlas/components.yml`) | AV and Tamper Protection untouched: matches EclipseOS goal | none | Security: positive |
| VBS/HVCI/mitigations | not touched | looser than Atlas (`script-core-isolation.yml`, `script-mitigations.yml`) | VBS/HVCI default on | no mitigation tuning | Anti-cheat: positive |
| Services | mostly **Manual**: `DiagTrack`, `WerSvc`, `lfsvc`, `Spooler`, `WSearch`, RDP, smart card, `MapsBroker`, `RasMan`; Disabled only `SysMain`, `WSAIFabricSvc`, `PcaSvc`; renames `TextInputHost.exe` to `.old.exe` (`Service.ps1`) | much gentler than Atlas | low breakage risk, easy undo | `TextInputHost.exe` rename breaks emoji panel/touch keyboard (inference) | neutral |
| Scheduled tasks | 13 tasks: Appraiser Exp, `StartupAppTask`, `MapsUpdateTask`, `Proxy`, `Consolidator`, `UsbCeip`, `DiskDiagnosticDataCollector`, `DmClient*`, `Sqm-Tasks` (`ScheduledTask.ps1`) | narrower than Atlas | conservative | none | neutral |
| Telemetry/privacy | `AllowTelemetry` policy, ContentDeliveryManager keys, Copilot/Recall policies, ConsentStore Deny for `userAccountInformation`, `appDiagnostics`; Wi-Fi MAC randomization; Bluetooth off via downloaded `Bluetooth.exe` | similar to Atlas | MAC randomization is a good idea | Bluetooth.exe is an unsigned download (inference) | neutral |
| Power/CPU/timer | Winhance power plan (`PowerPlan.ps1`, via `powercfg`), `HwSchMode=2`, MMCSS `GPU Priority=8`, `disablelastaccess`, `disable8dot3` | milder than Atlas | safe | no timer or latency tuning | gaming perf: small |
| Network | none beyond Wi-Fi randomization | absent | n/a | no gaming network tuning | neutral |
| UI/shell | Dark/light, taskbar layout, LibreWolf or Helium default browser via DISM default associations, per-user ActiveSetup | similar | fine | none | neutral |
| Edge/browsers | `EdgeRemoval.ps1` uses Edge's own `--force-uninstall`; skips `EdgeWebView` ("notlike *EdgeWebView*") | gentler than Atlas | **keeps WebView2** | none | Store/Xbox UI safe |
| OneDrive | `OneDriveRemoval.ps1` | same | fine | none | neutral |
| Revert path | none documented; edition switched to **Pro for Workstations** with a script | weaker than Atlas | n/a | edition change, installs PowerShell 7 required, downloads without hash pinning | n/a |

---

## 4. ShimmerOS 1.5.2

Files: `playbook.conf`, `README.md`, `Configuration/custom.yml` (1416 lines), `Executables/Shimmer/Software/Tweaks/*`, `Executables/hosts`.
README: explicitly "NOT designed for" Defender/BitLocker, Windows updates, Microsoft accounts, biometric login, System Restore.

| Area | What it changes | Diff vs Atlas | Positive | Negative/risk | Impact |
|---|---|---|---|---|---|
| Windows Update | `NoAutoUpdate=1`, `AUOptions=2`, pause to 2033, `DisableDualScan=1`, **`DoNotConnectToWindowsUpdateInternetLocations=1`**, `SetDisableUXWUAccess=1`, `DisableOSUpgrade=1`, `WindowsStore\AutoDownload=2`, `FlightSettingsMaxPauseDays=3650` (`custom.yml` l.243-277) | stricter than Atlas | none | WU effectively dead | Servicing: bad |
| Store/AppX | removes `Microsoft.Xbox*`, `GamingApp`, `Photos`, `WindowsTerminal`, `Copilot*`, `WebExperience`, `StickyNotes`, `YourPhone`, `Office.*`, all common bloat (`custom.yml` l.1059-1129); Store kept | broader than Atlas | thorough | `Microsoft.Xbox*` wildcard removes `XboxIdentityProvider`, `TCUI`, `GamingOverlay` | Xbox sign-in broken |
| Xbox/Gaming Services | AppX removal as above; `GameInputSvc` disabled; `BcastDVRUserService`; GameDVR off; Force_FSE tweak; Xbl services not explicitly listed | stricter than Atlas | FSE optimization | `GameInputSvc=4` breaks some input libraries (inference) | Servicing: breaks Xbox |
| Defender | `DisableAntiSpyware=1`, `DisableBehaviorMonitoring`, `EnableSmartScreen=0`; **deletes** registry keys of `WinDefend`, `Sense`, `MsSecCore`, `wscsvc`, `WdFilter`, `MsSecWfp`, `MsSecFlt`, `SecurityHealthService`; **deletes** `SecurityHealth*.exe/dll` files; requirement `DefenderDisabled` | much stricter than Atlas (Atlas uses a removable package; `Configuration/atlas/components.yml`) | none | irreversible hard removal, no revert; Tamper Protection must be off beforehand | Security: severe |
| VBS/HVCI/mitigations | defaults on: **mitigations off** (kernel `MitigationOptions` cleared tweak states `on.bat` as default Windows, so applied state removes them), Spectre/Meltdown override off, `bcdedit /set vsmlaunchtype Off`, `isolatedcontext no`, `disableelamdrivers yes`, `nx optin`; VBS/HVCI tweak off by default (`Executables/Shimmer/Software/Tweaks/VBS`, `Mitigations`, `Spectre_and_Meltdown`) | stricter than Atlas (Atlas default `mitigations-default`) | revert .bat files exist | ELAM drivers disabled, VBS launch off: anti-cheats (Vanguard, FACEIT) refuse | Anti-cheat: **fails** |
| Services | ~83 set to Start=4 incl. `VSS`, `EFS`, `WSearch`, `WpnService`, `themes`, **`vid`**, `ShellHWDetection`, `GameInputSvc`, `LanmanServer`, `BDESVC`, `TermService`, `Spooler`, `pla`, `wecsvc`; Store services untouched; `Default Services.lnk` and `ServicesBackup` revert | far stricter than Atlas | measured revert path | `VSS` off kills restore points; `themes` off breaks visual styles; `WpnService` off kills Store/UWP notifications | Servicing: partial |
| Scheduled tasks | ~230 lines of task disabling (`custom.yml` l.822-1054) | broader than Atlas | fine | not itemized here | neutral |
| Telemetry/privacy | hosts file with telemetry domains (`Executables/hosts`), `AllowTelemetry`, DiagTrack, ConsentStore changes | broader | simple | hosts block | neutral |
| Power/CPU/timer | `Win32PrioritySeparation=36`, `HwSchMode=2`, MMCSS (`mmcss.ps1`), `GlobalTimerResolutionRequests=1`, AMD/Interrupt steering tweaks, Shimmer.pow plans (`Temp/Shimmer.pow`, `ShimmerHetero.pow`), power-saving disable | broader | auto timer-resolution companion repo | `disablepnp.ps1` disables devices; aggressive | gaming perf: positive |
| Network | `nic.bat` (10 KB) NIC tweaks, `Network_Optimizations/on.bat` | broader | fine | not audited | neutral |
| UI/shell | StartAllBack (installed), OLED theme option | n/a | none | third-party paid shell | neutral |
| Edge/browsers | Edge removal always on (no option; `custom.yml` l.114+) | stricter than Atlas | none | no WebView2 choice | Store/Xbox UI: risk (inference) |
| OneDrive | `onedrive.bat` | same | fine | none | neutral |
| Revert path | per-tweak on/off .bat, services backup, `Default Services.lnk` | comparable to Atlas folder | good | Defender and file deletions irreversible | n/a |

---

## 5. LexBoosT OS 26.10.1

Files: `playbook.conf`, `README.md`, `Configuration/Tasks/{services,final,packages/*,registry/*}.yml`, `Executables/Scripts/{DEVICES,SYSTEM_TWEAKS,EDGE,ROLLBACK,BACKUP,FINALIZE*}`.

| Area | What it changes | Diff vs Atlas | Positive | Negative/risk | Impact |
|---|---|---|---|---|---|
| Windows Update | `wuauserv`=Manual(3), `UsoSvc`=Manual(3), `BITS`=Auto(2) (`Tasks/services.yml` l.160,194,260); `NoPendingUpdates` required; no pause or policy found (grep) | **looser than Atlas** (Atlas default disables auto-updates) | WU keeps working | none | Servicing: positive |
| Store/AppX | removes ~100 packages (`Executables/Scripts/APPX-REMOVE-LIST.TXT`): Copilot, AIX/CoreAI, Teams, `Global.*` widgets, `CallingShellApp`, `WindowsBackup`, `Microsoft.ECApp`, Bing, Todos, Camera, Maps, etc.; Store, AppInstaller, Photos kept; README prerequisite: update Store apps first | broader than Atlas | explicit "update Store apps first" matches maintainer rule | very long wildcard list, some (`*Filons*`, `*Speion*`, `*Voiess*`) unknown, risk of mismatches (inference) | Store ok |
| Xbox/Gaming Services | `XblAuthManager`, `XboxGipSvc` set to Manual(3) (`services.yml` l.54-56); README says "Xbox GameBar" AppX removed | looser than Atlas on services | Store-installed Xbox titles can still run | Game Bar removed; Xbox app status unclear (README) | Servicing: mostly OK |
| Defender | **Kept**: throttles it (`AvgCPULoadFactor=25`, `ScanAvgCPULoadFactor=25`, `LowPriority=1`, `ScanOnlyIfIdle=1`, `DisableCatchup*Scan=1`, `DisableScheduledScan=1`, `SignatureUpdateInterval=24`) + `Set-MpPreference -ScanAvgCPULoadFactor 20 -EnableLowCpuPriority` under option `enable-defender`; notifications kept; Tamper Protection untouched (`Tasks/registry/security.yml`) | **looser than Atlas** (Atlas removes Defender) | matches EclipseOS goal: AV on, lower CPU; scheduled scans disabled is a risk tradeoff | `DisableScheduledScan=1` + catch-up off means no periodic full scans | Security: positive; gaming perf: positive |
| VBS/HVCI/mitigations | VBS/HVCI keys not found in default tasks (grep for `DeviceGuard` returned none); README claims "Spectre/Meltdown disabled (+5-15 percent CPU)" but the only registry hits are in the optional Settings module `EnableMitigations.cmd`/`DisableMitigations.cmd` and `SYSTEM_TWEAKS.PS1` has none (`FeatureSettingsOverride` found only in Changelog) — the default may therefore be unchanged (inference, contradicts README); bcdedit: `disabledynamictick yes`, delete `useplatformclock/tick/tscsyncpolicy`, `nx optin`, `isolatedcontext No` on AMD, `bootmenupolicy legacy` (`DEVICES.PS1` l.1194-1220) | looser than Atlas for VBS; unclear for mitigations | VBS untouched | README claim vs code mismatch, verify in a lab | Anti-cheat: likely positive |
| Services | 231 `!service` lines; Disabled: telemetry/diag (`DiagTrack`, `diagsvc`, `WdiService*`, `DPS`, `PcaSvc`, `dusmsvc`, `UCPD`, `NvTelemetryContainer`), misc (`AJRouter`, `Fax`, `MapsBroker`, `RemoteRegistry`, `SSDPSRV`, `TrkWks`, `WalletService`, `WSAIFabricSvc`, `MicrosoftCopilotElevationService`, user-service templates); **explicit Store services**: `ClipSVC`=Auto, `TokenBroker`=Auto, `StorSvc`=Auto, `AppXSvc`=Manual, `InstallService`=Manual, `LicenseManager`=Manual (l.175-245) | looser than Atlas, with explicit Store pinning | **best Store-safe services table in this group** | a lot of services set (231) increases collision risk with future builds | Servicing: positive |
| Scheduled tasks | `packages/tasks.yml` (11 KB) + `SCHEDULED-TASKS-DISABLE.PS1` + `DISABLE-TELEMETRY-TASKS.PS1` | similar to Atlas | fine | not itemized | neutral |
| Telemetry/privacy | `registry/telemetry.yml` 24 KB, ConsentStore denies (radios, bluetoothSync, broadFileSystemAccess, libraries; microphone/webcam Allow), generativeAI/systemAIModels Deny, OneDrive KFM blocked, `TELEMETRY_CHECK.PS1` | broader | AI model Deny keys are a good idea | camera/mic Allow by default | neutral |
| Power/CPU/timer | DPC: `IdealDpcRate=1`, `DpcQueueDepth=1`, `ThreadDpcEnable=1`, `SplitLargeCaches`, `MaximumSharedReadyQueueSize=128`, `KiClockTimerPerCpu`; guarded by CPU check (>=6 cores, family >=6); timer-resolution force tools in `LexBoosTOS/Utilities/TimerResolution`; MMCSS `NetworkThrottlingIndex=ffffffff`; TSX enabled; Win32PrioritySeparation; IFEO `csrss IoPriority=High`; Core Parking exposed; `INSTALL-OVERLAY.PS1` | broader | **CPU guard for kernel tweaks** is a good pattern | benefit claims in README (+17 percent FPS, -55 percent latency) unverified marketing | gaming perf: possible positive, unproven |
| Network | `NETSH_TCPIP_APPLY.PS1`, `NIC-TWEAKS.PS1` (16 KB), `MMCSS-NIC.PS1`, `NETWORK-EXTRAS.PS1` | broader than Atlas | fine | not audited | neutral |
| UI/shell | custom dark theme, Nilesoft Shell context menu, cursors, `LexBoosT Launcher` (40+ tools), Start menu wipe, welcome panel | extras | none | many bundled tools incl. 48 MB `INSTALLSOFTS.exe`, 25 MB `PasswordGenerator.exe`; issues disabled on the repo (survey) | supply chain risk |
| Edge/browsers | option `remove-edge` unchecked (`EDGE.PS1 -Mode Full`, 29 KB) + `EDGE-LATENCY.PS1`; 6 browser choices | same as Atlas default (optional) | opt-in | WebView2 handling not verified | neutral |
| OneDrive | `packages/onedrive.yml` + `ONED.CMD` | same | fine | none | neutral |
| Revert path | `ROLLBACK.PS1` (18 KB), `BACKUP.PS1` (registry/services backup option), restore-point advice in README | **better than Atlas** | rollback script exists | not audited for completeness | n/a |

---

## 6. GamerzOS 0.2 (Atlas derivative, no 26300)

Files: `src/playbook.conf`, `src/Configuration/main.yml`, `tweaks.yml`, `GamerzOS/{appx,components,services}.yml`, `tweaks/**`.
Tree mirrors Atlas 0.4.x (`tweaks/privacy/*`, `GamerzOSDesktop` folder, `Z-GamerzOS-NoDefender-Package`).

| Area | What it changes | Diff vs Atlas | Positive | Negative/risk | Impact |
|---|---|---|---|---|---|
| Windows Update | no explicit WU task found in `tweaks.yml` (grep for `WindowsUpdate`, `NoAutoUpdate` returned none); Store `AutoDownload=2` (`tweaks/qol/disable-store-auto-updates.yml`, same as Atlas `Configuration/tweaks/qol/disable-store-auto-updates.yml`) | looser than Atlas (no `windows-update/*` tasks) | WU keeps working | Store auto-updates stay off | Servicing: neutral |
| Store/AppX | `appx.yml` removes common bloat; leaves Store, mentions "Microsoft Store in case the user needs them" for `XboxApp*`, `MSPaint*`; marks `Deprovisioned` keys | similar to Atlas | simple | based on 24H2; no 26H2 appx names | Store ok |
| Xbox/Gaming Services | Service-host splitting disabled for all services except `Xbl\|Xbox` (`disable-service-host-split.yml`, "to fix issues with Game Bar") | same as Atlas | **explicit Xbox exclusion** | none | Servicing: positive |
| Defender | options `defender-disable`/`defender-enable` (`components.yml` l.40-53, `Z-GamerzOS-NoDefender-Package`) | same as Atlas | revert option | same cab-style package as Atlas | Security: same as Atlas |
| VBS/HVCI/mitigations | no task found (grep) | absent | VBS untouched | `DisablePagingExecutive=1`, `DisablePageCombining=1` (`disable-paging.yml`) | Anti-cheat: neutral |
| Services | only: `OneSyncSvc`, `TrkWks`, `PcaSvc`, `DiagTrack`, `diagnosticshub...`, `WerSvc`, `wercplsupport`, `UCPD`; drivers `GpuEnergyDrv`, `NetBT`, `Telemetry` (`GamerzOS/services.yml`) | **much smaller than Atlas** | low risk | `UCPD` disabled (Atlas requires `UCPDDisabled` too) | Servicing: neutral |
| Scheduled tasks | `tweaks/debloat/disable-scheduled-tasks.yml` | same as Atlas | fine | none | neutral |
| Telemetry/privacy | ~35 small privacy tasks cloned from Atlas | same | fine | `NoConnectedUser=1` (`disallow-ms-accounts.yml`) blocks adding a Microsoft account; Atlas has the same file | Store sign-in via MSA: affected (same as Atlas) |
| Power/CPU/timer | `bcdedit /timeout 10`, `bootmenupolicy legacy` only; Atlas-like MMCSS, `win32-priority-seperation` | same as Atlas | safe | none | neutral |
| Network | LLMNR off, SMB anonymous restrictions | same as Atlas | fine | none | neutral |
| UI/shell | GamerzOS theme via `BS_THEME_CHANGER.exe` | extra | none | closed binary | neutral |
| Edge/browsers | `uninstall-edge` option via `RemoveEdge.ps1 -KeepAppX` | same as Atlas | fine | none | neutral |
| OneDrive | stripped at component level | same | fine | none | neutral |
| Revert path | `winServices.reg` backup + desktop folder toggles | same as Atlas | fine | build 26100 only | n/a |

---

## 7. Ideas for EclipseOS

### Adopt (with reason)

| Idea | From | Reason |
|---|---|---|
| Keep Defender running but throttle: `AvgCPULoadFactor`/`ScanAvgCPULoadFactor`, `LowPriority`, `ScanOnlyIfIdle`, `DisableCatchup*`, `Set-MpPreference -EnableLowCpuPriority`, `SubmitSamplesConsent`, keep Security Center notifications; do not touch Tamper Protection | LexBoosT `Configuration/Tasks/registry/security.yml` | Matches goals (secure + light) and the lab fact that Atlas leaves Tamper Protection off; do not copy `DisableScheduledScan=1` blindly |
| Explicit Store service pinning (`ClipSVC` Auto, `TokenBroker` Auto, `StorSvc` Auto, `AppXSvc`/`InstallService`/`LicenseManager` Manual, `BITS`/`wuauserv`/`UsoSvc` untouched) | LexBoosT `Tasks/services.yml` l.160-260 | Turns "Store installs must work" into a testable service table; add as a lab assertion |
| Services to Manual instead of Disabled (not Start=4) for Xbox and network helpers | Kiyomizu `Service.ps1`, LexBoosT | Reversible by on-demand start; avoids breaking Xbox/Store triggers |
| `SvcHostSplitDisable` exclusion for `Xbl\|Xbox` | GamerzOS/Atlas `disable-service-host-split.yml` | Already in Atlas; keep and extend to `GamingServices`, `ClipSVC`, `TokenBroker` (inference) |
| VBS radio default **enable** with anti-cheat text, and keep disable as opt-in | NOVA `playbook.conf` radio `enable-vbs`; Synergy default off | Direct EclipseOS goal; opposite of Atlas `disable-core-isolation` |
| Mitigation toggle opt-in only, off by default | Synergy `disable-mitigations` (unchecked), Atlas `mitigations-default` | Keep default Windows mitigations |
| CPU guard before kernel timer/DPC tweaks (>=6 physical cores, family check) | LexBoosT `SYSTEM_TWEAKS.PS1` l.43-60 | Avoids audio/stability regressions on low-end CPUs |
| WebView2-safe Edge removal (use Edge's own uninstaller, skip `EdgeWebView`) | Kiyomizu `EdgeRemoval.ps1` l.314 | WebView2 is used by Store/Xbox/Widgets UI (inference); NOVA and Shimmer delete it |
| Per-tweak on/off bat revert tree + services backup + `ROLLBACK.PS1` | Shimmer `Executables/Shimmer/Software/Tweaks/*`, LexBoosT `ROLLBACK.PS1`, `BACKUP.PS1` | Better revert path for every non-default option |
| Wi-Fi MAC randomization (`netsh wlan set randomization enabled=yes`) | Kiyomizu `main.yml` | Privacy, no servicing impact |
| AI model access Deny (`generativeAI`, `systemAIModels`) | LexBoosT `README.md` | Privacy, low risk |
| WU left functional (no `DoNotConnectToWindowsUpdateInternetLocations`, no 2038 pause) with only driver exclusion | LexBoosT, Kiyomizu | Maintainer rule: WU and Store fully updated; Atlas-style auto-update disable only if the user opts in |

### Avoid (with reason)

| Idea | From | Reason |
|---|---|---|
| `DoNotConnectToWindowsUpdateInternetLocations=1`, pause to 2033-2051, `SetDisableUXWUAccess=1` | Synergy, Shimmer | Kills cumulative updates and Store-dependent servicing |
| `PasswordSet` requirement | Synergy `playbook.conf` | Conflicts with local account without password |
| Disabling/removing `XblAuthManager`, `XboxGipSvc`, Identity Provider, TCUI, `GamingServices` by default | Synergy `disable-xbox` default on, Kiyomizu, NOVA (opt-in), Shimmer | Direct Xbox/Game Pass/Store-game regression |
| UAC off (`EnableLUA=0`) | Shimmer default, Synergy option | Synergy README says UWP/Store apps stop working |
| Defender deletion (registry keys and files), test root certificate in ROOT store | Shimmer, Synergy `NoDefender.cab` | Irreversible, untrusted CA; requires Tamper Protection off |
| VBS off, `vsmlaunchtype Off`, `disableelamdrivers yes`, `isolatedcontext no` | Shimmer | Anti-cheat refusal and weaker kernel isolation |
| Kernel mitigations/`FeatureSettingsOverride` off by default; CFG/XFG off | Shimmer default, Synergy option, LexBoosT README claim | Security and anti-cheat; also claimed gains unverified |
| `RunAsPPL=0` / `LsaCfgFlags=0` bundled in the VBS-off option | Synergy `vbs.bat` | Disables LSA protection and Credential Guard as a side effect |
| Services Start=4 for `VSS`, `EFS`, `themes`, `vid`, `WpnService`, `SharedAccess`, `BDESVC`, `LanmanServer` | Shimmer, Synergy | Breaks restore points, firewall pieces, notifications, Hyper-V, encryption |
| IFEO `CpuPriorityClass` on `RuntimeBroker.exe` | NOVA `registry/performance.yml` | RuntimeBroker serves Store/UWP apps (inference) |
| ISO-injection-only distribution | NOVA | Lab fact: AME ISO injection leaves Store/Xbox unable to update |
| Unpinned downloads of binaries/installers from author repos and unsigned tools | Kiyomizu (`Bluetooth.exe`, `FileOrFolderInUse.exe`), LexBoosT (`INSTALLSOFTS.exe` 48 MB), Synergy (`MinSudo`, `PowerRun`) | Supply chain risk |
| Marketing performance numbers without measurements | LexBoosT README | Not evidence |
| Hosts-file telemetry blocking | NOVA, Shimmer | Can break connectivity checks and Store/Xbox endpoints (inference) |

### Verification gaps for the librarian

- LexBoosT: confirm where Spectre/Meltdown mitigations are actually disabled (README says yes; only the optional Settings module and Changelog mention `FeatureSettingsOverride`). Grep `Configuration/Tasks/registry/*.yml` and `Executables/Scripts/FINALIZE*.CMD` found no default application; `SYSTEM_TWEAKS.PS1` sets none.
- NOVA: `IsChecked` is absent on checkboxes, so defaults are unchecked per AME semantics (inference).
- Shimmer: ~230 lines of scheduled-task disabling and the NIC tweaks were not itemized.
- Synergy main is 1.8.0, newer than the 1.7 release the survey recorded; `PasswordSet` may be new.
- No license file declared on SynergyOS, ShimmerOS, LexBoosT OS (GitHub API returns none): do not copy code.
