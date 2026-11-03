# Install method

Status: proposed. The maintainer must accept this profile through the orchestrator before it becomes an implementation requirement.

## Atlas today

Atlas 0.5.0 declares supported builds 26100 and 26200; build 26300 is absent. Its setup requirements include internet and no pending Windows Update items, but the configuration names gates without documenting their checks. The ISO block sets `DisableBitLocker` and `DisableHardwareRequirements` to true, and OOBE internet to `Force`. Those declarations describe Atlas's configuration and do not establish what EclipseOS should require. ([Atlas map: playbook configuration](../../map/playbook-conf.md); `src/playbook/playbook.conf:14-29,40-55`)

Atlas's initial configuration also installs utilities and can install optional browsers after setup; the mapped start task shows the scope of those actions and which lack a paired action in Atlas's upgrade revert. ([Atlas map: initial configuration](../../map/start.md); `src/playbook/Configuration/atlas/start.yml:31-93`, `src/playbook/Configuration/atlas/revert.yml:6-22`)

## Lab evidence and limits

The completed 26H2 comparison covered two different paths. Lane A installed Windows, updated Windows Update and Store to a fixed point, then applied the local lab playbook. Lane B injected the lab playbook into the ISO before setup and updated after first boot. After updates, lane B still had older Store/Xbox package versions, no Gaming Services, and an Xbox update error; lane A retained its updated package state and passed the recorded checks. The lanes also differed in options and execution details, so this comparison does not prove that injection timing caused the outcomes. ([lab comparison](../lab/comparison.md); [lab method](../lab/method.md); [catalog A01-A02](../research/problem-catalog.md#a-order-of-install-and-servicing))

The tested Atlas configuration did not list build 26300 as supported. A temporary local build-list change enabled the lab run, so the result is not a compatibility certification for the normal Atlas release. The lab also did not test physical hardware, account sign-in, purchases, or Game Pass. ([Atlas map: playbook configuration](../../map/playbook-conf.md); [lab method](../lab/method.md); [catalog A04](../research/problem-catalog.md))

## Other playbook choices

The dated 26H2 survey records ISO and post-install approaches from other projects, but its source inventory is not a matched clean-install compatibility test. Treat those approaches as research leads, not validation for EclipseOS. ([26H2 playbook survey](../research/26h2-playbooks.md); [survey scope and limits](../research/26h2-playbooks.md))

## Proposed EclipseOS default

1. **Ship a supported, documented clean-install path first.** Start from unmodified Windows installation media and keep Windows setup separate from EclipseOS configuration. Do not inject EclipseOS changes into an ISO until a matched test shows that the image can complete servicing and the acceptance checks below.
2. **Honor hardware security requirements.** Keep TPM 2.0 and Secure Boot enabled and required. Do not carry over Atlas's `DisableHardwareRequirements=true` setting; EclipseOS's stated anti-cheat goal depends on preserving those protections. Keep BitLocker available and make any setup choice explicit rather than silently disabling it.
3. **Finish servicing before applying system changes.** Complete Windows Update and Microsoft Store updates, confirm their states independently, and reboot before installing EclipseOS changes. A zero-pending Windows Update result alone does not establish Store readiness. This is a conservative gate motivated by the maintainer report and the two-lane comparison, not proof of a single cause. ([catalog A01-A02](../research/problem-catalog.md#a-order-of-install-and-servicing); [Windows Update design](windows-update.md))
4. **Keep setup choices visible and minimal.** Present security, update, account, Store/Xbox and optional software choices before applying them. Record the selected profile and build in an install receipt. Do not bundle unrelated browser or utility installation into the servicing and compatibility gate.
5. **Require a recovery route before broad changes.** Capture a pre-change restore point or equivalent supported recovery state, record each selected action and its result, and provide a documented repair or reinstall path. A restore point alone must not be described as a guaranteed undo for removed AppX packages or unsupported servicing states.
6. **Gate image deployment on parity.** If ISO deployment is later offered, compare it with the supported post-install path using the same Windows image, build, options and checkpoints. Until that test passes, describe ISO deployment as unvalidated and keep it out of the supported installation instructions.

## Trade-offs and acceptance checks

Separating Windows setup from system configuration adds a servicing and reboot stage, but gives EclipseOS a clear checkpoint before changes that might affect Store and Xbox. Requiring TPM and Secure Boot can exclude older hardware, which is a direct trade-off of the stated anti-cheat compatibility goal. Recovery snapshots and receipts add storage and implementation work.

For every supported build and installation path, record the exact image/build, firmware mode, TPM and Secure Boot state, option set, and installation order. After servicing and again after EclipseOS setup, verify Windows Update history and pending state, Store package versions and a successful Store app update/install, Xbox app launch, Gaming Services registration, Secure Boot/TPM/VBS/HVCI state, and recovery after reboot. Test Game Pass and account flows separately before claiming support. Do not mark ISO deployment supported based on a Windows Update scan alone.

