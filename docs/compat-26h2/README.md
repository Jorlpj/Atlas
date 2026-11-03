# Windows 11 26H2 compatibility register

This register records Atlas-related compatibility findings for Windows 11 build 26300 where a build is known. A finding marked `confirmed` confirms only the scoped observation or documented behavior stated below; it does not imply general compatibility or establish causation. Source IDs refer to graded records in the librarian `sources.json`.

## Summary

| ID | Finding | Build | Status | Finding grade |
| --- | --- | --- | --- | --- |
| C26-001 | Store, Xbox and Store installs failed in one maintainer run after Atlas was applied before Windows Update and Store were fully updated and rebooted | 26300 | confirmed | A1 |
| C26-002 | AME documents `NoPendingUpdates` as a Windows Update check; Store is not mentioned in that requirement definition | 26300 | confirmed | A1 |
| C26-003 | AME ISO/OOBE documentation does not establish whether Windows or Store servicing is complete when the playbook runs | 26300 | suspected | B2 |
| C26-004 | An upstream task denies Everyone full control on the current user's Store `store.db` | Not specified | confirmed | A1 |

## Findings

### C26-001 — Store and Xbox failures after early playbook application

- **Affected:** One Windows 11 build 26300 workflow: Atlas was applied before Windows Update and Microsoft Store had fully updated and the machine had rebooted.
- **Symptom:** The maintainer observed Microsoft Store and Xbox failures, including Store installs that failed irreparably in that run.
- **Evidence:** The maintainer's first-hand test supports this single reported outcome. The playbook map identifies possible areas to investigate—optional AppX removals (`src/playbook/Configuration/atlas/appx.yml:17-23,37-43,80-89`), UCPD startup configuration (`src/playbook/Configuration/atlas/services.yml:62-64`) and Store `AutoDownload=2` (`src/playbook/Configuration/tweaks/qol/disable-store-auto-updates.yml:1-9`)—but does not establish a cause. The configured `AutoDownload` value disables automatic Store app updates. Interactive AtlasDesktop Store/Xbox controls are separate manually launched operations.
- **Status / grade:** `confirmed`, A1 for the one observed run; causation and generality remain unresolved.
- **Sources:** Source record: `maintainer-test-2026-10-27` (A1, in librarian `sources.json`). Atlas map context: [`appx.md`](../map/appx.md), [`services.md`](../map/services.md), [`tweaks-qol.md`](../map/tweaks-qol.md), [`atlasdesktop.md`](../map/atlasdesktop.md).
- **Next step:** Run a controlled VM reproduction against the preflight gate and isolate candidate actions one at a time; record package versions, servicing state, errors and recovery outcome.
- **Card:** None recorded.

### C26-002 — Scope of AME `NoPendingUpdates`

- **Affected:** Atlas's AME requirement declaration at `src/playbook/playbook.conf:24-30` and the AME Wizard requirement.
- **Symptom / finding:** AME's requirement documentation defines `NoPendingUpdates` as checking for pending or downloading Windows updates and does not mention Microsoft Store in that definition.
- **Evidence limit:** This confirms the published requirement scope only. AME runtime implementation was not examined, and this does not rule out a separate Store check elsewhere.
- **Status / grade:** `confirmed`, A1 for the documented scope.
- **Source:** [`AME-NoPendingUpdates-requirement-docs`](https://docs.amelabs.net/developers/requirements.html) (A1; source record ID in `sources.json`).
- **Next step:** AME runtime implementation scope remains unverified; investigate it if the runtime behavior becomes material to this finding.
- **Card:** None recorded.

### C26-003 — ISO injection, OOBE and servicing order

- **Affected:** AME Wizard ISO injection/OOBE workflow; Atlas declares ISO support in `src/playbook/playbook.conf:40-55`.
- **Finding:** The documentation distinguishes offline ISO injection from OOBE: eligible `iso:true`/`only` YAML actions run during injection, while dynamic scripts and commands, including the playbook, run at OOBE after Windows installation and prerequisites/configuration. It does not state whether Windows Update or Microsoft Store servicing has completed by then.
- **Evidence limit:** AME's general update guidance recommends installing available Windows updates before running a playbook and checking again after reboot. The ISO/OOBE documentation still does not specify Windows Update or Store servicing state at the point the playbook runs, and neither source establishes a Store servicing prerequisite for ISO deployments. The timing claim therefore remains unconfirmed.
- **Status / grade:** `suspected`, B2; keep the before-servicing timing claim unconfirmed.
- **Sources:** [`AME-ISO-injection-OOBE-timing`](https://docs.amelabs.net/developers/iso.html) (A1 for the published process description); [`AME-Windows-updates-before-playbook`](https://docs.amelabs.net/using-wizard/apply-updates.html) (A1 for the general Windows Update recommendation; neither source provides Store-at-OOBE evidence).
- **Next step:** Retain suspected status unless AME documents ISO/OOBE servicing order explicitly or a controlled run records Windows Update and Store state at playbook execution.
- **Card:** None recorded.

### C26-004 — Store search recommendations database ACL

- **Affected:** Upstream `Disable-StoreSearchRecommendations.ps1`; no Windows build is specified in the finding.
- **Finding:** Source inspection of `upstream/new-update` and `upstream/ms-store-test` found identical scripts. The script resolves the current user's LocalApplicationData, creates the Store `LocalState` directory and `store.db` if absent, then invokes `icacls.exe` to deny SID `S-1-1-0` (Everyone) full control; it throws if `icacls` reports failure. The QoL task describes disabling recommended Store apps in Start and invokes the script elevated for the current user.
- **Evidence limit:** Static source confirms the ACL operation, not runtime behavior of recommendations or effects on Store/Xbox servicing.
- **Status / grade:** `confirmed`, A1 for the inspected source contents.
- **Sources:** source ID [`https://github.com/Atlas-OS/Atlas/blob/new-update/src/playbook/Executables/AtlasModules/Scripts/Tasks/Disable-StoreSearchRecommendations.ps1#L3-L19`](https://github.com/Atlas-OS/Atlas/blob/new-update/src/playbook/Executables/AtlasModules/Scripts/Tasks/Disable-StoreSearchRecommendations.ps1#L3-L19) (A1); source ID [`https://github.com/Atlas-OS/Atlas/blob/ms-store-test/src/playbook/Executables/AtlasModules/Scripts/Tasks/Disable-StoreSearchRecommendations.ps1#L3-L19`](https://github.com/Atlas-OS/Atlas/blob/ms-store-test/src/playbook/Executables/AtlasModules/Scripts/Tasks/Disable-StoreSearchRecommendations.ps1#L3-L19) (A1).
- **Next step:** Test runtime Store/Xbox effects before making claims beyond the inspected source contents.
- **Card:** None recorded.


