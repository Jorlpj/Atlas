# EclipseOS prepared media

This tool makes a copy of a supported Windows 11 26H2 ISO (build 26300) or
extracted ISO folder and adds the EclipseOS answer file and payload. It never
services `install.wim` or `boot.wim`. Run it from an elevated Windows
PowerShell 5.1 session because read-only ISO mounting, image metadata access,
and the in-box IMAPI2FS ISO writer use Windows components.

```powershell
.\media\tool\New-EclipseMedia.ps1 -IsoPath C:\ISO\Windows.iso -OutIso C:\ISO\EclipseOS.iso -EngineDir C:\Build\engine
```

`-EngineDir` is optional; if omitted, the tool warns that the engine payload is
absent. The source tree is mounted read-only when `-IsoPath` is used. Use
`-SourceDir` instead for an already extracted ISO, or use `-OutDir` to produce
a folder that can be copied over a stock Rufus USB made without Windows User
Experience options. The tool writes `EclipseOS-media.json` beside the output.
`-SkipImageCheck` is only for the synthetic fixtures in the included test; do
not use it with installation media.

Write the prepared ISO to USB with stock Rufus. Rufus will detect
`sources\$OEM$\$$\Panther\unattend.xml`, so its Windows User Experience
options dialog will not appear; the EclipseOS answer file remains on the USB.
Keep Rufus's TPM/Secure Boot bypass and silent disk erase options off if the
dialog is presented for a different source. Boot the USB and install Windows.

Keep the network unplugged during OOBE if Windows still asks for a Microsoft
account. Connect after the desktop appears so Windows Update and Store can
finish updating before the EclipseOS first-logon chain proceeds.
