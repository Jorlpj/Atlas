# Defender and Tamper Protection design

Status: proposed. The maintainer must accept this default through the orchestrator before it becomes an implementation requirement.

## Atlas today

Atlas exposes a `defender-disable` option that installs NoDefender and NoTelemetry packages; for ISO injection it also deletes the offline `WdBoot` service key. `defender-enable` installs NoTelemetry and uninstalls NoDefender. These are separate package actions, and the configuration does not show automatic restoration of Defender preferences such as Tamper Protection, cloud protection, or sample submission. (`src/playbook/Configuration/atlas/components.yml:36-61`; [Atlas map: components](../../map/components.md))

Independently of that option, `components.yml` deletes the SecurityHealth startup value and sets Smart App Control's `VerifiedAndReputablePolicyState` to `0`. These changes do not mean Defender Antivirus itself was removed. The Defender design should keep SecurityHealth visibility, Defender protection, and Smart App Control as distinct settings. (`src/playbook/Configuration/atlas/components.yml:6-15`; [Atlas map: components](../../map/components.md))

Atlas's UI wrapper offers disable and enable actions for the NoDefender package; its enable path tells the user to review Windows Security settings after restarting. That instruction does not establish that every protection preference is automatically restored. (`src/playbook/Executables/AtlasModules/Scripts/ScriptWrappers/ToggleDefender.ps1:74-85`; [Atlas map: components](../../map/components.md))

## Lab evidence and limits

In the first EclipseOS lane, the AME `DefenderToggled` prerequisite required the operator to turn off four Defender controls. The check records Tamper Protection, cloud protection (MAPS), and sample submission still off in the later checkpoints; there is no recorded step that re-enabled them. This is an observation from that run, not a claim that all Atlas installations change those preferences. ([problem catalog G03](../research/problem-catalog.md); [lane A](../lab/lane-a.md))

The lane's full-default run also reports a Defender definition update installed through Windows Update after application. That run did not compare malware-detection outcomes, performance, or every Defender preference. ([problem catalog G10](../research/problem-catalog.md); [lane A](../lab/lane-a.md))

## Other playbook choices

The dated 26H2 survey says Chamber kept Defender and dropped its Defender-off option for build 26300, while ReviOS 26.10 disabled Defender by default and SynergyOS 1.7 offered permanent removal. These repository and vendor descriptions are comparative design leads, not comparable security tests. ([26H2 playbook survey](../research/26h2-playbooks.md#comparison); [survey scope and limits](../research/26h2-playbooks.md))

## Proposed EclipseOS default

1. **Keep Microsoft Defender Antivirus installed and active.** Do not remove it, install a NoDefender package, or disable real-time and behavior monitoring by default. Microsoft's current Windows guidance describes always-on protection as using real-time protection, behavior monitoring, and heuristics; it warns that disabling real-time protection drastically reduces protection. ([Microsoft: always-on protection](https://learn.microsoft.com/en-us/defender-endpoint/configure-real-time-protection-microsoft-defender-antivirus))
2. **Enable Tamper Protection and verify its state after setup.** Microsoft documents that, when enabled, protected settings include real-time protection, behavior monitoring, cloud protection, security-intelligence updates, and automatic actions on detected threats; registry attempts to change protected Defender settings are blocked. Verify the resulting state rather than treating a successful-looking policy or registry write as proof. ([Microsoft: Tamper Protection overview](https://learn.microsoft.com/en-us/defender-endpoint/tamper-protection-overview))
3. **Do not trade broad protection for assumed game performance.** Ship with no broad path, extension, or process exclusions. If a user reports a specific, reproducible conflict, let them add a narrow game-library folder exclusion with an explanation of its scope and removal path. Microsoft's guidance says exclusions reduce protection and recommends using them sparingly for a demonstrated problem; an exclusion can also affect scanning and some protection features. ([Microsoft: Defender exclusions](https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-antivirus-exclusions-overview))
4. **Keep the controls visible and recoverable.** Keep the Windows Security app available and its notification icon visible by default; Atlas's separate `SecurityHealth` change deletes a startup Run value, not the app itself. Do not silently leave protection controls off after install. If a future supported diagnostic or game mode changes a protected setting, show the exact change, restore it at the end of the mode, and verify state after reboot. The lab's G03 observation makes this a concrete acceptance check. (`src/playbook/Configuration/atlas/components.yml:6-7`)
5. **Preserve security updates.** Keep Defender security-intelligence updates available through the Windows servicing design, and verify both Windows Update and Defender's reported intelligence version after reboot. The lab records one successful definition update but does not establish continuing update health across builds. ([Windows Update design](windows-update.md); [problem catalog G10](../research/problem-catalog.md))
6. **Keep Smart App Control and the SecurityHealth tray decision separate.** Decide and test Smart App Control independently from Defender Antivirus. Keep the Windows Security notification surface available by default so users can see protection status; any opt-out should be an explicit UI preference and must not disable the underlying protection. The Atlas map documents these as separate actions. ([Atlas map: components](../../map/components.md))

## Trade-offs and acceptance checks

Keeping the built-in antivirus and its protections may use CPU and storage during scans, and a narrow exclusion can reduce scanning of selected game files. Exclusions also create a protection gap; do not add them speculatively. These defaults favor visible protection and an understandable recovery path over an unmeasured performance gain.

For every supported build and install path, record Defender service and package presence, `Get-MpComputerStatus` values for `IsTamperProtected` and `RealTimeProtectionEnabled`, configured behavior/cloud/sample-submission values, Smart App Control state, SecurityHealth notification visibility, and the Defender intelligence version before and after reboot. Confirm Windows Update installs a Defender intelligence update, then repeat the same checks after applying EclipseOS. Test any proposed game exclusion with a specific title and compare launch/load behavior while confirming the exclusion is narrow and removable. Do not claim a security or performance outcome from package presence alone.
