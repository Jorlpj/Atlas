# Security tweaks

The security section runs two tasks in order after its status message: block anonymous SAM account enumeration, then disable Remote Assistance. The call site shows no build, edition, or architecture condition for either task. (`src/playbook/Configuration/tweaks.yml:298-307`)

## Actions

| Task | Effects and conditions |
| --- | --- |
| `block-anonymous-enum-sam.yml` | Sets `HKLM\SYSTEM\CurrentControlSet\Control\Lsa\RestrictAnonymousSAM` to DWORD `1`. No task-level condition is shown. (`src/playbook/Configuration/tweaks/security/block-anonymous-enum-sam.yml:1-10`) |
| `disable-remote-assistance.yml` | Sets `HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance\fAllowFullControl` and `fAllowToGetHelp` to DWORD `0`, then disables the Windows Firewall rule group named `Remote Assistance`. No task-level condition is shown. (`src/playbook/Configuration/tweaks/security/disable-remote-assistance.yml:1-15`) |

## Revert and servicing notes

The inspected upgrade-time `revert.yml` deletes Explorer `ThisPCPolicy` values; it does not restore either registry setting or re-enable the Remote Assistance firewall rule group. A repository search found no other matching reset for these values or rule group. (`src/playbook/Configuration/atlas/revert.yml:1-36`, `src/playbook/Configuration/tweaks/security/block-anonymous-enum-sam.yml:6-10`, `src/playbook/Configuration/tweaks/security/disable-remote-assistance.yml:5-15`)

These tasks change LSA and Remote Assistance firewall settings. They do not directly change Store, Xbox, AppX packages, or Windows Update servicing. (`src/playbook/Configuration/tweaks/security/block-anonymous-enum-sam.yml:6-10`, `src/playbook/Configuration/tweaks/security/disable-remote-assistance.yml:5-15`)
