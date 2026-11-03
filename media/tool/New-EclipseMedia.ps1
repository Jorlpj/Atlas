[CmdletBinding()]
param(
    [string]$IsoPath,
    [string]$SourceDir,
    [string]$OutIso,
    [string]$OutDir,
    [string]$EngineDir,
    [string]$UserName='User', [string]$InputLocale, [string]$SystemLocale,
    [string]$UILanguage, [string]$UserLocale, [string]$TimeZone,
    [int]$AutoLogonCount=15,
    # Test-only: skips Windows image metadata validation for synthetic fixtures.
    [switch]$SkipImageCheck
)
$ErrorActionPreference='Stop'
if (-not ('EclipseMediaStreamCopy' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
public static class EclipseMediaStreamCopy {
    public static void ToFile(object source, string path) {
        IStream stream = (IStream)source;
        using (FileStream output = File.Create(path)) {
            byte[] buffer = new byte[1048576];
            IntPtr readPtr = Marshal.AllocCoTaskMem(4);
            try {
                int read;
                do { Marshal.WriteInt32(readPtr, 0); stream.Read(buffer, buffer.Length, readPtr); read = Marshal.ReadInt32(readPtr); if (read > 0) output.Write(buffer, 0, read); } while (read > 0);
            } finally { Marshal.FreeCoTaskMem(readPtr); }
        }
    }
}
'@
}
$scriptDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot=(Resolve-Path (Join-Path $scriptDir '..\..')).Path
Import-Module (Join-Path $scriptDir 'EclipseUnattend.psm1') -Force
$supported=Get-Content -Raw (Join-Path $scriptDir 'supported-builds.json') | ConvertFrom-Json
$sourcePath=$null; $mounted=$false; $image=$null; $stage=$null; $inputHash=$null; $build=$null; $arch=$null; $comObjects=New-Object System.Collections.ArrayList; $adodbStream=$null
try {
    if ([bool]$IsoPath -eq [bool]$SourceDir) { throw 'Specify exactly one of -IsoPath or -SourceDir.' }
    if ([bool]$OutIso -eq [bool]$OutDir) { throw 'Specify exactly one of -OutIso or -OutDir.' }
    if ($IsoPath) {
        $iso=(Resolve-Path -LiteralPath $IsoPath).Path
        $inputHash=(Get-FileHash -LiteralPath $iso -Algorithm SHA256).Hash
        $image=Mount-DiskImage -ImagePath $iso -Access ReadOnly -PassThru; $mounted=$true
        $vol=$image | Get-Volume | Where-Object DriveLetter | Select-Object -First 1
        if (-not $vol) { throw 'Mounted ISO has no accessible drive letter.' }
        $sourcePath="$($vol.DriveLetter):\"
    } else {
        $sourcePath=(Resolve-Path -LiteralPath $SourceDir).Path
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) { throw 'SourceDir must be a directory.' }
        $sha=New-Object System.Security.Cryptography.SHA256Managed
        $hasher=[System.Security.Cryptography.IncrementalHash]::CreateHash([System.Security.Cryptography.HashAlgorithmName]::SHA256)
        Get-ChildItem -LiteralPath $sourcePath -File -Recurse | Sort-Object FullName | ForEach-Object {
            $rel=$_.FullName.Substring($sourcePath.Length).TrimStart('\')
            $bytes=[Text.Encoding]::UTF8.GetBytes($rel + "`n"); $hasher.AppendData($bytes)
            $fs=[IO.File]::OpenRead($_.FullName); try { $buf=New-Object byte[] 65536; while(($n=$fs.Read($buf,0,$buf.Length)) -gt 0) { $hasher.AppendData($buf,0,$n) } } finally { $fs.Dispose() }
        }
        $inputHash=([BitConverter]::ToString($hasher.GetHashAndReset())).Replace('-',''); $hasher.Dispose(); $sha.Dispose()
    }
    if (-not (Test-Path (Join-Path $sourcePath 'sources\install.wim')) -and -not (Test-Path (Join-Path $sourcePath 'sources\install.esd'))) { throw 'Source does not contain sources\install.wim or install.esd.' }
    if ((Test-Path (Join-Path $sourcePath 'sources\$OEM$\$$\Panther\unattend.xml')) -or (Test-Path (Join-Path $sourcePath 'autounattend.xml'))) {
        throw 'Source already contains an unattended answer file; refusing to replace or conflict with existing Setup instructions.'
    }
    if (-not $SkipImageCheck) {
        $imagePath=Join-Path $sourcePath 'sources\install.wim'; if (-not (Test-Path $imagePath)) { $imagePath=Join-Path $sourcePath 'sources\install.esd' }
        if (-not (Get-Command Get-WindowsImage -ErrorAction SilentlyContinue)) { Import-Module Dism -ErrorAction Stop }
        $images=Get-WindowsImage -ImagePath $imagePath
        $info=Get-WindowsImage -ImagePath $imagePath -Index $images[0].ImageIndex
        $build=[int]$info.Version.Build
        $archName=[string]$info.Architecture
        $arch=switch -Regex ($archName) { '^(9|x64|amd64)$' {'amd64'} '^(0|x86)$' {'x86'} '^(12|arm64)$' {'arm64'} default { $archName } }
        $entry=$supported.builds | Where-Object { $_.build -eq $build -and $_.architectures -contains $arch } | Select-Object -First 1
        if (-not $entry) { throw "Unsupported Windows image build/architecture: $build $arch." }
    } else { $build=26300; $arch='amd64' }

    if (-not $InputLocale) {
        try { $InputLocale=(Get-ItemProperty -LiteralPath 'HKCU:\Keyboard Layout\Preload' -Name '1' -ErrorAction Stop).'1' } catch { $InputLocale=(Get-Culture).Name }
    }
    if (-not $SystemLocale) { $SystemLocale=(Get-WinSystemLocale).Name }
    if (-not $UILanguage) { $UILanguage=(Get-UICulture).Name }
    if (-not $UserLocale) { $UserLocale=(Get-Culture).Name }
    if (-not $TimeZone) { $TimeZone=(Get-TimeZone).Id }

    $stage=Join-Path ([IO.Path]::GetTempPath()) ('EclipseOS-media-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stage | Out-Null
    Get-ChildItem -LiteralPath $sourcePath -Force | Copy-Item -Destination $stage -Recurse -Force
    $oem=Join-Path $stage 'sources\$OEM$'; $unattendPath=Join-Path $oem '$$\Panther\unattend.xml'; $payload=Join-Path $oem '$1\EclipseOS'
    New-Item -ItemType Directory -Path (Split-Path -Parent $unattendPath) -Force | Out-Null
    New-Item -ItemType Directory -Path $payload -Force | Out-Null
    New-EclipseUnattendXml -UserName $UserName -InputLocale $InputLocale -SystemLocale $SystemLocale -UILanguage $UILanguage -UserLocale $UserLocale -TimeZone $TimeZone -AutoLogonCount $AutoLogonCount -Arch $arch | Set-Content -LiteralPath $unattendPath -Encoding UTF8
    Copy-Item -LiteralPath (Join-Path $repoRoot 'src\playbook') -Destination (Join-Path $payload 'playbook') -Recurse
    if ($EngineDir) { if (-not (Test-Path -LiteralPath $EngineDir -PathType Container)) { throw "EngineDir not found: $EngineDir" }; Copy-Item -LiteralPath $EngineDir -Destination (Join-Path $payload 'engine') -Recurse }
    else { Write-Warning 'EngineDir was not supplied; this ISO has no engine payload.' }
    $firstboot=Join-Path $repoRoot 'media\firstboot'; if (Test-Path $firstboot) { Copy-Item -LiteralPath $firstboot -Destination (Join-Path $payload 'firstboot') -Recurse }

    if ($OutDir) {
        $target=[IO.Path]::GetFullPath($OutDir); if (Test-Path $target) { throw "OutDir already exists: $target" }
        Copy-Item -LiteralPath $stage -Destination $target -Recurse
        $metaPath=Join-Path (Split-Path -Parent $target) 'EclipseOS-media.json'
    } elseif ($OutIso) {
        $target=[IO.Path]::GetFullPath($OutIso); if (Test-Path $target) { throw "OutIso already exists: $target" }
        $efi=Join-Path $sourcePath 'efi\microsoft\boot\efisys.bin'; if (-not (Test-Path $efi)) { throw 'Source is missing efi\microsoft\boot\efisys.bin, required for UEFI boot.' }
        $fsImage=New-Object -ComObject IMAPI2FS.MsftFileSystemImage
        [void]$comObjects.Add($fsImage)
        $fsImage.FileSystemsToCreate=4; $fsImage.FreeMediaBlocks=0; $fsImage.UDFRevision=513; $fsImage.VolumeName='ECLIPSEOS'
        $fsRoot=$fsImage.Root; [void]$comObjects.Add($fsRoot); [void]$fsRoot.AddTree(($stage.TrimEnd('\') + '\'),$false)
        $adodbStream=New-Object -ComObject ADODB.Stream; [void]$comObjects.Add($adodbStream); $adodbStream.Type=1; $adodbStream.Open(); $adodbStream.LoadFromFile($efi)
        $boot=New-Object -ComObject IMAPI2FS.BootOptions; [void]$comObjects.Add($boot); $boot.PlatformId=0xEF; $boot.Emulation=0; $boot.AssignBootImage($adodbStream)
        $fsImage.BootImageOptions=$boot
        $result=$fsImage.CreateResultImage(); [void]$comObjects.Add($result); $outStream=$result.ImageStream; [void]$comObjects.Add($outStream)
        [EclipseMediaStreamCopy]::ToFile($outStream,$target)
        $metaPath=Join-Path (Split-Path -Parent $target) 'EclipseOS-media.json'
    }
    $options=[ordered]@{ userName=$UserName; inputLocale=$InputLocale; systemLocale=$SystemLocale; uiLanguage=$UILanguage; userLocale=$UserLocale; timeZone=$TimeZone; autoLogonCount=$AutoLogonCount }
    [ordered]@{ inputSha256=$inputHash; build=$build; architecture=$arch; options=$options; toolVersion='1.0.0' } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $metaPath -Encoding UTF8
} finally {
    if ($mounted -and $image) { Dismount-DiskImage -ImagePath $iso -ErrorAction SilentlyContinue }
    if ($adodbStream) { try { $adodbStream.Close() } catch {} }
    for ($i=$comObjects.Count-1; $i -ge 0; $i--) { try { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($comObjects[$i]) } catch {} }
    [GC]::Collect(); [GC]::WaitForPendingFinalizers(); [GC]::Collect()
    if ($stage -and (Test-Path $stage)) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
