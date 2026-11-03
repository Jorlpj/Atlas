# Revert legacy Explorer values

`revert.yml` runs with `TrustedInstaller` privileges and is marked `onUpgrade: true`. The file defines no option, build, edition or architecture condition. `custom.yml` lists it after `default.yml` and before the tweak list. (`src/playbook/Configuration/atlas/revert.yml:1-6`; `src/playbook/Configuration/custom.yml:74-81`)

## Registry changes

The action deletes the `ThisPCPolicy` value from the `PropertyBag` key for seven folder-description IDs. Each ID is handled under both `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions` and its `HKLM\SOFTWARE\Wow6432Node\...` counterpart. (`src/playbook/Configuration/atlas/revert.yml:10-36`)

The file does not name the folders represented by those IDs or set replacement values. It contains no service, driver, scheduled task, file, AppX package or Windows policy restore action. (`src/playbook/Configuration/atlas/revert.yml:1-36`)

## Restore and servicing scope

This is a targeted deletion of Explorer values, not a general inverse for the other Atlas configuration tasks. For example, the separate services page records service and driver startup changes; this file contains no corresponding service restore. (`src/playbook/Configuration/atlas/revert.yml:1-36`; `src/playbook/Configuration/atlas/services.yml:50-75`)

No Store, Xbox, Windows Update or AppX servicing operation is declared in this file. That describes the configured actions only; it does not establish runtime effects of other tasks. (`src/playbook/Configuration/atlas/revert.yml:1-36`)
