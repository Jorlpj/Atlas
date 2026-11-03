# Top-level playbook task list

`custom.yml` is the root task sequence. It has no build, edition, architecture, or setup-option condition on the root action list; individual child tasks can have their own conditions. (`src/playbook/Configuration/custom.yml:4-5`, `:74-81`)

## Setup and file handling

The root loads `C:\Users\Default\NTUSER.DAT` into `HKU\AME_UserHive_Default` when `oobe` is false, then later unloads that hive under the same condition. (`src/playbook/Configuration/custom.yml:6-9`, `:99-103`)

On upgrades, it calls `STOPFOLDERPROC.ps1` as the elevated current user, then removes `%windir%\AtlasDesktop` and `%windir%\AtlasModules` when `oobe` is false. The helper stops processes and scheduled tasks rooted under those folders before deletion. (`src/playbook/Configuration/custom.yml:11-25`; `src/playbook/Executables/STOPFOLDERPROC.ps1:16-17`, `:45-46`, `:112-113`)

The root copies the `AtlasModules` and `AtlasDesktop` source folders into `%windir%`, silently launches the bundled Process Explorer uninstaller, and copies theme files into `%windir%\Resources\Themes`. A missing source folder or copy failure exits nonzero and halts the task sequence. (`src/playbook/Configuration/custom.yml:28-44`)

## Configuration order

It runs `DISABLENOTIFS.cmd` elevated, kills Explorer and ShellExperienceHost, then starts Explorer again. The notification script writes notification and privacy registry values, hides notification Settings pages, disables Notification Center, and disables notification services. (`src/playbook/Configuration/custom.yml:46-54`; `src/playbook/Executables/DISABLENOTIFS.cmd:3-23`)

Next it runs PowerShell NGEN and PowerShell configuration tasks, then the hidden Settings page task. The latter writes `SettingsPageVisibility` with separate page lists for builds below 22000 and builds at or above 22000. (`src/playbook/Configuration/custom.yml:56-60`, `:70-72`; `src/playbook/Configuration/tweaks/scripts/script-ngen.yml:1-7`; `src/playbook/Configuration/tweaks/qol/config-powershell.yml:1-13`; `src/playbook/Configuration/tweaks/qol/set-hidden-settings-pages.yml:1-21`)

The cleanup step runs elevated. `CLEANUP.ps1` configures Disk Cleanup and starts it only when it finds no other Windows installation on another filesystem drive; it also clears user and system temporary folders and deletes all system restore points. (`src/playbook/Configuration/custom.yml:62-68`; `src/playbook/Executables/CLEANUP.ps1:4-46`, `:48-62`, `:66-102`, `:104`)

The main sequence then invokes `atlas/start.yml`, `services.yml`, `components.yml`, `appx.yml`, `default.yml`, `revert.yml`, followed by `tweaks.yml`, in that order. This root file establishes the order, while the child configurations define their changes and conditions; see the corresponding map pages for the detailed actions. (`src/playbook/Configuration/custom.yml:74-81`)

After those tasks, `APPLYDUHIVE.ps1` copies applicable HKCU values from tweak configuration paths into the loaded default-user hive. `SETPATHS.ps1` repairs stored script paths below `HKLM\SOFTWARE\AtlasOS\Services` to point into `%windir%\AtlasDesktop`. Finally, the root writes PowerShell's `ExecutionPolicy` to `RemoteSigned` (`REG_SZ`) under HKLM. (`src/playbook/Configuration/custom.yml:83-112`; `src/playbook/Executables/APPLYDUHIVE.ps1:1-37`; `src/playbook/Executables/SETPATHS.ps1:8-20`; `src/playbook/Configuration/custom.yml:105-112`)

## Revert and servicing scope

This file has no matching top-level revert sequence for its folder deletion/copy, notification changes, cleanup, hive-copy, or PowerShell policy actions; it only invokes `atlas/revert.yml` as one of the child tasks. (Inspection of `src/playbook/Configuration/custom.yml:6-112`; `src/playbook/Configuration/atlas/revert.yml:1-36`)

The root delegates AppX package work to `atlas/appx.yml`, so its task sequence includes Store/Xbox-sensitive package changes as detailed in the AppX map. It does not itself specify Windows Update or AppX servicing operations. (`src/playbook/Configuration/custom.yml:74-81`; `src/playbook/Configuration/atlas/appx.yml:1-20`)

