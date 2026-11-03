# Store, AppX and Xbox design

Status: proposed. This page sets the default for Store, AppX and Xbox compatibility; the maintainer must accept the
proposal through the orchestrator before it becomes an implementation requirement.

## Atlas today

Atlas schedules `appx.yml` after `components.yml` and before `default.yml` and `revert.yml`. The task is disabled on
upgrade and has no build, edition or architecture condition in its own declaration. It saves installed package
family names, removes a curated set of inbox apps, records deprovisioning keys for the removed families, then clears
three package caches. (`src/playbook/Configuration/custom.yml:74-80`; `src/playbook/Configuration/atlas/appx.yml:1-5,17-23,80-96`)

The curated removal list includes Xbox Console Companion (`Microsoft.XboxApp*`), annotated in the source as
deprecated. It does not list Microsoft Store or the current Xbox app (`Microsoft.GamingApp`). Snipping Tool removal
is an option selected by default in the GUI: its `CheckboxOption` has no `IsChecked="false"` override. Phone Link
is removed as both an installed and provisioned package. (`src/playbook/Configuration/atlas/appx.yml:37-43,62,71-78`;
`src/playbook/playbook.conf:116-121`)

The task's follow-on `revert.yml` does not restore removed packages or remove the deprovisioning keys. Its shown
actions delete Explorer folder-description registry values. Treat AppX removals as lasting changes unless a separate
reinstall path is demonstrated. (`src/playbook/Configuration/custom.yml:74-80`; `src/playbook/Configuration/atlas/revert.yml:1-36`)

## Lab evidence and limits

In the 26300.9457 to 26300.9711 Hyper-V runs, lane A applied the playbook after Windows Update and Store reached a
fixed point and retained the updated Store and Xbox packages. Its later Windows Update scan passed. Lane B used AME
ISO injection before servicing; Store and Xbox package versions stayed older, Gaming Services was absent, and an
Xbox update probe failed even after Windows Update reached the same build. The comparison does not isolate update
order: the injection method, first-boot path and one driver option differ. Neither lane tested account sign-in or
Game Pass. These observations support validating the whole servicing path; they do not identify the responsible
setting. ([lab comparison](../lab/comparison.md); [lane A](../lab/lane-a.md); [lane B](../lab/lane-b.md))

The maintainer's stated compatibility rule is to finish Windows Update and Store updates and reboot before applying
the playbook. EclipseOS uses a local passwordless account and does not require a Microsoft account. Acceptance tests cover free
Store installs and Gaming Services without Store sign-in. Xbox sign-in and Game Pass are outside the stated target;
test those flows only if the maintainer expands the target. They are also outside the current lab evidence. ([EclipseOS constraints](../README.md); [problem catalog A01](../research/problem-catalog.md))

## Proposed EclipseOS default

1. **Install post-setup only.** Require Windows Update and Store updates to reach a documented fixed point, then
   reboot before applying EclipseOS. Do not support AME ISO injection until a controlled, matched lab test shows
   Store and Xbox servicing remains healthy. The current two-lane result is a compatibility signal, not causal proof.
2. **Keep Store and Xbox package families.** Keep at least `WindowsStore`, `StorePurchaseApp`, `DesktopAppInstaller`,
   `VCLibs`, `UI.Xaml`, `XboxIdentityProvider`, `Xbox.TCUI`, `GamingApp` and `GamingServices` out of removal and
   deprovisioning rules. Keep the Xbox services and Store install/licensing services at Windows defaults until a
   controlled VM test supports a change. The protected-family set is a proposed guardrail to validate against clean
   installs and the current supported builds. ([problem catalog B05 and F04](../research/problem-catalog.md))
3. **Retain a narrow removable-app list.** Preserve Atlas's curated removals only after checking every package
   pattern against the protected-family list. Keep Snipping Tool removal an explicit option and consider unchecking
   it by default. A CI validator should fail on protected package names in either removal or deprovisioning actions.
4. **Make package state observable and recoverable.** Record package names and versions before and after application,
   report missing protected families, and document a supported reinstall or rollback procedure before expanding the
   removal list. The current Atlas revert file does not provide AppX restoration. (`src/playbook/Configuration/atlas/appx.yml:17-23,80-89`;
   `src/playbook/Configuration/atlas/revert.yml:1-36`)
5. **Test the actual account promise.** On each supported build, test free Store installs and Gaming Services under
   the local passwordless account, after WU and Store servicing. Record Store and Xbox package versions, deployment
   events, and launch results. Treat Xbox/MSA sign-in and Game Pass as unsupported until separately decided and
   tested.

The comparative survey of other playbooks recommends a protected-family validator and retaining Xbox components,
but its author marks most comparisons as untrusted until each source claim is re-verified. It is design input only;
do not reuse another playbook's code or treat the survey as compatibility evidence. ([APXB comparison and evidence
limits](../research/apbx-comparison.md))

## Trade-offs and open decisions

The preflight gate and protected package set limit background servicing failures and preserve Store installs and
Gaming Services. They also delay application, constrain debloating, and require compatibility checks as Windows
changes package families. Keeping services at Windows defaults may use more background resources than a tuned
profile. A maintainer decision is still needed on whether Xbox/MSA sign-in and Game Pass are supported; the current
local-account goal and lab scope do not establish that they work.

Before implementation, run a matched 26300 test that changes only update order or install method. Add an explicit
Store free-install test under the local account and capture package registration and deployment events. Compare
Store `AutoDownload` values separately; do not combine that experiment with package or service changes. (See
[lab comparison follow-up](../lab/comparison.md#follow-up-test) and [problem catalog B07](../research/problem-catalog.md).)
