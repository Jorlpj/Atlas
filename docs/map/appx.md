# AppX package removals and cache clearing

`custom.yml` schedules this task in the main sequence after `components.yml` and before `default.yml` and `revert.yml`. (`src/playbook/Configuration/custom.yml:74-80`) The task declares `onUpgrade: false`; it has no build, edition, or architecture condition in this file. (`src/playbook/Configuration/atlas/appx.yml:1-5`)

## Package changes

The task first saves the current installed package family names to `%WINDIR%\AtlasModules\AtlasPackagesOld.txt`. It then requests removal by package-family pattern of legacy and optional apps, including Teams, Copilot, Clipchamp, Disney+, Spotify, Cortana, Xbox Console Companion, Mail and Calendar, Paint 3D, Tips, Films & TV, Family Safety, Mixed Reality Portal, Dev Home, Bing apps, Outlook, Get Help, 3D Viewer, Office Hub, Solitaire, Sticky Notes, OneNote, People, Power Automate, Skype, To Do, Alarms, Camera, Feedback Hub, Maps, Sound Recorder, and the English handwriting package. (`src/playbook/Configuration/atlas/appx.yml:17-70`)

The Snipping Tool package (`Microsoft.ScreenSketch*`) is removed only when option `remove-snipping-tool` is selected. The playbook configuration exposes that checkbox. (`src/playbook/Configuration/atlas/appx.yml:62`; `src/playbook/playbook.conf:120-123`)

For Phone Link, the task removes both the installed `Microsoft.YourPhone*` package and the provisioned `Microsoft.YourPhone` package. (`src/playbook/Configuration/atlas/appx.yml:71-78`)

## Reinstallation prevention and cache changes

The task compares the saved package family names with the remaining installed families, creates a key for each difference under `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned`, then deletes the temporary package list. This is the file's stated mechanism for preventing removed apps from being reinstalled. (`src/playbook/Configuration/atlas/appx.yml:17-23,80-89`)

It clears caches for `MicrosoftWindows.Client.CBS`, `Microsoft.Windows.Search`, and `Microsoft.Windows.SecHealthUI`. (`src/playbook/Configuration/atlas/appx.yml:91-96`)

## Store and Xbox scope; revert coverage

This file does not list Microsoft Store or the current `Microsoft.GamingApp` Xbox app for removal. Its Xbox package match is `Microsoft.XboxApp*`, annotated as the deprecated Xbox Console Companion. (`src/playbook/Configuration/atlas/appx.yml:37-43`) Store settings and Xbox-related tweaks elsewhere in the playbook are outside this task's scope.

`revert.yml` is scheduled after this task, but its actions delete Explorer folder-description registry values; it does not restore removed AppX packages, remove the deprovisioning keys created here, or recreate the deleted temporary package-family list. (`src/playbook/Configuration/custom.yml:74-80`; `src/playbook/Configuration/atlas/revert.yml:1-36`)
