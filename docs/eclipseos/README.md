# EclipseOS

EclipseOS is the planned Atlas-based Windows 11 successor. This directory records the current evidence, proposed defaults, and open compatibility work. Design pages are proposals; a decision remains proposed until the maintainer accepts it through the orchestrator.

## Reading order

1. Read the [lab method](lab/method.md) for the test environment and the limits of the two runs.
2. Read the [lab comparison](lab/comparison.md), then [lane A](lab/lane-a.md) and [lane B](lab/lane-b.md) for their individual observations. The runs used Windows 11 26H2 build 26300.9457, later updated to 26300.9711; they do not isolate update order as the cause of every difference.
3. Read the [problem catalog](research/problem-catalog.md) for graded reports, lab findings and evidence limits. Use the [26H2 playbook survey](research/26h2-playbooks.md) and [APBX comparison](research/apbx-comparison.md) as comparative inputs; neither establishes compatibility by itself.
4. Read the design pages below for Atlas behavior, lab evidence, trade-offs and proposed defaults. Check cited map pages for Atlas source details.
5. Consult [decisions](decisions/README.md) for the acceptance status of proposed defaults.

## Design pages

- [Store, AppX and Xbox](design/store-appx-xbox.md)
- [Windows Update](design/windows-update.md)
- [Defender and Tamper Protection](design/defender-tamper.md)
- [VBS, HVCI and mitigations](design/vbs-hvci.md)
- [Services](design/services.md)
- [Scheduled tasks](design/scheduled-tasks.md)
- [Privacy and telemetry](design/privacy-telemetry.md)
- [Power and latency](design/power-latency.md)
- [Network](design/network.md)
- [Shell and UI](design/shell-ui.md)
- [Account model](design/account-model.md)
- [Install method](design/install-method.md)
- [Revert and recovery](design/revert.md)
- [Browser and WebView2](design/browser-webview2.md)

The [revert and recovery](design/revert.md) page defines proposed coverage and its acceptance checks.

## Constraints to preserve

- **Store, Xbox and AppX servicing:** update Windows and Microsoft Store fully, then reboot, before applying the playbook. Keep Store, Xbox, Gaming Services and Store installs working. A Windows Update scan with no pending updates is not a substitute for checking Store readiness. The current lab comparison is a compatibility signal, not a controlled causal result.
- **Identity:** use a local Windows account without a password and do not require a Microsoft account. Validate free Store installs and Gaming Services without signing in. Xbox, Microsoft account and Game Pass sign-in are outside the current lab test scope.
- **Security and anti-cheat:** keep TPM 2.0, Secure Boot, VBS and HVCI on by default; make aggressive cuts explicit options. Anti-cheat requirements vary by product and may change, so validate supported titles and devices.
- **Brand and license:** retain GPL-3.0 licensing, credit Atlas-OS, and do not use the Atlas name or logo as the EclipseOS brand.

These constraints reflect the maintainer's stated goals and current lab scope; they are not claims that every proposed design has been implemented or accepted.




