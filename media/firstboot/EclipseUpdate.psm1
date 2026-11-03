# EclipseUpdate.psm1 - Windows Update and Microsoft Store servicing gate for the EclipseOS first-logon chain.
#
# Contract: media/firstboot/README.md. Copied by the media tool to C:\EclipseOS\firstboot\EclipseUpdate.psm1 and
# imported by the first-logon chain (ATL-7). Target: Windows PowerShell 5.1, elevated, local administrator, 26300 amd64.
#
# This module SERVICES the system: it searches, downloads and installs Windows updates and triggers Store app
# updates. It never pauses, defers or blocks Windows Update, and it writes no Windows Update or Store policy value.
# Importing the module runs nothing: only constants and function definitions live at the top level.
#
# Methods reused from lab lane A (ATL-1, docs/eclipseos/lab/lane-a.md): WU COM API with the criteria
# 'IsInstalled=0 and IsHidden=0' (drivers included), Store rounds of MDM UpdateScanMethod plus
# 'winget upgrade --all --source msstore' until package versions are unchanged, and
# 'winget install --source msstore' for Gaming Services, which Store updates alone did not deliver.

$script:DefaultLogPath = 'C:\EclipseOS\logs\firstboot.log'
$script:DefaultGateLogPath = 'C:\EclipseOS\logs\gate.json'
$script:DefaultStoreStatePath = 'C:\EclipseOS\logs\store-last.json'
$script:DefaultCriteria = 'IsInstalled=0 and IsHidden=0'

# Families whose versions Invoke-EclipseStoreUpdate reports before and after.
$script:ProtectedFamilies = @(
    'Microsoft.WindowsStore',
    'Microsoft.StorePurchaseApp',
    'Microsoft.DesktopAppInstaller',
    'Microsoft.GamingApp',
    'Microsoft.GamingServices',
    'Microsoft.XboxIdentityProvider',
    'Microsoft.Xbox.TCUI'
)

# Families that must be present for Test-EclipseUpdateGate to PASS.
$script:GateRequiredFamilies = @(
    'Microsoft.WindowsStore',
    'Microsoft.DesktopAppInstaller',
    'Microsoft.GamingServices'
)

# Store product IDs that lane A installed with 'winget install --source msstore' (eclipse-checks.ps1 -InstallApps).
$script:StoreInstallIds = @{
    'Microsoft.GamingServices' = '9MWPM2CQNLHN'
    'Microsoft.GamingApp'      = '9MV0B5HZVK9Z'
}

# ---------------------------------------------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------------------------------------------

function Write-EclipseLog {
    <#
    .SYNOPSIS
    Appends one timestamped line to the module log (private).
    .DESCRIPTION
    Writes "<UTC ISO time> [<Source>] <Message>" as UTF-8 without BOM, creating the folder if needed. Never throws:
    a log failure is reported on the verbose stream only.
    .PARAMETER Message
    Text of the line.
    .PARAMETER Source
    Name of the calling function.
    .PARAMETER LogPath
    Log file path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Message,
        [string]$Source = 'EclipseUpdate',
        [string]$LogPath = $script:DefaultLogPath
    )
    $line = '{0} [{1}] {2}' -f [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'), $Source, $Message
    Write-Verbose $line
    if (-not $LogPath) { return }
    try {
        $dir = Split-Path -Path $LogPath -Parent
        if ($dir -and -not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
        [System.IO.File]::AppendAllText($LogPath, $line + "`r`n", (New-Object System.Text.UTF8Encoding $false))
    } catch {
        Write-Verbose ('log write failed: {0}' -f $_.Exception.Message)
    }
}

function Write-EclipseJsonFile {
    <#
    .SYNOPSIS
    Writes an object as JSON (UTF-8 without BOM) to a file (private).
    .PARAMETER InputObject
    Object to serialize.
    .PARAMETER Path
    Target file; the folder is created if needed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()][object]$InputObject,
        [Parameter(Mandatory = $true)][string]$Path
    )
    $dir = Split-Path -Path $Path -Parent
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
    $json = ConvertTo-Json -InputObject $InputObject -Depth 8
    [System.IO.File]::WriteAllText($Path, $json, (New-Object System.Text.UTF8Encoding $false))
}

function Get-EclipseHResult {
    <#
    .SYNOPSIS
    Returns the HResult of an exception as 0xXXXXXXXX, unwrapping PowerShell wrappers (private).
    .PARAMETER Exception
    The caught exception.
    #>
    [CmdletBinding()]
    param([System.Exception]$Exception)
    $e = $Exception
    while ($e -and $e.InnerException -and ($e -is [System.Management.Automation.MethodInvocationException] -or
            $e -is [System.Management.Automation.RuntimeException])) {
        $e = $e.InnerException
    }
    if (-not $e) { return $null }
    return ('0x{0:X8}' -f $e.HResult)
}

function Invoke-EclipseWuJob {
    <#
    .SYNOPSIS
    Runs one Windows Update search (and optionally download and install) in a background runspace with a timeout
    per phase (private).
    .DESCRIPTION
    The WU COM calls are synchronous, so they run in a separate runspace while this function watches the current
    phase and its start time. A phase that exceeds its timeout ends the wait: the result has TimedOut = $true and
    TimedOutPhase set, and the runspace is asked to stop and left to finish on its own.
    The search is always online (IUpdateSearcher.Online = $true); an offline search is never used.
    .PARAMETER Criteria
    WU search criteria.
    .PARAMETER SearchOnly
    Search only; do not download or install.
    .PARAMETER SearchTimeoutMinutes
    Timeout of the search phase.
    .PARAMETER DownloadTimeoutMinutes
    Timeout of the download phase.
    .PARAMETER InstallTimeoutMinutes
    Timeout of the install phase.
    .PARAMETER ClientApplicationId
    IUpdateSession.ClientApplicationID, shown in the WU log.
    .PARAMETER Source
    Name of the calling function, for the log.
    .PARAMETER LogPath
    Log file path.
    #>
    [CmdletBinding()]
    param(
        [string]$Criteria = $script:DefaultCriteria,
        [switch]$SearchOnly,
        [int]$SearchTimeoutMinutes = 30,
        [int]$DownloadTimeoutMinutes = 120,
        [int]$InstallTimeoutMinutes = 120,
        [string]$ClientApplicationId = 'EclipseOS',
        [string]$Source = 'Invoke-EclipseWuJob',
        [string]$LogPath = $script:DefaultLogPath
    )

    $worker = {
        param($State, $Criteria, $AppId, $SearchOnly)
        function Set-Phase([string]$Name) { $State.PhaseStart = [DateTime]::UtcNow; $State.Phase = $Name }
        function Get-HR($Err) {
            $e = $Err.Exception
            while ($e.InnerException) { $e = $e.InnerException }
            return ('0x{0:X8}' -f $e.HResult)
        }
        try {
            Set-Phase 'Search'
            $session = New-Object -ComObject Microsoft.Update.Session
            $session.ClientApplicationID = $AppId
            $searcher = $session.CreateUpdateSearcher()
            $searcher.Online = $true
            $State.ServerSelection = [int]$searcher.ServerSelection
            $sr = $searcher.Search($Criteria)
            $State.SearchResultCode = [int]$sr.ResultCode
            $found = New-Object System.Collections.ArrayList
            for ($i = 0; $i -lt $sr.Updates.Count; $i++) {
                $u = $sr.Updates.Item($i)
                $type = 'Software'
                if ([int]$u.Type -eq 2) { $type = 'Driver' }
                [void]$found.Add([pscustomobject]@{
                        Title    = [string]$u.Title
                        KB       = (@($u.KBArticleIDs) -join ',')
                        Type     = $type
                        UpdateId = [string]$u.Identity.UpdateID
                    })
            }
            $State.Found = $found.ToArray()
            if ($SearchOnly -or $sr.Updates.Count -eq 0) { Set-Phase 'Done'; return }

            $coll = New-Object -ComObject Microsoft.Update.UpdateColl
            for ($i = 0; $i -lt $sr.Updates.Count; $i++) {
                $u = $sr.Updates.Item($i)
                if (-not $u.EulaAccepted) { $u.AcceptEula() }
                [void]$coll.Add($u)
            }

            Set-Phase 'Download'
            $downloader = $session.CreateUpdateDownloader()
            $downloader.Updates = $coll
            $dr = $downloader.Download()
            $State.DownloadResultCode = [int]$dr.ResultCode
            $failed = New-Object System.Collections.ArrayList
            $toInstall = New-Object -ComObject Microsoft.Update.UpdateColl
            for ($i = 0; $i -lt $coll.Count; $i++) {
                $u = $coll.Item($i)
                $r = $dr.GetUpdateResult($i)
                if ($u.IsDownloaded) {
                    [void]$toInstall.Add($u)
                } else {
                    [void]$failed.Add([pscustomobject]@{
                            Title = [string]$u.Title; Phase = 'Download'; ResultCode = [int]$r.ResultCode
                            HResult = ('0x{0:X8}' -f $r.HResult)
                        })
                }
            }

            $installed = New-Object System.Collections.ArrayList
            if ($toInstall.Count -gt 0) {
                Set-Phase 'Install'
                $installer = $session.CreateUpdateInstaller()
                $installer.Updates = $toInstall
                $ir = $installer.Install()
                $State.InstallResultCode = [int]$ir.ResultCode
                $State.RebootRequired = [bool]$ir.RebootRequired
                for ($i = 0; $i -lt $toInstall.Count; $i++) {
                    $u = $toInstall.Item($i)
                    $r = $ir.GetUpdateResult($i)
                    $entry = [pscustomobject]@{
                        Title = [string]$u.Title; Phase = 'Install'; ResultCode = [int]$r.ResultCode
                        HResult = ('0x{0:X8}' -f $r.HResult)
                    }
                    if ([int]$r.ResultCode -eq 2 -or [int]$r.ResultCode -eq 3) {
                        [void]$installed.Add($entry)
                        if ($r.RebootRequired) { $State.RebootRequired = $true }
                    } else {
                        [void]$failed.Add($entry)
                    }
                }
            }
            $State.Installed = $installed.ToArray()
            $State.Failed = $failed.ToArray()
            Set-Phase 'Done'
        } catch {
            $State.Error = [string]$_.Exception.Message
            $State.ErrorHResult = Get-HR $_
            $State.ErrorPhase = [string]$State.Phase
            Set-Phase 'Done'
        }
    }

    $state = [hashtable]::Synchronized(@{
            Phase = 'Start'; PhaseStart = [DateTime]::UtcNow; ServerSelection = $null
            SearchResultCode = $null; DownloadResultCode = $null; InstallResultCode = $null
            Found = @(); Installed = @(); Failed = @(); RebootRequired = $false
            Error = $null; ErrorHResult = $null; ErrorPhase = $null
        })
    $timeouts = @{ Start = $SearchTimeoutMinutes; Search = $SearchTimeoutMinutes; Download = $DownloadTimeoutMinutes; Install = $InstallTimeoutMinutes }
    $started = [DateTime]::UtcNow
    $timedOutPhase = $null
    $rs = $null
    $ps = $null
    try {
        $rs = [runspacefactory]::CreateRunspace()
        $rs.Open()
        $ps = [powershell]::Create()
        $ps.Runspace = $rs
        [void]$ps.AddScript($worker.ToString()).AddArgument($state).AddArgument($Criteria).AddArgument($ClientApplicationId).AddArgument([bool]$SearchOnly)
        $handle = $ps.BeginInvoke()
        $lastPhase = ''
        while (-not $handle.IsCompleted) {
            $phase = [string]$state.Phase
            if ($phase -ne $lastPhase) {
                Write-EclipseLog -Source $Source -LogPath $LogPath -Message ('WU phase {0}' -f $phase)
                $lastPhase = $phase
            }
            if ($timeouts.ContainsKey($phase) -and
                ([DateTime]::UtcNow - [DateTime]$state.PhaseStart).TotalMinutes -gt $timeouts[$phase]) {
                $timedOutPhase = $phase
                break
            }
            Start-Sleep -Seconds 5
        }
        if ($timedOutPhase) {
            Write-EclipseLog -Source $Source -LogPath $LogPath -Message ('WU phase {0} timed out after {1} min; worker left to finish' -f $timedOutPhase, $timeouts[$timedOutPhase])
            try { [void]$ps.BeginStop($null, $null) } catch { Write-Verbose $_.Exception.Message }
        } else {
            try { [void]$ps.EndInvoke($handle) } catch { if (-not $state.Error) { $state.Error = [string]$_.Exception.Message; $state.ErrorHResult = Get-EclipseHResult $_.Exception } }
            $ps.Dispose(); $ps = $null
            $rs.Dispose(); $rs = $null
        }
    } catch {
        $state.Error = [string]$_.Exception.Message
        $state.ErrorHResult = Get-EclipseHResult $_.Exception
        $state.ErrorPhase = [string]$state.Phase
    }

    $found = @($state.Found)
    $software = @($found | Where-Object { $_.Type -eq 'Software' })
    $drivers = @($found | Where-Object { $_.Type -eq 'Driver' })
    # The search itself completed with orcSucceeded (2); later download/install errors do not change this.
    $searchSucceeded = ($state.SearchResultCode -eq 2) -and ($state.ErrorPhase -ne 'Search')
    return [pscustomobject]@{
        Criteria           = $Criteria
        Online             = $true
        ServerSelection    = $state.ServerSelection
        SearchResultCode   = $state.SearchResultCode
        SearchSucceeded    = [bool]$searchSucceeded
        Found              = $found
        FoundCount         = $found.Count
        FoundSoftwareCount = $software.Count
        FoundDriverCount   = $drivers.Count
        DownloadResultCode = $state.DownloadResultCode
        InstallResultCode  = $state.InstallResultCode
        Installed          = @($state.Installed)
        Failed             = @($state.Failed)
        RebootRequired     = [bool]$state.RebootRequired
        TimedOut           = [bool]$timedOutPhase
        TimedOutPhase      = $timedOutPhase
        Error              = $state.Error
        ErrorHResult       = $state.ErrorHResult
        ErrorPhase         = $state.ErrorPhase
        DurationSeconds    = [int]([DateTime]::UtcNow - $started).TotalSeconds
    }
}

function Get-EclipsePackageVersion {
    <#
    .SYNOPSIS
    Returns the highest installed version (all users) of each named package family, or 'absent' (private).
    .PARAMETER Name
    Package names (Get-AppxPackage -Name).
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string[]]$Name)
    $out = [ordered]@{}
    foreach ($n in $Name) {
        $p = @(Get-AppxPackage -AllUsers -Name $n -ErrorAction Stop | Sort-Object -Property { [version]$_.Version } -Descending)
        if ($p.Count -gt 0) {
            $out[$n] = [pscustomobject]@{ Version = [string]$p[0].Version; Status = [string]$p[0].Status }
        } else {
            $out[$n] = [pscustomobject]@{ Version = 'absent'; Status = $null }
        }
    }
    return $out
}

function Get-EclipsePackageFingerprint {
    <#
    .SYNOPSIS
    Returns the sorted, de-duplicated list of all-users package full names, used to see whether versions changed
    (private).
    #>
    [CmdletBinding()]
    param()
    $names = @(Get-AppxPackage -AllUsers -ErrorAction Stop | ForEach-Object { [string]$_.PackageFullName } | Sort-Object -Unique)
    return ($names -join '|')
}

function Find-EclipseWinget {
    <#
    .SYNOPSIS
    Returns the path of the newest x64 winget.exe under WindowsApps, or $null (private; same lookup as lane A).
    #>
    [CmdletBinding()]
    param()
    $w = Get-ChildItem -Path "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe" -ErrorAction SilentlyContinue |
        Sort-Object -Property FullName -Descending | Select-Object -First 1
    if ($w) { return $w.FullName }
    return $null
}

function Invoke-EclipseProcess {
    <#
    .SYNOPSIS
    Runs an executable hidden with a timeout and returns exit code and output tail (private).
    .PARAMETER FilePath
    Executable.
    .PARAMETER ArgumentList
    Arguments, as one string.
    .PARAMETER TimeoutMinutes
    The process is killed after this many minutes.
    .PARAMETER WorkPath
    Folder for the redirected output files.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string]$ArgumentList,
        [int]$TimeoutMinutes = 20,
        [string]$WorkPath = $env:TEMP
    )
    $tag = [guid]::NewGuid().ToString('N')
    $outFile = Join-Path $WorkPath ('eclipse-{0}.out' -f $tag)
    $errFile = Join-Path $WorkPath ('eclipse-{0}.err' -f $tag)
    $exit = $null
    $timedOut = $false
    $tail = @()
    try {
        $p = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput $outFile -RedirectStandardError $errFile -ErrorAction Stop
        $null = $p.Handle
        if ($p.WaitForExit($TimeoutMinutes * 60000)) {
            $exit = $p.ExitCode
        } else {
            $timedOut = $true
            try { $p.Kill() } catch { Write-Verbose $_.Exception.Message }
        }
        $lines = @()
        foreach ($f in @($outFile, $errFile)) {
            if (Test-Path -LiteralPath $f) { $lines += @(Get-Content -LiteralPath $f -ErrorAction SilentlyContinue) }
        }
        $tail = @($lines | ForEach-Object { "$_".Trim() } | Where-Object { $_ -and $_ -notmatch '^[-\\|/]$' } | Select-Object -Last 5)
    } finally {
        foreach ($f in @($outFile, $errFile)) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }
    }
    return [pscustomobject]@{ ExitCode = $exit; TimedOut = $timedOut; Tail = $tail }
}

# ---------------------------------------------------------------------------------------------------------------
# Public functions
# ---------------------------------------------------------------------------------------------------------------

function Test-EclipsePendingReboot {
    <#
    .SYNOPSIS
    Reports whether Windows has a reboot pending, and why.
    .DESCRIPTION
    Read-only. Checks four sources:
      CBS-RebootPending         HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending
      WU-RebootRequired         HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired
      PendingFileRenameOperations  HKLM\SYSTEM\CurrentControlSet\Control\Session Manager (value or ...2, non-empty)
      PendingComputerRename     ActiveComputerName differs from ComputerName
    A source that cannot be read adds 'CheckError:<source>' and counts as pending (fail closed).
    .PARAMETER LogPath
    Log file for timestamped lines. Default C:\EclipseOS\logs\firstboot.log.
    .OUTPUTS
    PSCustomObject: Pending [bool], Reasons [string[]], Timestamp [string, UTC].
    .EXAMPLE
    if ((Test-EclipsePendingReboot).Pending) { Restart-Computer }
    #>
    [CmdletBinding()]
    param(
        [string]$LogPath = $script:DefaultLogPath
    )
    $src = 'Test-EclipsePendingReboot'
    $reasons = New-Object System.Collections.ArrayList

    try {
        if (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
            [void]$reasons.Add('CBS-RebootPending')
        }
    } catch { [void]$reasons.Add('CheckError:CBS-RebootPending') }

    try {
        if (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') {
            [void]$reasons.Add('WU-RebootRequired')
        }
    } catch { [void]$reasons.Add('CheckError:WU-RebootRequired') }

    try {
        $sm = Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -ErrorAction Stop
        $pending = $false
        foreach ($v in @('PendingFileRenameOperations', 'PendingFileRenameOperations2')) {
            $prop = $sm.PSObject.Properties[$v]
            if ($prop -and @($prop.Value | Where-Object { $_ }).Count -gt 0) { $pending = $true }
        }
        if ($pending) { [void]$reasons.Add('PendingFileRenameOperations') }
    } catch { [void]$reasons.Add('CheckError:PendingFileRenameOperations') }

    try {
        $active = (Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' -Name ComputerName -ErrorAction Stop).ComputerName
        $next = (Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' -Name ComputerName -ErrorAction Stop).ComputerName
        if ($active -ne $next) { [void]$reasons.Add('PendingComputerRename') }
    } catch { [void]$reasons.Add('CheckError:PendingComputerRename') }

    $result = [pscustomobject]@{
        Pending   = ($reasons.Count -gt 0)
        Reasons   = [string[]]$reasons.ToArray()
        Timestamp = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    }
    Write-EclipseLog -Source $src -LogPath $LogPath -Message ('Pending={0} Reasons={1}' -f $result.Pending, ($result.Reasons -join ','))
    return $result
}

function Invoke-EclipseWindowsUpdateRound {
    <#
    .SYNOPSIS
    Runs one online Windows Update round: search, accept EULAs, download, install.
    .DESCRIPTION
    Uses the Microsoft.Update.Session COM API with the criteria 'IsInstalled=0 and IsHidden=0'. Drivers are
    included, as in lab lane A; -SoftwareOnly adds "and Type='Software'". The search is online
    (IUpdateSearcher.Online = $true) against the default server selection. Each phase (search, download, install)
    has its own timeout. An empty result is not an error: the round returns FoundCount = 0. Errors are returned in
    the result (Error, ErrorHResult, ErrorPhase), never thrown. The function does not reboot; the caller checks
    RebootRequired and Test-EclipsePendingReboot.
    .PARAMETER SoftwareOnly
    Exclude driver updates from the round.
    .PARAMETER SearchTimeoutMinutes
    Timeout of the search phase. Default 30.
    .PARAMETER DownloadTimeoutMinutes
    Timeout of the download phase. Default 120.
    .PARAMETER InstallTimeoutMinutes
    Timeout of the install phase. Default 120.
    .PARAMETER LogPath
    Log file for timestamped lines. Default C:\EclipseOS\logs\firstboot.log.
    .OUTPUTS
    PSCustomObject: Found, FoundCount, FoundSoftwareCount, FoundDriverCount, Installed, InstalledCount, Failed
    (Title, Phase, ResultCode, HResult), FailedCount, RebootRequired, SearchSucceeded, SearchResultCode, TimedOut,
    TimedOutPhase, Error, ErrorHResult, ErrorPhase, Criteria, Online, ServerSelection, Timestamp, DurationSeconds.
    .EXAMPLE
    $r = Invoke-EclipseWindowsUpdateRound
    if ($r.RebootRequired -or (Test-EclipsePendingReboot).Pending) { Restart-Computer }
    #>
    [CmdletBinding()]
    param(
        [switch]$SoftwareOnly,
        [ValidateRange(1, 1440)][int]$SearchTimeoutMinutes = 30,
        [ValidateRange(1, 1440)][int]$DownloadTimeoutMinutes = 120,
        [ValidateRange(1, 1440)][int]$InstallTimeoutMinutes = 120,
        [string]$LogPath = $script:DefaultLogPath
    )
    $src = 'Invoke-EclipseWindowsUpdateRound'
    $criteria = $script:DefaultCriteria
    if ($SoftwareOnly) { $criteria = $criteria + " and Type='Software'" }
    $stamp = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    Write-EclipseLog -Source $src -LogPath $LogPath -Message ('round start, criteria: {0}' -f $criteria)

    $job = Invoke-EclipseWuJob -Criteria $criteria -SearchTimeoutMinutes $SearchTimeoutMinutes `
        -DownloadTimeoutMinutes $DownloadTimeoutMinutes -InstallTimeoutMinutes $InstallTimeoutMinutes `
        -Source $src -LogPath $LogPath

    foreach ($u in $job.Found) { Write-EclipseLog -Source $src -LogPath $LogPath -Message ('found [{0}] {1}' -f $u.Type, $u.Title) }
    foreach ($u in $job.Installed) { Write-EclipseLog -Source $src -LogPath $LogPath -Message ('installed rc={0} hr={1} {2}' -f $u.ResultCode, $u.HResult, $u.Title) }
    foreach ($u in $job.Failed) { Write-EclipseLog -Source $src -LogPath $LogPath -Message ('FAILED {0} rc={1} hr={2} {3}' -f $u.Phase, $u.ResultCode, $u.HResult, $u.Title) }
    if ($job.Error) { Write-EclipseLog -Source $src -LogPath $LogPath -Message ('ERROR in {0}: {1} hr={2}' -f $job.ErrorPhase, $job.Error, $job.ErrorHResult) }

    $result = [pscustomobject]@{
        Timestamp          = $stamp
        Criteria           = $job.Criteria
        Online             = $job.Online
        ServerSelection    = $job.ServerSelection
        SearchSucceeded    = $job.SearchSucceeded
        SearchResultCode   = $job.SearchResultCode
        Found              = $job.Found
        FoundCount         = $job.FoundCount
        FoundSoftwareCount = $job.FoundSoftwareCount
        FoundDriverCount   = $job.FoundDriverCount
        Installed          = $job.Installed
        InstalledCount     = @($job.Installed).Count
        Failed             = $job.Failed
        FailedCount        = @($job.Failed).Count
        RebootRequired     = $job.RebootRequired
        TimedOut           = $job.TimedOut
        TimedOutPhase      = $job.TimedOutPhase
        Error              = $job.Error
        ErrorHResult       = $job.ErrorHResult
        ErrorPhase         = $job.ErrorPhase
        DurationSeconds    = $job.DurationSeconds
    }
    Write-EclipseLog -Source $src -LogPath $LogPath -Message ('round end: searchOk={0} found={1} installed={2} failed={3} reboot={4} timedOut={5}' -f `
            $result.SearchSucceeded, $result.FoundCount, $result.InstalledCount, $result.FailedCount, $result.RebootRequired, $result.TimedOutPhase)
    return $result
}

function Invoke-EclipseStoreUpdate {
    <#
    .SYNOPSIS
    Triggers Microsoft Store app updates and waits until package versions stop changing.
    .DESCRIPTION
    Each round, as in lab lane A:
      1. MDM_EnterpriseModernAppManagement_AppManagement01.UpdateScanMethod (CIM root\cimv2\mdm\dmmap), which
         scans and updates Store apps for the device (all users);
      2. 'winget upgrade --all --source msstore' (lane A's second method; skipped with -SkipWinget or if winget.exe
         is not found);
      3. wait SettleSeconds, then fingerprint all all-users package full names.
    The run is Stable when, from round MinRounds on, the fingerprint equals the previous round's. If a protected
    family with a known Store ID (Gaming Services, Xbox app) is still absent when stable, it is installed once with
    'winget install --source msstore' (lab lane A method; skip with -SkipMissingInstall) and the rounds go on until
    stable again. MaxRounds or TimeoutMinutes ends the run with Stable = $false.
    The result is returned and written to StatePath, where Test-EclipseUpdateGate reads it. Errors are recorded,
    not thrown. No Store or Windows Update policy value is written.
    .PARAMETER MaxRounds
    Maximum number of rounds. Default 8.
    .PARAMETER MinRounds
    First round at which an unchanged fingerprint counts as stable. Default 2.
    .PARAMETER SettleSeconds
    Wait after the triggers of each round before the fingerprint. Default 240 (lane A rounds took about 5 min).
    .PARAMETER TimeoutMinutes
    Overall timeout. Default 60.
    .PARAMETER WingetTimeoutMinutes
    Timeout of each winget call. Default 20.
    .PARAMETER SkipWinget
    Use only the MDM scan.
    .PARAMETER SkipMissingInstall
    Do not install absent protected families.
    .PARAMETER StatePath
    JSON file that receives the result. Default C:\EclipseOS\logs\store-last.json.
    .PARAMETER LogPath
    Log file for timestamped lines. Default C:\EclipseOS\logs\firstboot.log.
    .OUTPUTS
    PSCustomObject: Stable, StopReason, Rounds, RoundDetails, Before, After (family -> Version, Status), Changed,
    Missing, Installs, Error, Timestamp, DurationSeconds.
    .EXAMPLE
    $s = Invoke-EclipseStoreUpdate
    $s.Before.'Microsoft.WindowsStore'.Version; $s.After.'Microsoft.WindowsStore'.Version
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(1, 50)][int]$MaxRounds = 8,
        [ValidateRange(1, 50)][int]$MinRounds = 2,
        [ValidateRange(0, 3600)][int]$SettleSeconds = 240,
        [ValidateRange(1, 1440)][int]$TimeoutMinutes = 60,
        [ValidateRange(1, 240)][int]$WingetTimeoutMinutes = 20,
        [switch]$SkipWinget,
        [switch]$SkipMissingInstall,
        [string]$StatePath = $script:DefaultStoreStatePath,
        [string]$LogPath = $script:DefaultLogPath
    )
    $src = 'Invoke-EclipseStoreUpdate'
    $started = [DateTime]::UtcNow
    $deadline = $started.AddMinutes($TimeoutMinutes)
    $stamp = $started.ToString('yyyy-MM-ddTHH:mm:ssZ')
    $rounds = New-Object System.Collections.ArrayList
    $installs = New-Object System.Collections.ArrayList
    $installTried = $false
    $stable = $false
    $stopReason = 'MaxRounds'
    $topError = $null
    $before = $null
    $after = $null
    $workPath = $env:TEMP
    if ($LogPath) { $workPath = Split-Path -Path $LogPath -Parent }
    if (-not $workPath) { $workPath = $env:TEMP }

    try {
        $before = Get-EclipsePackageVersion -Name $script:ProtectedFamilies
        foreach ($k in $before.Keys) { Write-EclipseLog -Source $src -LogPath $LogPath -Message ('before {0}={1}' -f $k, $before[$k].Version) }
        $winget = $null
        if (-not $SkipWinget) {
            $winget = Find-EclipseWinget
            Write-EclipseLog -Source $src -LogPath $LogPath -Message ('winget: {0}' -f $(if ($winget) { $winget } else { 'not found, MDM only' }))
        }
        $previous = $null

        for ($n = 1; $n -le $MaxRounds; $n++) {
            if ([DateTime]::UtcNow -gt $deadline) { $stopReason = 'Timeout'; break }
            $round = [ordered]@{ Round = $n; Start = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'); Mdm = $null; Winget = $null; Changed = $null; Error = $null }

            try {
                $c = Get-CimInstance -Namespace 'root\cimv2\mdm\dmmap' -ClassName 'MDM_EnterpriseModernAppManagement_AppManagement01' -ErrorAction Stop
                $r = Invoke-CimMethod -InputObject $c -MethodName UpdateScanMethod -ErrorAction Stop
                $round.Mdm = [pscustomobject]@{ ReturnValue = $r.ReturnValue; Error = $null }
            } catch {
                $round.Mdm = [pscustomobject]@{ ReturnValue = $null; Error = ('{0} hr={1}' -f $_.Exception.Message, (Get-EclipseHResult $_.Exception)) }
            }
            Write-EclipseLog -Source $src -LogPath $LogPath -Message ('round {0} MDM UpdateScanMethod rv={1} err={2}' -f $n, $round.Mdm.ReturnValue, $round.Mdm.Error)

            if ($winget) {
                try {
                    [void](Invoke-EclipseProcess -FilePath $winget -ArgumentList 'source update' -TimeoutMinutes $WingetTimeoutMinutes -WorkPath $workPath)
                    $w = Invoke-EclipseProcess -FilePath $winget -WorkPath $workPath -TimeoutMinutes $WingetTimeoutMinutes `
                        -ArgumentList 'upgrade --all --source msstore --accept-package-agreements --accept-source-agreements --silent --disable-interactivity'
                    $round.Winget = $w
                    Write-EclipseLog -Source $src -LogPath $LogPath -Message ('round {0} winget upgrade exit={1} timedOut={2} :: {3}' -f $n, $w.ExitCode, $w.TimedOut, ($w.Tail -join ' | '))
                } catch {
                    $round.Winget = [pscustomobject]@{ ExitCode = $null; TimedOut = $false; Tail = @([string]$_.Exception.Message) }
                    Write-EclipseLog -Source $src -LogPath $LogPath -Message ('round {0} winget error: {1}' -f $n, $_.Exception.Message)
                }
            }

            $wait = [Math]::Min($SettleSeconds, [Math]::Max(0, [int]($deadline - [DateTime]::UtcNow).TotalSeconds))
            if ($wait -gt 0) { Start-Sleep -Seconds $wait }

            try {
                $fp = Get-EclipsePackageFingerprint
            } catch {
                $fp = $null
                $round.Error = 'fingerprint: ' + $_.Exception.Message
            }
            $round.Changed = -not ($fp -and $previous -and ($fp -eq $previous))
            [void]$rounds.Add([pscustomobject]$round)
            Write-EclipseLog -Source $src -LogPath $LogPath -Message ('round {0} packages changed since previous round: {1}' -f $n, $round.Changed)

            if ($fp -and -not $round.Changed -and $n -ge $MinRounds) {
                $current = Get-EclipsePackageVersion -Name $script:ProtectedFamilies
                $missing = @($script:StoreInstallIds.Keys | Where-Object { $current[$_].Version -eq 'absent' } | Sort-Object)
                if ($missing.Count -gt 0 -and -not $SkipMissingInstall -and -not $installTried -and $winget) {
                    $installTried = $true
                    foreach ($fam in $missing) {
                        $id = $script:StoreInstallIds[$fam]
                        $i = Invoke-EclipseProcess -FilePath $winget -WorkPath $workPath -TimeoutMinutes $WingetTimeoutMinutes `
                            -ArgumentList ('install --id {0} --source msstore --accept-package-agreements --accept-source-agreements --silent --disable-interactivity' -f $id)
                        [void]$installs.Add([pscustomobject]@{ Family = $fam; StoreId = $id; ExitCode = $i.ExitCode; TimedOut = $i.TimedOut; Tail = $i.Tail })
                        Write-EclipseLog -Source $src -LogPath $LogPath -Message ('install {0} ({1}) exit={2} timedOut={3} :: {4}' -f $fam, $id, $i.ExitCode, $i.TimedOut, ($i.Tail -join ' | '))
                    }
                    $previous = $fp
                    continue
                }
                $stable = $true
                $stopReason = 'Stable'
                break
            }
            $previous = $fp
        }
        if (-not $stable -and $stopReason -eq 'MaxRounds' -and [DateTime]::UtcNow -gt $deadline) { $stopReason = 'Timeout' }
        $after = Get-EclipsePackageVersion -Name $script:ProtectedFamilies
    } catch {
        $topError = ('{0} hr={1}' -f $_.Exception.Message, (Get-EclipseHResult $_.Exception))
        $stable = $false
        $stopReason = 'Error'
        Write-EclipseLog -Source $src -LogPath $LogPath -Message ('ERROR: {0}' -f $topError)
    }

    $changed = @()
    $missingAfter = @()
    if ($before -and $after) {
        $changed = @($script:ProtectedFamilies | Where-Object { $before[$_].Version -ne $after[$_].Version })
    }
    if ($after) {
        $missingAfter = @($script:ProtectedFamilies | Where-Object { $after[$_].Version -eq 'absent' })
        foreach ($k in $after.Keys) { Write-EclipseLog -Source $src -LogPath $LogPath -Message ('after {0}={1} {2}' -f $k, $after[$k].Version, $after[$k].Status) }
    }

    $result = [pscustomobject]@{
        Timestamp       = $stamp
        Stable          = [bool]$stable
        StopReason      = $stopReason
        Rounds          = $rounds.Count
        RoundDetails    = $rounds.ToArray()
        Before          = $before
        After           = $after
        Changed         = $changed
        Missing         = $missingAfter
        Installs        = $installs.ToArray()
        Error           = $topError
        DurationSeconds = [int]([DateTime]::UtcNow - $started).TotalSeconds
    }
    if ($StatePath) {
        try { Write-EclipseJsonFile -InputObject $result -Path $StatePath }
        catch { Write-EclipseLog -Source $src -LogPath $LogPath -Message ('state write failed: {0}' -f $_.Exception.Message) }
    }
    Write-EclipseLog -Source $src -LogPath $LogPath -Message ('end: Stable={0} StopReason={1} Rounds={2} Changed={3} Missing={4}' -f `
            $result.Stable, $result.StopReason, $result.Rounds, ($changed -join ','), ($missingAfter -join ','))
    return $result
}

function Test-EclipseUpdateGate {
    <#
    .SYNOPSIS
    Decides whether the playbook may run: PASS only when Windows Update and the Store are at a fixed point.
    .DESCRIPTION
    PASS only if every check holds:
      Network      the system reports a network connection (an offline state is FAIL);
      WindowsUpdate  a fresh ONLINE search ('IsInstalled=0 and IsHidden=0') succeeds (ResultCode 2, no error, no
                   timeout) and finds 0 applicable software updates (driver updates are reported, not counted);
      Reboot       Test-EclipsePendingReboot reports nothing pending;
      Store        the last Invoke-EclipseStoreUpdate result (-StoreResult, else StatePath JSON) has Stable = true;
      Packages     Microsoft.WindowsStore, Microsoft.DesktopAppInstaller and Microsoft.GamingServices are present.
    Fail closed: a check that errors, times out, or lacks its input is FAIL, never PASS. The function only reads and
    searches; it installs nothing. The structured result is returned and appended to the JSON array at GateLogPath.
    .PARAMETER GateLogPath
    JSON log (an array of gate results) to append to. Default C:\EclipseOS\logs\gate.json.
    .PARAMETER StoreResult
    Result object of Invoke-EclipseStoreUpdate. If omitted, StoreStatePath is read.
    .PARAMETER StoreStatePath
    JSON written by Invoke-EclipseStoreUpdate. Default C:\EclipseOS\logs\store-last.json.
    .PARAMETER SearchTimeoutMinutes
    Timeout of the WU search. Default 30.
    .PARAMETER LogPath
    Log file for timestamped lines. Default C:\EclipseOS\logs\firstboot.log.
    .OUTPUTS
    PSCustomObject: Pass [bool], Status ('PASS'|'FAIL'), FailedChecks [string[]], Checks (per-check Pass and
    detail), Build, Timestamp.
    .EXAMPLE
    if ((Test-EclipseUpdateGate).Pass) { 'run the playbook' }
    #>
    [CmdletBinding()]
    param(
        [string]$GateLogPath = $script:DefaultGateLogPath,
        [object]$StoreResult,
        [string]$StoreStatePath = $script:DefaultStoreStatePath,
        [ValidateRange(1, 1440)][int]$SearchTimeoutMinutes = 30,
        [string]$LogPath = $script:DefaultLogPath
    )
    $src = 'Test-EclipseUpdateGate'
    $stamp = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    $checks = [ordered]@{}

    # Network
    try {
        $up = [System.Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable()
        $checks.Network = [pscustomobject]@{ Pass = [bool]$up; Detail = ('GetIsNetworkAvailable={0}' -f $up) }
    } catch {
        $checks.Network = [pscustomobject]@{ Pass = $false; Detail = ('error: {0}' -f $_.Exception.Message) }
    }

    # Windows Update: fresh online search, software updates must be 0
    try {
        $wu = Invoke-EclipseWuJob -Criteria $script:DefaultCriteria -SearchOnly -SearchTimeoutMinutes $SearchTimeoutMinutes -Source $src -LogPath $LogPath
        $wuPass = [bool]($wu.SearchSucceeded -and -not $wu.TimedOut -and -not $wu.Error -and $wu.FoundSoftwareCount -eq 0)
        $checks.WindowsUpdate = [pscustomobject]@{
            Pass               = $wuPass
            SearchSucceeded    = $wu.SearchSucceeded
            SearchResultCode   = $wu.SearchResultCode
            FoundSoftwareCount = $wu.FoundSoftwareCount
            FoundDriverCount   = $wu.FoundDriverCount
            Software           = @($wu.Found | Where-Object { $_.Type -eq 'Software' } | ForEach-Object { $_.Title })
            Drivers            = @($wu.Found | Where-Object { $_.Type -eq 'Driver' } | ForEach-Object { $_.Title })
            TimedOut           = $wu.TimedOut
            Error              = $wu.Error
            ErrorHResult       = $wu.ErrorHResult
        }
    } catch {
        $checks.WindowsUpdate = [pscustomobject]@{ Pass = $false; Error = $_.Exception.Message; ErrorHResult = (Get-EclipseHResult $_.Exception) }
    }

    # Reboot
    try {
        $rb = Test-EclipsePendingReboot -LogPath $LogPath
        $checks.Reboot = [pscustomobject]@{ Pass = (-not $rb.Pending); Reasons = $rb.Reasons }
    } catch {
        $checks.Reboot = [pscustomobject]@{ Pass = $false; Reasons = @('error: ' + $_.Exception.Message) }
    }

    # Store: last round must have ended stable
    try {
        $s = $StoreResult
        $from = 'parameter'
        if (-not $s) {
            $from = $StoreStatePath
            if (-not $StoreStatePath -or -not (Test-Path -LiteralPath $StoreStatePath)) { throw ('no Store result at {0}' -f $StoreStatePath) }
            $s = Get-Content -LiteralPath $StoreStatePath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        }
        $stableProp = $s.PSObject.Properties['Stable']
        $isStable = [bool]($stableProp -and ($stableProp.Value -is [bool]) -and $stableProp.Value)
        $checks.Store = [pscustomobject]@{ Pass = $isStable; Source = $from; Stable = $(if ($stableProp) { $stableProp.Value } else { $null }); StopReason = $s.StopReason; Timestamp = $s.Timestamp }
    } catch {
        $checks.Store = [pscustomobject]@{ Pass = $false; Source = $StoreStatePath; Error = $_.Exception.Message }
    }

    # Required packages present
    try {
        $v = Get-EclipsePackageVersion -Name $script:GateRequiredFamilies
        $absent = @($script:GateRequiredFamilies | Where-Object { $v[$_].Version -eq 'absent' })
        $checks.Packages = [pscustomobject]@{ Pass = ($absent.Count -eq 0); Missing = $absent; Versions = $v }
    } catch {
        $checks.Packages = [pscustomobject]@{ Pass = $false; Missing = $script:GateRequiredFamilies; Error = $_.Exception.Message }
    }

    $failedChecks = @($checks.Keys | Where-Object { -not ($checks[$_].Pass -eq $true) })
    $pass = ($failedChecks.Count -eq 0) -and ($checks.Count -eq 5)
    $build = $null
    try {
        $cv = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        $build = '{0}.{1}' -f $cv.CurrentBuild, $cv.UBR
    } catch { $build = $null }

    $result = [pscustomobject]@{
        Timestamp    = $stamp
        Pass         = [bool]$pass
        Status       = $(if ($pass) { 'PASS' } else { 'FAIL' })
        FailedChecks = $failedChecks
        Checks       = $checks
        Build        = $build
        ComputerName = $env:COMPUTERNAME
    }

    if ($GateLogPath) {
        try {
            $entries = @()
            if (Test-Path -LiteralPath $GateLogPath) {
                try {
                    $old = Get-Content -LiteralPath $GateLogPath -Raw -ErrorAction Stop
                    if ($old -and $old.Trim()) {
                        # PS 5.1 returns a JSON array as one object: assign first, then wrap.
                        $parsed = ConvertFrom-Json -InputObject $old -ErrorAction Stop
                        $entries = @($parsed)
                    }
                } catch {
                    $bad = '{0}.{1}.bad' -f $GateLogPath, [DateTime]::UtcNow.ToString('yyyyMMddHHmmss')
                    Move-Item -LiteralPath $GateLogPath -Destination $bad -Force -ErrorAction SilentlyContinue
                    Write-EclipseLog -Source $src -LogPath $LogPath -Message ('unreadable gate log moved to {0}' -f $bad)
                    $entries = @()
                }
            }
            $entries += $result
            Write-EclipseJsonFile -InputObject @($entries) -Path $GateLogPath
        } catch {
            Write-EclipseLog -Source $src -LogPath $LogPath -Message ('gate log write failed: {0}' -f $_.Exception.Message)
        }
    }
    Write-EclipseLog -Source $src -LogPath $LogPath -Message ('{0} failed=[{1}] build={2}' -f $result.Status, ($failedChecks -join ','), $build)
    return $result
}

Export-ModuleMember -Function Test-EclipsePendingReboot, Invoke-EclipseWindowsUpdateRound, Invoke-EclipseStoreUpdate, Test-EclipseUpdateGate
