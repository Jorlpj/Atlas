# Public AME Wizard playbook (.apbx) inventory

Date: 2026-11-02. Read-only: GitHub API (`gh search code --filename playbook.conf`, `gh search repos`, topics `ame-wizard`/`apbx`, tree + raw `playbook.conf`, releases JSON, README text) plus one WebSearch. Nothing downloaded or run.
Stale = last push before 2026-05-02. "Latest" = latest GitHub release (tag, date) or `Version` in playbook.conf when none. Stars from the GitHub API. Builds = `<SupportedBuilds>` of the default-branch `playbook.conf` (26300 = 26H2, 26200 = 25H2, 26100 = 24H2). "n/v" = not verified (no conf readable).
Install = per README; default is "AME Wizard, drag .apbx onto a running system". Source = `playbook.conf`/yml readable as text in the repo.
Count: 65 playbook rows (some rows group forks), plus non-playbooks listed at the end.

## Inventory

| Name | Repo | Latest | Stars | License | SupportedBuilds | Install | Focus | Source | Status |
|---|---|---|---|---|---|---|---|---|---|
| AtlasOS | https://github.com/Atlas-OS/Atlas | 0.5.0-hotfix, 2025-10-21 (push 2026-10-27) | 22002 | GPL-3.0 | 26100, 26200 (no 26300) | AME Wizard | gaming/general | conf+yml | active |
| ReviOS | https://github.com/meetrevision/playbook | 26.10, 2026-10-09 | 2116 | CC-BY-SA-4.0 | 19044,19045,22631,26100,26200,26300,28000 | AME Wizard; ISO injection (Win11 ISOs) | general/perf | conf+yml | active |
| RapidOS | https://github.com/rapid-community/RapidOS | v1.3, 2026-06-28 | 122 | AGPL-3.0 | 19045,22621,22631,26100,26200 | AME Wizard | gaming/perf | conf+yml | active |
| AME 11 / Privacy+ | https://github.com/Ameliorated-LLC/privacy_plus | 0.8.2, 2025-10-03 (conf 0.8.3) | 91 | none | 22000..22635,26100,26200 | AME Wizard | privacy | conf+yml | stale (push 2025-10-22) |
| AME 10 | https://github.com/Ameliorated-LLC/AME-10 | 0.8, 2025-08-14 | 43 | none | 19044,19045 | AME Wizard | privacy (Win10) | conf+yml | stale |
| SynergyOS | https://github.com/Synergy-Tweaks/SynergyOS | 1.7, 2026-10-23 (conf 1.8.0) | 44 | none | 19044..22635,26100,26200,26300 | AME Wizard (README: stock ISO 22H2-26H2, LTSC) | gaming/perf | conf+yml | active |
| NOVA | https://github.com/synoxvf/NOVA | 1.0.1, 2026-10-17 | 31 | Apache-2.0 | 22631,26100,26200,26300 | ISO injection ONLY | gaming/privacy | conf+yml | active |
| AtmosphereOS | https://github.com/AtmosphereTeam/AtmosphereOS | 0.2.1, 2026-09-02 | 20 | none | 19045,22631,26100,26200 | AME Wizard | general | conf+yml | active |
| ArkanoidOS Lite | https://github.com/jointhearkanoid/playbook | conf 15.0 | 19 | NOASSERTION | 17763..22621 | AME Wizard (branch `lite`) | general | conf+yml | stale (2024-03) |
| ReimaginedOS | https://github.com/cr1mix/ReimaginedOS | 0.1v, 2026-10-05 | 15 | GPL-3.0 | n/v (repo has only README/LICENSE/images) | AME Wizard | general, optional tweaks | apbx only | active |
| Atom Playbook | https://github.com/ProjectAtomOS/Atom-Playbook | 0.0.8, 2026-10-05 | 12 | MIT | 19044..23620,26100,26200,27000..27900 | AME Wizard | general | conf+yml | active |
| oudenOS | https://github.com/redpersongpt/oudenOS | v1.0.5, 2026-06-18 | 10 | none | 19045,22631,26100 | AME Wizard; HW reqs disabled | minimal/debloat | conf+yml (under artifacts/) | active |
| DeckXP | https://github.com/veygax/DeckXP | none (conf 0.1) | 8 | none | n/v | AME Wizard | handheld/Steam Deck | conf+yml | stale (2024-09) |
| Eternity | https://github.com/haslate/Eternity | v1.4, 2023-08-30 (conf 1.5) | 8 | GPL-3.0 | 19045,22621 | AME Wizard | general | conf+yml | archived |
| Rebuild OS | https://github.com/TheRebuild/Playbook | 0.2.0, 2024-06-20 | 7 | none | 19045,22621,22631 | AME Wizard | general | conf+yml | archived |
| UltraOS | https://github.com/UltraOS-Project/playbook | v1.2.1, 2026-10-28 | 6 | GPL-3.0 | 26100,26200,26300 | AME Wizard (3 presets, rollback) | general/perf, 26H2-first, Xbox excluded from svchost split | conf+yml | active |
| ShimmerOS | https://github.com/u-chr/ShimmerOS | v1.5.2, 2026-10-28 | 5 | none | 19042..22635,26100,26200,26300 | AME Wizard | general | conf+yml | active |
| LexBoosT OS | https://github.com/LexBoosT/LexBoosT_OS | 26.10.1, 2026-10-23 | 5 | none | 26200,26300,28000 | AME Wizard (README FR; keeps Store/ClipSVC/TokenBroker) | gaming | conf+yml | active |
| VenixOS | https://github.com/Ronix1/VenixOS | 0.0.1, 2024-04-11 | 5 | GPL-3.0 | n/v | AME Wizard | general | conf+yml | stale |
| SucklessWindows | https://github.com/SucklessWindows/SucklessWindows | 4.2024.8, 2024-04-30 | 61 | GPL-3.0 | n/v | AME Wizard | minimal | conf+yml | archived |
| Akati OS | https://github.com/x2Swiftyouz/Akati-Os | v1.14.0, 2026-10-15 | 4 | GPL-3.0 | src: 26100,26200,26300; src-win10: 19045 | AME Wizard (Atlas-based) | general | conf+yml | active |
| ReviOS Canary (VikashLoomba) | https://github.com/VikashLoomba/revi-playbook-canary | conf 23.12 | 4 | NOASSERTION | 19044..22631,26020 | AME Wizard | ReviOS fork | conf+yml | stale (2024-01) |
| KiyomizuOS | https://github.com/KiyomizuSuzu/KiyomizuOS | 3.0.0, 2026-06-29 (conf 3.0.1 Preview) | 3 | AGPL-3.0 | 26200,26300 | AME Wizard (Winhance-based, PowerShell) | general | conf+yml | active |
| SapphireOS | https://github.com/HickerDicker/SapphireOS-Playbook | conf 0.0.1; apbx-sapphireos-v0.0.3 in KT catalog | 3 | GPL-3.0 | 19044..22631,26100,26200 | AME Wizard | general | conf+yml | active (push 2026-05-17) |
| KutayOS | https://github.com/kutaykalay/KutayOS | conf 0.9.0 | 3 | GPL-3.0 | 26100 (LTSC 2024) | AME Wizard | LTSC | conf+yml | active |
| FiqnOS | https://github.com/FiqnOS/Playbook | conf 1.0 | 1 | none | 19045..26100 | AME Wizard | general | conf+yml | stale (2024-12) |
| Nebula OS | https://github.com/Zibgame/Nebula-Os | conf 1.0 | 1 | none | 19044..22631,26100,26200 | AME Wizard | general | conf+yml | active (push 2026-05-02) |
| ShuraOS | https://github.com/SanyaSavin/ShuraOS_PlayBook | 1.0, 2026-02-03 | 2 | none | 19044..22631,26100,26200,28000,28020 | AME Wizard | general | conf+yml | active (push 2026-05-13) |
| plasXOC playbook | https://github.com/plasXOC/playbook | v1, 2026-03-16 | 2 | NOASSERTION | n/v (readme only) | AME Wizard | privacy/perf | apbx only | stale |
| Redress Server | https://github.com/redress-server/playbook | Alpha2.0, 2023-06-11 | 2 | GPL-3.0 | 20348 | AME Wizard | Windows Server | conf+yml | stale |
| RaxOS | https://github.com/imribiy/RaxOS | conf 0.0.1 | 2 | MIT | 19045,22621,22631 | AME Wizard | general | conf+yml | stale (2024-08) |
| ThinNekoOS | https://github.com/MeowBot233/ThinNekoOS | none | 2 | AGPL-3.0 | n/v | AME Wizard | general | not published | stale (2023-04) |
| KT-TWEAKS APBX catalog | https://github.com/KT-TWEAKS/KT-TWEAKS-APBX | apbx-xos-v0.777, 2026-10-08 (also vain v1.4.0, sapphireos v0.0.3) | 2 | GPL-3.0 | n/v (apbx in releases only, SHA-256 catalog) | AME Wizard | catalog (XOS, Vain, SapphireOS) | apbx only | active |
| GlendaOS | https://github.com/Sapphxre5261/GlendaOS | GlendaOS-V.1.0.0, 2026-10-26 | 1 | none | 22000..22635,26100,26200,26300 | AME Wizard | general | conf+yml | active |
| MuulfzOS Fortnite | https://github.com/Muulfz/MuulfzOSFN | v0.9.4, 2026-10-16 | 1 | MIT | 26100,26200,26300 | AME Wizard; anti-cheat invariants | gaming (Fortnite/EAC) | conf+yml (playbook-fortnite.conf) | active |
| GamerzOS | https://github.com/GamerzOS-Playbook/GamerzOS | 0.2, 2025-08-29 | 1 | GPL-3.0 | 19045,26100 | AME Wizard (Atlas fork) | gaming | conf+yml | active (push 2026-09-03) |
| RivalsOS | https://github.com/Rob-QT/RivalsOS-Playbook | v0.5.0, 2026-08-03 | 1 | GPL-3.0 | 26100,26200 | AME Wizard (Atlas fork) | gaming | conf+yml | active |
| 3R4-OS | https://github.com/3R4-TBNKZ/3R4-OS | conf 0.4.1 | 1 | GPL-3.0 | 19045,26100 | AME Wizard (Atlas fork) | general | conf+yml | stale (2025-09) |
| Dlrow Playbook | https://github.com/dlrowdetrevni1-boop/Dlrow-Playbook | none (Dlrow_Optimizer_v1.0.apbx in tree) | 1 | MIT | n/v | AME Wizard | gaming (latency/FPS) | apbx only | active (2026-09-16) |
| flibPlat | https://github.com/flibteam/flibPlat | conf 26.09 | 1 | MIT | 19044,19045,22631,26100,26200 | AME Wizard | general | conf+yml | active |
| JarvisOS (PsProsen) | https://github.com/PsProsen-Dev/JarvisOS | v11.06.26, 2026-06-10 | 1 | MIT | 22000..22631,26100,26200,27686 | AME Wizard | general | conf+yml | active |
| SymbioseOS (Chaos) | https://github.com/Saimonokuma/Chaos-SymbioseOS | conf 3.0 | 0 | GPL-2.0 | 19045,22621,26100 | AME Wizard | general | conf+yml | active (2026-05-13) |
| ChamberTech Playbook | https://github.com/ChamberTechFPS/Playbook | v1.3.3 2026-10-25 (beta v1.4.0-beta.2 2026-10-30) | 0 | NOASSERTION | 26100,26200,26300 | AME Wizard (Chamber.apbx); Secure Boot, Store, winget, Defender kept; undo | gaming (anti-cheat safe) | conf+yml | active |
| GamingOS (Witthen) | https://github.com/Witthen/GamingOS | v1.0.2, 2026-10-21 | 0 | MIT | 26100,26200 | AME Wizard (no NoPendingUpdates; Edge/OneDrive/Xbox kept by default) | gaming | conf+yml | active |
| Meridian 26H2 | https://github.com/zykmm/meridian-26h2 | v1.0.0, 2026-11-01 | 0 | GPL-3.0 | 26300 only | AME Wizard | general 26H2 | conf+yml | active |
| ChinazesOS | https://github.com/hxkfi65-hub/ChinazesOS | v1.5, 2026-11-02 | 0 | MIT | 19044..26200,26300,28000,28020 | AME Wizard | general | conf+yml | active |
| ANCX777 | https://github.com/wakgimang11t-bot/ANCX777 | v0.777, 2026-10-17 | 0 | GPL-3.0 | 17763..19045,22000..22631,26100,26200,26300,28000 | AME Wizard | general | conf+yml | active |
| EZE OS | https://github.com/BaskaranElilan/EZE-OS | v1.0, 2026-08-08 | 0 | none | 19044..22631,26100,26200 | AME Wizard | general | conf+yml | active |
| Z-LAG-OS | https://github.com/MrPcGamerYT/Z-LAG-OS (mirror testssssa22a/Z-LAG-OS, 5.16) | 5.20, 2026-10-22 | 0 | NOASSERTION | not declared | AME Wizard, FreshInstall req | gaming/emulators; blocks updates; Store removal option-gated | conf+yml | active |
| WMAROS | https://github.com/alrigroup/wmaros | V0.1, 2026-04-30 | 0 | NOASSERTION | 17763..19045,22000..22631,26100,26200,28000,295xx | AME Wizard | general | conf+yml | active (push 2026-05-05) |
| Capsule OS | https://github.com/IN8torious/CapsuleOS | conf 0.1.0 | 0 | none | n/v | AME Wizard | general | conf+yml | active (push 2026-11-02) |
| MatiOS | https://github.com/Matidobryja/MatiOS | none (README only) | 0 | none | n/v | AME Wizard | aggressive gaming (removes Defender, UWP) | not published | active (2026-06-14) |
| APEX (apexOS Windows) | https://github.com/MagicTwist541/APEX | none (README only) | 0 | Apache-2.0 | n/v | AME Wizard | general | not published | active (2026-08-06) |
| Appalachian Windows 11 | https://github.com/AppalachianMounta1n/App-s-AME-Playbook | conf 0.1.0 | 0 | AGPL-3.0 | n/v | AME Wizard | general | conf+yml | stale (2025-10) |
| JarvisOS "Catgirl Playbook" | https://github.com/Star123451/JarvisOS | v1.0.0, 2025-11-02 | 0 | MIT | n/v | AME Wizard | joke/general | conf+yml | stale |
| ReviOS copies | https://github.com/huuhait/playbook , https://github.com/m0420/playbook-ReviOS | conf 1.0 | 0 / 1 | NOASSERTION | 19044..22631,26100 | AME Wizard | ReviOS fork | conf+yml | stale (2024-10 / 2025-08) |
| AtlasOS 21H2 | https://github.com/EricPanDev/AtlasOS-21H2 | conf 0.4.1 | 0 | none | 19044,19045,26100 | AME Wizard | Atlas fork | conf+yml | stale (2024-10) |
| RaxOS beta | https://github.com/ignatividiu/RaxPlayBook-Beta | conf 001 | 0 | none | 19044..22631 | AME Wizard | general | conf+yml | stale (2024-06) |
| Ryne OS | https://github.com/Ryne-os/Ryne | conf 0.3 | 0 | NOASSERTION | 22621,22631 | AME Wizard | general | conf+yml (+2 apbx) | stale (2023-12) |
| Power11 | https://github.com/XPower7125/power11 | conf 2305.0 | 1 | none | n/v | AME Wizard | general | conf+yml | stale (2023-10) |
| CleanOS | https://github.com/cleancustomos/cleancustomos | v1.0, 2024-03-28 | 0 | GPL-3.0 | n/v | AME Wizard | general | conf+yml | stale |
| Windows Server 2025 playbook | https://github.com/Sample-Text-OS/Sample-Text-OS | conf 0.1 | 0 | GPL-3.0 | n/v | AME Wizard | Server | conf+yml | stale |
| Piarre dev setup | https://github.com/Piarre/AMESetup | conf 1.0.0 | 0 | none | n/v | AME Wizard | dev setup | conf+yml | stale |
| GarciaLnk windows-playbook | https://github.com/GarciaLnk/windows-playbook | conf 1.1 | 0 | NOASSERTION | 19044,19045,22631,26100 | AME Wizard | general | conf+yml | stale (2024-12) |
| windows-debloat (sdhlfqr) | https://github.com/sdhlfqr/windows-debloat | conf 0.1 | 0 | MIT | 26100 | AME Wizard | debloat | conf+yml | stale (2024-12) |
| WinOptimizer | https://github.com/berkyildiz/WinOptimizer | v1.0, 2024-10-27 | 3 | MIT | n/v | AME Wizard (assumed) | optimizer | apbx only | stale |
| MerengOS | https://github.com/Bosbaboi/MerengOS-AME-Wizard- | none (repo empty) | 0 | none | n/a | n/a | n/a | empty | stale |
| ProPlus playbook (lucidslab) | https://github.com/lucidslab/proplus_playbook | none (repo empty) | 0 | none | n/a | n/a | n/a | empty | stale |

Not found as public repos (gh + WebSearch): Nexus, FSOS-X. Found: Z-LAG-OS, KT-TWEAKS, SapphireOS (above).

Suspicious "apbx"-named repos, treated as hostile bait, not downloaded: Oopti/apbx, axmostyc/apbx, silverridge99/apbx, smithdavid9944/apbx, orytrizlest/apbx, faint-axiom6/apbxx, veethawebertond/apbxq, parksamanda439/apbxec, alan726613/apbxoa, adaan5frt9oqc/repo-z11apbxm, x7yxpksk72-maker/*, Internet-explorer-5-shap/*. (Judged by name only.)

Non-playbooks surfaced: QuiteAFancyEmerald/Slate-Desktop-for-Windows-11 (CLI ricing, 91 stars), Synergy-Tweaks/SynToolkit (companion tool), meetrevision/revision-tool, osmanonurkoc/ReviOS_Patcher, Ameliorated-LLC/trusted-uninstaller-cli (engine), KT-TWEAKS/KT-WIRZADE (MIT, C# AME Wizard fork engine, v1.0.2 2026-10-22), Miguel-ezh/apbx-chrome-extension, erenceylan16/atlas-gic and AhmedZakaria01/bsl-atlas (unrelated).

Caveats: SupportedBuilds read from the default branch only; many small repos copy Atlas/ReviOS; no security assessment of any apbx. Other sources: https://github.com/topics/ame-wizard, https://github.com/Ameliorated-LLC, https://github.com/ChamberTechFPS/Playbook/releases/tag/v1.4.0-beta.2.

## Shortlist for a gaming-focused, Store/Xbox-compatible, secure 26H2 fork

1. ChamberTech Playbook (https://github.com/ChamberTechFPS/Playbook): keeps Store, winget, Defender and Secure Boot, supports 26300, has undo and a beta line; closest in intent.
2. UltraOS (https://github.com/UltraOS-Project/playbook): 26H2-first, GPL-3.0, presets, full rollback, Xbox excluded from its service-host split; reference for reversible design.
3. LexBoosT OS (https://github.com/LexBoosT/LexBoosT_OS): gaming, 26300/28000, keeps ClipSVC/TokenBroker for the Store and says to update Store apps first.
4. MuulfzOS Fortnite (https://github.com/Muulfz/MuulfzOSFN): anti-cheat invariants checked, 26300, MIT; model for anti-cheat safety.
5. ReviOS (https://github.com/meetrevision/playbook): largest active community, 26300/28000, compatibility-first; same engine/layout as Atlas.
6. Meridian 26H2 (https://github.com/zykmm/meridian-26h2): Atlas-structured, 26300-only, 79 documented changes with a changelog; handy diff base for 26H2.
7. GamingOS Witthen (https://github.com/Witthen/GamingOS): default keeps Edge/OneDrive/Xbox, opt-in max mode, drops NoPendingUpdates; same philosophy as our Store/Xbox rule.
8. RapidOS (https://github.com/rapid-community/RapidOS): 122 stars, active gaming/perf; 26300 missing, compare tweak set.
9. NOVA (https://github.com/synoxvf/NOVA): 26300, Apache-2.0, gaming/privacy; ISO-injection only (conflicts with maintainer rule), so tweak catalog only.
10. Z-LAG-OS (https://github.com/MrPcGamerYT/Z-LAG-OS): runtime-aware debloat preserving AppX runtime services; caution, blocks updates and has no SupportedBuilds.
11. SynergyOS (https://github.com/Synergy-Tweaks/SynergyOS): active with 26300, but README lists UAC and exploit mitigations off (breaks Store/UWP); negative reference for the security goal.
12. Atlas upstream (https://github.com/Atlas-OS/Atlas): baseline; its conf lists only 26100/26200 (no 26300).
