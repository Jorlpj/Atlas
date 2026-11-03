# Windows Update design

Status: proposed. The maintainer must accept this default through the orchestrator before it becomes an implementation requirement.

## Atlas today

The QoL group runs its Windows Update subgroup alongside other system tweaks. The subgroup disables update nagging, Insider enrollment, MSRT telemetry and Delivery Optimization, sets feature-update targeting and configures automatic restart policy values. Disabling automatic updates is a separate action selected only with the `auto-updates-disable` option. The Store app auto-update task is separate again: it writes `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate\AutoDownload=2`, which disables automatic Store app updates. These controls do not remove Store or Xbox packages. ([Atlas map: QoL](../../map/tweaks-qol.md); `src/playbook/Configuration/tweaks.yml:180-188`; `src/playbook/Configuration/tweaks/qol/windows-update/disable-auto-updates.yml:1-17`; `src/playbook/Configuration/tweaks/qol/disable-store-auto-updates.yml:1-9`)

The automatic-update task calls the AtlasDesktop disable script only when its option is selected; it also writes DevHome and Outlook scheduler completion markers. Feature-update targeting is configured in a different task, so its selected branch and the current product version must be checked before interpreting the target. The other subgroup tasks write Windows Update policies, including restart, Insider and Delivery Optimization controls. ([Atlas map: QoL](../../map/tweaks-qol.md); `src/playbook/Configuration/tweaks/qol/windows-update/disable-auto-updates.yml:1-17`; `src/playbook/Configuration/tweaks/qol/windows-update/disable-feature-updates.yml:1-14`)

The inspected upgrade revert only removes legacy Explorer folder-description values; it does not restore these update or Store settings. Atlas's documented servicing choice is therefore not fully reversible through that configuration's upgrade revert. (`src/playbook/Configuration/atlas/revert.yml:1-36`; [Atlas map: QoL](../../map/tweaks-qol.md))

## Lab evidence and limits

In the two Hyper-V runs on build 26300.9457, later updated to 26300.9711, lane A applied Atlas after Windows Update and Store reached a fixed point; its later Windows Update scan passed and updated Store/Xbox packages remained present. Lane B injected Atlas into the ISO before servicing; after Windows Update reached the same build, Store and Xbox packages were older, Gaming Services was absent, and an Xbox update probe failed. The lanes differ in more than update order, so the comparison does not establish which policy or installation step caused the difference. ([lab comparison](../lab/comparison.md); [lane A](../lab/lane-a.md); [lane B](../lab/lane-b.md))

This evidence supports checking Store readiness and package state separately from Windows Update's pending-update scan. It does not establish that any single Atlas policy causes the lane B outcome, nor does it cover all supported hardware, sign-in, purchases or Game Pass. ([lab comparison](../lab/comparison.md))

## Other playbook choices

The dated 26H2 source survey records ReviOS pausing updates to 2038 and leaving `NoAutoUpdate` commented out after that policy was associated with an Xbox sign-in problem; it records UltraOS Balanced recommending automatic updates and Chamber offering a notify-only option. The survey is a snapshot of repository and vendor reads, not a uniform clean-install test, so these are design leads rather than compatibility proof. ([26H2 playbook survey](../research/26h2-playbooks.md#comparison); [survey scope and limits](../research/26h2-playbooks.md))

## Proposed EclipseOS default

1. **Keep Windows Update available and automatic by default.** Do not disable the Windows Update service, delete update components, or pause updates indefinitely. Offer a user-visible maintenance window or notification choice only if testing confirms it preserves security and feature servicing.
2. **Make post-install servicing an explicit gate.** Before applying debloating or other system changes, bring Windows Update and Microsoft Store updates to a recorded fixed point and reboot. Do not support ISO injection until a matched lab run shows the same Store, Xbox and Windows Update checks pass. The current lab comparison motivates this sequence but does not prove it is causal.
3. **Keep Store app updates enabled.** Do not apply Atlas's `AutoDownload=2` behavior by default. Treat Store app updates as separate from Windows Update policy and verify that Store installs and updates complete after the Windows servicing gate.
4. **Keep update controls narrow and observable.** Avoid conflicting feature-target, pause and automatic-update policies. If EclipseOS later offers a pause or notification setting, expose its duration and current state, record it in diagnostics, and test resumption. Keep Insider enrollment and telemetry choices separate from the ability to receive security updates.
5. **Require a recovery path.** Provide a supported way to restore update policy values and restart affected services. Capture policy state before changes and verify that Windows Update can scan and install, Store can update apps, and Xbox/Gaming Services remain present afterward.

## Trade-offs and acceptance checks

Automatic servicing can cause downloads, restarts and game-session interruptions. Microsoft says Windows 11 automatically downloads and installs updates to provide security fixes, and recommends staying updated; it also describes restart scheduling and active hours as ways to manage interruptions ([Windows Update FAQ](https://support.microsoft.com/en-au/windows/deployment/updates-lifecycle/windows-update-faq)). This supports keeping security servicing available while giving users control over restart timing. A maintenance window should not block required security servicing.

For each supported build, record Windows Update history and pending-update state, Store package versions and an app update/install result, Xbox app and Gaming Services package state, and the result after reboot. Repeat with matched post-install and ISO-injection paths before claiming both are supported. No EclipseOS update-policy change should be accepted solely because Windows Update reports no pending updates.
