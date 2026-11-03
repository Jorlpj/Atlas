# Privacy and telemetry

Status: proposed design. Atlas mapping below describes its current configuration; the EclipseOS defaults are recommendations for the maintainer to accept or revise.

## Current Atlas behavior

Atlas runs its privacy group without an option or build gate. The group sets app permission defaults, disables several activity, speech, usage and diagnostic features, and blocks adding Microsoft accounts as Windows user accounts. It also disables cloud search and search suggestions. The exact effects and source files are mapped in [the privacy tweak page](../../map/tweaks-privacy.md), including the account policy and search settings (`src/playbook/Configuration/tweaks.yml:71-131`; `src/playbook/Configuration/tweaks/privacy/disallow-ms-accounts.yml:1-9`; `src/playbook/Configuration/tweaks/privacy/search-settings.yml:1-84`).

Atlas disables Office and NVIDIA telemetry for the current user, disables settings sync, and turns off advertising ID and sync-provider notifications (`src/playbook/Configuration/tweaks/privacy/apps/disable-office-telemetry.yml:1-22`; `src/playbook/Configuration/tweaks/privacy/apps/disable-nvidia-telemetry.yml:1-9`; `src/playbook/Configuration/tweaks/privacy/cloud/disable-setting-sync.yml:1-61`; `src/playbook/Configuration/tweaks/privacy/advertising/disable-advertising-info.yml:1-15`; `src/playbook/Configuration/tweaks/privacy/advertising/disable-sync-provider-notifs.yml:1-9`). Its telemetry subgroup stops DiagTrack, writes diagnostic data and event-transcript settings, disables a WMI autologger, and deletes matching ETL logs (`src/playbook/Configuration/tweaks/privacy/telemetry/disallow-data-collection.yml:1-57`).

The matching Atlas `revert.yml` only removes named legacy Explorer values; it does not restore these privacy settings or recover deleted logs (`src/playbook/Configuration/atlas/revert.yml:1-36`). That is a concrete reversibility gap for EclipseOS to address.

## Lab evidence and limits

The 26300 lab comparison reports Store, Xbox, update, security and resource observations for two install sequences. It does not isolate privacy settings or measure diagnostic-data behavior, so it cannot establish that any of the privacy changes affect Store, Xbox, anti-cheat, Windows Update or performance (`../lab/comparison.md`, “What the comparison supports” and “Follow-up test”). Keep those effects as unverified until a matched test changes the privacy profile alone.

## Proposed EclipseOS default

- Minimize optional advertising, app usage, activity upload, tailored experiences, input personalization, and vendor telemetry when Windows or the application exposes a supported opt-out. Keep each setting independently selectable and document its effect.
- Keep Windows security, servicing, Store and Xbox components intact. Do not block Microsoft-account sign-in globally: EclipseOS creates a local Windows account, while Store account sign-in remains optional. Do not imply Xbox or Game Pass sign-in is supported; those flows are outside the current target. The Atlas policy that blocks adding Microsoft accounts as Windows accounts should not silently become an EclipseOS default (`src/playbook/Configuration/tweaks/privacy/disallow-ms-accounts.yml:1-9`).
- Make cloud search, settings sync, online speech, location, and app permissions clear opt-in choices. Explain that disabling them reduces the corresponding online or cross-device feature.
- Do not delete diagnostic logs as a privacy default. Prefer supported collection controls and a bounded retention policy, preserving logs users or support staff may need to diagnose update, Store, driver, or anti-cheat failures. Atlas currently deletes matching ETL files in its collection task (`src/playbook/Configuration/tweaks/privacy/telemetry/disallow-data-collection.yml:42-57`).
- Make every privacy change visible and reversible: record the original value and scope (machine or user), provide a per-setting restore, and verify restore after upgrade. Do not treat Atlas's narrow upgrade cleanup as privacy rollback (`src/playbook/Configuration/atlas/revert.yml:1-36`).

Trade-off: this profile collects less optional personalization and application telemetry while retaining account sign-in and diagnostic evidence that can help resolve compatibility problems. It does not promise zero telemetry; document what Windows and each opted-in application still collect, based on verified vendor documentation before release.

## Acceptance checks before adopting the proposal

1. On a clean 26300 image, compare each setting's effective value and user-visible behavior with the privacy profile enabled and disabled; cover the proposed local Windows account (its administrator or standard-user role remains undecided) and a separate optional Store sign-in.
2. Verify Windows Update scans and installs, Store app update/install, Xbox app launch and Gaming Services presence, and anti-cheat launch with the default profile. Treat Xbox or Game Pass sign-in as out of scope unless the maintainer explicitly expands the target; if expanded, test and report those flows separately. Capture servicing and application logs without attributing an outcome to privacy unless a controlled comparison supports it.
3. Restore each changed setting, sign out or reboot where required, and confirm its prior value and behavior return. Confirm diagnostic logs are not removed by the default profile.
4. Review vendor documentation for every claimed collection opt-out and describe the residual collection and feature trade-off in the settings UI.
