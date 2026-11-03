# ADR-001: Service Windows and Store before applying EclipseOS

- Status: proposed
- Date: 2026-11-03
- Decision owner: maintainer, through the orchestrator
- Scope: supported Windows 11 install and update paths

## Context

The maintainer's current compatibility constraint is to finish Windows Update and Microsoft Store updates, then reboot, before applying system changes. A Windows Update scan with no pending updates does not establish that Store servicing has completed. (`docs/eclipseos/README.md:34`)

In the two Hyper-V lanes, the post-install path reached Windows and Store fixed points before Atlas was applied; the ISO-injection path applied Atlas before servicing. Store/Xbox package versions and Gaming Services state differed afterward. The runs also differed in injection timing, first-boot work and a network-driver option, so they do not show that timing alone caused the outcome. (`docs/eclipseos/lab/comparison.md:9-11,24-30`; [comparison](../lab/comparison.md))

## Decision

Propose that EclipseOS apply system changes only after Windows Update and Microsoft Store reach a recorded fixed point and the machine reboots. Keep Store app updates enabled. Do not claim ISO-injection support until a matched test shows the same servicing and compatibility checks pass on that path. This proposal follows the maintainer's stated constraint and treats the current lab result as a compatibility signal, not causal proof. (`docs/eclipseos/design/windows-update.md:15-17,26,35`; [Windows Update design](../design/windows-update.md))

## Consequences

- Install and first-run take longer because servicing completes before system changes.
- The process must record separate Windows Update and Store readiness evidence.
- ISO injection remains unvalidated until it passes the matched comparison.
- The gate does not decide Xbox, Microsoft account or Game Pass sign-in support; those flows need separate decisions and tests.

## Acceptance checks

For every supported build and each claimed install path:

1. Record Windows Update history and pending-update state.
2. Record Store package versions and a successful app update or install.
3. Record Xbox app and Gaming Services package state and verify the required launch/update checks.
4. Reboot, repeat the checks, and retain the result with the install receipt.
5. For ISO injection, compare matched images and options, changing only servicing order, then verify the same checks pass.

The current lab run does not satisfy the matched-test requirement. This ADR remains proposed until the maintainer accepts it through the orchestrator.
