# Services and drivers

`services.yml` is marked `onUpgrade: false`; its actions include a Windows service and driver backup, file sharing, location and indexing changes, then explicit service startup changes. The backup is written to `%windir%\AtlasModules\Other\winServices.reg`. (`src/playbook/Configuration/atlas/services.yml:1-19`)

## Actions applied by the configuration

The playbook runs the file sharing, location and minimal indexing scripts with elevated privileges and waits for each to finish. These calls do not show a build, edition, architecture or setup-option condition. (`src/playbook/Configuration/atlas/services.yml:25-44`)

The service actions set startup value `4` for `OneSyncSvc`, `TrkWks`, `PcaSvc`, `DiagTrack`, `diagnosticshub.standardcollector.service`, `WerSvc`, `wercplsupport` and `UCPD`. The comments group the first four as “OK to disable,” the next two as “Do not disable,” and the final two as “No guidance”; these are labels in the configuration. (`src/playbook/Configuration/atlas/services.yml:50-64`)

The driver actions set startup value `4` for `GpuEnergyDrv`, `NetBT` and `Telemetry`. The adjacent comment says NetBIOS support can be enabled with the file sharing script. (`src/playbook/Configuration/atlas/services.yml:66-75`)

### Related script effects

`DisableFileSharing.ps1` disables four network adapter bindings, sets NetBIOS over TCP/IP off for matching interfaces, disables the `NetBT` service, sets network profiles to Public, disables File and Printer Sharing and Network Discovery firewall rules for Private profiles, and imports two Explorer UI registry files. (`src/playbook/Executables/AtlasModules/Scripts/ScriptWrappers/DisableFileSharing.ps1:7-33`) The related `EnableFileSharing.ps1` enables the adapter bindings, launches the Network Discovery service enable script, and sets `NetBT` to system start; it also offers interactive profile, firewall and Explorer choices. (`src/playbook/Executables/AtlasModules/Scripts/ScriptWrappers/EnableFileSharing.ps1:3-9`, `:11-46`)

`Disable Location (default).cmd` records its state and path under `HKLM\SOFTWARE\AtlasOS\Services\Location`, disables `lfsvc` and `MapsBroker`, writes Find My Device and location consent policy values, stops the two services, and hides the related settings pages. (`src/playbook/Executables/AtlasDesktop/3. General Configuration/Location/Disable Location (default).cmd:1-40`)

`Minimal Search Indexing (default).cmd` records its state and path under `HKLM\SOFTWARE\AtlasOS\Services\Indexing`, stops indexing, clears policies, includes Start Menu programs and the AtlasDesktop folder, excludes user folders, sets `RespectPowerModes=1`, restarts indexing and resets `SetupCompletedSuccessfully=0`. (`src/playbook/Executables/AtlasDesktop/3. General Configuration/Search Indexing/Minimal Search Indexing (default).cmd:1-34`)

## Restore paths and scope limits

The configuration captures the Windows service and driver defaults before making its listed changes. (`src/playbook/Configuration/atlas/services.yml:14-19`) The Atlas troubleshooting script runs each `(default)` script under `AtlasDesktop\6. Advanced Configuration\Services`; if both the Windows and Atlas service backup files exist, it offers to import either backup. It says a restart is required to apply changes. (`src/playbook/Executables/AtlasDesktop/9. Troubleshooting/Set services to defaults.cmd:23-54`, `:37-41`) The toolbox copy has the same restore flow. (`src/playbook/Executables/AtlasModules/Toolbox/Scripts/setServicesToDefaults.cmd:23-54`)

The enumerated `(default)` scripts cover Superfetch, Printing, NVIDIA Display Container, Network Discovery, Bluetooth and Lanman Workstation (SMB). (`src/playbook/Executables/AtlasDesktop/6. Advanced Configuration/Services/Superfetch/Enable SuperFetch (default).cmd:1-6`, `src/playbook/Executables/AtlasDesktop/6. Advanced Configuration/Services/Printing/Enable Printing (default).cmd:1-6`, `src/playbook/Executables/AtlasDesktop/6. Advanced Configuration/Services/NVIDIA Display Container/Enable NVIDIA Display Container LS (default).cmd:1-6`, `src/playbook/Executables/AtlasDesktop/6. Advanced Configuration/Services/Network Discovery/Enable Network Discovery Services (default).cmd:1-6`, `src/playbook/Executables/AtlasDesktop/6. Advanced Configuration/Services/Bluetooth/Enable Bluetooth (default).cmd:1-6`, `src/playbook/Executables/AtlasDesktop/6. Advanced Configuration/Services/Lanman Workstation (SMB)/Enable Lanman Workstation (default).cmd:1-6`) The generic service restore utility does not itself show a matching default UI script for every service in `services.yml`. The separate `revert.yml` is marked `onUpgrade: true` and deletes legacy Explorer folder-description values; it contains no service restore action. (`src/playbook/Configuration/atlas/revert.yml:1-36`)

`UCPD` is explicitly assigned startup value `4` here, so this is a Windows Update/Store-adjacent system area to consider in compatibility work. This map records the configured operation and does not establish its runtime effect on Store, Xbox or AppX servicing. (`src/playbook/Configuration/atlas/services.yml:62-64`)

