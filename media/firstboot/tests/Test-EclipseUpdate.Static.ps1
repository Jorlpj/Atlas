<#
.SYNOPSIS
Static checks of media/firstboot/EclipseUpdate.psm1. Parses only: never imports, dot-sources or calls the module.
.DESCRIPTION
  1. The module parses with the PowerShell language parser, with no errors.
  2. The top level holds only constant assignments, function definitions and one Export-ModuleMember call, so
     importing the module invokes no function and runs no command.
  3. The exported functions are exactly the four of the contract, each defined at the top level, with
     [CmdletBinding()], comment-based help (.SYNOPSIS and .DESCRIPTION) and a LogPath parameter.
  4. The module is ASCII-only (Windows PowerShell 5.1 reads BOM-less files as ANSI).
  5. The module writes no registry value and changes no service (it services the system, it does not configure it),
     and its WU search is online.
  6. PSScriptAnalyzer runs if it is installed (Error severity fails, warnings are listed); skipped otherwise.
Exit 0 = PASS, 1 = FAIL.
.PARAMETER ModulePath
Module to check. Default: ..\EclipseUpdate.psm1 next to this folder.
.EXAMPLE
powershell.exe -NoProfile -File media/firstboot/tests/Test-EclipseUpdate.Static.ps1
#>
[CmdletBinding()]
param(
    [string]$ModulePath
)
if (-not $ModulePath) {
    # $PSScriptRoot is empty in a param default under Windows PowerShell 5.1 -File.
    $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ModulePath = Join-Path (Split-Path -Parent $here) 'EclipseUpdate.psm1'
}

$ErrorActionPreference = 'Stop'
$script:failures = New-Object System.Collections.ArrayList

function Add-Result {
    param([string]$Name, [bool]$Ok, [string]$Detail = '')
    if ($Ok) { Write-Output ('PASS  {0}' -f $Name) }
    else {
        Write-Output ('FAIL  {0}: {1}' -f $Name, $Detail)
        [void]$script:failures.Add($Name)
    }
}

$expected = @('Test-EclipsePendingReboot', 'Invoke-EclipseWindowsUpdateRound', 'Invoke-EclipseStoreUpdate', 'Test-EclipseUpdateGate')

if (-not (Test-Path -LiteralPath $ModulePath)) {
    Write-Output ('FAIL  module not found: {0}' -f $ModulePath)
    exit 1
}
$ModulePath = (Resolve-Path -LiteralPath $ModulePath).ProviderPath

# 1. Parse
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($ModulePath, [ref]$tokens, [ref]$errors)
Add-Result 'parse' (@($errors).Count -eq 0) ((@($errors) | ForEach-Object { '{0}:{1} {2}' -f $_.Extent.StartLineNumber, $_.Extent.StartColumnNumber, $_.Message }) -join '; ')
if (@($errors).Count -gt 0) { exit 1 }

# 2. Top level: nothing runs at import
$topFunctions = @($ast.EndBlock.Statements | Where-Object { $_ -is [System.Management.Automation.Language.FunctionDefinitionAst] })
$topNames = @($topFunctions | ForEach-Object { $_.Name })
$moduleFunctionNames = $topNames
$exportCalls = @()
$bad = New-Object System.Collections.ArrayList
foreach ($block in @($ast.BeginBlock, $ast.ProcessBlock, $ast.DynamicParamBlock)) {
    if ($block -and @($block.Statements).Count -gt 0) { [void]$bad.Add('begin/process/dynamicparam block at top level') }
}
foreach ($st in @($ast.EndBlock.Statements)) {
    if ($st -is [System.Management.Automation.Language.FunctionDefinitionAst]) { continue }
    if ($st -is [System.Management.Automation.Language.AssignmentStatementAst]) {
        $cmds = @($st.Right.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -or
                    $n -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -or
                    $n -is [System.Management.Automation.Language.ScriptBlockExpressionAst] }, $true))
        if ($cmds.Count -gt 0) { [void]$bad.Add(('line {0}: assignment runs code: {1}' -f $st.Extent.StartLineNumber, $cmds[0].Extent.Text)) }
        continue
    }
    if ($st -is [System.Management.Automation.Language.PipelineAst] -and @($st.PipelineElements).Count -eq 1 -and
        $st.PipelineElements[0] -is [System.Management.Automation.Language.CommandAst] -and
        $st.PipelineElements[0].GetCommandName() -eq 'Export-ModuleMember') {
        $exportCalls += $st.PipelineElements[0]
        continue
    }
    [void]$bad.Add(('line {0}: top-level statement: {1}' -f $st.Extent.StartLineNumber, ($st.Extent.Text -split "`n")[0].Trim()))
}
Add-Result 'no code runs at import (top level = constants, functions, Export-ModuleMember)' ($bad.Count -eq 0) ($bad -join '; ')

# Module functions are invoked only inside function bodies
$outsideCalls = @($ast.EndBlock.Statements | Where-Object { $_ -isnot [System.Management.Automation.Language.FunctionDefinitionAst] } |
        ForEach-Object { $_.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) } |
        Where-Object { $moduleFunctionNames -contains $_.GetCommandName() })
Add-Result 'no module function invoked at import time' ($outsideCalls.Count -eq 0) (($outsideCalls | ForEach-Object { $_.Extent.Text }) -join '; ')

# 3. Exports
Add-Result 'exactly one Export-ModuleMember' ($exportCalls.Count -eq 1) ('found {0}' -f $exportCalls.Count)
$exported = @()
if ($exportCalls.Count -eq 1) {
    $exported = @($exportCalls[0].CommandElements | Select-Object -Skip 1 |
            Where-Object { $_ -isnot [System.Management.Automation.Language.CommandParameterAst] } |
            ForEach-Object {
                if ($_ -is [System.Management.Automation.Language.ArrayLiteralAst]) { $_.Elements | ForEach-Object { $_.Value } }
                else { $_.Value }
            })
    $params = @($exportCalls[0].CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] } | ForEach-Object { $_.ParameterName })
    Add-Result 'Export-ModuleMember exports functions only' (($params -join ',') -eq 'Function') ('parameters: {0}' -f ($params -join ','))
}
$missing = @($expected | Where-Object { $exported -notcontains $_ })
$extra = @($exported | Where-Object { $expected -notcontains $_ })
Add-Result 'exported names match the contract' (($missing.Count -eq 0) -and ($extra.Count -eq 0)) ('missing: {0}; extra: {1}' -f ($missing -join ','), ($extra -join ','))

foreach ($name in $expected) {
    $fn = @($topFunctions | Where-Object { $_.Name -eq $name })
    if ($fn.Count -ne 1) { Add-Result ('{0} defined once at top level' -f $name) $false ('count {0}' -f $fn.Count); continue }
    $fn = $fn[0]
    $pb = $fn.Body.ParamBlock
    $hasCb = $pb -and @($pb.Attributes | Where-Object { $_.TypeName.Name -eq 'CmdletBinding' }).Count -gt 0
    Add-Result ('{0} has [CmdletBinding()]' -f $name) ([bool]$hasCb)
    $help = $fn.GetHelpContent()
    Add-Result ('{0} has comment-based help' -f $name) ([bool]($help -and $help.Synopsis -and $help.Description)) 'no .SYNOPSIS/.DESCRIPTION'
    $hasLog = $pb -and @($pb.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'LogPath' }).Count -gt 0
    Add-Result ('{0} has a LogPath parameter' -f $name) ([bool]$hasLog)
}
$gate = @($topFunctions | Where-Object { $_.Name -eq 'Test-EclipseUpdateGate' })
if ($gate.Count -eq 1) {
    $gp = @($gate[0].Body.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'GateLogPath' })
    $default = if ($gp.Count -eq 1 -and $gp[0].DefaultValue) { $gp[0].DefaultValue.Extent.Text } else { '' }
    $constOk = $ast.EndBlock.Statements | Where-Object {
        $_ -is [System.Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -eq '$script:DefaultGateLogPath' -and
        $_.Right.Extent.Text -eq "'C:\EclipseOS\logs\gate.json'" }
    Add-Result 'gate log default is C:\EclipseOS\logs\gate.json' (($default -eq '$script:DefaultGateLogPath') -and [bool]$constOk) ('default: {0}' -f $default)
}

# 4. ASCII only
$bytes = [System.IO.File]::ReadAllBytes($ModulePath)
$nonAscii = @($bytes | Where-Object { $_ -gt 127 }).Count
Add-Result 'module is ASCII-only' ($nonAscii -eq 0) ('{0} non-ASCII bytes' -f $nonAscii)

# 5. Services the system, configures nothing
$forbiddenCmds = @('Set-ItemProperty', 'New-ItemProperty', 'Remove-ItemProperty', 'Set-Service', 'Stop-Service', 'Set-ScheduledTask',
    'Disable-ScheduledTask', 'Unregister-ScheduledTask', 'reg', 'reg.exe', 'sc', 'sc.exe', 'Restart-Computer', 'Stop-Computer', 'shutdown', 'shutdown.exe')
$cmdHits = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) |
        Where-Object { $forbiddenCmds -contains $_.GetCommandName() } | ForEach-Object { '{0}: {1}' -f $_.Extent.StartLineNumber, $_.GetCommandName() })
Add-Result 'no registry, service, task or restart command' ($cmdHits.Count -eq 0) ($cmdHits -join '; ')
$text = [System.IO.File]::ReadAllText($ModulePath)
$policyHits = @([regex]::Matches($text, '(?i)PauseUpdates|DeferQualityUpdates|DeferFeatureUpdates|NoAutoUpdate|AUOptions|AutoDownload|SetRegistry|OpenSubKey\([^)]*,\s*\$true') | ForEach-Object { $_.Value })
Add-Result 'no WU or Store policy value referenced' ($policyHits.Count -eq 0) ($policyHits -join ', ')
$onlineSet = [regex]::IsMatch($text, '\$searcher\.Online\s*=\s*\$true')
$offlineSet = [regex]::IsMatch($text, '(?i)\.Online\s*=\s*\$false')
Add-Result 'WU search is online' ($onlineSet -and -not $offlineSet) 'IUpdateSearcher.Online must be $true'
Add-Result 'WU criteria IsInstalled=0 and IsHidden=0' ($text.Contains("'IsInstalled=0 and IsHidden=0'")) 'criteria constant not found'

# 6. PSScriptAnalyzer (optional)
$pssa = Get-Module -ListAvailable -Name PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1
if ($pssa) {
    Import-Module $pssa -ErrorAction Stop
    $diag = @(Invoke-ScriptAnalyzer -Path $ModulePath -Severity Error, Warning)
    foreach ($d in $diag | Where-Object { "$($_.Severity)" -eq 'Warning' }) { Write-Output ('WARN  PSSA {0} line {1}: {2}' -f $d.RuleName, $d.Line, $d.Message) }
    $errs = @($diag | Where-Object { "$($_.Severity)" -eq 'Error' })
    Add-Result ('PSScriptAnalyzer {0} (Error severity)' -f $pssa.Version) ($errs.Count -eq 0) (($errs | ForEach-Object { '{0} line {1}' -f $_.RuleName, $_.Line }) -join '; ')
} else {
    Write-Output 'SKIP  PSScriptAnalyzer not installed'
}

if ($script:failures.Count -gt 0) {
    Write-Output ('RESULT FAIL ({0} check(s) failed)' -f $script:failures.Count)
    exit 1
}
Write-Output 'RESULT PASS'
exit 0
