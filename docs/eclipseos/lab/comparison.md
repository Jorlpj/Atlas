# EclipseOS lab comparison: post-update apply and pre-update injection

Status: completed lab runs, 2026-11-02. This compares two isolated Hyper-V guest lanes on Windows 11 26H2 build 26300.9457, later updated to 26300.9711. It is an observation of these runs, not proof that update order alone caused every difference. See [lane A](lane-a.md), [lane B](lane-b.md), [method](method.md), and the graded observations in [problem catalog section G](../research/problem-catalog.md).

## Comparison

| | Lane A: apply after updates | Lane B: inject before updates |
|---|---|---|
| Starting point | Stock Windows installed, then WU and Store updated to a fixed point before the playbook was applied | AME 0.8.4 injected the playbook into the stock ISO before Windows setup; WU and Store updates ran after first boot |
| Playbook | Local lab build, GUI defaults; `SupportedBuilds` temporarily included 26300 for the test | Same lab build and GUI defaults, plus `ame-drivers-network`; injected ISO |
| Checkpoints | A0 updated stock; A1 minimal options; A1f GUI defaults; A2f after WU and Store scans | B1 first desktop; B2 after WU and Store scans reached fixed point |
| Store package | `WindowsStore` 22609.1401.8.0 at A0, A1, A1f and A2f | 22506.1400.2.0 at B1 and B2 |
| Xbox package state | `GamingApp` 2611.1001.10.0; `GamingServices` present at A2f (39.118.21002.0) | `GamingApp` 2605.900.13.0; `GamingServices` absent at B1 and B2 |
| Xbox behavior | Launch probe alive; after A2f the sign-in page opened, but account sign-in and Game Pass were not tested | Xbox launch probe failed; B2 displayed “Xbox needs an update, but we're unable to apply the update right now” |
| WU | Scan/install checks passed after playbook; A2f had no pending updates | Five updates pending at B1; none at B2 on 26300.9711 |
| Store installs | Store package list remained healthy; the tested installs completed or were already present | At B2, winget reported success for To Do and Gaming Services while the packages were absent; AppX deployment events recorded failures |
| Security and boot | Secure Boot and TPM remained on; HVCI/VBS were off after the GUI defaults | Secure Boot and TPM remained on; HVCI/VBS were off |
| Resource sample | A2f: 94 processes, 93 running services, 202 enabled tasks, 2,099 MB used RAM | B2: 93 processes, 89 running services, 198 enabled tasks, 2,181 MB used RAM |

Sources are the archived ATL-1 and ATL-2 reports and their per-checkpoint JSON under `C:\EclipseLab\lane-a\out\` and `C:\EclipseLab\lane-b\out\`. The reports are archived outside this docs worktree at `C:\Atlas\.handoff\archive\ATL-1\ATL-1.report.md` and `C:\Atlas\.handoff\archive\ATL-2\ATL-2.report.md`.

## What the comparison supports

In these runs, lane A retained the updated Store and Xbox package versions and its WU and Store checks passed after applying the playbook. Lane B retained older Store and Xbox package versions after WU reached the same Windows build; `GamingServices` stayed absent, and the Xbox app showed an update error. The sequence is a useful compatibility signal for the EclipseOS install design: test Store/Xbox readiness across the complete install/update path, rather than treating “WU has no pending updates” as sufficient evidence.

The runs do not isolate the cause. Lane B differs in ISO injection timing and includes `ame-drivers-network`; test execution and first-boot paths also differ. Candidate explanations in ATL-2 include Store update policy applied before the Store updated, `InstallService` Manual/Stopped, and AME first-boot AppX work. These remain hypotheses. The result also does not cover Microsoft account sign-in, Game Pass, purchases, physical hardware, or all 26H2 builds.

## Follow-up test

Repeat with matched images and options, changing only whether Windows and Store are brought to a documented fixed point before playbook application or ISO injection. Capture Store/Xbox package versions, package registration, install results, WU history, relevant services, and Xbox launch/sign-in behavior at the same checkpoints. Treat the current result as a lab finding until reproduced with the confounders controlled.
