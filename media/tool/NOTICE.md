# Rufus attribution

`EclipseUnattend.psm1` ports selected Windows Setup answer-file behavior from
Rufus v4.15 `src/wue.c`, Copyright (C) Pete Batard. Rufus and this derived
portion are licensed under GPL-3.0. The EclipseOS-specific AutoLogon and
first-logon launcher are additions. EclipseOS deliberately uses the Windows
time-zone ID from `(Get-TimeZone).Id` instead of Rufus's localized
`StandardName`; Windows Setup expects the ID and localized names vary by host.
Rufus source: <https://github.com/pbatard/rufus/blob/v4.15/src/wue.c>.
