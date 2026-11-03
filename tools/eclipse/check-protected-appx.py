#!/usr/bin/env python3
"""Static guard: no playbook removal or deprovision rule may match a protected package family.

EclipseOS keeps Store, Xbox, Gaming Services, their frameworks and WebView2. This script reads (never executes)
  src/playbook/Configuration/**/*.yml
  src/playbook/Executables/**/*.{ps1,psm1,cmd,bat}
and fails (exit 1) when an AME `!appx` removal, a PowerShell Remove-AppxPackage / Remove-AppxProvisionedPackage
pipeline, a DISM provisioned-package removal or an AppxAllUserStore `Deprovisioned` rule names a protected family.
Wildcards count: a rule pattern such as 'Microsoft.Xbox*' or '*Store*' matches if it could select a protected family.

It also fails when `uninstall-edge` is ticked by default in playbook.conf: RemoveEdge.ps1 runs an unpinned
'latest' Remove-Edge.exe, so WebView2 safety of that path cannot be proven statically.

Removal targets that are only known at run time (variables, `$_`) are printed as warnings; they do not fail.

Usage: python -X utf8 tools/eclipse/check-protected-appx.py [--root <checkout>]
Stdlib only, read-only. Exit 0 = pass, 1 = protected match (or stale allowlist), 2 = usage error.
"""

import argparse
import fnmatch
import re
import sys
from pathlib import Path

PUBLISHER = "_8wekyb3d8bbwe"

# label -> family patterns ('*' = any suffix, as in AME and PowerShell -like)
PROTECTED = {
    "Microsoft.WindowsStore": ["Microsoft.WindowsStore"],
    "Microsoft.StorePurchaseApp": ["Microsoft.StorePurchaseApp"],
    "Microsoft.DesktopAppInstaller": ["Microsoft.DesktopAppInstaller"],
    "Microsoft.VCLibs*": ["Microsoft.VCLibs*"],
    "Microsoft.UI.Xaml*": ["Microsoft.UI.Xaml*"],
    "Microsoft.XboxIdentityProvider": ["Microsoft.XboxIdentityProvider"],
    "Microsoft.Xbox.TCUI": ["Microsoft.Xbox.TCUI"],
    "Microsoft.GamingApp": ["Microsoft.GamingApp"],
    "Microsoft.GamingServices": ["Microsoft.GamingServices"],
    "Microsoft.Services.Store.Engagement": ["Microsoft.Services.Store.Engagement"],
    "Microsoft.NET.Native*": ["Microsoft.NET.Native*"],
    "WebView2": ["msedgewebview*", "*EdgeWebView*", "Microsoft.Win32WebViewHost"],
}

# Concrete names a removal pattern is tried against (lower case).
SAMPLE_SUFFIXES = {
    "Microsoft.VCLibs*": [".140.00", ".140.00.UWPDesktop", ".120.00"],
    "Microsoft.UI.Xaml*": [".2.8", ".2.7", ".CBS"],
    "Microsoft.NET.Native*": [".Framework.2.2", ".Runtime.2.2"],
}
WEBVIEW_SAMPLES = ["msedgewebview2", "msedgewebview2.exe", "Microsoft.EdgeWebView", "EdgeWebView",
                   "Microsoft EdgeWebView", "Microsoft.Win32WebViewHost", "Microsoft.Win32WebViewHost_cw5n1h2txyewy"]

# Allowlist: user-run Atlas-folder tools only, never a path the playbook runs.
# key: (path relative to the checkout, protected label) -> reason
ALLOWLIST = {
    ("src/playbook/Executables/AtlasDesktop/6. Advanced Configuration/Microsoft Store/Disable Microsoft Store.cmd",
     "Microsoft.WindowsStore"):
        "user-run Atlas-folder toggle (no '(default)' marker, not referenced by Configuration); "
        "paired with 'Enable Microsoft Store (default).cmd', which re-registers the Store",
}

REMOVAL_RE = re.compile(
    r"Remove-AppxPackage|Remove-AppxProvisionedPackage|Remove-AppPackage|Remove-ProvisionedAppxPackage"
    r"|Remove-ProvisionedAppPackage|/Remove-ProvisionedAppxPackage|/Remove-Package\b|Deprovisioned",
    re.IGNORECASE)
GET_ALL_RE = re.compile(
    r"Get-Appx(?:Provisioned)?Package((?:\s+-(?:AllUsers|Online|User\s+\S+|PackageTypeFilter\s+\S+))*)\s*\|"
    r"\s*Remove-", re.IGNORECASE)
DYNAMIC_RE = re.compile(r"\$\w+|\$_|\$\(", re.IGNORECASE)
QUOTED_RE = re.compile(r"'([^']*)'|\"([^\"]*)\"")
TOKEN_RE = re.compile(r"[A-Za-z0-9_*][A-Za-z0-9_.*\-]*[.*][A-Za-z0-9_.*\-]*")
WEBVIEW_DELETE_RE = re.compile(r"Remove-Item|\brmdir\b|\brd\s|\bdel\s|\berase\s|!file:|uninstall", re.IGNORECASE)


def samples(label):
    out = []
    for pat in PROTECTED[label]:
        if label == "WebView2":
            out += WEBVIEW_SAMPLES
            continue
        base = pat.rstrip("*")
        names = [base + s for s in SAMPLE_SUFFIXES.get(label, [])] or [base]
        for n in names:
            out += [n, n + PUBLISHER, n + "_1.0.0.0_x64__8wekyb3d8bbwe"]
    return [s.lower() for s in out]


SAMPLES = {label: samples(label) for label in PROTECTED}


def protected_hits(target):
    """Return the protected labels a removal target pattern could select."""
    t = target.strip().strip("'\"").lower()
    if not t:
        return []
    hits = []
    literal = t.replace("*", "").replace("?", "")
    for label, pats in PROTECTED.items():
        if any(fnmatch.fnmatchcase(s, t) for s in SAMPLES[label]):
            hits.append(label)
            continue
        # the target names something inside a protected family (e.g. 'Microsoft.VCLibs.140.00_8wekyb3d8bbwe')
        if literal and any(fnmatch.fnmatchcase(literal, p.lower() + "*") for p in pats):
            hits.append(label)
            continue
        # plain substring of a protected token anywhere in the target (conservative)
        if any(p.strip("*").lower() in t for p in pats if len(p.strip("*")) >= 8):
            hits.append(label)
    return hits


def strip_comment(line, kind):
    s = line.strip()
    if kind == "cmd":
        if s.lower().startswith(("rem ", "::")) or s.lower() == "rem":
            return ""
        return line
    if s.startswith("#"):
        return ""
    return line


def logical_lines(text, kind):
    """Yield (line number, statement text), joining continued lines and dropping comments."""
    in_block = False
    buf, start = [], None
    for no, raw in enumerate(text.splitlines(), 1):
        line = raw
        if kind == "ps":
            if in_block:
                if "#>" in line:
                    in_block = False
                    line = line.split("#>", 1)[1]
                else:
                    continue
            if "<#" in line:
                head, _, tail = line.partition("<#")
                if "#>" not in tail:
                    in_block = True
                line = head + (tail.split("#>", 1)[1] if "#>" in tail else "")
        line = strip_comment(line, "cmd" if kind == "cmd" else "ps")
        if not line.strip():
            if buf:
                yield start, " ".join(buf)
                buf, start = [], None
            continue
        if start is None:
            start = no
        buf.append(line.strip())
        cont = line.rstrip()
        if cont.endswith(("|", "`", "^", "{", "(", ",")):
            continue
        yield start, " ".join(buf)
        buf, start = [], None
    if buf:
        yield start, " ".join(buf)


def candidates(stmt):
    found = set()
    for m in QUOTED_RE.finditer(stmt):
        val = m.group(1) if m.group(1) is not None else m.group(2)
        for part in re.split(r"[\s,;|]+", val):
            if part:
                found.add(part)
    for m in TOKEN_RE.finditer(stmt):
        found.add(m.group(0))
    # PowerShell "Get-AppxPackage <name>" positional and -Name/-Package/-PackageName arguments
    for m in re.finditer(r"(?:Get-Appx(?:Provisioned)?Package|-Name|-Package|-PackageName|-like|-eq|-match)"
                         r"\s+(?:-AllUsers\s+|-Online\s+)*([^\s|;{}()]+)", stmt, re.IGNORECASE):
        found.add(m.group(1))
    return found


def check_statement(stmt):
    """Return (labels, dynamic) for one removal statement."""
    labels = set()
    if GET_ALL_RE.search(stmt):
        labels.update(PROTECTED)  # unfiltered pipeline removes every package
    literal = False
    for cand in candidates(stmt):
        if cand.startswith(("-", "$")):
            continue
        labels.update(protected_hits(cand))
        if ("." in cand or "*" in cand) and "\\" not in cand:
            literal = True  # a package-like literal names the target
    dynamic = bool(DYNAMIC_RE.search(stmt)) and not labels and not literal
    return labels, dynamic


def yaml_actions(text):
    """Yield (line number, action text) for each '- !action' block of an AME YAML file (comments dropped)."""
    lines = text.splitlines()
    start, buf = None, []
    for no, raw in enumerate(lines, 1):
        s = raw.strip()
        if s.startswith("#"):
            continue
        if re.match(r"^\s*-\s*!\w+", raw):
            if buf:
                yield start, "\n".join(buf)
            start, buf = no, [raw]
        elif buf:
            buf.append(raw)
    if buf:
        yield start, "\n".join(buf)


def scan_yaml(path, text, report):
    for no, act in yaml_actions(text):
        head = act.lstrip()
        if head.startswith("- !appx"):
            op = re.search(r"operation:\s*['\"]?(\w+)", act)
            if op and op.group(1).lower() == "clearcache":
                continue
            name = re.search(r"name:\s*(?:'([^']*)'|\"([^\"]*)\"|([^\s,}]+))", act)
            if name:
                target = next(g for g in name.groups() if g is not None)
                report(path, no, "!appx", target, protected_hits(target))
            continue
        if "deprovisioned" in act.lower():
            for m in re.finditer(r"Deprovisioned\\+([^'\"\s,}\\]+)", act, re.IGNORECASE):
                report(path, no, "Deprovisioned", m.group(1), protected_hits(m.group(1)))
        if REMOVAL_RE.search(act) or WEBVIEW_DELETE_RE.search(act):
            scan_script(path, act, "ps", report, base=no - 1)


def scan_script(path, text, kind, report, base=0):
    for no, stmt in logical_lines(text, kind):
        if REMOVAL_RE.search(stmt):
            labels, dynamic = check_statement(stmt)
            report(path, base + no, "removal", stmt, sorted(labels), dynamic=dynamic)
        elif WEBVIEW_DELETE_RE.search(stmt):
            labels = [l for l in ["WebView2"] if any(c in stmt.lower() for c in
                                                     ("msedgewebview", "edgewebview", "win32webviewhost"))]
            if labels:
                report(path, base + no, "delete", stmt, labels)


def edge_default_check(conf):
    text = conf.read_text(encoding="utf-8")
    m = re.search(r"<CheckboxOption([^>]*)>\s*<Text>[^<]*</Text>\s*<Name>uninstall-edge</Name>", text)
    if not m:
        return None
    if re.search(r'IsChecked\s*=\s*"false"', m.group(1), re.IGNORECASE):
        return None
    return "playbook.conf: 'uninstall-edge' must be IsChecked=\"false\" (RemoveEdge.ps1 runs an unpinned Remove-Edge.exe)"


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", default=str(Path(__file__).resolve().parents[2]), help="repository checkout")
    args = ap.parse_args()
    root = Path(args.root).resolve()
    pb = root / "src" / "playbook"
    if not pb.is_dir():
        print(f"error: {pb} not found", file=sys.stderr)
        return 2

    failures, warnings, used = [], [], set()

    def report(path, line, kind, target, labels, dynamic=False):
        rel = path.relative_to(root).as_posix()
        short = " ".join(target.split())[:140]
        for label in labels:
            if (rel, label) in ALLOWLIST:
                used.add((rel, label))
                continue
            failures.append(f"{rel}:{line}: {kind} matches protected {label}: {short}")
        if dynamic and not labels:
            warnings.append(f"{rel}:{line}: {kind} target resolved at run time, not checked: {short}")

    files = sorted((pb / "Configuration").rglob("*.yml"))
    for f in files:
        scan_yaml(f, f.read_text(encoding="utf-8-sig", errors="replace"), report)
    scripts = [p for p in sorted((pb / "Executables").rglob("*"))
               if p.is_file() and p.suffix.lower() in (".ps1", ".psm1", ".cmd", ".bat")]
    for f in scripts:
        raw = f.read_bytes()
        enc = "utf-16" if raw[:2] in (b"\xff\xfe", b"\xfe\xff") else "utf-8-sig"
        kind = "cmd" if f.suffix.lower() in (".cmd", ".bat") else "ps"
        scan_script(f, raw.decode(enc, errors="replace"), kind, report)

    # Allowlist hygiene: entries must still match, must be user-run (no '(default)' marker, not run by Configuration)
    config_text = "\n".join(f.read_text(encoding="utf-8-sig", errors="replace") for f in files).lower()
    for (rel, label), reason in ALLOWLIST.items():
        name = Path(rel).name
        if (rel, label) not in used:
            failures.append(f"allowlist entry no longer matches anything (remove it): {rel} [{label}]")
        if "(default)" in name.lower():
            failures.append(f"allowlist entry is run by DEFAULT.ps1 ('(default)' marker): {rel}")
        if Path(name).stem.lower() in config_text:
            failures.append(f"allowlist entry is referenced by Configuration/**: {rel}")

    edge = edge_default_check(pb / "playbook.conf")
    if edge:
        failures.append(edge)

    print(f"scanned {len(files)} YAML and {len(scripts)} script files under {pb.relative_to(root).as_posix()}")
    for (rel, label), reason in sorted(ALLOWLIST.items()):
        state = "used" if (rel, label) in used else "UNUSED"
        print(f"allowlisted ({state}): {rel} [{label}] - {reason}")
    for w in warnings:
        print(f"WARNING {w}")
    for f in failures:
        print(f"FAIL {f}")
    print("PROTECTED-APPX FAIL" if failures else "PROTECTED-APPX PASS")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
