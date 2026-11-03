# `playbook.conf`: supported builds, install gates, and setup choices

This page records the playbook metadata and choices declared in `src/playbook/playbook.conf`. The file names the install requirements and UI options; it does not define the implementation behind each requirement or option.

## Version and supported builds

The configuration identifies AtlasOS version `0.5.0`, title `Atlas v0.5.0`, and lists build `26100` under the `24H2` comment and build `26200` under `25H2`. It declares upgrades from `0.4.1`. (`src/playbook/playbook.conf:14-21`)

Build `26300` is not listed in this supported-build block. (`src/playbook/playbook.conf:15-20`)

## Install requirements

The declared requirements are `DefenderToggled`, `NoAntivirus`, `Internet`, `NoPendingUpdates`, `UCPDDisabled`, and `PluggedIn`. This file names those gates but does not describe how they are checked. (`src/playbook/playbook.conf:22-29`)

## Setup options

The required Defender radio page defaults to `defender-enable`; its other choice is `defender-disable`. The required mitigation radio page defaults to `mitigations-default`, with `mitigations-disable` as the other choice. (`src/playbook/playbook.conf:57-84`)

The required Windows Update radio page defaults to `auto-updates-disable`; the other choice is `auto-updates-default`. (`src/playbook/playbook.conf:85-98`)

Required checkboxes offer `disable-hibernation`, `disable-power-saving`, and `disable-core-isolation`; a separate required checkbox page offers `remove-snipping-tool`, `uninstall-edge`, and `install-another-browser`. The configuration says these selections can be changed in the Atlas folder later. (`src/playbook/playbook.conf:99-132`)

An additional checkbox offers `install-toolbox`. When `install-another-browser` is selected, a dependent radio-image page offers Brave, LibreWolf, Firefox, or Chrome. (`src/playbook/playbook.conf:133-174`)

## ISO and OOBE declarations

The ISO section sets `DisableBitLocker` and `DisableHardwareRequirements` to `true`. The OOBE section sets internet to `Force`. These are configuration values; this page does not infer their runtime effects. (`src/playbook/playbook.conf:40-55`)
