# Rufus "Windows User Experience" (WUE) - what the chosen options write

Researched 2026-11-03. Source of truth: Rufus tag v4.15 (released 2026.06.30, ChangeLog.txt:1). Latest tag seen is
v4.16_BETA. Abbreviations: W = https://github.com/pbatard/rufus/blob/v4.15/src/wue.c ; H = .../v4.15/src/rufus.h ;
CL = .../v4.15/ChangeLog.txt ; L = .../v4.15/res/loc/rufus.loc ; FAQ = https://github.com/pbatard/rufus/wiki/FAQ.
`[S]` = sourced from code/docs. `[I]` = my inference, not verified by a run. No Rufus code was executed.

## (a) Option table

Flags: H:687-710 (QOL 0x1000, SKUSIPOLICY 0x400, CA2023 0x200, BITLOCKER 0x80, SET_USER 0x40, LOCALE 0x20,
NO_DATA 0x8, NO_ONLINE 0x4, TPM 0x1, SILENT 0x800). With your selection no flag is in UNATTEND_WINPE_SETUP_MASK
(TPM|SILENT, H:703), so the generated answer file has NO windowsPE pass. It has specialize + oobeSystem only.

| Option | State | Pass | What it writes (exact) | Source / introduced |
|---|---|---|---|---|
| Remove 4GB RAM/SB/TPM requirement | OFF | windowsPE (if ON) | If ON: 3x `reg add HKLM\SYSTEM\Setup\LabConfig /v BypassTPMCheck / BypassSecureBootCheck / BypassRAMCheck /t REG_DWORD /d 1 /f`, written offline into boot.wim index 2 SYSTEM hive (fallback: RunSynchronous in Autounattend.xml). Also renames `sources\appraiserres.dll` to a backup + empty placeholder and installs a `setup.exe` wrapper (build >= 26000). OFF = none of this | W:45, W:235-251, W:1154-1205, W:1237-1306; CL: 3.19 (dialog), 3.20 (offline hive), 4.6 (setup.exe wrapper) |
| Remove online MS account requirement | ON | specialize (`Microsoft-Windows-Deployment`, RunSynchronous order 1) | `reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f`. Comment says picked from AveYo MediaCreationTool.bat. INCOMPATIBLE with S-Mode | W:266-275; CL 3.19, 3.20 (no longer needs TPM option) |
| Create local account "User" | ON | oobeSystem (`Microsoft-Windows-Shell-Setup`) + FirstLogonCommands | `<UserAccounts><LocalAccounts><LocalAccount>`: Name=DisplayName=`User`, Group `Administrators;Power Users`, Password Value `UABhAHMAcwB3AG8AcgBkAA==` PlainText=false (= empty password, see (b)). FirstLogon: `net user "User" /logonpasswordchg:yes` then `net accounts /maxpwage:unlimited` | W:337-382; CL 3.20, 3.21 (arbitrary name), 4.6 (no expiry), 4.12 (char filter), 4.14 (whitespace), 4.15 (username validation) |
| Regional options same as this user | ON | oobeSystem (`Microsoft-Windows-International-Core`) + TimeZone in Shell-Setup | `InputLocale` (HKCU Keyboard Layout\Preload\1), `SystemLocale`, `UserLocale`, `UILanguage`, `UILanguageFallback` (HKLM ...\Nls\Language\InstallLanguageFallback) copied from the PC running Rufus; `<TimeZone>` from host `StandardName` | W:331-336 (TZ), W:459-476 (locale); CL 3.20, 4.6 (TimeZone) |
| Disable data collection | ON | oobeSystem `<OOBE>` | `<HideEULAPage>true</HideEULAPage>` and `<ProtectYourPC>3</ProtectYourPC>` (3 = no recommended settings / all privacy answers "off"). `HideOnlineAccountScreens` and `HideWirelessSetupInOOBE` only with Silent install (OFF here) | W:318-331; CL 3.19 |
| SILENTLY erase disk and install | OFF | windowsPE (if ON) | If ON: auto-partitions Disk 0 (EFI 260 MB, MSR 16, NTFS C:), InstallTo disk 0 part 3, WillShowUI OnError, labels USB part 2 `RUFUS_BOOT`, and forces the Autounattend.xml-in-boot.wim route. OFF = nothing | W:153-225; CL 4.14, 4.15 (fix 75% failure) |
| Disable BitLocker auto device encryption | ON | oobeSystem | `Microsoft-Windows-SecureStartup-FilterDriver` `<PreventDeviceEncryption>true</PreventDeviceEncryption>` and `Microsoft-Windows-EnhancedStorage-Adm` `<TCGSecurityActivationDisabled>1</TCGSecurityActivationDisabled>`. (`DisableEncryptedDiskProvisioning` only with Silent, W:158-159) | W:477-491; CL 3.22 |
| QoL improvements | ON | specialize RunSynchronous + oobeSystem FirstLogonCommands | Full list in (a2) below | W:276-294, W:400-447; CL 4.14; FAQ section "What Windows features does Rufus QoL option enable/disable exactly" |
| Windows CA 2023 signed bootloaders | OFF | none (media edit) | If ON: extracts `EFI_EX`/`Fonts_EX` from boot.wim idx 2 and overwrites `\efi\boot\boot*.efi`, `\bootmgr.efi`, `\efi\microsoft\boot\*` fonts on the USB. Needs target PC with "Windows UEFI CA 2023" in DB. OFF = original 2011-signed files | W:1058, W:1345-1410; CL 4.10, 4.11; L:614 |
| Apply SkuSiPolicy.p7b | OFF | oobeSystem FirstLogon (if ON) | If ON: `cmd /c mountvol S: /S && copy %WINDIR%\system32\SecureBootUpdates\SkuSiPolicy.p7b S:\EFI\Microsoft\Boot && mountvol S: /D` (uses the INSTALLED system's copy, not the host's) | W:385-399; CL 4.14; L:566-567 (text "See KB5042562") |

### (a2) QoL: complete list `[S]` (W:276-294 specialize, runs as SYSTEM; W:400-447 first logon)
Specialize pass (machine-wide, before first logon):
- `HKLM\Software\Policies\Microsoft\Windows\OneDrive\DisableFileSyncNGSC = 1` (DWORD). FAQ: restore by setting it to 0.
- PowerShell: delete `%SystemRoot%\System32\OneDriveSetup.exe` and `SysWOW64\OneDriveSetup.exe`.
- PowerShell: `Remove-AppxProvisionedPackage` + `Remove-AppxPackage -AllUsers` for any package matching `*Outlook*`
  and `*Teams*` (wildcards; note they match by name substring).
First-logon pass (FirstLogonCommands, run in the new user's session, so every HKCU value below lands in the HKCU of
the first account that logs on, i.e. "User" `[I]`; not in the Default profile):
- `HKLM\System\CurrentControlSet\Control\Session Manager\Power\HiberbootEnabled = 0` (Fast Startup off).
- `HKCU\...\Explorer\Advanced\ShowCopilotButton = 0`; `HKLM\Software\Policies\Microsoft\Windows\WindowsCopilot\TurnOffWindowsCopilot = 1`.
- `HKCU\...\Search\SearchboxTaskbarMode = 1` and `SearchboxTaskbarModeCache = 1` (search as icon); `HKCU\...\Search\BingSearchEnabled = 0`.
- `HKLM\Software\Policies\Microsoft\Windows\CloudContent\DisableWindowsConsumerFeatures = 1` and `DisableCloudOptimizedContent = 1`.
- `HKCU\...\ContentDeliveryManager\SystemPaneSuggestionsEnabled = 0`.
- `HKLM\Software\Policies\Microsoft\Dsh\AllowNewsAndInterests = 0`; `HKLM\Software\Policies\Microsoft\Windows\Windows Feeds\EnableFeeds = 0`.
- `HKLM\Software\Microsoft\Windows\CurrentVersion\Communications\ConfigureChatAutoInstall = 0`.
- `HKLM\Software\Policies\Microsoft\Edge\HideFirstRunExperience = 1`.
- `HKCU\...\Explorer\Advanced\Start_Layout = 1` (more pins) and PowerShell `Set-ItemProperty HKCU\...\CurrentVersion\Start VisiblePlaces` = fixed binary
  (Documents, Downloads, Network, Personal Folder, File Explorer, Settings next to the Start power button).
All are DWORD via `reg add ... /f`. The log line in Rufus prints each "• QoL" item (W:278, W:400, W:422 region).
Windows-Phone-Link side effects were reported by a user (issue 3038, comment on 26H2 losing phone auto-hotspot) `[S]`
https://github.com/pbatard/rufus/issues/3038 (user claim, not confirmed by Rufus maintainer).

### File location on the USB `[S]`
- With a windowsPE section (TPM bypass or Silent): `Autounattend.xml` at the ROOT of boot.wim index 2 (W:1312-1322).
- Without it (YOUR case): copied to `<USB>:\sources\$OEM$\$$\Panther\unattend.xml`, which Setup copies to
  `%WINDIR%\Panther\unattend.xml` (W:1323-1337; Rufus issue 1981 cited in the comment). Not at the USB root.
- boot.wim is opened for write only if windowsPE data exists or CA 2023 is ON (W:1216). With your choices boot.wim and
  install.wim are NOT modified, no `appraiserres.dll` rename, no `setup.exe` wrapper (those are inside the
  `flags & UNATTEND_WINPE_SETUP_MASK` branch, W:1154-1205). install.wim is never touched by any option. `[S]`
- Rufus 4.5 refuses to show WUE when an `unattend.xml` already exists in the ISO (CL, "Don't display the WUE dialog
  when a conflicting 'unattend.xml' already exists").

## (b) Local account section
- Name `User`; reserved names rejected (Administrator and localized variants, Guest, DefaultAccount, WDAGUtilityAccount,
  etc., W:112-117, W:341-343). Invalid chars replaced by `_` (issue 3057 "periods replaced by underscores",
  https://github.com/pbatard/rufus/issues/3057; issue 2991 `&` broke XML, fixed). `[S]`
- Group: `Administrators;Power Users` (W:362). So "User" is a full local administrator, not a standard user. `[S]`
- Password: empty. The Base64 value is the UTF-16 string "Password", which is the unattend convention for an empty
  password (W:363-371; comment says empty password is chosen to allow "automated logon during setup"). `[S]`
- Change at first logon: `net user "User" /logonpasswordchg:yes` (W:378). Comment: "we'll ask the user to change it at
  next logon". CL 3.20: "empty password that the user will be prompted to change after first reboot". `[S]`
  Behaviour of that prompt with an empty password, and whether Windows lets you keep it empty, is not covered in
  Rufus sources. `[I]` unverified.
- Expiry: after the command above, `net accounts /maxpwage:unlimited` is applied machine-wide (W:380-382, CL 4.6)
  because `/logonpasswordchg` may reset expiry to 90 days. This is a global SAM policy change, not only for "User". `[S]`
- Autologon: Rufus writes NO `<AutoLogon>` element (grep of W). The first logon happens during OOBE to run
  FirstLogonCommands; persistent autologon is not configured. `[S]` for "no AutoLogon element"; behaviour after OOBE `[I]`.
- Local-account creation is by UserAccounts (supported unattend), the comment at W:355-356 says this also makes 22H2 skip
  MSA even with network connected. Whether that still holds on 26H2: not verified. `[I]`
- BypassNRO on 24H2/25H2: Microsoft Insider notes announced removal of "known mechanisms" (OOBE\BYPASSNRO) in build
  26220.6772 (Oct 2025) https://blogs.windows.com/windows-insider/2025/10/06/announcing-windows-11-insider-preview-build-26220-6772-dev-channel/ ;
  maintainer's position in https://github.com/pbatard/rufus/issues/2810 and /2844: the registry value
  `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE\BypassNRO` still works on retail 25H2, but the network MUST be
  disconnected (setup then offers a local account). He tested 25H2 with Rufus 4.10 BETA successfully. `[S]` (maintainer's
  own test, no 26H2/26300 test found).
- Converting later to an MSA: maintainer will not support; he says a pure Windows issue
  https://github.com/pbatard/rufus/issues/2983 , /3054 (closed, no log).

## (c) Known issues on recent builds (searched issues up to 2026-11-02)
- No open or closed Rufus issue found mentioning build 26300 / 26H2 breakage of the local account, BypassNRO or QoL. Only
  26200 (25H2) data points exist. 26300 behaviour is UNVERIFIED. `[S]` absence of evidence, searched titles/bodies via gh.
- Issue 3059 (closed): "Windows cannot parse or process the unattended installation answer file for the [specialize] pass"
  with Rufus WUE + username `USER` on a laptop; maintainer guessed modified ISO or conflicting unattend; no log, no cause.
  https://github.com/pbatard/rufus/issues/3059 . Relevant because your set uses specialize (BypassNRO + QoL).
- Issue 3016 (closed): WUE dialog not shown on 25H2 v2 ISO when WIM XML cannot be parsed (corrupted/unofficial ISO).
  https://github.com/pbatard/rufus/issues/3016
- Issue 2974/2950 (closed): reserved/localized "Administrador" and leading spaces in account name broke login; fixed in 4.12-4.15.
- Issue 2960 / CL 4.15: silent install failing at 75% (not your case, Silent OFF).
- Issue 2919 (closed): 0xc0000428 winload.efi on media boot; maintainer blamed UUP ISOs; fully-updated CA-2023 PCs
  rejecting 2011 media is the context. https://github.com/pbatard/rufus/issues/2919 , https://github.com/pbatard/rufus/issues/3062
- Issue 2244 (open): Rufus warns when source bootloaders are revoked (DBX / SkuSiPolicy list).
  https://github.com/pbatard/rufus/issues/2244
- Microsoft Store / Xbox / Windows Update / Defender-Tamper / VBS-HVCI / anti-cheat: searching the tracker for these terms
  returned no Rufus issue about the WUE options causing them. Nothing sourced. The only Rufus-related Secure Boot/VBS
  coupling is the TPM/SB bypass (OFF for you, so Secure Boot/TPM requirements are left intact) and BitLocker below.
- Windows CA 2023 (what it is): `Windows UEFI CA 2023` replaces `Windows Production PCA 2011`, which signs the Windows boot
  loader; PCA 2011 expires 2026-10-19, KEK CA 2011 2026-06-24, UEFI CA 2011 2026-06-27. Microsoft says unupdated devices
  keep booting and installing updates, they just stop getting new boot-level protections.
  https://support.microsoft.com/en-us/servicing/os/secure-boot/2025/06/windows-secure-boot-certificate-expiration-and-ca-updates
  Rufus option: media boots only on PCs whose DB already has "Windows UEFI CA 2023" (W:1400-1407; L:614 "Requires a
  compatible target PC"; FAQ: Rufus 4.10+, Windows 11 25H2+ ISO, CL 4.10). Leaving it OFF: `[I]` correct if the Secure
  Boot-on target is a PC that might not yet have the 2023 DB entry or the ISO is not a 25H2/26H2 image with `_EX`
  files; it boots with 2011-signed files, which a 2026 PC keeps trusting until/unless PCA 2011 is revoked in DBX.
  Turning it ON is right only if the machine has been moved to the 2023 DB (or the firmware revoked PCA 2011).
  The 26300 ISO has not been checked for `EFI_EX`; Rufus logs "Could not extract 2023 signed UEFI bootloaders - Ignoring
  option" if absent (W:1360).
- SkuSiPolicy (KB5042562): Microsoft guidance says once the UEFI-lock mitigations apply, the policy must not be removed
  and external boot media must carry updates >= 2024-08-13 plus the signed `SkuSiPolicy.p7b`; this is revocation of old boot
  managers (BlackLotus family) by version. Secondary summary: https://www.elevenforum.com/t/kb5042562-guidance-for-blocking-rollback-of-virtualization-based-security-vbs-related-security-updates/ ;
  Microsoft KB page text itself not re-fetched, so verify at https://support.microsoft.com/kb/5042562 . Note KB5042562 is
  titled as VBS rollback blocking in third-party mirrors; Rufus links it for the boot-manager revocation part. `[S]` (Rufus
  code comment W:386-391 cites it). Rufus copies the policy to the installed ESP in FirstLogon, using the installed
  system's file to avoid 0xc0000428 on a system not yet fully patched (W:388-391). Leaving it OFF = no revocation
  enforced by this path; irreversibility on the installed system `[I]` from the KB wording. OFF is the safe choice
  for a dual-boot/rescue USB use and for a fresh install that will update anyway. `[I]`
- BitLocker: PreventDeviceEncryption is the documented `Microsoft-Windows-SecureStartup-FilterDriver` setting; it only
  stops automatic device encryption at first logon. It does not remove BitLocker, and manual enable stays possible. `[S]` W:477-491
  (docs semantic: `[I]`, from Microsoft's component name). Open feature request about Windows To Go (not your case):
  https://github.com/pbatard/rufus/issues/2877

## (d) Implications for a post-install playbook (AME .apbx) run after this install
All items are `[I]` unless a Rufus line is cited. None have been run.
1. Empty password on an administrator account named User, "must change at next logon". Playbooks or AME steps that
   require a password (AME Wizard needs the user to be admin; some Atlas steps use `runas`/schtasks with credentials; Windows
   Hello / PIN setup; RDP/network logon refuses empty passwords by default) can fail until the first-logon password
   prompt is resolved. Decide whether the playbook should keep the password-less account (Atlas/EclipseOS assume
   a local account without password per CLAUDE.md), because `logonpasswordchg:yes` conflicts with that: the first logon
   asks to set a password. A playbook that runs before the first logon change must not depend on it. Check this on the VM.
2. `net accounts /maxpwage:unlimited` (machine-wide) will match any playbook password-policy edit; no conflict, but a
   playbook that resets `net accounts` or Local Security Policy would undo it.
3. Duplicates: the playbook probably also disables Fast Startup (`HiberbootEnabled`), Copilot (`TurnOffWindowsCopilot`,
   `ShowCopilotButton`), OneDrive (`DisableFileSyncNGSC` + removal), consumer features (`DisableWindowsConsumerFeatures`),
   Widgets/News (`AllowNewsAndInterests`, `EnableFeeds`), Teams/Chat (`ConfigureChatAutoInstall`), Edge first run, Bing
   search, SystemPaneSuggestions, Start_Layout/VisiblePlaces. Rufus writes the same keys; idempotent when values match.
   Conflict only where a playbook wants OPPOSITE values (e.g. re-enable Fast Startup, keep OneDrive, restore Outlook or
   Teams). Reverting requires Rufus's values being overwritten, and the policy keys under `HKLM\Software\Policies` are
   not removed by a "default" playbook state.
4. `Remove-AppxProvisionedPackage` / `Remove-AppxPackage -AllUsers` for `*Outlook*` and `*Teams*` run at specialize.
   Because they match by substring, they can also remove other packages whose name contains "Teams" or "Outlook" (e.g.
   "MicrosoftTeams", "OutlookForWindows", also possibly "MSTeams"). They do not match Store, Xbox, GamingApp or Defender
   packages, so STORE-XBOX is not directly hit `[S]` (W:284-293). OneDriveSetup.exe is deleted from System32/SysWOW64, so any
   playbook or "restore" step that expects OneDriveSetup.exe will fail. After a Windows servicing cycle, the policy
   `DisableFileSyncNGSC` is still honored.
5. HKCU values from QoL apply only to the first-logon profile, not the Default profile; a playbook that creates new users or
   edits `Default` hive does not inherit them. If the playbook runs under a different account than "User", those HKCU
   tweaks will not be visible to it.
6. BypassNRO: in a post-install context it only influences OOBE; harmless afterwards. A playbook that re-checks OOBE
   or sets `OOBE\BypassNRO` again is a duplicate. `ProtectYourPC=3` and `HideEULAPage` mean Windows telemetry-related
   OOBE answers (diagnostic data "required only" style, location, tailored experiences, find my device, ads ID) are
   off at first boot; a playbook that assumes defaults (e.g. toggles them "back on" or verifies they are on) will see them off. The
   exact mapping of 3 to individual settings was not checked.
7. PreventDeviceEncryption + TCGSecurityActivationDisabled: BitLocker/device encryption off. Playbooks that require
   TPM/BitLocker or Device Encryption (e.g. Windows Update for some builds, Defender features, "Device encryption" checks)
   are unaffected; anything that later enables BitLocker will still work.
8. Updating before the playbook (maintainer rule): Rufus customization does not touch Store/WU components. Applying the
   playbook after WU+Store update is unaffected by these options. The only first-boot network side effect is
   `BypassNRO` needing the NIC disconnected to see the local-account page; if the NIC is connected, the account created by
   `LocalAccount` should still be used `[I]`, but if setup asks for an MSA, disconnect and retry.
9. Secure Boot/TPM/VBS/anti-cheat: with the bypass OFF, no `LabConfig` keys exist in the installed system (they are set only
   in the WinPE registry, never in the installed one) `[S]` W:1262-1278 modifies boot.wim's SYSTEM hive only. Install media
   keeps the original security posture; VBS/HVCI, Secure Boot, TPM 2.0 state are untouched by Rufus. 
10. Not verified: whether the 26300 ISO shows the "local account" OOBE page with BypassNRO + a LocalAccount unattend; 
    whether `Start_Layout`/`VisiblePlaces`/search keys still take effect on 26H2 UI; behaviour of `logonpasswordchg` with an
    empty password. Recommend one VM run of the exact USB with the log (Rufus log button) saved, which the
    maintainer asks for in all issues.
