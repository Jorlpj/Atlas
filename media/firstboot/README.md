# EclipseOS first-boot servicing gate (`EclipseUpdate.psm1`)

Path A first-logon chain ([ADR-003](../../docs/eclipseos/decisions/003-two-delivery-paths-playbook-and-prepared-iso.md)):
Windows Update and the Microsoft Store are brought to a fixed point, with reboots, before any playbook action
([ADR-001](../../docs/eclipseos/decisions/001-post-install-servicing-gate.md)). This module services the system and
decides whether the playbook may run. It does not configure Windows Update or the Store: it pauses, defers or blocks
nothing and writes no policy value. The AME engine's own `NoPendingUpdates` check is not used (ADR-002).

The media tool (ATL-6) copies the module to `C:\EclipseOS\firstboot\EclipseUpdate.psm1`. The first-logon chain
(ATL-7) imports it elevated, as the local passwordless administrator, in Windows PowerShell 5.1 on 26300 amd64.
Importing runs nothing; only the four exported functions do work. The methods are the ones lab lane A proved
([lane A](../../docs/eclipseos/lab/lane-a.md), ATL-1 report).

All functions take `-LogPath` (default `C:\EclipseOS\logs\firstboot.log`) and append UTC timestamped lines
`<time> [<function>] <message>`. None throws on an expected failure: errors are fields of the result.

## Functions

| Function | Does | Returns |
|---|---|---|
| `Test-EclipsePendingReboot` | Read-only. Reasons: `CBS-RebootPending`, `WU-RebootRequired` (`Auto Update\RebootRequired`), `PendingFileRenameOperations` (or `...2`), `PendingComputerRename` (active name differs from the next name). A source that cannot be read adds `CheckError:<source>` and counts as pending. | `Pending` bool, `Reasons` string[], `Timestamp` |
| `Invoke-EclipseWindowsUpdateRound` | One online round with `Microsoft.Update.Session`: criteria `IsInstalled=0 and IsHidden=0`, drivers included as in lane A (`-SoftwareOnly` excludes them), `Online = $true`, EULAs accepted, download, install. Timeout per phase (`-SearchTimeoutMinutes` 30, `-DownloadTimeoutMinutes` 120, `-InstallTimeoutMinutes` 120); the COM calls run in a background runspace, and a phase over its timeout ends the wait with `TimedOut`. An empty search is `FoundCount = 0`, not an error. Does not reboot. | `Found`/`FoundCount` (+ `FoundSoftwareCount`, `FoundDriverCount`), `Installed`/`InstalledCount`, `Failed`/`FailedCount` (each `Title`, `Phase`, `ResultCode`, `HResult`), `RebootRequired`, `SearchSucceeded`, `SearchResultCode`, `TimedOut`, `TimedOutPhase`, `Error`, `ErrorHResult`, `ErrorPhase` |
| `Invoke-EclipseStoreUpdate` | Rounds of: `MDM_EnterpriseModernAppManagement_AppManagement01.UpdateScanMethod` (CIM `root\cimv2\mdm\dmmap`, device-wide, so all users), then `winget upgrade --all --source msstore` (lane A's second method; `-SkipWinget` or no `winget.exe` = MDM only), then wait `-SettleSeconds` (240) and fingerprint every all-users package full name. Stable when, from round `-MinRounds` (2), the fingerprint equals the previous round's. If Gaming Services or the Xbox app is still absent when stable, it is installed once with `winget install --source msstore` (lane A: Store updates alone did not bring Gaming Services; `-SkipMissingInstall` turns this off) and the rounds continue. `-MaxRounds` (8) or `-TimeoutMinutes` (60) ends with `Stable = $false`. Writes its result to `-StatePath` (`C:\EclipseOS\logs\store-last.json`). | `Stable`, `StopReason` (`Stable`, `MaxRounds`, `Timeout`, `Error`), `Rounds`, `RoundDetails`, `Before`/`After` (Version, Status) for `Microsoft.WindowsStore`, `StorePurchaseApp`, `DesktopAppInstaller`, `GamingApp`, `GamingServices`, `XboxIdentityProvider`, `Xbox.TCUI`, `Changed`, `Missing`, `Installs` |
| `Test-EclipseUpdateGate` | PASS only if all five checks pass: `Network` (a connection is available), `WindowsUpdate` (a fresh online search succeeds with ResultCode 2, no error or timeout, and finds 0 software updates; drivers are listed, not counted), `Reboot` (nothing pending), `Store` (`-StoreResult` or the `-StoreStatePath` JSON has `Stable = true`), `Packages` (`Microsoft.WindowsStore`, `Microsoft.DesktopAppInstaller`, `Microsoft.GamingServices` present). Fail closed: an error, timeout, offline state, missing Store result or missing family is FAIL. Searches only, installs nothing. Appends the result to the JSON array at `-GateLogPath` (`C:\EclipseOS\logs\gate.json`). | `Pass`, `Status` (`PASS`/`FAIL`), `FailedChecks`, `Checks`, `Build`, `Timestamp` |

## How ATL-7 must loop

The chain runs at every logon until the gate passes or the round budget is spent. It keeps its round counter in a
file (for example `C:\EclipseOS\logs\chain-state.json`), because every reboot restarts it.

```
import C:\EclipseOS\firstboot\EclipseUpdate.psm1
rounds = read counter (0 if none)
loop:
    if rounds >= MaxServicingRounds (suggested 8): stop, record FAIL, do NOT run the playbook, tell the user
    rounds += 1, save the counter
    if (Test-EclipsePendingReboot).Pending: reboot, continue at the next logon
    wu = Invoke-EclipseWindowsUpdateRound
    if wu.RebootRequired or (Test-EclipsePendingReboot).Pending: reboot, continue at the next logon
    if not wu.SearchSucceeded or wu.TimedOut or wu.FoundCount > wu.InstalledCount: go to loop (another WU round)
    store = Invoke-EclipseStoreUpdate
    if (Test-EclipsePendingReboot).Pending: reboot, continue at the next logon
    gate = Test-EclipseUpdateGate -StoreResult store
    if gate.Pass: reboot once (ADR-001: reboot after servicing), then on the next logon run
                  Test-EclipseUpdateGate again and start the playbook only if it passes
    else: go to loop
```

Rules for the chain:

- Only `Test-EclipseUpdateGate` decides. A WU round with `FoundCount = 0` is not proof of readiness; nor is a
  Store result alone.
- Never weaken a gate check to escape the loop. When the budget is spent, stop and leave the system serviced
  but un-debloated; the logs (`firstboot.log`, `gate.json`, `store-last.json`) say why.
- A reboot reason that never clears (for example a `PendingFileRenameOperations` entry another program keeps
  renewing) ends at the round budget; it must not be ignored.
- A timed-out WU phase leaves its worker running inside the chain's process; exiting or rebooting stops it. The
  next round and the gate's own online search show the real state.
- The chain must keep the network up; offline is always FAIL.

## Tests

`tests/Test-EclipseUpdate.Static.ps1` is static: it parses the module with the PowerShell AST and never imports
or calls it. It checks the parse, that the top level holds only constants, function definitions and
`Export-ModuleMember` (nothing runs at import), the four exported names, `[CmdletBinding()]`, comment-based help
and `-LogPath` on each, ASCII-only content, no registry, service, task or restart command, no WU or Store policy
name, the online search and the criteria. It runs PSScriptAnalyzer when installed and skips it otherwise.

```
powershell.exe -NoProfile -File media/firstboot/tests/Test-EclipseUpdate.Static.ps1
```

Behaviour is tested only inside an `eclipse-lab-*` Hyper-V guest (ATL-8), never on a live system.
