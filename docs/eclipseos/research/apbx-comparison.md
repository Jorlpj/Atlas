# AME Wizard playbooks (.apbx) vs AtlasOS: comparative analysis for EclipseOS

Orchestrator synthesis, 2026-11-02. Inputs: five read-only research passes (Claude Sonnet, low effort). Each read
`playbook.conf`, YAML and scripts as text with `gh api`. No `.apbx` or binary was downloaded or run. The raw passes,
with per-playbook change tables and `path:line` or URL citations, are in [apbx/](apbx/); the side-by-side matrix of all 16 is [apbx-matrix.md](apbx-matrix.md):
- [inventory](apbx/inventory.md): 65 rows;
- [KT-TWEAKS](apbx/kt-tweaks.md);
- [group A](apbx/group-a.md): ReviOS, Chamber, UltraOS, RapidOS, AME 11;
- [group B](apbx/group-b.md): SynergyOS, NOVA, KiyomizuOS, ShimmerOS, LexBoosT, GamerzOS;
- [group C](apbx/group-c.md): MuulfzOS, Meridian 26H2, GamingOS, Z-LAG-OS.

APBX-VER-MERGE (2026-11-03) applies the release-tag findings in [V1](apbx/verify-1.md), [V2](apbx/verify-2.md), and [V3](apbx/verify-3.md). These pages supply primary tag URLs, path/line citations and grades: A1 for direct source instructions, B2 for bounded absence findings, A6 for unavailable requested-release behavior. Source instructions do not establish successful execution, runtime compatibility or opaque/downloaded utility behavior. The [matrix](apbx-matrix.md) records the per-cell results and unknown count.

The orchestrator spot-checked a few earlier claims against source (marked "verified"). Unchanged survey claims remain untrusted input:
librarians re-verify a claim before a design page relies on it, and grade it in `sources.json`. Lab evidence is
section G of [problem-catalog.md](problem-catalog.md).

## 1. Overview (defaults, not options)

| Playbook | 26300 | Install | Defender | VBS/HVCI | Windows Update | Store | Xbox | Revert | License | Verdict for EclipseOS |
|---|---|---|---|---|---|---|---|---|---|---|
| **AtlasOS 0.5.0** (base) | no (PR #1750) | post-install, ISO | kept, Tamper left off (lab G03) | **off** (`disable-core-isolation` ticked; lab G11) | auto-updates off; Store AutoDownload=2 | kept | kept | narrow onUpgrade cleanup + manual toggles | GPL-3.0 | base; flip VBS default |
| MuulfzOS Fortnite 0.9.4 | yes | post-install | kept, tuned; Tamper stays on | off by default (option, with explicit ON path) | works | kept | kept, Game Bar kept | partial | MIT | **anti-cheat test-definition reference**: 13 VM anti-cheat test definitions; not evidence of a passing run |
| Chamber 1.3.3 | declared | post-install (ISO beta) | kept | on (opt-in off) | untouched (opt-in notify) | kept | kept | snapshot, verify, restore | **CC BY-NC-SA 4.0** (verified): no code reuse | **best design match**, ideas only |
| UltraOS 1.2.1 | yes (primary) | post-install, ISO | kept | on (opt-in off, with anti-cheat warnings) | automatic | kept | kept (Extreme removes) | backup, restore point, HTML report | GPL-3.0 (verified) | **code reference**: presets plus CI validator; default Balanced disables SAC (V1, A1) |
| LexBoosT OS 26.10.1 | yes (+28000) | post-install | kept and throttled | not touched (legacy inference) | not disabled | kept; AutoDownload=2 (V2, A1); ClipSVC and TokenBroker Auto, InstallService Manual (verified) | Game Bar removed | ROLLBACK.PS1 | none declared | Store service model; fresh-install mitigation override/mask=3 (V2, A1); closed 48 MB binary |
| Meridian 26H2 1.0.0 | 26300 only | post-install, ISO | as Atlas | off (as Atlas) | auto off | kept | kept | as Atlas | GPL-3.0 | **26H2 fix source** (Atlas fork) |
| ReviOS 26.10 | yes | post-install, ISO | **off** | **off** (no option) | paused to 2038 | kept (AutoDownload=4) | kept | onUpgrade revert | CC-BY-SA-4.0 | individual tweaks only |
| RapidOS 1.3 | no | post-install | kept (opt-in off) | **off, unconditional**; SAC, MOTW, secure desktop off | 500-day pause + IFEO update blocks + AUOptions=2 (V1, A1) | kept; AutoDownload=2 unconditional (V1, A1) | Game Bar removed (non dual-CCD X3D) | good | AGPL-3.0 | tweaks only; security cuts |
| GamingOS (Witthen) 1.0.2 | no | post-install | kept | on (opt-in off) | on | **removed by core script**, contradicting its README | kept | services and BCD backup | MIT | option design only |
| KiyomizuOS tag 3.0.1 (conf 3.0.0 Stable) | no; conf lists only 26200 (V2, A1) | post-install, ISO | untouched | untouched | paused to 2051 | kept | **app, Identity and TCUI removed** | none | AGPL-3.0 | SAC off (V2, A1); avoid Xbox removal |
| SynergyOS tag 1.7 (conf 1.7.0) | not re-verified | ISO bypass declared (V2, A1) | not re-verified | not re-verified | not re-verified | not re-verified | not re-verified | no automatic backup found (V2, B2) | not re-verified | six bounded cell findings only; legacy 1.8 survey is not tag evidence |
| NOVA 1.0.1 | yes (legacy survey) | **ISO only**, hardware bypass (V2, A1) | **off** | on | paused to 2030 | not verified | option | batches | Apache-2.0 | conflicts with the install rule; UAC off and System Restore disabled (V2, A1) |
| ShimmerOS 1.5.2 | yes | post-install | **deleted** | `vsmlaunchtype Off`, ELAM off | killed | **UAC off breaks UWP** | Xbox* wildcard removes Identity | on/off batches | none | worst for the goals |
| Z-LAG-OS tag 5.20 (conf 5.18) | none declared | post-install | kept by default; marker-gated repair attempt (V3, A1) | off forced | **blocked** (services and hosts) | kept | **removed** with WebView2 | none | NOASSERTION | negative |
| AME 11 / Privacy+ 0.8.3 (unverified release [V1](apbx/verify-1.md)) | no (legacy survey) | post-install, ISO | **deleted** | not touched | **deleted** | **removed** | **removed** | none | none | not a base |
| GamerzOS tag 0.2 (conf 0.1) | no | post-install | unconditional disable-policy import (V3, A1) | HVCI Enabled=0 unconditional; VBS wrapper flag-gated (V3, A1) | wuauserv/UsoSvc Manual; AUOptions=2 payload flag lacks selector (V3, A1) | unconditional removal attempt (V3, A1) | app, Identity, TCUI and overlays removed by FPSBOOSTER (V3, A1) | not re-verified | GPL-3.0 (legacy survey) | harmful default instructions; split exclusion does not establish preservation |

KT-TWEAKS-APBX is not a playbook. It is a website catalog (`public/catalog.json`) that re-hosts 9 third-party `.apbx`
files: Atlas, Atom, FSOS-X, RapidOS, ReviOS, SapphireOS, SynergyOS, Vain and XOS.
- Its Atlas SHA-256 matches the upstream `0.5.0-hotfix` asset. For the other 8, the hash only proves the file is
  unchanged since KT uploaded it.
- Its "KT WIRZADE" tool is presented as an MIT fork of AME Wizard, which is closed source. It commits binaries,
  including a NoDefender CAB, and checks hashes through a private API.
- Every playbook in the catalog with readable source turns VBS off. Atom also removes Store, winget and Xbox identity
  and disables AppXSvc, ClipSVC, wuauserv and BITS.
- Verdict: do not use it as a dependency or a source.

Release/version limits: Privacy+ 0.8.3 tag lookup returned HTTP 404; its unchanged overview behavior is legacy survey input, not verified release behavior (V1, A6). Synergy 1.6.0, 1.7.0 and 1.8.0 identify tag 1.6, tag 1.7 and a main snapshot respectively; only six behavior cells were audited at tag 1.7. Remaining Synergy claims in the thematic survey below remain legacy 1.8 input. GamerzOS and Z-LAG conf versions differ from their tag labels as shown. Kiyomizu tag metadata does not declare 26300 (V2/V3, A1).

## 2. Change-by-change comparison (positives, negatives, differences, impact)

Impact columns: **G** = gaming performance, **S** = security and anti-cheat, **X** = Store/Xbox servicing. Scale:
`++` to `--`, `0` = none.

| Area | Atlas today | Alternatives seen (who) | Positive | Negative / risk | G | S | X | EclipseOS proposal |
|---|---|---|---|---|---|---|---|---|
| Supported builds | 26100, 26200 | 26300 (most), 28000 (LexBoosT, ReviOS main) | runs on 26H2 | an unvalidated build claim | 0 | 0 | 0 | add 26300 after lab validation; the AME CLI does not enforce the list (G02) |
| Identity in `playbook.conf` | Atlas Name, UniqueId, ProductCode | Meridian: own Name and UniqueId, no ProductCode | AME no longer tags the playbook "Malicious" (Meridian F5-7; likely the cause of lab G22) | none | 0 | + | 0 | own Name, UniqueId and Username; drop ProductCode |
| Install method | post-install, ISO allowed | NOVA ISO-only; Chamber ISO beta | ISO is convenient | ISO injection breaks Store and Xbox updates (lab G18, G19) | 0 | 0 | -- | post-install only, after full WU + Store; no `SupportsISO` |
| Windows Update | auto-updates off (policy) | pause to 2030-2051 (ReviOS, NOVA, Kiyomizu); 500-day pause + IFEO blocks + notify policy (RapidOS, V1); blocked (Z-LAG; Synergy legacy survey); automatic (UltraOS, Chamber) | fewer surprise reboots | paused or blocked means no security updates; a `NoAutoUpdate` policy once broke Xbox sign-in (ReviOS) | + | -- to - | - | notify or automatic with active hours; never block or pause for years |
| Store auto-update | AutoDownload=2 (off) | 4 (ReviOS); 2 (RapidOS V1, LexBoosT V2, unconditional); not set (Chamber, UltraOS) | less background traffic | old Store and Xbox apps stop updating (lab G18 correlation) | + | 0 | - | lab A/B test 2 vs 4 (cheap card) |
| Store services | not pinned | ClipSVC and TokenBroker Auto, InstallService and AppXSvc Manual (LexBoosT) | Explicit startup assignments; runtime licensing/install health unverified | none known | 0 | 0 | ++ | adopt the pinning and add a protected-service list in CI |
| Store/AppX removals | curated list, Store kept | Store removal attempted (GamerzOS FPSBOOSTER, V3); Store removed (AME 11 legacy survey, GamingOS core, Atom); `Microsoft.Xbox*` wildcard (Shimmer) | less disk use | breaks Store, Xbox identity and Gaming Services | + | 0 | -- | keep Atlas's list; CI validator for protected families (UltraOS list: WindowsStore, WebView2, XboxIdentityProvider, Xbox.TCUI, GamingServices) |
| Xbox and Gaming Services | kept | Xbl services off (Synergy legacy survey); FPSBOOSTER removes app/Identity/TCUI/overlays (GamerzOS V3); app, Identity and TCUI removed (Kiyomizu, Z-LAG) | saves a few services | Game Pass and Xbox break | + | 0 | -- | keep everything Xbox; removal only as an explicit option |
| Game Bar | kept | removed (GamerzOS FPSBOOSTER V3; LexBoosT; RapidOS except dual-CCD X3D) | less overlay overhead | X3D scheduling may need Game Bar (inference, RapidOS) | + | 0 | - | keep; offer removal with an X3D warning |
| Defender | kept, Tamper left off | tuned, Tamper kept on (MuulfzOS); throttled (LexBoosT); disable-policy import (GamerzOS V3); off (ReviOS, NOVA); deleted (AME 11, Shimmer) | lower CPU use when tuned | off or deleted removes protection; some anti-cheats object (inference) | + | -- when off | 0 | keep it on, tune scan CPU (LexBoosT); restore Tamper after the run (G03) |
| VBS/HVCI (Core Isolation) | **off by default** | on by default (Chamber, UltraOS, NOVA, GamingOS); unconditional HVCI-off instruction (GamerzOS V3); off (ReviOS, RapidOS, Meridian, MuulfzOS, Z-LAG) | off gives a few % FPS in some titles (inference) | Vanguard and FACEIT need HVCI-capable systems; off lowers security | + | -- | 0 | **on by default**; off only as an option with an anti-cheat warning (UltraOS forced-value pattern for the opt-in) |
| CPU mitigations | default (option) | FeatureSettingsOverride/Mask=3 on fresh install (LexBoosT V2, not all mitigation families); off by default (Shimmer legacy survey); opt-in (Synergy legacy survey, UltraOS) | small CPU gain | Spectre-class exposure | + | - | 0 | keep the default; option with a warning |
| UAC, SmartScreen, MOTW, SAC | kept | UAC off (NOVA V2, Shimmer); SAC off (UltraOS Balanced V1, Kiyomizu V2, GamerzOS V3); SAC, MOTW and secure desktop off (RapidOS, Z-LAG legacy survey) | fewer prompts | UAC off breaks UWP/Store (SynergyOS README); malware exposure | 0 | -- | -- | never by default |
| Services | Atlas set; svchost split threshold | ~83 services disabled (Shimmer); SysMain, WSearch and TabletInput off (Chamber); most set to Manual (Kiyomizu) | less RAM use | VSS, `vid` and search broken; hard to revert | + | - | - | Manual over Disabled; protected list; backup of the services hive (GamingOS, UltraOS) |
| Scheduled tasks | Atlas set | 26H2: `sih`/`sihboot` tasks are gone (Meridian) | fewer wakeups | errors on 26H2 | + | 0 | 0 | guard missing tasks and services on 26300 (Meridian B5-2, B5-3) |
| Telemetry/privacy | Atlas policies | hosts-file blocks (Chamber, Z-LAG); re-apply after first sign-in (Chamber) | stronger privacy | hosts entries can block WU, Store or Xbox endpoints | 0 | + | - if broad | policies first; test a re-apply task on 26300; no broad hosts blocks |
| Power/latency | Atlas power scheme, hibernation off | laptop detection (RapidOS); timer, MMCSS and interrupt tools (NOVA, Synergy, LexBoosT binaries) | lower latency | closed tools; laptop battery life | ++ | 0 | 0 | keep the Atlas scheme; add laptop detection; no closed timer tools |
| Edge/WebView2 | Edge removed, WebView2 kept (lab G12) | WebView2 deleted (NOVA, AME 11, Z-LAG); Edge kept (GamingOS) | less background work | Xbox sign-in and many apps need WebView2 | + | 0 | -- if WebView2 removed | remove Edge only as an option; never WebView2; pin the `Remove-Edge` hash (Meridian B1-1) |
| Copilot (26H2) | not handled | `RemoveCopilotApp.ps1`: Chromium host via Edge Update, ~1.1 GB (Meridian) | disk and RAM saved | none known | + | 0 | 0 | adopt after verification |
| New 26H2 apps | not handled | QuickAssist and CrossDevice removal (Meridian) | lighter | none known | + | 0 | 0 | adopt as an option |
| UCPD (26H2) | `UCPDDisabled` requirement | Widgets and default-browser steps moved to `postReboot.ps1` (Meridian) | the 26H2 install completes | none | 0 | 0 | 0 | adopt |
| Account | AME default | `PasswordSet` required (SynergyOS); Administrator password (AME 11) | none | conflicts with the local passwordless account | 0 | 0 | 0 | no password requirement |
| ISO hardware bypass | Atlas ISO block | `DisableHardwareRequirements` true (Meridian); unset (Chamber) | installs on old hardware | TPM and Secure Boot missing break anti-cheats | 0 | -- | 0 | leave unset (and no ISO anyway) |
| Revert/verification | `revert.yml` and scripts | snapshot, verify, restore, receipt (Chamber, design); presets, backup, HTML report, CI validator (UltraOS); onUpgrade revert (ReviOS); anti-cheat invariant VM test (MuulfzOS) | measurable pass/fail | more code to maintain | 0 | + | + | adopt the UltraOS validator and backup, the MuulfzOS invariant tests in the EclipseOS lab, and the ReviOS onUpgrade pattern |
| Bundled binaries | StoreFixer, AtlasModules CABs | NSudo, NoDefender.cab with test root CA (Synergy), INSTALLSOFTS.exe (LexBoosT), revitool `latest` (ReviOS) | convenience | supply chain and AV flags; unverifiable | 0 | -- | 0 | YAML and PowerShell only; every download pinned by hash |

## 3. Atlas 0.5.0 defects confirmed through other playbooks (verified in `C:\Atlas`)
- `NewStartPanelt` typo: `src/playbook/Configuration/tweaks/qol/disable-windows-spotlight.yml:41` and
  `src/playbook/Executables/AtlasModules/Scripts/Modules/Qol/Qol.psm1:424` (should be `NewStartPanel`; Meridian B2-4).
- No `TargetReleaseVersionInfo` pin anywhere in `src/playbook` (Meridian B2-3).
- No `RunAsPPL` handling in `src/playbook/Executables/AtlasModules/Scripts/ScriptWrappers/ConfigVBS.ps1` (Meridian D5). On 26H2
  the `HypervisorEnforcedCodeIntegrity` key is missing (F3-3), which matches lab G24, "ConfigVBS.ps1 HVCI key missing".
- Not verified yet: the `Ink.Handwriting` AppX pattern (`src/playbook/Configuration/atlas/appx.yml:70`), the 26H2 service guards, the
  `.bmp`/`.rtf` ShellNew keys, and the `SecHealthUI` cache name. See [apbx/group-c.md](apbx/group-c.md) section 2.3.

## 4. Short list for EclipseOS design
1. **Defaults:**
   - VBS/HVCI on;
   - Tamper Protection restored after the run;
   - Windows Update notify or automatic;
   - Store, Xbox, WebView2 and Gaming Services protected by a CI validator;
   - post-install only.
2. **Reuse:**
   - code candidates: UltraOS (GPL-3.0) for presets, validator, backup and report, excluding its SAC-off default; Meridian (GPL-3.0) for the 26H2 fixes;
   - ideas only: Chamber (non-commercial license) and MuulfzOS (MIT) for the anti-cheat invariants.
3. **Lab A/B tests next:**
   - Store AutoDownload 2 vs 4;
   - InstallService/ClipSVC pinning against the ISO regression (G18-G20);
   - Chamber's re-apply-after-sign-in task;
   - Atlas with VBS left on: FPS and anti-cheat smoke test.
4. **Avoid:**
   - pausing or blocking Windows Update for years;
   - Defender, UAC, SAC or MOTW off by default;
   - deleting WebView2 or Xbox identity;
   - WinSxS removal packages;
   - closed binaries;
   - hosts-file blocks of service endpoints.
