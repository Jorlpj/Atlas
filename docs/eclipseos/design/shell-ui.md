# Shell and UI design

Status: proposed. The maintainer must accept this default through the orchestrator before it becomes an implementation requirement.

## Atlas today

Atlas applies a broad QoL set that changes Start, taskbar, Explorer, context menus, personalization and shell behavior. Examples include Start behavior and recommendations, theme values, taskbar pins and visibility controls, Explorer defaults and context-menu entries, and shell options such as AutoRun and Nearby Sharing. The Explorer `disable-folders-this-pc` call is commented out; ARM64 has a separate cleanup that deletes matching Open-Shell files under AtlasDesktop. ([Atlas map: QoL](../../map/tweaks-qol.md); [Atlas map: misc](../../map/tweaks-misc.md))

Several changes write registry settings or create shell associations, and the upgrade revert does not restore the QoL settings. AtlasDesktop also supplies user-launched interface toggles and links into Windows Settings; those controls have different effects and reversibility, so their labels alone do not establish a complete undo path. ([Atlas map: QoL](../../map/tweaks-qol.md); [Atlas map: AtlasDesktop](../../map/atlasdesktop.md); [Atlas map: revert](../../map/revert.md))

Atlas has separate Store update and app archival controls in QoL. They change Store update or archival behavior without removing Store or Xbox packages. Keep these servicing controls documented and tested with the Windows Update design; do not treat their settings as shell appearance choices. ([Atlas map: QoL](../../map/tweaks-qol.md))

The two 26300 lab lanes record Store, Xbox, update, package and service observations, but do not compare shell configuration or measure UI responsiveness. The lane comparison therefore provides no evidence that Atlas's shell changes caused or fixed the Store/Xbox differences, or that any specific UI tweak improves gaming performance. ([lab comparison](../lab/comparison.md); [lab method](../lab/method.md))

## Proposed EclipseOS default

1. **Keep the supported Windows shell.** Do not replace Start, taskbar, Explorer, notification surfaces or shell brokers by default. Keep the shipped shell components available so Windows features and updates retain their expected surfaces.
2. **Use a small, readable default profile.** Choose a consistent theme, show file extensions, and use straightforward Start and taskbar settings. Keep recommendations and cloud-fed content off where the choice is supported, while preserving user control over pins, search and accessibility. Do not silently remove Settings pages or shell features to make the interface look simpler.
3. **Make appearance choices separate from servicing and privacy controls.** A theme or taskbar preference should not disable Store app updates, Windows Update, notifications, Defender, account features or AppX packages. Put each such control in its own named setting with its user-visible effect and support boundary.
4. **Preserve gaming and capture surfaces.** Keep Game Bar, Game DVR, overlays, notification handling and game-related shell protocols at Windows defaults unless a reproducible compatibility test supports an opt-in change. Atlas's mapped performance Game Bar task is commented out; a separate AtlasDesktop control changes FSO/Game Bar values, so these should not be conflated. ([Atlas map: performance](../../map/tweaks-performance.md); [Atlas map: AtlasDesktop](../../map/atlasdesktop.md))
5. **Keep each optional change reversible.** Before changing a setting, record its original value and scope (per-user or machine). Provide a matching restore action, including for pins, context-menu registrations, feature visibility and shell policies. Confirm restoration after sign-out and reboot; do not use a generic “Windows defaults” command as proof that a user's previous state was restored.
6. **Support the documented account and accessibility constraints.** Test the shell under the passwordless local account, and verify keyboard navigation, high contrast, scaling, input methods, notifications and assistive technology before accepting a visual change. Keep accessibility controls visible and available.

## Trade-offs and acceptance checks

A restrained shell profile may leave some suggestions, background content or user interface elements that a more aggressive debloat would remove. Keeping Windows components and user choices available costs some simplicity and may retain background activity, but it avoids making unsupported assumptions about shell dependencies.

For each supported build, compare stock Windows with the proposed profile under the documented local-account setup. Verify Start search and pins, taskbar and notification behavior, Explorer navigation and file associations, context menus, accessibility paths, Game Bar and capture behavior, Store app launch and update, Xbox app and Gaming Services launch, and Windows Update. Repeat after cumulative updates and after restoring every optional UI setting. Record the changed values and task/package state, and measure any claimed responsiveness improvement with a matched workload rather than inferring it from fewer visible controls.
