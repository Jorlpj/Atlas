# Remaining APBX matrix question marks: verification 1

Verified by atl-lib-2 on 2026-11-03 for `SRC-GRADE-1`. This pass resolves three SynergyOS 1.7 metadata cells and the three repeated Atlas ISO-bypass cells in the [matrix](apbx-matrix.md). It inventories the remaining unknowns for the next source pass. Findings describe published source declarations, not successful playbook execution or measured Windows state.

## Cells resolved

| Playbook | Matrix area | Verified value | Primary source | Admiralty grade |
|---|---|---|---|---|
| SynergyOS tag 1.7 (conf 1.7.0) | Supported builds | 19044, 19045, 22000, 22621, 22631, 22635, 26100, 26200 and 26300 | [playbook.conf at tag 1.7, Version/SupportedBuilds/requirements](https://github.com/Synergy-Tweaks/SynergyOS/blob/1.7/playbook.conf#L9-L49) | A1 |
| SynergyOS tag 1.7 (conf 1.7.0) | Install method | `SupportsISO=true`; post-install path is also present | [playbook.conf at tag 1.7](https://github.com/Synergy-Tweaks/SynergyOS/blob/1.7/playbook.conf#L34-L49); source-scoped release identification in [V2](apbx/verify-2.md#synergyos-version-conflict) | A1 |
| SynergyOS tag 1.7 (conf 1.7.0) | Account/password requirement | `PasswordSet` is a declared requirement. This does not establish the wizard's account behavior beyond the prerequisite. | [playbook.conf at tag 1.7](https://github.com/Synergy-Tweaks/SynergyOS/blob/1.7/playbook.conf#L24-L38) | A1 |
| AtlasOS 0.5.0 | Secure Boot/TPM bypass (repeated in three matrix sections) | `SupportsISO=true` and `DisableHardwareRequirements=true`. This is an installer hardware-check bypass declaration, not evidence of live Secure Boot/TPM state. | `src/playbook/playbook.conf:40-55` | A1 |

The V2 source audit already supplies source-scoped values for SynergyOS tag 1.7's Store-service startup pins, WebView2-related actions, SmartScreen/SAC/MOTW, ISO hardware-check bypass, hosts-file actions and backup/checkpoint instructions. Those rows remain documented in [V2](apbx/verify-2.md#cell-results) with their original citations and grades.

## Remaining unknowns

The matrix now counts 28 question-bearing cells. These 23 SynergyOS cells still carry 1.8 survey wording or a question mark because V2 did not verify those behaviors against tag 1.7:

| Matrix section | SynergyOS tag-1.7 cells awaiting source verification |
|---|---|
| A2: servicing and apps | Windows Update; Store auto-update; Store kept/removed; Xbox apps and identity; Gaming Services; Game Bar; Edge |
| B2: security | Defender; Tamper Protection; UAC; VBS/HVCI; CPU mitigations |
| C2: performance and system | Services disabled; scheduled tasks; telemetry/privacy; power plan/hibernation; timer/latency tweaks; network tweaks; AppX removal scope |
| D2: project | Revert path; bundled binaries; license; 26H2-specific fixes |

Five more cells remain unresolved:

| Playbook | Matrix area | Why the question mark remains |
|---|---|---|
| Privacy+ / AME 11 0.8.3 | Gaming Services | No 0.8.3 release tag was available to inspect; the 0.8.2 audit cannot establish 0.8.3 behavior. See [V1](apbx/verify-1.md#cell-results), A1 for the release lookup and A6 for the requested-release behavior. |
| Privacy+ / AME 11 0.8.3 | Secure Boot/TPM bypass | Same release-tag limit; 0.8.2's ISO setting cannot be carried forward to 0.8.3. See [V1](apbx/verify-1.md#cell-results), A1/A6. |
| Privacy+ / AME 11 0.8.3 | Hosts-file blocks | Same release-tag limit; the bounded 0.8.2 text audit cannot establish 0.8.3 behavior. See [V1](apbx/verify-1.md#cell-results), A1/B2/A6. |
| GamerzOS tag 0.2 | WebView2 | Local source has an InstallWebView path, but the default path fetches an unpinned external EdgeRemover script; its release-time contents and effect are unknown. See [V3](apbx/verify-3.md#cell-results), A1. |
| GamerzOS tag 0.2 | Tamper Protection | The source declares a DefenderToggled prerequisite, but the bounded text audit found no explicit TamperProtection write or restoration. Final state remains unknown. See [V3](apbx/verify-3.md#cell-results), A1 for the requirement and B2 for bounded absence. |

The SynergyOS items need a separate tag-1.7 source pass before the old 1.8 survey values can be used in the matrix. The Privacy+ cells need a published 0.8.3 source; the GamerzOS cells remain bounded by an unpinned external dependency and absent state-setting instructions. No inference from the newer main branch, another release, a binary, or live Windows state fills these gaps.
