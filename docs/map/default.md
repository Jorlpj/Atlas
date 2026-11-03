# Default settings

`custom.yml` runs `atlas\default.yml` after services, components and AppX setup, then runs `revert.yml` and the tweak list. `default.yml` imports `Executables\DEFAULT.reg` and runs `DEFAULT.ps1`; the PowerShell action is marked `onUpgrade: true`. No option, build, edition or architecture filter is specified in this task. (`src/playbook/Configuration/custom.yml:74-81`; `src/playbook/Configuration/atlas/default.yml:1-15`)

## Actions

`DEFAULT.reg` seeds `HKLM\SOFTWARE\AtlasOS\Services\<name>` entries with a DWORD `state` and the corresponding `(default).cmd` path. The names cover interface settings, security, networking, background apps, power, Windows Spotlight, update notifications, Store app archiving and FSO/Game Bar. These state/path entries describe AtlasDesktop toggle metadata; the commands perform the settings changes. (`src/playbook/Executables/DEFAULT.reg:3-15`, `:21-27`, `:65-75`, `:197-215`)

`DEFAULT.ps1` relaunches elevated if needed, walks files recursively under `%windir%\AtlasDesktop`, and starts every filename matching `(default).cmd` with `/silent /noAction`, waiting for each one. The configuration does not gate this sweep by option or Windows build. (`src/playbook/Executables/DEFAULT.ps1:1-16`; `src/playbook/Configuration/atlas/default.yml:9-15`)

Examples of effects in that sweep:

- The Store App Archiving default writes `AllowAutomaticAppArchiving=0` under `HKLM\Software\Policies\Microsoft\Windows\Appx`. This is a Store/AppX policy change. (`src/playbook/Executables/AtlasDesktop/3. General Configuration/Store App Archiving/Disable Store App Archiving (default).cmd:17-26`)
- The Microsoft Store default registers the installed `Microsoft.WindowsStore` package for all users through its manifest. (`src/playbook/Executables/AtlasDesktop/6. Advanced Configuration/Microsoft Store/Enable Microsoft Store (default).cmd:17-25`)
- The FSO/Game Bar default changes per-user GameConfigStore and GameBar values, machine Game Bar activation/policy values, then calls `winget install 9NZKPSTSNW4P`. These are gaming-related settings and a package-install action; the file does not identify the package publisher or describe an Xbox AppX operation. (`src/playbook/Executables/AtlasDesktop/3. General Configuration/FSO and Game Bar/Enable FSO and Game Bar Support (default).cmd:17-45`)
- The Delivery Optimization default writes policy `DODownloadMode=0`; the Update Notifications default deletes three Windows Update notification values. (`src/playbook/Executables/AtlasDesktop/3. General Configuration/Delivery Optimization/Disable Delivery Optimization (default).cmd:17-24`; `src/playbook/Executables/AtlasDesktop/3. General Configuration/Update Notifications/Enable Update Notifications (default).cmd:17-26`)

The two values in `DEFAULT.reg` for `AutomaticUpdates` point to “Remove Idle Toggle in Desktop Context Menu,” while the separate `UpdateNotifications` entry points to the update-notification script. The registry file alone therefore does not show an automatic-updates change for that first entry. (`src/playbook/Executables/DEFAULT.reg:21-23`, `:197-199`)

## Restore and servicing scope

The configuration's `revert.yml` is marked `onUpgrade: true` but only deletes legacy Explorer `ThisPCPolicy` values; it contains no broad rollback for the defaults sweep. Individual AtlasDesktop scripts may offer a paired setting command, but this task does not save a system snapshot or invoke a matching inverse for each setting. (`src/playbook/Configuration/custom.yml:79-81`; `src/playbook/Configuration/atlas/revert.yml:1-36`; `src/playbook/Executables/DEFAULT.ps1:5-15`)

This area includes Store/AppX policy and package-registration operations, Windows Update notification and Delivery Optimization settings, and Game Bar/gaming configuration. The citations show the configured operations; they do not establish their runtime effect on Store, Xbox, Windows Update or AppX servicing. (`src/playbook/Executables/AtlasDesktop/3. General Configuration/Store App Archiving/Disable Store App Archiving (default).cmd:17-26`; `src/playbook/Executables/AtlasDesktop/6. Advanced Configuration/Microsoft Store/Enable Microsoft Store (default).cmd:20`; `src/playbook/Executables/AtlasDesktop/3. General Configuration/FSO and Game Bar/Enable FSO and Game Bar Support (default).cmd:17-45`; `src/playbook/Executables/AtlasDesktop/3. General Configuration/Delivery Optimization/Disable Delivery Optimization (default).cmd:17-24`; `src/playbook/Executables/AtlasDesktop/3. General Configuration/Update Notifications/Enable Update Notifications (default).cmd:17-26`)
