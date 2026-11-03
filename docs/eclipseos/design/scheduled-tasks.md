# Scheduled tasks design

Status: proposed. The maintainer must accept this default through the orchestrator before it becomes an implementation requirement.

## Atlas today

Atlas disables selected scheduled tasks in its debloat and performance groups. The debloat task disables Program Compatibility Assistant patch database, UCPD velocity, Disk Diagnostic, CEIP, USB CEIP and Usage Data Reporting tasks; it also deletes a Usage Data Reporting maintenance registration. The UCPD velocity task is under `AppxDeploymentClient`, so this is an AppX-servicing-sensitive change to investigate, but the map does not establish an effect on Store installs or updates. ([Atlas map: debloat](../../map/tweaks-debloat.md); `src/playbook/Configuration/tweaks/debloat/disable-scheduled-tasks.yml:2-23`)

The performance group disables the `Power Efficiency Diagnostics\AnalyzeSystem` task and sets the Task Scheduler Maintenance `WakeUp` policy to zero. The Storage Sense task enables monthly cleanup and the `SilentCleanup` task. These actions affect different maintenance functions; a general “disable scheduled tasks” setting would conceal that distinction. ([Atlas map: performance](../../map/tweaks-performance.md); `src/playbook/Configuration/tweaks/performance/disable-sleep-study.yml:1-14`; `src/playbook/Configuration/tweaks/performance/config-automatic-maintenance.yml:1-21`; [Atlas map: debloat](../../map/tweaks-debloat.md); `src/playbook/Configuration/tweaks/debloat/config-storage-sense.yml:2-25`)

Other Atlas features create scheduled work: the LibreWolf updater registers a task for enabled users, taskbar pin configuration registers logon tasks, and upgrades stop tasks that run from Atlas folders before deleting those folders. The source map does not indicate that these are part of the selected-task disable list. ([Atlas map: executables](../../map/executables.md); `src/playbook/Executables/LIBREWOLF.ps1:37-62`; `src/playbook/Executables/SETTABST.ps1:1-24`; `src/playbook/Executables/STOPFOLDERPROC.ps1:16-17,45-46,112-113`)

The inspected upgrade revert removes Explorer folder-description registry values and does not restore scheduled-task state or maintenance policy. The debloat task operations ignore errors, and the mapped actions do not show a saved pre-change state for these tasks. ([Atlas map: debloat](../../map/tweaks-debloat.md); `src/playbook/Configuration/tweaks/debloat/disable-scheduled-tasks.yml:8-23`; `src/playbook/Configuration/atlas/revert.yml:1-36`)

## Lab evidence and limits

The two build 26300 lab runs report Store, Xbox, Windows Update, package and service observations, but their documented checks do not compare scheduled-task state or isolate a task change. The AppxDeploymentClient task is therefore a lead for matched testing, not an established explanation for the lane B Store/Xbox outcome. ([lab comparison](../lab/comparison.md); [problem catalog](../research/problem-catalog.md); [Atlas map: debloat](../../map/tweaks-debloat.md))

## Other playbook choices

The dated 26H2 playbook survey compares servicing, security, package and restore choices but does not report a task-by-task scheduler policy. It cannot support a claim that another playbook’s scheduled-task changes are safe or improve gaming performance. ([26H2 playbook survey](../research/26h2-playbooks.md); [survey scope and limits](../research/26h2-playbooks.md))

## Proposed EclipseOS default

1. **Keep Windows scheduled tasks enabled by default.** Do not apply a broad task-disable list or disable maintenance based on task names alone. Keep Windows servicing, Store/AppX deployment, security intelligence, Defender, driver and device maintenance tasks available unless an isolated test justifies a specific exception.
2. **Treat each optional task as a named feature choice.** Before changing one, record its full task path, trigger, principal, action, supported build, feature dependency and measured reason. Explain the user-visible effect. Do not bundle AppX deployment, diagnostics, compatibility and power maintenance under one privacy or performance switch.
3. **Preserve and restore exact prior state.** Capture whether each affected task was enabled and its settings before applying a change. Provide a supported restore action that returns the captured state, then verify task registration, enabled state and next-run behavior after reboot. Do not assume that setting `Enabled=true` recreates an OEM or user-customized definition.
4. **Keep privacy controls narrow.** If a diagnostic task is considered unnecessary, document which diagnostic signal it produces and what stops working when it is disabled. Prefer a supported Windows privacy control when it achieves the same goal without deleting task registrations or unrelated maintenance state.
5. **Test servicing separately from task health.** For every supported build and install path, record task state before and after setup, then test Windows Update scan and install, Store app install and update, Xbox app and Gaming Services state, Defender intelligence update, Storage Sense behavior, and any opted-out task’s feature. A zero pending-update count does not establish that Store/AppX tasks or scheduled work are healthy.
6. **Avoid performance claims from task counts.** Measure idle CPU, disk activity and game frametimes with matched systems and the same workload before claiming a disabled task reduces latency. Restore the original task state and repeat the measurements.

## Trade-offs and acceptance checks

Leaving scheduled tasks enabled may retain background maintenance and diagnostic activity. Disabling a specific task may reduce a measured activity but can defer maintenance, remove diagnostics, or interfere with servicing. The proposed default favors Windows’ registered maintenance and a reversible, task-specific choice over speculative gains.

For each supported build, compare a clean baseline and the proposed EclipseOS profile. Export the affected task definitions and state, record task history and execution results across reboot and idle, and verify each user-facing feature. Include Store and AppX install/update checks, Windows Update install, Defender intelligence update, and Storage Sense. For any task that EclipseOS disables, demonstrate the stated benefit with a repeatable measurement and restore the exact prior definition and enabled state.
