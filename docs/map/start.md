# Initial configuration task

`Configuration/atlas/start.yml` runs after the root task has copied AtlasModules and AtlasDesktop into Windows, and after the initial cleanup and hidden Settings page task. Its position is in `Configuration/custom.yml`. (`src/playbook/Configuration/custom.yml:71-82`)

## Machine setup

The opening PowerShell action adds `%WINDIR%\AtlasModules`, its `Tools` folder, and its `Scripts` folder to the machine PATH. It reads the existing machine PATH, adds unique nonempty entries, then writes the joined result. The script checks that each target is a directory and emits an error for a missing directory; there is no build or option condition on this action. (`src/playbook/Configuration/atlas/start.yml:6-29`)

## Windows features and component store

The task enables the DirectPlay optional feature online with `/All` and `/NoRestart`. It removes the Steps Recorder capability only when `onUpgrade: false` permits it, then runs DISM component-store cleanup. These actions sit between the `NO LOCAL BUILD` comments and have no option or architecture condition in this file. (`src/playbook/Configuration/atlas/start.yml:31-39,95`)

## Utility installation

The unconditional elevated `SOFTWARE.ps1` action installs Visual C++ runtimes and legacy DirectX runtimes, and attempts NanaZip with a 7-Zip fallback. The script checks ARM64 to select the 7-Zip download architecture; NanaZip is installed as a provisioned AppX package when its release assets are available, otherwise the script falls back to 7-Zip. (`src/playbook/Configuration/atlas/start.yml:41-49`; `src/playbook/Executables/SOFTWARE.ps1:16,89-149,152-188,191-233`)

The optional `install-toolbox` action calls `SOFTWARE.ps1 -Toolbox`, which downloads and starts the Toolbox installer. (`src/playbook/Configuration/atlas/start.yml:51-59`; `src/playbook/Executables/SOFTWARE.ps1:24-36`)

## Optional browser installs

The browser radio choice gates one of four elevated installer calls: Brave, Firefox, LibreWolf, or Chrome. The configuration calls the matching script or switch; the scripts download and install the selected browser. LibreWolf's script also installs its updater, registers a scheduled task per enabled user, and creates desktop and Start Menu shortcuts. (`src/playbook/playbook.conf:141-170`; `src/playbook/Configuration/atlas/start.yml:61-93`; `src/playbook/Executables/SOFTWARE.ps1:39-65,68-91`; `src/playbook/Executables/LIBREWOLF.ps1:14-34,37-62`)

## Reversion and servicing scope

The Atlas revert task has an action list, but no matching reversal for the PATH additions, DirectPlay enablement, Steps Recorder capability removal, utilities, Toolbox, or browser installs was identified there. The map therefore records these as lacking a paired revert in that task, not as impossible to undo by other means. (`src/playbook/Configuration/atlas/revert.yml:6-22`; `src/playbook/Configuration/atlas/start.yml:6-93`)

The start task directly changes Windows optional-feature/capability and component-store state. NanaZip is the AppX-related action here: it uses `Add-AppxProvisionedPackage`; the file does not invoke Store or Xbox actions. (`src/playbook/Configuration/atlas/start.yml:33-39`; `src/playbook/Executables/SOFTWARE.ps1:175-182`)


