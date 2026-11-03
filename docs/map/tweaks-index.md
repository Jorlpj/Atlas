# Tweaks root index

`Configuration/tweaks.yml` includes tweak groups in a fixed sequence. It begins with Networking, Performance, Privacy and QoL, then runs Security, Debloat, Scripts and Misc. The root file says that playbook files run in order and that commenting out an entry disables that YAML file. (`src/playbook/Configuration/tweaks.yml:5-10`, `:19-26`, `:41-48`, `:71-82`, `:136-148`, `:298-306`, `:312-320`, `:329-337`, `:348-356`)

## Group sequence

| Order | Group | Root-file organization |
| --- | --- | --- |
| 1 | Networking | Network settings, followed by three `shares` tasks. LLMNR disable is commented out with a compatibility note. (`src/playbook/Configuration/tweaks.yml:26-36`) |
| 2 | Performance | Main tasks followed by `performance/system`; Game Bar and paging tasks are commented out. (`src/playbook/Configuration/tweaks.yml:48-66`) |
| 3 | Privacy | Main tasks, then `apps`, `advertising`, `cloud` and `telemetry` subgroups. (`src/playbook/Configuration/tweaks.yml:81-131`) |
| 4 | QoL | Main tasks, then `appearance`, `windows-update`, `ease-of-access`, `taskbar`, `explorer`, `security`, `shell`, `startup-shutdown` and `system` subgroups. (`src/playbook/Configuration/tweaks.yml:147-294`) |
| 5 | Security | Two security tasks. (`src/playbook/Configuration/tweaks.yml:298-307`) |
| 6 | Debloat | Five debloat tasks. (`src/playbook/Configuration/tweaks.yml:312-324`) |
| 7 | Scripts | Seven script tasks. (`src/playbook/Configuration/tweaks.yml:329-343`) |
| 8 | Misc | Miscellaneous tasks, with `scripts/script-power.yml` deliberately placed here before the final two miscellaneous tasks. (`src/playbook/Configuration/tweaks.yml:348-365`) |

The root includes a Store-related entry, `qol/disable-store-auto-updates.yml`, and a Windows Update subgroup with entries for feature updates, automatic updates, automatic reboot and Delivery Optimization. These names identify areas for review; the root index alone does not establish their implementation effects. (`src/playbook/Configuration/tweaks.yml:180-188`, `:148-167`)

The `disable-screen-capture-hotkey.yml` task is explicitly conditional on the `remove-snipping-tool` option. No build, edition or architecture condition appears on these root entries; any conditions inside the referenced files require checking those files. (`src/playbook/Configuration/tweaks.yml:167`)
