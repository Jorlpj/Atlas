# Derived from Rufus v4.15 src/wue.c by Pete Batard; GPL-3.0. See NOTICE.md.
function New-EclipseUnattendXml {
    [CmdletBinding()]
    param(
        [string]$UserName = 'User', [string]$InputLocale, [string]$SystemLocale,
        [string]$UILanguage, [string]$UserLocale, [string]$TimeZone,
        [ValidateRange(1, 999)][int]$AutoLogonCount = 15,
        [ValidateSet('amd64','x86','arm64')][string]$Arch = 'amd64'
    )
    if (-not $InputLocale) { $InputLocale = (Get-Culture).Name }
    if (-not $SystemLocale) { $SystemLocale = (Get-WinSystemLocale).Name }
    if (-not $UILanguage) { $UILanguage = (Get-UICulture).Name }
    if (-not $UserLocale) { $UserLocale = (Get-Culture).Name }
    if (-not $TimeZone) { $TimeZone = (Get-TimeZone).Id }
    if ($UserName -match '["<>|*?:/\\]' -or [string]::IsNullOrWhiteSpace($UserName)) { throw 'Invalid local account name.' }

    $doc = New-Object System.Xml.XmlDocument
    $decl = $doc.CreateXmlDeclaration('1.0','utf-8',$null); [void]$doc.AppendChild($decl)
    $root = $doc.CreateElement('unattend','urn:schemas-microsoft-com:unattend'); [void]$doc.AppendChild($root)
    $ns = 'urn:schemas-microsoft-com:unattend'
    function Add-Text($Parent, [string]$Name, [string]$Value) { $e=$doc.CreateElement($Name,$ns); $e.InnerText=$Value; [void]$Parent.AppendChild($e); return $e }
    function Add-Settings([string]$Pass) {
        $s=$doc.CreateElement('settings',$ns); $s.SetAttribute('pass',$Pass); [void]$root.AppendChild($s); return $s
    }
    function Add-Component($Settings,[string]$Name) {
        $c=$doc.CreateElement('component',$ns); $c.SetAttribute('name',$Name); $c.SetAttribute('processorArchitecture',$Arch); $c.SetAttribute('publicKeyToken','31bf3856ad364e35'); $c.SetAttribute('language','neutral'); $c.SetAttribute('versionScope','nonSxS'); [void]$Settings.AppendChild($c); return $c
    }
    function Add-RunCommand($Parent,[int]$Order,[string]$Command) {
        $cmd=Add-Text $Parent 'RunSynchronousCommand' ''; [void](Add-Text $cmd 'Order' "$Order"); [void](Add-Text $cmd 'Path' $Command); [void](Add-Text $cmd 'WillReboot' 'Never')
    }

    $spec=Add-Settings 'specialize'
    $dep=Add-Component $spec 'Microsoft-Windows-Deployment'
    $sync=Add-Text $dep 'RunSynchronous' ''
    Add-RunCommand $sync 1 'reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f'
    Add-RunCommand $sync 2 'reg add "HKLM\Software\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f'
    Add-RunCommand $sync 3 'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Remove-Item $env:SystemRoot\System32\OneDriveSetup.exe,$env:SystemRoot\SysWOW64\OneDriveSetup.exe -Force -ErrorAction SilentlyContinue; Get-AppxProvisionedPackage -Online | Where-Object DisplayName -Like ''*Outlook*'' | Remove-AppxProvisionedPackage -Online; Get-AppxPackage -AllUsers | Where-Object Name -Like ''*Outlook*'' | Remove-AppxPackage -AllUsers; Get-AppxProvisionedPackage -Online | Where-Object DisplayName -Like ''*Teams*'' | Remove-AppxProvisionedPackage -Online; Get-AppxPackage -AllUsers | Where-Object Name -Like ''*Teams*'' | Remove-AppxPackage -AllUsers"'

    $oobeSettings=Add-Settings 'oobeSystem'
    $sh=Add-Component $oobeSettings 'Microsoft-Windows-Shell-Setup'; [void](Add-Text $sh 'TimeZone' $TimeZone)
    $intl=Add-Component $oobeSettings 'Microsoft-Windows-International-Core'; [void](Add-Text $intl 'InputLocale' $InputLocale); [void](Add-Text $intl 'SystemLocale' $SystemLocale); [void](Add-Text $intl 'UILanguage' $UILanguage); [void](Add-Text $intl 'UserLocale' $UserLocale)
    $oobe=Add-Text $sh 'OOBE' ''; [void](Add-Text $oobe 'HideEULAPage' 'true'); [void](Add-Text $oobe 'ProtectYourPC' '3')
    $accounts=Add-Text $sh 'UserAccounts' ''; $locals=Add-Text $accounts 'LocalAccounts' ''; $local=Add-Text $locals 'LocalAccount' ''
    [void](Add-Text $local 'Name' $UserName); [void](Add-Text $local 'DisplayName' $UserName); [void](Add-Text $local 'Group' 'Administrators')
    $pass=Add-Text $local 'Password' ''; [void](Add-Text $pass 'Value' 'UABhAHMAcwB3AG8AcgBkAA=='); [void](Add-Text $pass 'PlainText' 'false')
    $aut=Add-Text $sh 'AutoLogon' ''; [void](Add-Text $aut 'Enabled' 'true'); [void](Add-Text $aut 'LogonCount' "$AutoLogonCount"); [void](Add-Text $aut 'Username' $UserName)
    $ap=Add-Text $aut 'Password' ''; [void](Add-Text $ap 'Value' 'UABhAHMAcwB3AG8AcgBkAA=='); [void](Add-Text $ap 'PlainText' 'false')
    $fd=Add-Component $oobeSettings 'Microsoft-Windows-SecureStartup-FilterDriver'; [void](Add-Text $fd 'PreventDeviceEncryption' 'true')
    $enh=Add-Component $oobeSettings 'Microsoft-Windows-EnhancedStorage-Adm'; [void](Add-Text $enh 'TCGSecurityActivationDisabled' '1')
    # Emit additional Rufus QoL and then the EclipseOS launcher in one ordered FirstLogonCommands component.
    $fl=$doc.CreateElement('FirstLogonCommands',$ns); [void]$sh.AppendChild($fl)
    $commands=@(
      @('reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f','Disable Fast Startup'),
      @('reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f','Disable Copilot'),
      @('reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f','Hide Copilot button'),
      @('reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 1 /f','Simplify taskbar search'),
      @('reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarModeCache /t REG_DWORD /d 1 /f','Simplify cached taskbar search'),
      @('reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 0 /f','Disable Bing search'),
      @('reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f','Disable consumer features'),
      @('reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v DisableCloudOptimizedContent /t REG_DWORD /d 1 /f','Disable cloud optimized content'),
      @('reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f','Disable system pane suggestions'),
      @('reg add "HKLM\Software\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f','Disable News and interests'),
      @('reg add "HKLM\Software\Policies\Microsoft\Windows\Windows Feeds" /v EnableFeeds /t REG_DWORD /d 0 /f','Disable feeds'),
      @('reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Communications" /v ConfigureChatAutoInstall /t REG_DWORD /d 0 /f','Disable automatic Chat install'),
      @('reg add "HKLM\Software\Policies\Microsoft\Edge" /v HideFirstRunExperience /t REG_DWORD /d 1 /f','Hide Edge first run'),
      @('reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_Layout /t REG_DWORD /d 1 /f','Use expanded Start pins'),
      @('PowerShell -NonInteractive -WindowStyle Hidden -Command "Set-ItemProperty -Path ''Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Start'' -Name ''VisiblePlaces'' -Value $([convert]::FromBase64String(''ztU0LVr6Q0WC8iLm6vd3PC+zZ+PeiVVDv85h83sYqTe8JIoUDNaJQqCAbtm7okiCRIF1/g0IrkKL2jTtl7ZjlEqwvXRK+WhPi9ZDmAcdqLyGCHNSqlFDQp97J3ZYRlnU'')) -Type ''Binary''"','Set Start visible places')
    )
    $order=1; foreach($entry in $commands) { $sc=Add-Text $fl 'SynchronousCommand' ''; [void](Add-Text $sc 'Order' "$order"); [void](Add-Text $sc 'Description' $entry[1]); [void](Add-Text $sc 'CommandLine' $entry[0]); [void](Add-Text $sc 'RequiresUserInput' 'false'); $order++ }
    $sc=Add-Text $fl 'SynchronousCommand' ''; [void](Add-Text $sc 'Order' "$order"); [void](Add-Text $sc 'Description' 'Start EclipseOS first-logon chain'); [void](Add-Text $sc 'CommandLine' 'cmd /c if exist C:\EclipseOS\firstboot\Start-EclipseFirstLogon.ps1 powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\EclipseOS\firstboot\Start-EclipseFirstLogon.ps1'); [void](Add-Text $sc 'RequiresUserInput' 'false')
    $doc.OuterXml
}
Export-ModuleMember -Function New-EclipseUnattendXml
