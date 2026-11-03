# APBX group C vs AtlasOS (for EclipseOS)

Scope: MuulfzOS Fortnite, Meridian 26H2, GamingOS (Witthen), Z-LAG-OS. Method: `gh api` raw text of each repo's conf, YAML and scripts (nothing downloaded or run), read 2026-11-02. Atlas baseline = `C:\Atlas\src\playbook` (conf Version 0.5.0, SupportedBuilds 26100/26200, Requirements DefenderToggled, NoAntivirus, Internet, NoPendingUpdates, UCPDDisabled, PluggedIn). Atlas facts below are from that tree. "(inference)" marks guesses. Abbreviations: A = Atlas path under `src/playbook/Configuration/`.

Ranking for EclipseOS goals: MuulfzOS (best reference for anti-cheat and Store/Xbox safety) > Meridian (diff base for 26H2 fixes) > GamingOS (good option design, destructive Core code that contradicts its own docs) > Z-LAG-OS (negative reference).

---
## 1. MuulfzOS Fortnite
Repo https://github.com/Muulfz/MuulfzOSFN (MIT, last push 2026-10-16).

### 1.1 Metadata
| Item | Value (source) |
|---|---|
| Version/date | 0.9.4, release v0.9.4 2026-10-16 (GitHub API; `playbook/playbook-fortnite.conf`) |
| License | MIT (`LICENSE`) |
| SupportedBuilds | 26100, 26200, 26300 (conf). 28000 deliberately excluded (test `tools/test_fortnite_playbook.py`) |
| Requirements | only `NoPendingUpdates`. No `LocalAccounts` (comment: AME forces a password / bakes credentials) |
| ISO | `SupportsISO` true, DisableBitLocker true, **DisableHardwareRequirements false on purpose** (tournaments need Secure Boot + TPM 2.0 + IOMMU) |
| Options (default) | vbs-off **checked (VBS/HVCI off by default)**; fortnite-high-priority on; x3d-balanced off; wu-no-drivers off; svchost-group off; memcomp-off off; fth-off off; spectre-off off; x3d-affinity off; standby-clean off; Defender radio default `defender-keep` (disable / remove opt-in); install-gpu off; gpu-tweaks-aggressive off; install-epic on; install-chrome off; install-runtimes off; muulfz-wallpaper on |
| Bundled binaries | none seen in tree (wallpaper html, scripts). Installs Epic launcher / Chrome MSI / VC++ from official URLs at apply time (opt-in) |
| Test harness | `tests/vm/validate-fortnite.ps1` (Hyper-V), `bench-compare.ps1`, `tools/test_fortnite_playbook.py` |

### 1.2 Change table
| Area | What it changes | Difference vs Atlas | Positive | Negative/risk | Impact |
|---|---|---|---|---|---|
| Windows Update | Active hours 10:00-04:00 (`WindowsUpdate\SetActiveHours`, `ActiveHoursStart/End`); blocks OutlookUpdate / DevHomeUpdate orchestrator jobs; optional `ExcludeWUDriversInQualityUpdate` (off); asserts WU not disabled (invariant `wuauserv` not Disabled) (`registry/fortnite-qol.yml`) | Looser than Atlas: Atlas disables auto-updates by default (`tweaks/qol/windows-update/disable-auto-updates.yml`, option `auto-updates-disable`); MuulfzOS leaves WU working. Orchestrator block same as Atlas | Store/Xbox servicing stays updatable; no restart in play hours | Needs NoPendingUpdates | Servicing: positive |
| Store/AppX removals | Removes Copilot, Recall, AIX, Bing*, Widgets/WebExperience, Teams, Outlook, To Do, PowerAutomate, DevHome, Family, QuickAssist, CrossDevice, Sticky Notes, Alarms, Camera, Sound Recorder, AI apps (`appx/trim.yml`, `ai-26h2.yml`, `fortnite-debloat.yml`). **Kept on purpose:** Store, Xbox app, Game Bar, Edge, Photos, Paint, Snipping, Notepad, Terminal, codecs (inventory comment from a 26300.9550 VM) | Similar scope to Atlas `atlas/appx.yml`; Atlas also keeps Store/GamingApp (appx.yml line 11 comment). Adds 26H2 packages (QuickAssist, CrossDevice, AIX) that Atlas 0.5.0 lacks | Measured: appx 122 -> 85, processes 139 -> 124 on 26H2 VM (`README.md`) | Removes Photos? no (kept). Nothing risky | Store/Xbox safe |
| Xbox / Gaming Services | Nothing removed; `svchost-group` skips Xbl*/Xbox*/Gaming* and keeps Audiosrv, AudioEndpointBuilder, Dhcp, Dnscache, NlaSvc split (`registry/performance-options.yml`); Game Bar kept for X3D scheduling; GameDVR capture off, Game Mode on (`registry/gamer-input.yml`); validator asserts Store + `Microsoft.XboxGamingOverlay` present | Stricter than Atlas on services split (Atlas excludes only `Xbl|Xbox`, `tweaks/performance/system/disable-service-host-split.yml`). Same GameDVR off as Atlas | Network/audio keep isolation, Xbox keeps own host | none | Positive for Store-Xbox |
| Defender | Default keep + tuned scans (policy `Scan\LowCpuPriority=1`, `AvgCPULoadFactor=20`, `ScheduleDay=8`); `DisableAntiSpyware=0` and `DisableRealtimeMonitoring=0` forced; SmartScreen forced on. Opt-in tiers disable/remove; both detect Tamper Protection via `Get-MpComputerStatus.IsTamperProtected` and skip with a desktop note (`registry/defender-mode.yml`, `anticheat-safe.yml`). Does not write TamperProtection | Stricter than Atlas default (Atlas `defender-enable` default, needs DefenderToggled requirement so Tamper must be off before running). Mu keeps Tamper ON | Defender on by default, Tamper untouched; fits "Tamper Protection on" goal | Disable/remove tiers still exist | Anti-cheat neutral; security positive |
| VBS/HVCI/Core Isolation, mitigations | Option `vbs-off` **default checked**: HVCI `Enabled=0`, `EnableVirtualizationBasedSecurity=0`, `Lsa\LsaCfgFlags=0`; without it, forces HVCI + VBS = 1 and `bcdedit hypervisorlaunchtype auto`; `KernelShadowStacks\Enabled=0` always (breaks EAC error 1275); `VulnerableDriverBlocklistEnable=1`; opt-in `spectre-off` writes `FeatureSettingsOverride/Mask=33554435` (`registry/anticheat-safe.yml`, `performance-options.yml`) | Same default risk as Atlas `disable-core-isolation` (VBS/HVCI off by default). Extra: explicit ON path and Vanguard/FACEIT warning. Mitigations: same as Atlas default (kept), opt-in off | Only playbook here that writes an explicit "VBS on" path and notes Valorant/FACEIT need it; blocklist forced on | Default ships VBS off (~5-8% FPS claimed). Note: on 26H2 hypervisor launch starts VBS even with EnableVBS=0 (their VM run 2) so it skips `hypervisorlaunchtype` when vbs-off | Anti-cheat: default breaks Vanguard/FACEIT; EclipseOS should invert default |
| Services | DiagTrack, dmwappushservice Start=4 (`services/disable.yml`); optional `memcomp-off` (16 GB+), `fth-off`, `svchost-group` | Subset of Atlas `atlas/services.yml` (much shorter list) | Very low breakage risk | Small gain | Neutral |
| Scheduled tasks | Disables ~14 telemetry/CEIP tasks incl. Appraiser variants resolved dynamically per build (25H2/26H2 only have "... Exp"), Maps, Siuf DmClient, CEIP Consolidator (`services/disable.yml`, `registry/fortnite-qol.yml`); validator checks tasks still enabled list | Same family as Atlas `tweaks/debloat/disable-scheduled-tasks.yml`; dynamic names fix errors on ISO path | Avoids "missing task" errors | none | Neutral |
| Telemetry/privacy | `AllowTelemetry=0`, `AllowDeviceNameInTelemetry=0`, Autologger Diagtrack-Listener Start=0; `DisableWpbtExecution=1`; `PreventDeviceMetadataFromNetwork=1`; consumer content off; Delivery Optimization HTTP only (`DODownloadMode=0`); AI policy keys (DisableClickToDo, DisableSettingsAgent, AllowRecallEnablement=0, generative AI consent Deny, Notepad `DisableAIFeatures`, Paint `DisableCocreator`) | Same core as Atlas `tweaks/privacy/**`; adds 26H2 AI keys (Click to Do, Settings agent) and WPBT, which Atlas 0.5.0 lacks (grep: no WPBT in Atlas tree, inference from missing hit) | WPBT off blocks firmware-injected OEM installers | none | Neutral |
| Power / CPU / timer / latency | Ultimate Performance on desktops (laptops keep Balanced; `x3d-balanced` keeps Balanced); HAGS `HwSchMode=2`; per-user `DirectXUserGlobalSettings=SwapEffectUpgradeEnable=1;VRROptimizeEnable=1;`; Fast Startup off; IFEO `PerfOptions\CpuPriorityClass=3` only on `FortniteClient-Win64-Shipping.exe` (never Debugger/GlobalFlag on anti-cheat exes); optional X3D affinity task, standby-clean task (once a minute, `NtSetSystemInformation`); no PowerThrottlingOff; no bcdedit timer flags, no MSI forcing, no Win32PrioritySeparation/MMCSS (README "What it does not do") | Looser than Atlas on timers (Atlas sets `GlobalTimerResolutionRequests`, `tweaks/performance/**`; Mu omits), no MMCSS tweak vs Atlas `tweaks/performance/config-mmcss.yml` | Evidence-based: they ran VM A/B and UDP stress; avoided placebo | IFEO CpuPriority on a game exe is the only route that works under EAC (their note) | Gaming perf: modest, safe |
| Network | NIC power saving off (EEE, Green Ethernet etc.) via boot scheduled task `\MuulfzOTMZ\`, receive buffers to max, Wi-Fi off while wired (`WcmSvc\GroupPolicy fMinimizeConnections=3`), QoS DSCP 46 for Fortnite; explicitly NOT Nagle/TcpAck/NetworkThrottlingIndex/RSS/IMOD (`registry/nic-gaming.yml`) | Atlas applies a network driver pack (`tweaks/networking/**`, `atlas/...`); Mu is lighter and avoids contested tweaks | Re-applies after driver update; avoids Teredo/IPv6 off (breaks Xbox party) | `fMinimizeConnections=3` drops Wi-Fi when wired (could surprise) | Xbox party/LAN safe |
| UI/shell | Classic Start pins replaced by gaming set; Replace-layout `LayoutModification.xml` for new accounts; Taskband reset; Edge startup boost off (`Policies\Microsoft\Edge StartupBoostEnabled=0`); Spotlight desktop icon off; wallpaper | Atlas has own Start config (`tweaks/qol/config-start-menu.yml`). Mu documents that 26H2 Start ignores `ConfigureStartPins` on existing profiles and that UCPD refuses the Dsh `AllowNewsAndInterests` value | 26H2-specific learnings | Cosmetic only | Neutral |
| Edge/browsers | Edge kept (WebView2 host); optional Chrome MSI | Atlas keeps Edge by default, optional removal (`uninstall-edge`) | Safe | none | Store/Xbox safe |
| OneDrive | `DisableFileSyncNGSC=1` plus user uninstall script; validator checks binary gone (policy alone passed once while uninstall failed) (`registry/onedrive-removal.yml`) | Atlas removes OneDrive (`atlas/components.yml`, ONED.cmd) | Verifies result, not only policy | Data in OneDrive must be kept local first (README) | Neutral |
| Revert path | Restore point "MuulfzOS (before)" always created (`restore-point.yml`); `tests/vm/undo-host.cmd` is for the VM kit; README says removed apps reinstall from Store; no per-tweak undo scripts | Weaker than Atlas (`atlas/revert.yml`, AtlasDesktop toggles) | Restore point | No toggle scripts | Servicing: n/a |

### 1.3 Anti-cheat invariant checks (`tests/vm/validate-fortnite.ps1`, lines 164-182)
| # | Check | Expected |
|---|---|---|
| 1 | `Confirm-SecureBootUEFI` | true |
| 2 | `(Get-Tpm).TpmReady` | true |
| 3 | TPM / TBS `Start` not 4 (missing TBS key is fine on 26H2) | not disabled |
| 4 | `C:\Windows\Logs\MeasuredBoot\*.log` present | true |
| 5 | Defender real-time on (when mode = keep) | true |
| 6 | `CI\Config VulnerableDriverBlocklistEnable` | 1 |
| 7 | bcdedit has no testsigning / nointegritychecks / debug | false |
| 8 | bcdedit `nx OptIn` | true |
| 9 | `Get-ProcessMitigation -System` ASLR BottomUp and DEP not OFF | true |
| 10 | `wuauserv` StartType not Disabled | true |
| 11 | `Winmgmt` running | Running |
| 12 | `Microsoft.WindowsStore` present | true |
| 13 | `Microsoft.XboxGamingOverlay` present (X3D) | true |
Plus tweak-level check `KernelShadowStacks Enabled = 0` and HVCI/VBS state matching the vbs-off choice (`Check tweak` lines 33-37). Anti-cheat caveat from README: EAC refuses to run in a VM, so the whole suite is VM-only and "not verified on bare metal with Fortnite".

### 1.4 Ideas for EclipseOS
| Verdict | Idea | Reason |
|---|---|---|
| ADOPT | Copy the 13 invariants as an EclipseOS post-apply gate (extend with `TamperProtection` state and VBS/HVCI running) | Direct fit with anti-cheat + Store goals; runs in the lab VM |
| ADOPT | `VulnerableDriverBlocklistEnable=1`, `KernelShadowStacks=0` pin, explicit VBS/HVCI ON path | Vanguard/FACEIT need HVCI; Epic EAC error 1275 with kernel shadow stacks |
| ADOPT | Defender keep + scan tuning via GPO `Scan` keys instead of disable | Works with Tamper Protection on, and Atlas leaves Tamper off |
| ADOPT | Per-build dynamic scheduled-task disable (`Get-ScheduledTask ... | Disable`) | Missing-task errors on 26H2 |
| ADOPT | Verify results not policy (OneDrive binary check) | Policy-only checks lied once |
| ADOPT | `DODownloadMode=0`, WPBT off, DisableClickToDo etc. | Cheap privacy gains Atlas 0.5.0 lacks |
| ADOPT | Keep Audio/network/Xbox split when collapsing svchost | Atlas only excludes Xbl|Xbox |
| AVOID | VBS off as default | Conflicts with EclipseOS "VBS/HVCI on by default" |
| AVOID | Defender disable/remove tiers; `DisableHardwareRequirements` is correctly false (keep false) | Security goal |
| AVOID | `fMinimizeConnections=3` as default (inference: may surprise laptops with docks) | Optional only |

---
## 2. Meridian 26H2
Repo https://github.com/zykmm/meridian-26h2 (GPL-3.0, push 2026-11-01). Fork of **Atlas 0.5.0** (commit 6c26aab), so the diff against `C:\Atlas` (also 0.5.0) is direct.

### 2.1 Metadata
| Item | Value |
|---|---|
| Version/date | 1.0.0, 2026-11-01 (`src/playbook/playbook.conf`, `CAMBIOS-26H2.md` section 12) |
| License | GPL-3.0 |
| SupportedBuilds | **26300 only** |
| Requirements | DefenderToggled, NoAntivirus, Internet, NoPendingUpdates, UCPDDisabled, PluggedIn (identical to Atlas) |
| Options (default) | defender-enable (default) / defender-disable; mitigations-default / mitigations-disable; auto-updates-disable (**default disable, as Atlas**) / auto-updates-default; checkboxes disable-hibernation, disable-power-saving, **disable-core-isolation** (all `IsChecked` default true, same as Atlas, so VBS/HVCI off by default); remove-snipping-tool, uninstall-edge, install-another-browser; install-toolbox; browser radio default Brave |
| ISO | SupportsISO true, **DisableHardwareRequirements true** (TPM/Secure Boot bypass at install; contradicts EclipseOS goal) |
| Binaries | CAB packages and Atlas Toolbox 0.1.13 as upstream; `Remove-Edge.exe` release 2.3 pinned with SHA256 and downloaded at apply time (`RemoveEdge.ps1`); self-signed CABs retained (B4-12) |
| Docs | `CAMBIOS-26H2.md` (24 KB changelog, sections 1-12; row IDs B*, F3-*, F5-*, D*) |

### 2.2 Change table (Meridian vs Atlas 0.5.0; everything not listed is identical to Atlas)
| Area | What it changes | Difference vs Atlas | Positive | Negative/risk | Impact |
|---|---|---|---|---|---|
| Windows Update | `disable-feature-updates.yml` writes version to `TargetReleaseVersionInfo` (was overwriting `TargetReleaseVersion`=1 with text); `Toggle Windows Updates.cmd` drops non-existent `sih`/`sihboot` tasks; `DEFAULT.ps1` now runs on clean install and respects `auto-updates` choice (`CAMBIOS` sec. 3, 6) | Bug fixes. Atlas path `tweaks/qol/windows-update/disable-feature-updates.yml` line 8/13 still has the `TargetReleaseVersion` mismatch (grep confirmed) | Correct feature-update pin | Keeps default "auto-updates-disable" | Servicing: same as Atlas (lab: OK after full update) |
| Store/AppX removals | `atlas/appx.yml`: uses `-PackageTypeFilter Main` and deprovisions only removed packages (`'<='`), fixing deprovisioning of `WindowsAppRuntime.1.5`; adds removal of `MicrosoftCorporationII.QuickAssist`, `MicrosoftWindows.CrossDevice`; `Ink.Handwriting.Main.Store*`; `clearCache` fixed to `*Microsoft.SecHealthUI*`; new `RemoveCopilotApp.ps1` for the Chromium Copilot host (F5-5) | Atlas `atlas/appx.yml` line 96 uses the non-matching `*Microsoft.Windows.SecHealthUI*`; no QuickAssist/CrossDevice (grep: none) | Fixes a real bug: framework deprovisioning could break app installs | Removes Photos? no. Keeps Store/Xbox like Atlas | Store/Xbox: framework fix is positive |
| Xbox / Gaming Services | No change vs Atlas (GamingApp/Store kept); fixes FSO/Game Bar path to `HKCU\SOFTWARE\Microsoft\GameBar` and the `Remove-AppxPackage` that never ran (B2-13, B4-1); `Enable Mobile Device Settings.cmd` no longer re-enables Store auto updates | Atlas toggle scripts keep the wrong path (inference from Meridian's changelog; not re-verified per file) | Toggle scripts finally work | none | Store-Xbox neutral/positive |
| Defender | Adds `tamper-protection-reminder.yml` + `tamperReminder.ps1` (RunOnce reminder if Tamper still off, opens Security page); `RemoveEdge.ps1` note that host Defender flags `Remove-Edge.exe` as `Trojan:Win32/Yomal!rfn` | Atlas has no reminder. Tamper stays off until the user turns it on (matches lab fact: Atlas leaves Tamper off) | Directly addresses "Tamper off" gap | Reminder only, not enforced; F3-22 open: defender-disable CAB recipe incomplete | Security positive |
| VBS/HVCI/Core Isolation | `ConfigVBS.ps1`: creates `...\Scenarios\HypervisorEnforcedCodeIntegrity` if missing (New-ItemProperty failed in VM, memory integrity not explicitly disabled); "Disable Core Isolation" **no longer sets `Lsa\RunAsPPL=0`** (D5/B3-5); `Enable VBS.cmd` state fix and clears KernelShadowStacks/CredentialGuard Enabled=0; `script-core-isolation.yml` writes `VbsState=0` | Atlas `Executables/AtlasModules/Scripts/ScriptWrappers/ConfigVBS.ps1` line 34 still writes `RunAsPPL=0` (confirmed). Default still VBS off (disable-core-isolation checked) | RunAsPPL stays on (LSA protection) | Default is unchanged: VBS/HVCI off | Anti-cheat: still bad default; adopt RunAsPPL fix only |
| Services | `atlas/services.yml`: `diagnosticshub.standardcollector.service`, `GpuEnergyDrv`, `Telemetry` changed only if they exist (AME created stub service keys with only `Start`) | Atlas `atlas/services.yml` lines 59, 72 change them unconditionally (confirmed) | Avoids junk service keys | none | Neutral |
| Scheduled tasks | Drops `sih`/`sihboot` entries | Atlas still lists them (inference) | Fewer errors | none | Neutral |
| Telemetry/privacy | `setx /M` for dotnet/PowerShell telemetry env (machine scope); `Searchbox`, `ContentDeliveryAllowed`, `GlobalUserDisabled`, blue tooltips etc. re-applied for new users (`newUsers.ps1`); `CLIENTCBS.ps1` also reads 2 `SettingsExtensions.json` (Microsoft 365, OneDrive, Xbox, Copilot cards on Settings home) | Atlas lacks machine-scope setx and the Settings-home cards (inference from changelog) | Cleaner Settings home on 26H2 | none | Neutral |
| Power / CPU / timer | Unchanged vs Atlas except Mitigations numbering/`VendorIdentifier` fix (`Enable All Mitigations.cmd` was not writing `FeatureSettingsOverride`) | Atlas still has the bug (inference) | Correct mitigations toggle | none | Neutral |
| Network | `Reset Network to Atlas Default.cmd` iterates all physical adapters (was only last PCI); File sharing wrappers fixed (`NetbiosOptions=0`, `.reg` references) ; firewall group `@FirewallAPI.dll,-33002` for Remote Assistance | Atlas has these bugs (per changelog) | Language-independent firewall rule disable | none | Neutral |
| UI/shell | **UCPD handling:** `postReboot.ps1` (new) writes Widgets policies and browser file associations after reboot (UCPD blocked them during install, `disable-news-and-interests.yml` always failed with access denied), task `AtlasPostReboot` (SYSTEM, 30 s delay, max 5 tries); `DisableSettings banner` guard; `HideDesktopIcons\NewStartPanel` typo fix; autorun values as proper REG_SZ; pin cleanup after Explorer rewrites AuxilliaryPins | Atlas has `NewStartPanelt` typo (`tweaks/qol/disable-windows-spotlight.yml` line 41, confirmed) and Widgets via `disable-news-and-interests.yml` | Fixes real 26H2 failures | `AtlasPostReboot` task is extra machinery | Neutral |
| Edge/browsers | `RemoveEdge.ps1` pins Remove-Edge 2.3 + SHA256, no `Read-Host` (NonInteractive crash); browser association applied to new users | Atlas downloads latest, no hash check | Supply-chain check | Remove-Edge is Defender-flagged | Store/Xbox: Edge removal can affect WebView2 consumers (Atlas has same option, inference) |
| OneDrive | Removes obsolete OneDriveSetup comment; scheduled-task issue closed (V-1) | basically same | none | none | Neutral |
| Revert path | Atlas folder toggles kept and **repaired**: Toolbox state values aligned (0/1/2 numbering for Terminals, Mitigations), FSO, Lock Screen, Recent Items, Sleep Study, Printing, XPS writer (F5-6: `Enable Printing` no longer enables XPS features) ; lists 7 unfixable Atlas Toolbox 0.1.13 bugs (F5-2) | Stronger than Atlas: Atlas has these toggle bugs | Most thorough revert audit of the four | Toolbox bugs unfixed (external app) | Neutral |

### 2.3 Which of the 79 documented changes are 26H2-specific fixes Atlas lacks
The changelog does not number rows; counting table rows gives about 79. Classification below (verified against `C:\Atlas` where noted by grep).

**A. 26H2-specific (adopt):**
| ID | Change | Atlas state |
|---|---|---|
| 26H2 | Add `26300` to SupportedBuilds | absent (conf lists 26100/26200) |
| D4 | Remove `QuickAssist`, `CrossDevice` (new in 26H2) | absent (grep) |
| F5-5 | `RemoveCopilotApp.ps1`: Copilot 154.x is a Chromium host installed by Edge Update (`Program Files (x86)\Microsoft\Copilot`, ~1.1 GB, service `MicrosoftCopilotElevationService`) | absent |
| F3-1, F3-21 | UCPD blocks Widgets policy and default-browser association during install; move them to `postReboot.ps1` | absent; Atlas relies on `UCPDDisabled` requirement and still fails on Widgets per Meridian VM log |
| B5-1 | `CLIENTCBS.ps1` reads `AccountExperiences` `SettingsExtensions.json` (Settings home cards) | absent (inference) |
| B5-2 | Guard services missing on clean 26H2 (`GpuEnergyDrv`, `Telemetry`, `diagnosticshub...`) | absent (`atlas/services.yml` 59, 72) |
| B5-3 | `sih`/`sihboot` tasks no longer exist | present (inference) |
| B5-4 | `ValueBanner.IdealStateFeatureControlProvider` absent on clean 26H2 | present (inference) |
| F3-16, D7 | `.bmp`/`.rtf` `ShellNew` keys don't exist in 26H2 | present (inference) |
| F3-3 | `HypervisorEnforcedCodeIntegrity` key missing on 26H2 so `New-ItemProperty` fails | present (ConfigVBS.ps1 line ~34 area) |
| F5-6 | 26H2 ships XPS Document Writer disabled; Printing toggle must not re-enable | present (inference) |
| B1-5 | `Ink.Handwriting.Main.Store*` (was fixed `en-US1.0`, `atlas/appx.yml` line 70) | present (confirmed line 70) |
| B5-5 | 18 AppX patterns match nothing on 26H2 (harmless) | n/a |

**B. Generic upstream bugs (not 26H2-specific, but Atlas 0.5.0 lacks the fix; adopt the safe ones):**
`TargetReleaseVersionInfo` (B2-3, confirmed present in Atlas), `RunAsPPL` (D5, confirmed), `SecHealthUI` clearCache name (F3-17, confirmed), `NewStartPanelt` typo (B2-4, confirmed), framework deprovisioning (F3-8), `New-Item -Force` recreating keys empty (F5-1), `DEFAULT.ps1` on clean install (D1), Toolbox state numbering (F3-13, B4-5/7/10), `Remove-Edge` SHA256 pin (B1-1), `setx /M` (B2-9), file-sharing wrappers (F3-5, B4-8), `Remote Assistance` firewall group (F3-4), GameBar path (B2-13), mitigations CPU vendor read (B4-5).

**C. Meridian-only decisions, do not adopt:** `SupportedBuilds` 26300 only (EclipseOS may want 26100-26300), `DisableHardwareRequirements true`, `AllowUnsupportedUpgrades false` (fine), branding strings (`Name`, `UniqueId`, no `ProductCode`; F5-7: AME flagged the package "Malicious" when it reused Atlas Name/UniqueId/ProductCode, so EclipseOS **must** use its own Name, Username and UniqueId and drop `ProductCode`).

### 2.4 Ideas for EclipseOS
| Verdict | Idea | Reason |
|---|---|---|
| ADOPT | Cherry-pick group A and the safe group B fixes as a card (diff `src/playbook` vs Meridian) | Same base, GPL-3.0 compatible with Atlas license (inference: Atlas is GPL-3.0; verify) |
| ADOPT | `ame_conf_check.py` / `validate_yaml.py` rules (max 2 options with TopLine+BottomLine, 3 with one, 4 with none; SupportsISO needs exactly 3 distinct BulletPoint icons; DefaultOption must exist) | Cuts AME load errors; matches our `atlas_gate.py` approach |
| ADOPT | Tamper Protection reminder RunOnce (but EclipseOS goal is Tamper ON, so make it a check that fails loudly) | Lab fact |
| ADOPT | AME "Malicious" label lesson: unique Name/UniqueId/no ProductCode | EclipseOS branding |
| AVOID | `DisableHardwareRequirements true` | TPM/Secure Boot goal |
| AVOID | default `disable-core-isolation` checked | VBS/HVCI default on |
| AVOID | 26300-only if 26100/26200 support is still wanted | Scope decision |

---
## 3. GamingOS (Witthen)
Repo https://github.com/Witthen/GamingOS (MIT, push 2026-10-21).

### 3.1 Metadata
| Item | Value |
|---|---|
| Version/date | v1.0.2, 2026-10-21 (`playbook/playbook.conf`) |
| License | MIT |
| SupportedBuilds | 26100, 26200 (**no 26300**) |
| Requirements | Internet, NoAntivirus, UCPDDisabled, PluggedIn. No NoPendingUpdates, no global DefenderToggled (docs/compatibilidad.md) |
| Options (default) | profile-default (Equilibrado) / profile-agresivo; defender-enable default / defender-disable (Tamper must be off); mitigations-default / mitigations-disable; auto-updates-default (default **on**) / disable; disable-hibernation on; **disable-core-isolation off**; disable-device-power on; uninstall-edge off; remove-onedrive off; strip-xbox-stack off; power-max-performance off; search-minimal on; timer-holder-enable, bcd-disabledynamictick, nic-imod-off off |
| Language | Spanish wizard |
| Bundled | `WitthenDesktop/**` tools: NVIDIA Profile Inspector `.nip`/config and `Reference.xml` (854 KB), `.reg` packs, `.cmd`, `Apply-WitthenOS.ps1` (83 KB, 1,528 lines), `Healthcheck.ps1`, `UserLogin.ps1`. SetTimerResolution.exe referenced but not in the tree listing (inference: shipped in release, not source) |
| Account | `UserLogin.ps1` asks a name then sets a blank password (`LimitBlankPasswordUse=0`, `net user /passwordreq:no`, autologon) |
| Pass | docs/compare.md mentions playbook password `malte` (AME .apbx password) |

### 3.2 Change table
Important: docs (README, compare.md, conf) promise "Equilibrado keeps Edge/OneDrive/Xbox, Defender, mitigations". The code in `Invoke-Core` (`WitthenModules/Apply-WitthenOS.ps1`, always runs) does more. Findings from the script text:

| Area | What it changes | Difference vs Atlas | Positive | Negative/risk | Impact |
|---|---|---|---|---|---|
| Windows Update | Default leaves WU on; opt-in `UpdatesDisable`: `NoAutoUpdate=1`, `AUOptions=2`, `PauseUpdatesExpiryTime`, services `BITS`, `UsoSvc`, `wuauserv`, `WaaSMedicSvc` Disabled. Core: `DoSvc` disabled, `DODownloadMode=0`. Aggressive also disables `WSearch`, `VSS` | Default stricter than Atlas (Atlas default disables auto updates). Opt-in is far harsher (services disabled, not policy) | WU on by default | Opt-in kills BITS, UsoSvc: Store updates stop | Servicing: opt-in breaks; default OK except DoSvc/InstallService below |
| Store/AppX removals | **Core removes `Microsoft.WindowsStore`, `Microsoft.StorePurchaseApp`, `Microsoft.Services.Store.Engagement`, `Microsoft.XboxApp`, `Microsoft.SecHealthUI`, `Microsoft.MicrosoftEdge.Stable`, `Microsoft.BioEnrollment`, `Microsoft.StartExperiencesApp`, `Microsoft.Windows.CloudExperienceHost`, `Microsoft.Windows.ContentDeliveryManager`**, YourPhone, CrossDevice, QuickAssist, Copilot, etc. and also deprovisions Store (`Remove-AppxProvisionedPackage ... WindowsStore|StorePurchase`) (lines ~565-700) | Far looser than Atlas, which keeps Store (`atlas/appx.yml` header comment line 11). Contradicts GamingOS README ("Edge/Xbox kept") | Fewer processes | **Breaks Store, Store installs, Windows Security app UI**, cannot be undone with a toggle | Store/Xbox: severe, hard conflict with EclipseOS |
| Xbox / Gaming Services | Default keeps GamingApp, Xbox TCUI, IdentityProvider, GamingServices (wildcard filters exclude them); Core removes `Microsoft.XboxApp` and `XboxSpeechToTextOverlay`; opt-in `strip-xbox-stack` removes GamingApp, XboxGamingOverlay, IdentityProvider, TCUI; svchost split excludes only `^(Xbl|Xbox)`; keeps Audio* untouched | Similar to Atlas for default; Core also disables `InstallService`, `PushToInstall`, `WpnService`, `CDPSvc` (Store install + notification infra) | Opt-in is explicit and labelled | `InstallService` Disabled = Store/GamingApp installs fail (inference from service role) | Store-Xbox: degraded by default |
| Defender | Default keep; opt-in `DefenderDisable`: policies, `Start=4` on WinDefend, WdNisSvc, Sense, SecurityHealthService, MDCoreSvc, wscsvc and filter drivers WdFilter/WdBoot/WdNisDrv, tries `Set-MpPreference -DisableTamperProtection`, startup hold task `GamingOS-DefenderHold`; SmartScreen off; `AgresivoExtra` (profile-agresivo) disables Defender services too even without the Defender option | Looser than Atlas only in opt-ins. Docs say Tamper must be turned off first (docs/defender-tamper.md) | Documented pre-step | Profile "agresivo" turns Defender services off irrespective of the Defender radio (code in `Invoke-AgresivoExtra`), a hidden coupling. Windows Security shows blank | Security: risky; anti-cheat neutral |
| VBS/HVCI/Core Isolation, mitigations | `disable-core-isolation` **off by default** (opt-in `VbsOff`: EnableVBS=0, HVCI=0, LsaCfgFlags=0, `hypervisorlaunchtype off`); mitigations default kept; opt-in `Set-ProcessMitigation -System -Disable DEP, SEHOP, CFG, ...` plus `DisableExceptionChainValidation=1` | Stricter default than Atlas (Atlas checked-by-default VBS off). Opt-in mitigations broader | Only one of the four with VBS off opt-in rather than default (with Muulfz it is default-on) | `hypervisorlaunchtype off` breaks Hyper-V/WSL | Anti-cheat: default friendly |
| Services | ~110 services disabled in Core: DiagTrack, WerSvc, PcaSvc, Hello (`WbioSrvc`, `NgcSvc`), Spooler, `LanmanServer`, `lmhosts`, `NetBT`, `SSDPSRV`, `TermService`, `RasMan`, `SstpSvc`, `DoSvc`, `InstallService`, `WpnService`, `CDPSvc`, `CDPUserSvc`, `UCPD`, `GraphicsPerfSvc`, `QWAVE`, `SysMain`, edge updaters; Bluetooth kept. Explicit do-not-touch comment: Audio*, Xbox*, LicenseManager, PlugPlay, Rpc*, EventLog, Winmgmt, CryptSvc, BFE/mpssvc | Much looser than Atlas `atlas/services.yml` | List is documented, backup `reg export` of Services + bcd export (`Backup-PreApply`, `C:\...\Backups`) | NetBT/LanmanServer/QWAVE/DoSvc/WpnService off can break LAN games, Xbox party chat (QWAVE), notifications. `Disable-ServiceSafe` uses wildcard `"$Name*"` so `Spooler*`, `lmhosts*` etc. match more than intended (code) | Store-Xbox: Wpn/Install/QWAVE hits |
| Scheduled tasks | ~26 telemetry/CEIP/Hello/Family/Maps tasks; agresivo adds Defender scan tasks, StorageSense, Maintenance WinSAT; `MaintenanceDisabled=1` | Superset of Atlas `tweaks/debloat/disable-scheduled-tasks.yml` | Fewer wakeups | Disabling Storage Sense / maintenance in agresivo | Neutral |
| Telemetry/privacy | `AllowTelemetry=0`, WER disabled, AppCompat inventory off, `PublishUserActivities=0`, DO HTTP-only, Windows AI snapshots off (`WindowsAI\TurnOffSavingSnapshots`), content-delivery keys, Hello/biometrics policies off | Same family as Atlas | Broad list | Hello off disables PIN logon (they use blank password anyway) | Neutral |
| Power / CPU / timer | `GlobalTimerResolutionRequests=1`; X3D detected -> Balanced else High Performance; USB selective suspend off; MSPower_DeviceEnable cleared; MMCSS Games (GPU 8, Priority 6, High, SFIO High; SystemResponsiveness=10); opt-in TimerHolder scheduled task (SetTimerResolution 5000), `bcdedit /set disabledynamictick yes`, NIC interrupt moderation off; Win animations off, `AutoEndTasks`, `WaitToKillAppTimeout=2000` | `GlobalTimerResolutionRequests` and MMCSS same as Atlas (`tweaks/performance/config-mmcss.yml`); extras opt-in with benchmark script `micro-adjust-benchmark.ps1` | Opt-in timer set has a measurement tool; X3D awareness | `disabledynamictick` is disputed (Muulfz calls it placebo/stability risk); `AutoEndTasks=1` can lose unsaved data | Gaming perf: small, opt-in |
| Network | Disables NetBT, LanmanServer, SSDPSRV; opt-in IMOD off | Atlas disables file sharing too (option) | fewer ports | Breaks SMB/LAN | Neutral |
| UI/shell | Task View / widgets / chat / search box off, animations off, start clean once, wallpaper, `LayoutModification.xml` | Similar to Atlas `tweaks/qol/**` | none | none | Neutral |
| Edge/browsers | `Invoke-Core` calls `Invoke-RemoveEdge` unconditionally (README says optional): kills edge, runs `setup.exe --uninstall --force-uninstall`, removes Edge AppX and force-deletes folders; WebView2 kept | Looser than Atlas (Edge kept by default) | WebView2 kept | Contradicts docs; EdgeUpdate disabled | Store/Xbox: OK if WebView2 kept |
| OneDrive | Opt-in `OneDriveSetup /uninstall` + `DisableFileSyncNGSC=1` | same as Atlas | clean | none | Neutral |
| Revert path | `Backup-PreApply` exports services.reg, mmcss.reg, bcd; `bcd-disabledynamictick-OFF.cmd`, `net-autotuning-normal.cmd`, `01-global-timer-requests-UNDO.reg`; Healthcheck script; no revert of AppX removals | Weaker than Atlas `atlas/revert.yml` | Service snapshot | Store removal not revertable | Servicing: poor |

### 3.3 Ideas for EclipseOS
| Verdict | Idea | Reason |
|---|---|---|
| ADOPT | Three-tier wizard: Balanced default, aggressive opt-in; VBS-off and mitigations-off as opt-in (default off) | Fits goals; Atlas/Meridian invert this |
| ADOPT | Drop `NoPendingUpdates` only if WU+Store full update is enforced another way | Their reasoning: over-blocks. But maintainer rule requires full update, so keep the requirement (inference) |
| ADOPT | Pre-apply backup of Services hive + BCD (`Backup-PreApply`) | Cheap revert aid |
| ADOPT | `Healthcheck.ps1` after apply (EclipseOS should assert Store, Xbox, Gaming Services, TPM, Secure Boot) | Matches lab approach |
| ADOPT | Blank password autologon setup is similar to EclipseOS "local account without password" goal (`UserLogin.ps1` sets `LimitBlankPasswordUse=0`, `net user /passwordreq:no`); review security trade-off first | Goal |
| AVOID | Removing `Microsoft.WindowsStore`, `StorePurchaseApp`, `Services.Store.Engagement`, `CloudExperienceHost`, `SecHealthUI` | Breaks Store and Windows Security |
| AVOID | Disabling `InstallService`, `PushToInstall`, `WpnService`, `QWAVE`, `CDPSvc`, `DoSvc` | Store install, notifications, Xbox party chat QoS |
| AVOID | Wildcard service matching (`"$Name*"`) and `Set-ProcessMitigation -System -Disable DEP,...` | Over-broad |
| AVOID | Docs that disagree with code (Edge removed unconditionally) | Rule: read the diff, not the README |

---
## 4. Z-LAG-OS
Repo https://github.com/MrPcGamerYT/Z-LAG-OS (license NOASSERTION per GitHub API though LICENSE file exists; push 2026-10-22). Mirror testssssa22a/Z-LAG-OS (5.16).

### 4.1 Metadata
| Item | Value |
|---|---|
| Version/date | 5.20, release 2026-10-22 (`src/playbook.conf`, API) |
| License | NOASSERTION (LICENSE file present, 2.6 KB, not SPDX-recognized) |
| SupportedBuilds | **none declared**; claims Windows 10 and 11 (`docs/windows-compatibility.md`); no 26300 testing claimed |
| Requirements | Internet, DefenderToggled, NoAntivirus, FreshInstall |
| Options (default) | Browser radio (Chrome default; Brave; OperaGX; None); defender-keep default / defender-disable; bluetooth-keep / bluetooth-disable; wifi-keep / wifi-disable; store-keep default / store-disable. The `.conf` lists only 5 pages, but `04_appx.yml` references options `remove-appx-photos/devhome/xbox/yourphone` that are not in the conf (inference: dead options, never selectable) |
| Bundled | `src/Executables`: ~50 scripts, cursors, `user.PNG` (1.3 MB), `edge_remover.bat` (downloads ShadowWhisperer setup.exe pinned by SHA-256 at apply time), Z-LAG Toolbox downloaded from GitHub release (always installed) |

### 4.2 Change table
| Area | What it changes | Difference vs Atlas | Positive | Negative/risk | Impact |
|---|---|---|---|---|---|
| Windows Update | **Unconditional full block** (`Tasks/13_blockUpdates.yml`): `wuauserv`, `UsoSvc`, `WaaSMedicSvc` Disabled, `NoAutoUpdate=1`, `AUOptions=1`, `DisableWindowsUpdateAccess=1`, `DoNotConnectToWindowsUpdateInternetLocations=1`, hosts-file entries (`add_update_hosts.ps1`), clears `SoftwareDistribution\Downloads` and `DataStore`; `10_services.yml` also disables UsoSvc, wuauserv, WaaSMedicSvc. README FAQ: re-enable by restoring hosts and services | Much stricter than Atlas (Atlas default disables only auto-download via policy, keeps services startable: `tweaks/qol/windows-update/disable-auto-updates.yml`) | Zero background update traffic | No security updates; Microsoft Store and app updates break; cannot take 26H2 cumulative updates | Servicing: severe |
| Store/AppX removals | Base list removes Xbox (`XboxApp`, `XboxGamingOverlay`, `Xbox.TCUI`, `GamingApp`, `XboxGameCallableUI`, `XboxSpeechToTextOverlay`), Calculator, `ScreenSketch`, Paint, Copilot, Widgets, Clipchamp, Office Hub, etc. (`04_appx.yml`); base **keeps** `WindowsStore`, `StorePurchaseApp`, `XboxIdentityProvider`; `store-disable` (opt-in) removes Store, Xbox, MS account/cloud services and blocks MS accounts (`05_RemoveStoreServices.ps1`, `17_removeMSAccount.yml`: `BlockMicrosoftAccounts=1`, `NoConnectedUser=3`); `34_repairAppxRuntime.yml` repairs the AppX launch stack afterwards | Much looser than Atlas (Xbox app/GamingApp removed in base) | Documents `StoreRemovalComplete` verification and a repair step (docs/store-removal-validation.md); keeps wlidsvc deliberately | Xbox app, Game Bar overlay and Gaming App removed even in default path | Store-Xbox: Xbox gone; Store half-working because updates are blocked |
| Xbox / Gaming Services | Services `XblAuthManager`, `XblGameSave`, `XboxNetApiSvc`, `XboxGipSvc`, `BcastDVRUserService` Disabled (`10_services.yml`); `ms-gamebar` protocol hijacked to `systray.exe` in option branch | Atlas keeps Xbox services (excluded from SvcHostSplit) | Fewer processes | Game Pass / Minecraft Launcher sign-in need XboxIdentityProvider (their own note); Gaming Services not explicitly protected | Xbox: broken |
| Defender | Default keep; keep path runs `defender_guard.ps1` (re-enables WinDefend, WdNisSvc, SecurityHealthService, wscsvc, removes stale disable policies, forces signature update) (README line 267); opt-in disable (`07_defenderAggressive.yml`: policies + services + scheduled scans + `DefenderRemoved` marker). `EnableSmartScreen=0`, `SmartScreenEnabled=Off` unconditional (`03_registry.yml`); host blocks via hosts file | Default same as Atlas. SmartScreen off is looser | Re-enable guard is a good idea | `DefenderToggled` requirement forces user to disable Tamper first even when keeping Defender | Security: SmartScreen off |
| VBS/HVCI, mitigations | **Unconditional** `EnableVirtualizationBasedSecurity=0`, `RequirePlatformSecurityFeatures=0`, `Lsa\DisableVSM=1` (`03_registry.yml`); `ConsentPromptBehaviorAdmin=5` kept but **`PromptOnSecureDesktop=0`**; `CoreParkingDisabled=1`; `set_kernel_profile.ps1` writes `Win32PrioritySeparation=38`, `SystemResponsiveness=10` with snapshot + `-Restore` | Looser than Atlas (VBS off with no option) | Kernel profile has snapshot/restore and DWORD type validation | Breaks Vanguard/FACEIT/Memory Integrity; UAC weakened | Anti-cheat: bad |
| Services | `10_services.yml`: DiagTrack, WerSvc, PcaSvc, SysMain, WSearch, WbioSrvc, MapsBroker, VSS, SwPrv, MSDTC, `BDESVC`, `Spooler`, sensors, `WpnService`, `OneSyncSvc`..., plus `32_processFloor`/`enforce_service_floor.ps1` and `win11_process_floor.ps1` "process floor" watchdog (scheduled, no resident process); 26_gamingCore/`set_timer_resolution.ps1`; backs up Services hive to `ProgramData\Z-LAG-OS\services_backup.reg` | Far looser than Atlas | Backup exported; wlidsvc deliberately untouched | BDESVC off; "floor" watchdog keeps re-disabling services after Windows changes; VSS/System Restore disabled | Servicing: risky |
| Scheduled tasks | `11_scheduledTasks.yml`, `30_taskPurger.yml`, `purge_telemetry_tasks.ps1` | Superset of Atlas | fewer wakeups | none | Neutral |
| Telemetry/privacy | Hosts-file telemetry block (`add_telemetry_hosts.ps1`), `CEIPEnable=0`, `AllowTelemetry=0`, DisableFileSyncNGSC, Spotlight off, `BlockMicrosoftAccounts` (store-disable only) | Hosts blocking is beyond Atlas | Backed by `hosts_file_utils.ps1` + `tests/test_hosts_file.ps1` | Hosts blocking can break Store/Xbox sign-in/license endpoints (inference) | Servicing: risk |
| Power / CPU / timer | Ultimate Performance plan (verified, GUID recorded), `set_timer_resolution.ps1`, CPU priority IFEO for BlueStacks processes, `NetworkThrottlingIndex=0xFFFFFFFF`, `GPU Priority 8`, `HwSchPriority`, DisablePagingExecutive, `set_pagefile.ps1`, `fsutil disablelastaccess/disable8dot3` (`23_advancedPerf.yml`) | Beyond Atlas | Many are reversible | `NetworkThrottlingIndex` max and `TCPNoDelay` are disputed placebo (Muulfz measured); `disable8dot3` can break old installers | Gaming perf: marginal |
| Network | `TcpAckFrequency=1`, `TcpDelAckTicks=0`, `TCPNoDelay`, `NonBestEffortLimit=0`, `EnablePacing=0`, NIC offload disabled (`disable_network_offload.ps1`), optional Wi-Fi/Bluetooth service removal (`08/09_*.yml`, `RemoveWiFi.ps1`) | Beyond Atlas | none proven | Offload off costs CPU; Wi-Fi/BT removal | Gaming perf: placebo or negative |
| UI/shell | Dark theme, cursors `ElegantDark`, small auto-hide taskbar, empty Start layout, context-menu cleaner (14.8 KB), welcome panel, rename PC (`16_computerName.yml`) | Beyond Atlas | cosmetic | `start2.bin` deleted | Neutral |
| Edge/browsers | **Unconditional removal of Edge AND WebView2** (`20_edgeRemoval.yml`, `remove_edge.ps1`, `edge_remover.bat`); browser chosen (Chrome default) | Far looser than Atlas (keeps WebView2) | pinned SHA-256 for downloaded remover | WebView2 is needed by Xbox app, Store UI parts, Widgets-free apps (inference); their own doc notes app compat depends on WebView2 | Store/Xbox: high risk |
| OneDrive | `38_deepClean.yml` + `remove_onedrive.ps1` | same as Atlas | none | none | Neutral |
| Revert path | Restore point first (`create_restore_point.ps1`) but System Restore/VSS disabled later; service backup `.reg`; kernel profile `-Restore`; hosts restore documented; no toggle tree | Weaker than Atlas | tests: `validate_repo.py`, `test_audit_guards.py` | Removed packages not restorable | Servicing: poor |

### 4.3 Ideas for EclipseOS
| Verdict | Idea | Reason |
|---|---|---|
| ADOPT | Snapshot + `-Restore` pattern with validation (`set_kernel_profile.ps1`) for any kernel/scheduler registry change | Clean revert path |
| ADOPT | Pinned-SHA256 downloader pattern (`edge_remover.bat`) and CI repo validators (`tests/validate_repo.py`, `validate_powershell.ps1`) | Supply chain and static checks |
| ADOPT | `defender_guard.ps1` idea: re-assert Defender ON at end of apply | Fits Defender-on goal |
| AVOID | Block Windows Update (services + hosts) | Store/Xbox servicing |
| AVOID | VBS unconditionally off, `DisableVSM`, `PromptOnSecureDesktop=0` | Anti-cheat and security |
| AVOID | Removing Xbox apps, WebView2 and Edge unconditionally | Store/Xbox/Gaming Services |
| AVOID | Hosts-file telemetry blocks (inference: can break Store licensing) and "process floor" watchdog | Fragile |
| AVOID | `TcpAckFrequency`, `NetworkThrottlingIndex`, offload-off defaults | Placebo per Muulfz VM stress test |
| NOTE | No SupportedBuilds and no 26300 claim; do not treat as 26H2-tested | |

---
## 5. Cross-playbook summary vs EclipseOS goals
| Playbook | VBS/HVCI default | Tamper Protection | WU | Store | Xbox | TPM/SecureBoot | Verdict |
|---|---|---|---|---|---|---|---|
| MuulfzOS | OFF by default (option) with explicit ON path | untouched (stays on) | working | kept | kept | never touched; HW check kept | best reference; flip the VBS default |
| Meridian | OFF (as Atlas) | off (reminder only) | auto-update disabled by default | kept | kept | ISO bypass true | use as 26H2 fix source |
| GamingOS | ON (opt-in off) | must be off only if Defender removed | on by default | **removed in Core** | default kept, removed `XboxApp`; opt-in strip | untouched | take option design; reject Core destructiveness |
| Z-LAG-OS | OFF forced | unspecified | **blocked** | kept (base) / removed (opt) | **removed** | untouched | negative reference |

Open points (not verifiable from text): none of the four was run here; all behaviour claims are from source text and the authors' own docs. Muulfz's test suite is VM-only (EAC refuses VMs).
