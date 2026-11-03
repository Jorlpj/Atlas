# Revert and recovery

Status: proposed. This page defines recovery requirements for EclipseOS; it does not claim Atlas currently provides a complete undo path. The maintainer must accept proposed defaults through the orchestrator before they become implementation requirements.

## Atlas behavior and evidence limits

Atlas's configured `revert.yml` deletes `ThisPCPolicy` values for seven Explorer folder IDs in both the normal and Wow6432Node registry paths. It has no option or build condition and is marked for upgrades. The map finds no service, driver, task, file, AppX, or Windows policy restoration in that file. This is a narrow cleanup, not a general inverse of the playbook. ([Atlas revert map](../../map/revert.md); `src/playbook/Configuration/atlas/revert.yml:1-36`)

The map pages document other actions with limited or absent paired restoration. For example, services and drivers are changed in the services configuration, while `revert.yml` contains no matching service restore. Some changes are direct registry writes, while others disable services, remove components or packages, or alter scheduled tasks; these have different recovery needs. ([services map](../../map/services.md); [components map](../../map/components.md); [AppX map](../../map/appx.md); [scheduled-task map](../../map/atlasmodules.md))

The lab comparison did not exercise a complete rollback, restore point, package repair, or recovery-media workflow. Its Store and Xbox observations therefore say nothing about how reliably any recovery method reverses EclipseOS changes. ([lab comparison](../lab/comparison.md); [lab method](../lab/method.md))

## Proposed EclipseOS default

1. **Describe recovery per action.** Before applying a setting, record its identifier, target, prior state where it can be read safely, new state, condition, and an explicit recovery method. Mark actions as directly reversible, recoverable through a supported Windows repair path, or requiring reset/reinstall. Do not label an action reversible just because its configuration has a separate script.
2. **Use narrow, paired changes for supported reversible settings.** A paired undo should restore the captured prior value or state, not assume a universal Windows default. It should report actions it could not restore and avoid silently continuing after an unexpected target state.
3. **Separate destructive changes.** Package/component removal, deleted files, servicing changes, and actions with unknown prior state need a separately documented repair or reinstall route. A restore point or registry export alone must not be presented as a guaranteed way to restore removed packages or a healthy servicing state.
4. **Create a recovery checkpoint before broad changes.** Use a supported recovery mechanism appropriate to the action set, confirm that it was created, and preserve a bootable recovery route. If checkpoint creation fails, stop before applying actions that depend on it.
5. **Keep the receipt and recovery instructions together.** Record OS build, image, firmware and security state, selected options, action results, checkpoint identifier, and recovery instructions. Provide a tested route to undo the selected profile or reinstall Windows while preserving user data where supported.
6. **Do not promise full rollback until tested.** For each supported build and profile, test recovery after a partial apply, a normal apply, and a reboot. Verify restored values and services, Store app install/update, Xbox launch and Gaming Services, Windows Update, and TPM/Secure Boot/VBS/HVCI state. Record failures and unsupported actions in the receipt.

## Trade-offs and acceptance checks

Capturing prior state and maintaining per-action recovery adds implementation, storage, and test work. Some removals may remain reset/reinstall-only, so the interface must show that limitation before applying them. A broad snapshot can aid recovery but does not replace targeted verification of Windows servicing, Store, Xbox, or security state.

Acceptance requires a recovery matrix for every supported action and build, a clear user-visible recovery path before changes, and recorded results from rollback and reboot checks. No profile is described as fully reversible until all its actions have passed those checks. Keep the Windows servicing and Store readiness gate in the [install method](install-method.md); rollback tests must include the Store/Xbox checks defined by the [Store and Xbox design](store-appx-xbox.md).

