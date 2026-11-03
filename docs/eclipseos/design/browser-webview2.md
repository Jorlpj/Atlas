# Browser and WebView2 design

Status: proposed. The maintainer must accept this default through the orchestrator before it becomes an implementation requirement.

## Atlas today

Atlas offers a radio choice to install Brave, Firefox, LibreWolf, or Chrome. The scripts install the selected browser; the LibreWolf script also sets up its updater, a per-user scheduled task, and shortcuts. (`src/playbook/playbook.conf:141-170`; `src/playbook/Configuration/atlas/start.yml:61-93`; `src/playbook/Executables/SOFTWARE.ps1:39-91`; `src/playbook/Executables/LIBREWOLF.ps1:14-62`; [Atlas map: start](../../map/start.md))

Separately, `uninstall-edge` runs an elevated Edge removal wrapper, removes the legacy Edge AppX family when present, and adds Edge package names to the AppX deprovisioned list. The wrapper has a distinct `-InstallWebView` path that downloads and installs the Evergreen WebView2 Runtime. The configuration does not call that install path during Edge removal. (`src/playbook/Configuration/atlas/components.yml:17-29`; `src/playbook/Executables/AtlasModules/Scripts/ScriptWrappers/RemoveEdge.ps1:248-272,351-390`; [Atlas map: components](../../map/components.md))

The cited Atlas revert task has no Edge or browser restoration action. Browser installation and Edge removal are therefore not automatically reversed by that task; this does not establish that users cannot reinstall them by other means. (`src/playbook/Configuration/atlas/revert.yml:1-36`; [Atlas map: start](../../map/start.md); [Atlas map: components](../../map/components.md))

## Lab evidence and limits

In lane A, the `uninstall-edge` run removed `msedge.exe` while the WebView2 Runtime remained installed. The later Xbox sign-in button opened a `gamingservicestcui` window, but the lab did not observe an `msedgewebview2` process within 30 seconds. The sign-in flow was outside the test scope, so this does not show whether Xbox, Widgets, or any specific launcher depends on WebView2. ([problem catalog G12](../research/problem-catalog.md); [lane A](../lab/lane-a.md))

The research catalog records Microsoft's documented requirement that WebView2 apps need a Runtime and that blocked initialization can prevent embedded content from loading. It leaves dependencies for named apps unverified. ([problem catalog F08](../research/problem-catalog.md))

## Other playbook choices

The dated playbook survey lists Edge as removed by default for ReviOS 26.10 and SynergyOS 1.7, and removed for AME 11 / Privacy+ 0.8.3. The survey does not establish those projects' WebView2 runtime state or app-by-app compatibility. Treat these as configuration choices only, not evidence that Edge removal is harmless. ([26H2 playbook survey](../research/26h2-playbooks.md#comparison); [survey scope and limits](../research/26h2-playbooks.md))

## Proposed EclipseOS default

1. **Keep the Edge browser and WebView2 Runtime available by default.** Treat the browser and runtime as distinct components. Microsoft documents that WebView2 is an app-facing runtime rather than a user-visible browser, and that Edge can be uninstalled without stopping WebView2. ([Microsoft: WebView2 end-user FAQ](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/end-user-faq); [Microsoft: Evergreen vs. fixed version](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/evergreen-vs-fixed-version))
2. **Make optional browser installation explicit.** Offer browser choices in a user-visible step and describe which one is being installed. Do not silently remove the user's existing browser profile or data. Any browser-removal option should be separate, opt-in, and paired with a supported reinstall path.
3. **Do not remove WebView2 as a debloat action.** Most Windows 11 devices include the Evergreen Runtime, but Microsoft says apps should check its availability and handle missing-runtime cases. Evergreen is shared by apps and receives automatic updates; removing it can affect any app that requires it. ([Microsoft: WebView2 distribution](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/distribution); [Microsoft: Evergreen vs. fixed version](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/evergreen-vs-fixed-version))
4. **Do not infer named app dependencies.** Before publishing compatibility claims for Store, Xbox, Widgets, game launchers, or setup tools, identify which ones actually initialize WebView2 in supported builds and test their documented flows. A process not observed during one lab action is not proof that an app never uses the runtime.
5. **Keep runtime servicing healthy.** Prefer the Evergreen Runtime for a consumer desktop and verify that it is installed and can update. Microsoft's distribution guidance describes Evergreen as shared across apps and updated automatically; a Fixed Version runtime instead requires the app distributor to manage updates. ([Microsoft: Evergreen vs. fixed version](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/evergreen-vs-fixed-version))

## Trade-offs and acceptance checks

Keeping Edge costs disk space and retains a user-visible browser; removing it may reduce the installed browser surface, but the lab and source review do not establish a security or performance benefit for EclipseOS. Keeping WebView2 supports applications that require its embedded web platform, while Evergreen servicing means those applications consume a shared, automatically updated runtime.

On each supported build and install method, record Edge and WebView2 Runtime presence and versions before and after setup and reboot. If an opt-in Edge removal is offered, verify the Runtime remains installed, launches, and updates; confirm the Edge browser can be reinstalled without restoring or overwriting user data. Test only named app flows with evidence of a WebView2 requirement, and record app-specific failures without generalizing them. Verify Store installs and Xbox launch/sign-in separately, since the current lab does not establish those dependencies. Check that the documented revert or reinstall path restores each browser component changed by the installer.
