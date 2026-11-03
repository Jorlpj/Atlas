# Account model design

Status: proposed. The maintainer must accept this default through the orchestrator before implementation.

## Requirements

The EclipseOS constraint is one device-local Windows account with no password and no Microsoft account connected to Windows. Store and Xbox packages must remain available, but the acceptance target is free Store installs and Gaming Services without signing in; Xbox and Game Pass sign-in are outside the stated target. Keep this requirement separate from Store app authentication: Microsoft documents local accounts as device-specific and independent of cloud services, and Windows OOBE can create either a local or Microsoft account. Neither source establishes that every Store install works without signing into Store, so that remains a test requirement. ([EclipseOS constraints](../README.md); [Microsoft: Change from a local account to a Microsoft account](https://support.microsoft.com/en-us/accounts-billing/manage/change-from-a-local-account-to-a-microsoft-account-in-windows); [Microsoft: Customize the OOBE](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/customize-oobe-in-windows-11))

## Atlas today

Atlas's called `CLIENTCBS.ps1` tweak hides the Microsoft account Settings page on supported detected Windows builds. It does not create a local account or set its password. The root task loads the default-user hive for configuration, which is not the same as creating or changing an account. (`src/playbook/Configuration/tweaks/scripts/script-clientcbs.yml:1-8`; `src/playbook/Executables/CLIENTCBS.ps1:9-17,39-83`; [Atlas map: script tweaks](../../map/tweaks-scripts.md); [Atlas map: top-level task list](../../map/custom.md))

## Lab evidence and limits

Both lanes used a local passwordless account as the intended model, but the lab did not test Microsoft account, Xbox, or Game Pass sign-in. In lane B, the test harness could not use PowerShell Direct with the empty-password account, so that lane used a lab-only password deviation. This is a test-access limitation, not evidence that the product account must have a password. The runs also differ in install method and other conditions, so they do not prove account state caused the Store/Xbox differences. ([lab method](../lab/method.md); [lab comparison](../lab/comparison.md); [lane A](../lab/lane-a.md))

## External evidence and boundaries

Microsoft describes a local account as device-specific and not requiring internet connectivity for Windows sign-in; it recommends a Microsoft account for integration and security features, and warns that a forgotten local-account password may not be recoverable without a reset disk. Windows OOBE includes local or Microsoft account creation, while exact screens can vary and networking is required to complete OOBE on Home SKUs. These facts support offering the local-account path while documenting setup variation and recovery consequences; they do not establish a supported, unattended blank-password provisioning method for every supported SKU. ([Microsoft: Change from a local account to a Microsoft account](https://support.microsoft.com/en-us/accounts-billing/manage/change-from-a-local-account-to-a-microsoft-account-in-windows); [Microsoft: Customize the OOBE](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/customize-oobe-in-windows-11))

Microsoft Store purchase sign-in settings apply to purchases, and Microsoft's Windows sign-in guidance treats Windows credentials separately from account access to services. Do not infer from those pages that free Store installs or Gaming Services work without Store sign-in. Test that promise directly on each supported build after the required Windows and Store servicing gate. ([Microsoft: Change purchase sign-in settings for Microsoft Store](https://support.microsoft.com/en-us/accounts-billing/change-purchase-sign-in-settings-for-microsoft-store-on-windows); [Microsoft: User account access in Windows](https://support.microsoft.com/en-us/accounts-billing/security/user-account-access-in-windows))

## Proposed EclipseOS default

1. **Keep Windows sign-in local.** Create the user through a documented, supported setup path and do not convert the Windows sign-in to an MSA. Make setup behavior explicit for Home and Pro; OOBE screens and network requirements can differ. Do not copy another playbook's account script without an independent source review and clean-install validation.
2. **Meet the passwordless requirement transparently.** The proposed profile has no password on its local Windows account. Explain that anyone with physical access may reach that session, and that forgotten-password recovery for a local account is limited. Do not silently set a shared password, enable an MSA, suppress UAC, or weaken unrelated sign-in protections to make automation easier. Offer an explicit recovery/security note before the user selects this profile.
3. **Keep Store identity optional and separate.** Do not require or silently add an MSA for Windows setup. Check whether a free Store install and Gaming Services provisioning work with no Store sign-in. If Windows requests an identity for a particular app or purchase, show that requirement as an app-level limitation; do not bind it to the Windows account without a separate decision.
4. **Keep Xbox scope accurate.** Preserve Store and Xbox package families as described in [Store, AppX and Xbox design](store-appx-xbox.md), but do not claim Xbox account sign-in or Game Pass compatibility. Those flows remain unsupported by the stated requirement and untested by the lab.
5. **Do not hide account recovery controls as a substitute for policy.** Atlas hides the Microsoft account Settings page through a feature-velocity task; EclipseOS should not hide account controls by default. A user must be able to inspect the local account, choose recovery methods, and understand the boundary between Windows sign-in and optional app sign-in.

## Acceptance checks

On each supported Windows build and clean-install path, record the SKU, OOBE route, network state, account type, whether the local password is blank, and whether a Microsoft account was connected to Windows. Reboot and verify that the same local account can reach the desktop without a password. Verify UAC remains enabled and that no shared credential or hidden account was introduced.

After Windows Update and Microsoft Store updates reach the required fixed point and the device reboots, test Store launch, a free app install and update, and Gaming Services presence with no Store sign-in. Save package state and deployment events. Confirm that setup and these checks do not require an MSA; separately record any app-specific prompt. Do not count Xbox sign-in, purchases, or Game Pass as passed unless the maintainer changes the scope and those flows are tested. Repeat on Home and Pro where supported. The current lab does not satisfy these account and Store-authentication checks. ([EclipseOS constraints](../README.md); [lab comparison follow-up](../lab/comparison.md#follow-up-test))

## Trade-off and open decision

A blank-password local account preserves the stated privacy and setup constraint but sacrifices protection at the local sign-in screen and may complicate unattended lab access and account recovery. A password or PIN would change the maintainer's stated requirement and needs an explicit decision. The account's role (administrator or standard user) also needs a maintainer decision before implementation; this page does not assume a role or authorize automation that changes it.
