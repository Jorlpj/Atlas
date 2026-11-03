# Rufus 26H2 install x 16 playbooks: collision analysis

Date 2026-11-03. Static reading only; nothing was run. Baseline: Rufus USB, Windows 11 26H2 (build 26300), local account "User" (Rufus source specifies an empty password and a change-at-first-logon flag; the prompt outcome is unverified), BitLocker auto-encryption off, privacy pages skipped, QoL enabled (exact writes documented in [rufus-wue.md](rufus-wue.md); 26H2 runtime effects are unverified), TPM 2.0 + Secure Boot kept, then full WU + Store with reboot, then the playbook post-install (not ISO injection).
Abbreviations: M = `C:\Atlas.librarian\docs\eclipseos\research\apbx-matrix.md`; GA/GB/GC = `...\research\apbx\group-a.md`, `group-b.md`, `group-c.md`; PC = `...\research\problem-catalog.md` (section G, lab IDs). "(inf)" = inference, not source-verified. Atlas source = `C:\Atlas\src\playbook`.

## 0. Facts that frame everything
- F1. Post-install runs do not use the playbook `ISO` block, so `DisableBitLocker` and `DisableHardwareRequirements` are inert on a Rufus install (inf; block at Atlas `playbook.conf:52-55`; AME ISO mode checks only build and system status, PC G21).
- F2. Atlas requirements: `DefenderToggled, NoAntivirus, Internet, NoPendingUpdates, UCPDDisabled, PluggedIn` (`playbook.conf:22-29`); no account or password requirement. Builds 26100/26200 only (`playbook.conf:15-20`). AME CLI 0.8.4 does not enforce `SupportedBuilds` (PC G02); GUI behaviour on 26300 not verified.
- F3. Lab: `DefenderToggled` makes the user switch off 4 Defender toggles and nothing restores them: Tamper Protection, MAPS and sample submission stay off (PC G03). Real-time protection returns after the UCPD prep reboot, so toggles must be turned off twice (PC G13). Rufus does not touch Defender (inf), so this is a requirement-vs-baseline issue, not a Rufus duplicate.
- F4. Atlas already does what Rufus QoL overlaps: Fast Startup off `HiberbootEnabled=0` and hibernation off (`src/playbook/Configuration/tweaks/scripts/script-power.yml:15-29`), Copilot and Outlook AppX removal (`src/playbook/Configuration/atlas/appx.yml:35,53`), OneDrive removal (`src/playbook/Configuration/atlas/components.yml:31-33`), Copilot policy (`src/playbook/Configuration/tweaks/qol/taskbar/disable-copilot.yml:8-9`). Idempotent over Rufus = harmless duplicates. OneDriveSetup startup entries remain after removal (PC G16, low).
- F5. Telemetry/privacy policies from playbooks sit over Rufus privacy answers; policies win, no conflict known. A revert that deletes policies returns to the Windows default, not to the Rufus answer (low, inf).
- F6. AME handling of a passwordless account is undocumented in the inputs. GC:17 quotes a MuulfzOS comment that AME "forces a password / bakes credentials", UNVERIFIED for AME 0.8.4.
- F7. No input mentions Rufus.

## (a) Matrix
Sev: B blocker, H high, M medium, L low, I info.

| Playbook | Install works? | Requirement issues | Duplicates with Rufus | Conflicts with Rufus | Breaks baseline goals | Sev |
|---|---|---|---|---|---|---|
| AtlasOS 0.5.0 | Yes (G01/G10 PC), but 26300 not in SupportedBuilds | DefenderToggled (G03/G13 PC); UCPDDisabled; builds (F2) | Fast Startup, hibernation, Copilot, Outlook, OneDrive (F4) harmless | Reverting power toggles restores Fast Startup/hibernation that Rufus set off (inf, `src/playbook/Configuration/tweaks/scripts/script-power.yml:15-29`) | VBS/HVCI off by default (PC G11); auto-updates off, Store AutoDownload=2 (M:17-18); Tamper left off (PC G03) | H |
| ReviOS 26.10 | Yes in principle (lists 26300, M:15) | DefenderToggled; Tamper off beforehand (M:66) | Telemetry=0, hibernate off | Defender off by default (M:65) | Defender off, VBS off no option, WU paused to 2038 (M:17,65,69) | H |
| Chamber 1.3.3 | Yes (26300 declared, M:15) | NoPendingUpdates, NoAntivirus (GA:77); no DefenderToggled | Telemetry policies | None found | WSearch/SysMain off, hosts blocks (M:103,106); CC BY-NC-SA license | M |
| UltraOS 1.2.1 | Yes (26300 primary, M:15) | Internet, NoPendingUpdates, PluggedIn only (M:66) | Fast Startup off in Safe+ (M:107) | None | SAC disabled in default Balanced (M:67) | M |
| RapidOS 1.3 | Build gate fails or warns: no 26300 (M:15) | DefenderToggled, NoPendingUpdates (M:66) | CEIP, Recall, telemetry | None | PromptOnSecureDesktop=0; VBS off unconditional; WU pause + IFEO redirect + AutoDownload=2 unconditional (M:17-18,68-69) | H |
| AME 11 0.8.3 | Blocked: no 26300 (M:15) and LocalAccounts + AdministratorPasswordSet (GA:199-201) | Both password requirements fail or demand a password on the passwordless account (inf) | BitLocker decrypt harmless (M:107) | Demands admin password vs empty password | Deletes WU, Store, Xbox, Defender, WebView2 (M:17-22,25) | B |
| SynergyOS 1.7 (main 1.8) | Unknown for tag 1.7 (builds "?", M:31) | `PasswordSet` in main (GB:16,25,195); tag 1.7 UNVERIFIED | Telemetry, sync off | PasswordSet vs empty password (main) | Legacy survey only: WU paused 2038 + endpoints blocked, Xbl off (M:33,37) | B (main) / ? (tag) |
| NOVA 1.0.1 | No: ISO-injection only (M:32) | FreshInstall (GB:16); misfire after WU/Store (inf) | Telemetry, OneDrive/Edge tasks | Defender off by default, Tamper=0 (M:77-78) | UAC off, SmartScreen off, System Restore disabled, WebView2 deleted (M:25,79-80,156) | B |
| KiyomizuOS 3.0.1 | Tag declares only 26200 (M:31): 26300 unsupported | No password req (M:159); build gate | Telemetry policies | None | SAC disabled; Xbox app/Identity/TCUI removed (M:37,79) | H |
| ShimmerOS 1.5.2 | Likely (26300 listed, M:31), but needs Defender already disabled | `DefenderDisabled` (GB:16): misfires on Rufus (Defender on, inf) | Hosts, telemetry | Defender deleted, UAC off (M:77,80) | Defender deleted, UAC off, VBS/ELAM off, ~83 services, Xbox* removal, WU endpoints blocked (M:33,37,80-81,116) | B |
| LexBoosT 26.10.1 | Yes (26300 + 28000 listed, M:31) | DefenderToggled, NoPendingUpdates, PluggedIn (M:159) | Telemetry | None | AutoDownload=2 (M:34); mitigation override=3 on fresh install (M:82) | M |
| GamerzOS 0.2 | No 26300 declared (M:47) | DefenderToggled (M:90); FreshInstall (M:170) | Fast Startup off (M:133) | Defender disable reg; HVCI Enabled=0 unconditional (M:89,93) | Attempts Store + Xbox removal, SAC off, secure desktop off (M:52-55,91-92) | B |
| MuulfzOS 0.9.4 | Yes (26300 listed, M:47) | NoPendingUpdates only (GC:17) | WU active hours, telemetry | None; Tamper stays on | VBS off by default (M:93) | M |
| Meridian 26H2 1.0.0 | Yes (26300 only, M:47) | Same as Atlas (GC:83) | Atlas-derived (F4) | ISO bypass true is inert post-install (F1) | VBS off by default (M:93); auto-updates off (M:49) | M |
| GamingOS 1.0.2 | No 26300 (M:47) | Internet, NoAntivirus, UCPDDisabled, PluggedIn; no NoPendingUpdates (GC:153) | Fast Startup off | Blank-password autologon script (M:170) | Core removes Store + Edge (M:52,56); DoSvc and ~110 services disabled (M:129) | H |
| Z-LAG-OS 5.20 | No builds declared (M:47) | DefenderToggled (M:90), FreshInstall (M:170) | Hosts, telemetry | Optional MSA block is moot (no MSA) | WU services + hosts blocked, SmartScreen off, VBS forced off, Xbox/WebView2/Edge removed (M:49,53,57,91,93) | B |


## (b) Main errors, ranked by severity x playbooks
1. E3 (B, 3-4 playbooks): password requirements. AME 11 `LocalAccounts` + `AdministratorPasswordSet` (GA:199-201,225), SynergyOS main `PasswordSet` (GB:16,25,195), GamingOS blank-password autologon script (M:170). Directly conflicts with the Rufus passwordless account.
2. E5 (B/H, 6): Store, Xbox, Defender, WebView2 or Xbox Identity removal: AME 11, GamerzOS (FPSBOOSTER), GamingOS Core, Z-LAG, Shimmer, Kiyomizu (M:20-22,36-37,52-53). Store/Xbox regression class.
3. E1 (H, 10+): `DefenderToggled` / `DefenderDisabled` force Tamper and Defender toggles off with no restore (PC G03/G13): Atlas, ReviOS, RapidOS, NOVA, Shimmer, LexBoosT, GamerzOS, Meridian, Z-LAG, Synergy (M:66,78,90; GB:16; GC:83).
4. E2 (H, ~10): VBS/HVCI off by default or unconditionally, defeating TPM2/Secure Boot kept for anti-cheat: Atlas, ReviOS, RapidOS, Shimmer, GamerzOS, Meridian, MuulfzOS, Z-LAG (M:69,81,93; PC G11).
5. E4 (H, ~9): Windows Update and Store AutoDownload neutered: Atlas, ReviOS, RapidOS, Shimmer, NOVA, Z-LAG, GamerzOS, LexBoosT, Synergy legacy (M:17-18,33-34,49-50).
6. E6 (M, 7): `SupportedBuilds` lacks 26300: Atlas, RapidOS, AME 11, Kiyomizu, GamerzOS, GamingOS, Z-LAG (M:15,31,47). AME CLI does not enforce (PC G02); GUI behaviour UNVERIFIED.
7. E8 (M, 5): UAC secure desktop or EnableLUA off: NOVA, Shimmer, RapidOS, GamerzOS, Z-LAG (M:68,80,92). Extra risk with a passwordless account (inf). UAC consent also blocked an ISO first-logon script in the lab (PC G23, not a post-install result).
8. E7 (M, 3-4): ISO-only / `FreshInstall` assumptions: NOVA ISO-only (M:32); FreshInstall on NOVA, GamerzOS, Z-LAG (M:159,170). Meaning after WU + Store updates UNVERIFIED.
9. E9 (L, ~14): idempotent duplicates with Rufus QoL/privacy (F4, F5); revert pairs may restore Windows defaults over Rufus choices.
10. E10 (L/I, 7): ISO-block hardware bypass true in Revi, UltraOS, RapidOS, Synergy, NOVA, Kiyomizu, Meridian, AME 11 (M:71,83,95) is inert for post-install (F1) but would break the TPM/Secure Boot goal if ISO injection were ever used.

## (c) Best solutions
- S1 (E1, EclipseOS design): do not declare `DefenderToggled`; keep Defender and Tamper on; no tweak that needs Tamper off by default. Opt-in Defender-off tiers must check `IsTamperProtected` and skip with a note (MuulfzOS pattern, GC:29). Models: Chamber, UltraOS, MuulfzOS (M:66,90). No Rufus change needed.
- S2 (E2): default VBS/HVCI on; opt-in off with anti-cheat warning (UltraOS/Chamber/NOVA radio, M:69,81, GA:242). Do not copy Atlas `disable-core-isolation` ticked by default (PC G11).
- S3 (E3): no `LocalAccounts`, `PasswordSet`, `AdministratorPasswordSet` requirement; do not base on AME 11 or SynergyOS main; no blank-password autologon script. Add a lab test that the playbook applies on a passwordless account (UNVERIFIED so far). Rufus option: keep passwordless local account as is.
- S4 (E4): no auto-update policy and no Store AutoDownload=2 by default (Chamber/UltraOS/LexBoosT-style pins, M:17,34-35); the Atlas `auto-updates-disable` default must flip to off; verify revert leaves WU unpaused.
- S5 (E5): Store, Xbox, Gaming Services, WebView2 are protected families; re-run lab invariants G01/G10 and never use ISO injection (PC G18/G19).
- S6 (E6/E7): declare 26300 in `SupportedBuilds`; keep `NoPendingUpdates` (enforces the maintainer's WU rule), `Internet`, `PluggedIn`; drop `FreshInstall`, `UCPDDisabled` handling per Meridian's postReboot approach (apbx-comparison.md:78). Base: Atlas or Meridian or UltraOS (GPL-3.0, M:182,191).
- S7 (E8): leave UAC at Windows defaults; first-logon work must not need consent prompts.
- S8 (E9/E10): write idempotent tweaks, make reverts restore only what EclipseOS itself changed (snapshot/restore as Chamber, M:144); omit the ISO block (F1).

## Not verified
- Rufus source specifies the empty password and QoL writes, but the empty-password first-logon prompt outcome and 26H2 runtime effects of the options remain unverified; see [rufus-wue.md](rufus-wue.md).
- AME behaviour on unsupported builds in the GUI and whether its Wizard accepts an already passwordless local user remain unverified; the `FreshInstall` definition is verified in [verify-1.md](verify-1.md).
- The KT-TWEAKS-only playbooks (Atom etc.) are not in the 16-column matrix.
- Whether any revert actually undoes Rufus-set values (inferred from revert design, M:144-171).
