$ErrorActionPreference='Stop'
$toolRoot=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$script=Join-Path $toolRoot 'New-EclipseMedia.ps1'
Import-Module (Join-Path $toolRoot 'EclipseUnattend.psm1') -Force
function Assert($condition,[string]$message) { if (-not $condition) { throw $message } }

$xmlText=New-EclipseUnattendXml -UserName 'User' -InputLocale 'en-US' -SystemLocale 'en-US' -UILanguage 'en-US' -UserLocale 'en-US' -TimeZone 'UTC' -Arch amd64
$doc=New-Object System.Xml.XmlDocument; $doc.LoadXml($xmlText)
$all=$doc.OuterXml
foreach($required in @('Microsoft-Windows-Deployment','BypassNRO','HideEULAPage','ProtectYourPC','LocalAccount','Administrators','AutoLogon','PreventDeviceEncryption','Start-EclipseFirstLogon.ps1','TCGSecurityActivationDisabled')) {
    Assert ($all.Contains($required)) "Missing required XML item: $required"
}
foreach($forbidden in @('logonpasswordchg','maxpwage','windowsPE','LabConfig','SkuSiPolicy','Windows CA 2023')) {
    Assert (-not $all.Contains($forbidden)) "Forbidden XML item found: $forbidden"
}
$ns=New-Object System.Xml.XmlNamespaceManager($doc.NameTable); $ns.AddNamespace('u','urn:schemas-microsoft-com:unattend')
$passes=$doc.SelectNodes('/u:unattend/u:settings',$ns)
$passNames=@($passes | ForEach-Object { $_.GetAttribute('pass') })
Assert (($passNames | Sort-Object -Unique).Count -eq $passNames.Count) 'A settings pass appears more than once.'
foreach($pass in $passes) { Assert ($pass.ChildNodes.Count -gt 0) "Empty settings pass: $($pass.GetAttribute('pass'))" }
$specCommands=$doc.SelectNodes('//u:settings[@pass="specialize"]/u:component[@name="Microsoft-Windows-Deployment"]/u:RunSynchronous/u:RunSynchronousCommand',$ns)
Assert ($specCommands.Count -gt 0) 'Specialize RunSynchronous commands missing.'
$commands=$doc.SelectNodes('//u:settings[@pass="oobeSystem"]/u:component[@name="Microsoft-Windows-Shell-Setup"]/u:FirstLogonCommands/u:SynchronousCommand',$ns)
$orders=@($commands | ForEach-Object { [int]$_.SelectSingleNode('u:Order',$ns).InnerText })
Assert ($orders.Count -gt 1) 'Expected FirstLogonCommands entries.'
Assert ((($orders | Sort-Object -Unique) -join ',') -eq (($orders | Sort-Object) -join ',')) 'FirstLogonCommand orders are not unique and ascending.'
Assert ($commands[$commands.Count-1].SelectSingleNode('u:CommandLine',$ns).InnerText -like '*Start-EclipseFirstLogon.ps1*') 'EclipseOS launcher is not last.'
Assert ($commands[$commands.Count-2].SelectSingleNode('u:CommandLine',$ns).InnerText -like '*VisiblePlaces*') 'VisiblePlaces is not the last QoL command.'
Assert ($all.Contains('Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Start')) 'VisiblePlaces registry path missing.'

$temp=Join-Path ([IO.Path]::GetTempPath()) ('EclipseMediaTest-' + [guid]::NewGuid().ToString('N'))
try {
    $fake=Join-Path $temp 'fake'; New-Item -ItemType Directory -Path (Join-Path $fake 'sources') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $fake 'efi\microsoft\boot') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $fake 'sources\install.wim') -Value 'fake' -Encoding ASCII
    [IO.File]::WriteAllBytes((Join-Path $fake 'efi\microsoft\boot\efisys.bin'),(New-Object byte[] 1474560))
    Set-Content -LiteralPath (Join-Path $fake 'setup.exe') -Value 'dummy' -Encoding ASCII
    $out=Join-Path $temp 'outdir'
    & $script -SourceDir $fake -OutDir $out -SkipImageCheck
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw 'New-EclipseMedia OutDir invocation failed.' }
    Assert (Test-Path (Join-Path $out 'sources\$OEM$\$$\Panther\unattend.xml')) 'Answer file missing from output.'
    Assert (Test-Path (Join-Path $out 'sources\$OEM$\$1\EclipseOS\playbook\playbook.conf')) 'Playbook payload missing from output.'
    Assert (Test-Path (Join-Path $out 'setup.exe')) 'Source tree was not copied.'
    Assert (Test-Path (Join-Path $temp 'EclipseOS-media.json')) 'Media metadata missing next to output.'
    if (($env:OS -eq 'Windows_NT') -and ($PSVersionTable.PSEdition -eq 'Desktop')) {
        $smallIso=Join-Path $temp 'prepared-small.iso'
        & $script -SourceDir $fake -OutIso $smallIso -SkipImageCheck
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw 'New-EclipseMedia small OutIso invocation failed.' }
        Assert ((Test-Path $smallIso) -and ((Get-Item $smallIso).Length -gt 0)) 'Small OutIso did not create an ISO file.'
        $large=Join-Path $fake 'sources\large-sparse.bin'
        $largeStream=[IO.File]::Open($large,[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::None)
        try { $largeStream.SetLength(4GB + 1MB) } finally { $largeStream.Dispose() }
        $iso=Join-Path $temp 'prepared-large.iso'
        & $script -SourceDir $fake -OutIso $iso -SkipImageCheck
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw 'New-EclipseMedia OutIso invocation failed.' }
        Assert ((Test-Path $iso) -and ((Get-Item $iso).Length -gt 0)) 'OutIso did not create an ISO file.'
    } else { Write-Output 'SKIP: >4 GB OutIso test requires Windows PowerShell 5.1 and IMAPI2FS.' }
    Write-Output 'PASS: Eclipse media tests'
} finally { if (Test-Path $temp) { Remove-Item -LiteralPath $temp -Recurse -Force } }
