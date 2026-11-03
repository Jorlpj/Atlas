# Lab lane A: post-install method on 26300 (ATL-1)

Orchestrator summary, 2026-11-02. Source: the ATL-1 report (rounds 1 and 2) and the JSON in
`C:\EclipseLab\lane-a\out\`. Guest: Hyper-V Gen2 VM `eclipse-lab-a`, 4 vCPU, 8 GB, vTPM, Secure Boot. Windows 11 Pro
26H2 was installed from 26300.9457 and updated to 26300.9711 with every Windows Update and Store update. Then the
Atlas playbook (lab build, 26300 added to `SupportedBuilds`) was applied with AME CLI 0.8.4. Findings: problem catalog section
G ([../research/problem-catalog.md](../research/problem-catalog.md)).

## Points
- A0: stock, fully updated. A0v: A0 with nested virtualization, VBS and HVCI running.
- A1: playbook with RadioPage defaults only. A1f: playbook with the full GUI defaults (11 options). A2f: A1f after
  Windows Update and the Store update again.
- Checkpoints left on the VM: A0-updated-stock, A1-playbook-applied, A2-post-update, A0v-stock-vbs, A1-full, A2-full.

## Results
| item | A0 | A1 | A1f | A2f |
|---|---|---|---|---|
| Store / Xbox packages | Ok | Ok | Ok | Ok |
| launches (Store, Settings x3, Xbox, Terminal) | 6/6 | 6/6 | 6/6 | not rerun |
| WU scan / install after playbook | - | ok | - | ok (definition update hr 0) |
| VBS / HVCI | off (A0v: on) | off | off | off |
| Defender RTP / Tamper | on / on | on / off | on / off | on / off |
| Edge / WebView2 | present / 156 | not measured | removed / 156 | removed / 156 |
| processes / services / tasks | 135 / 97 / 218 | 89 / 89 / 196 | 89 / 88 / 201 | 94 / 93 / 202 |
| used RAM MB / C: GB | 2429 / 29.2 | 2130 / 16.1 | 2098 / 17.3 | 2099 / 17.9 |

## Open
None for lane A. Microsoft account, Xbox and Game Pass sign-in are out of scope: EclipseOS uses a local account
without password. ATL-1 closed 2026-11-02; `eclipse-lab-a` stays off with its checkpoints.
