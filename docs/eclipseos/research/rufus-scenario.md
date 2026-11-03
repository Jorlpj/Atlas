# Rufus install scenario: main errors and best solutions across AME playbooks

Orchestrator synthesis, 2026-11-03. Scenario set by the maintainer: every Windows 11 26H2 (build 26300) install is made
from a Rufus USB. Windows Update AND Microsoft Store are then fully updated (with reboot), and the playbook runs
post-install. There is no Microsoft account at any point.

Status: everything below is static analysis (Rufus source, playbook source, earlier lab runs of Atlas only). No
third-party playbook has been run yet; the lab plan is in section 5.

Raw inputs:
- [rufus/rufus-wue.md](rufus/rufus-wue.md): what each Rufus option writes, from Rufus v4.15 `src/wue.c`;
- [rufus/rufus-apbx-collisions.md](rufus/rufus-apbx-collisions.md): 16 playbooks x Rufus baseline;
- [apbx-matrix.md](apbx-matrix.md), [apbx-comparison.md](apbx-comparison.md);
- [problem-catalog.md](problem-catalog.md) section G (lab).

## 1. Rufus baseline (maintainer's choices)

The orchestrator verified the key lines in `pbatard/rufus` at tag `v4.15`, `src/wue.c`.

| Rufus option | Choice | What it writes (verified) | Note |
|---|---|---|---|
| Remove 4GB+ RAM / Secure Boot / TPM 2.0 requirement | **OFF** | nothing; with it ON, Rufus adds windowsPE bypass entries | OFF keeps TPM 2.0 and Secure Boot, which anti-cheats (Vanguard, FACEIT, EA AC) need |
| Remove online Microsoft account requirement | ON | specialize: `HKLM\...\OOBE\BypassNRO=1` (`wue.c:274`) | on recent builds BypassNRO works only with the network unplugged during OOBE (rufus-wue.md, issues 2810/2844) |
| Create local account "User" | ON | oobeSystem LocalAccount, Administrators group, **empty password** (`wue.c:363-371`); FirstLogon `net user "User" /logonpasswordchg:yes` (`wue.c:378`) and `net accounts /maxpwage:unlimited` (`wue.c:382`) | first logon asks for a password change, see error R1 |
| Regional options = this user's | ON | oobeSystem International settings | none |
| Disable data collection | ON | `ProtectYourPC=3` (`wue.c:327`), EULA page hidden | the privacy pages are answered "off" |
| SILENTLY erase disk | OFF | nothing | correct: no unattended disk wipe |
| Disable BitLocker automatic encryption | ON | `PreventDeviceEncryption=true` (`wue.c:485`) | Secure Boot and TPM stay usable; no auto-encryption |
| QoL improvements | ON | `HiberbootEnabled=0` (Fast Startup off, `wue.c:402`); Copilot policy and button off; OneDrive setup off; `*Outlook*` and `*Teams*` AppX removed and deprovisioned (`wue.c:284-295`); consumer features, news and recommendations off | HKCU values reach only the first-logon profile |
| "Windows CA 2023" bootloaders | OFF | the original 2011-signed boot files stay | watch item W1 |
| SkuSiPolicy.p7b | OFF | nothing | ON would copy the policy to the ESP at first logon (BlackLotus mitigation, KB5042562) |

The file lands at `sources\$OEM$\$$\Panther\unattend.xml` on the USB (`wue.c:1328-1335`). Because the TPM bypass
and silent install are OFF, `boot.wim` and `install.wim` are not modified. This is an answer file, not image
servicing: it is NOT AME ISO injection, and the playbook still runs post-install after the updates.

## 2. Map of main errors (Rufus install + playbook), ranked

Severity: B blocker, H high, M medium, L low. "Playbooks" counts the 16 in the matrix.

| # | Error | Sev | Playbooks hit | Effect on the Rufus baseline | Evidence |
|---|---|---|---|---|---|
| E3 | Password requirements (`PasswordSet`, `LocalAccounts` + `AdministratorPasswordSet`) or a blank-password autologon script | B | AME 11, SynergyOS (main), GamingOS | the playbook refuses to run or demands a password on the passwordless "User" | collisions §b.1 |
| E5 | Store, Xbox, Gaming Services, WebView2 or Xbox Identity removed | B | AME 11, GamerzOS, GamingOS, Z-LAG, ShimmerOS, KiyomizuOS | Store and Game Pass break; an irreversible loss of the regression class | matrix A1-A3 |
| E7 | ISO-only or `FreshInstall` assumptions | B for NOVA | NOVA (ISO only), GamerzOS, Z-LAG | NOVA cannot run post-install; FreshInstall may misfire after WU+Store updates (unverified) | collisions §b.8 |
| E1 | `DefenderToggled` / `DefenderDisabled` requirement: the user turns off Tamper Protection and Defender toggles, nothing restores them | H | about 10, including Atlas, ReviOS, RapidOS, LexBoosT, Meridian | Tamper, MAPS and sample submission stay off after the run (lab G03); toggles must be turned off twice (G13) | problem-catalog G03, G13 |
| E2 | VBS/HVCI off by default or unconditionally | H | about 10, including Atlas, ReviOS, RapidOS, Meridian, MuulfzOS | wastes the TPM/Secure Boot kept by the Rufus choice; some anti-cheats and Windows security features expect HVCI | lab G11 |
| E4 | Windows Update paused, blocked or set to never, or Store AutoDownload=2 | H | about 9, including Atlas (auto-updates off, AutoDownload=2), ReviOS, RapidOS, ShimmerOS, Z-LAG | breaks the "WU and Store always updated" rule after the install | matrix A rows |
| E8 | UAC, secure desktop or SmartScreen off | M | NOVA, ShimmerOS, RapidOS, GamerzOS, Z-LAG | an Administrators account with no password AND no UAC means any process gets full rights silently | matrix B rows |
| E6 | 26300 missing from `SupportedBuilds` | M | 7, including Atlas | the AME CLI does not enforce it (G02); the GUI behaviour on 26300 is unverified | collisions §b.6 |
| R1 | Rufus forces a password change at first logon (`/logonpasswordchg:yes`) | M | all (Rufus side) | first logon stops at "change your password"; leaving both fields blank should keep the account passwordless (needs lab confirmation) | `wue.c:375-378` |
| R2 | BypassNRO needs the network unplugged during OOBE | M | all (Rufus side) | with Ethernet or Wi-Fi connected, OOBE may still demand a Microsoft account | rufus-wue.md §c |
| E9 | Duplicates with Rufus QoL: Fast Startup, Copilot, OneDrive, Outlook, Teams, telemetry | L | about 14 | harmless and idempotent; a playbook revert may restore Windows defaults over the Rufus choices (inference: an Atlas power revert would re-enable Fast Startup) | collisions F4, F5 |
| E10 | Hardware bypass `true` in the playbook ISO block | L | 8 | inert post-install; dangerous only with ISO injection, which is forbidden | collisions §b.10 |

Not an error: with the TPM bypass OFF, Rufus leaves the Windows image untouched, so the Store and Xbox ISO-injection
regression (lab G18-G20) does not apply to a Rufus install.

Watch item W1 (inference, to verify): the Microsoft Windows Production PCA 2011 certificate expires in 2026 and the
BlackLotus revocations (KB5042562) may eventually distrust 2011-signed boot managers. If the target PC's Secure Boot
DB/DBX is updated, a USB made with the 2011 bootloaders could stop booting; Rufus's "Windows CA 2023" option exists for
that case. Leaving it OFF is right while the target PCs still boot the 2011 media.

## 3. Best solutions

| Error | Best solution | Where |
|---|---|---|
| E3 | No `PasswordSet`, `LocalAccounts` or `AdministratorPasswordSet` requirement; no autologon script; lab test "playbook applies on a passwordless account" | EclipseOS `playbook.conf` |
| E5 | Store, WindowsStore runtime, Xbox apps, XboxIdentityProvider, Xbox.TCUI, GamingServices and WebView2 are protected families, enforced by a CI validator (UltraOS model) | EclipseOS CI + `appx.yml` |
| E7 | Post-install only; no `FreshInstall`; no `SupportsISO` | EclipseOS `playbook.conf` |
| E1 | Do not declare `DefenderToggled`; Defender and Tamper stay on; a Defender-off tier is opt-in and checks `IsTamperProtected` first (MuulfzOS pattern) | EclipseOS options |
| E2 | VBS/HVCI on by default; an opt-in off option with an anti-cheat warning (UltraOS, Chamber); drop Atlas's ticked `disable-core-isolation` | EclipseOS options |
| E4 | WU notify or automatic with active hours; Store AutoDownload left at default (lab A/B test 2 vs 4 still open); never pause or block | EclipseOS defaults |
| E8 | UAC, secure desktop and SmartScreen at Windows defaults; no first-logon step that needs a consent prompt | EclipseOS defaults |
| E6 | Declare 26300 after the lab run passes | EclipseOS `playbook.conf` |
| R1 | Maintainer step: at the first-logon prompt leave both fields empty and confirm; the lab confirms it keeps the account passwordless | install guide |
| R2 | Maintainer step: unplug the network until the desktop appears; connect only for Windows Update | install guide |
| E9 | Tweaks idempotent; reverts restore only what EclipseOS changed (snapshot and restore, Chamber model), not Windows defaults over Rufus choices | EclipseOS revert |
| E10 | Omit the ISO block entirely | EclipseOS `playbook.conf` |

## 4. Playbook ranking for the Rufus scenario (static)

| Fit | Playbooks | Why |
|---|---|---|
| Runs, few conflicts | UltraOS, Chamber, MuulfzOS | no password or Defender-off requirement; Store and Xbox kept; UltraOS and Chamber keep VBS on |
| Runs, needs EclipseOS changes | AtlasOS, Meridian 26H2, LexBoosT | E1, E2 and E4 by default (Atlas, Meridian), AutoDownload=2 (LexBoosT) |
| Runs, harmful defaults | ReviOS, RapidOS, KiyomizuOS | Defender or VBS off, WU paused, Xbox removal (Kiyomizu) |
| Blocked or breaks the baseline | AME 11, SynergyOS (main), NOVA, ShimmerOS, GamerzOS, GamingOS, Z-LAG-OS | password requirement, ISO-only, Store/Xbox/Defender removal |

## 5. Lab plan (proposed, not run)

1. Rufus media in the lab: run Rufus inside a helper `eclipse-lab-*` guest and write the USB layout to an attached VHDX
   with exactly the options in section 1. If Rufus refuses a non-USB target, build the same layout from the ISO
   inside the guest and add the `unattend.xml` Rufus generates. Nothing runs on the host.
2. Install a Gen2 guest (TPM and Secure Boot on) from that VHDX with the network off during OOBE (R2), check R1, then
   run full WU and Store updates with reboots. Checkpoint `R0-rufus-updated`.
3. From `R0`, apply each playbook in its own checkpoint branch and run the shared checks: Store install, Xbox and
   Gaming Services, WU scan and install, Defender and Tamper state, VBS/HVCI state, account still passwordless, revert.
   Order: Atlas, Meridian, UltraOS, Chamber, MuulfzOS, LexBoosT, ReviOS, then the rest as cost allows.
