#!/usr/bin/env python3
"""Collect live AI tool sessions (Claude Code, Gemini, Codex, Ollama, desktop apps...) for the sketchybar dropdown.

Only run while the popup is open. Emits tab-separated lines, never with empty
fields (the bash reader collapses empty tab fields):
  H<TAB>header label
  R<TAB>pid<TAB>sessionId<TAB>status<TAB>needs(0|1)<TAB>cwd<TAB>row label
  F<TAB>footer label
Claude Code sessions come from ~/.claude/sessions; every other tool is found by matching
AI_TOOLS ("Label=regex" lines, from variables.sh) against process command lines, so those
rows only know pid, cwd, age and (for ollama) the model.
Claude needs-action flags come from FLAG_DIR (written by ~/.claude/sketchybar-claude-update.sh);
model/context from /tmp/claude-sl/<sessionId>.json (written by the statusline script),
falling back to the tail of the session transcript.
"""
import glob
import json
import os
import re
import subprocess
import time

CLAUDE = "Claude"

HOME = os.path.expanduser("~")
FLAG_DIR = os.environ.get("AI_FLAG_DIR", "/tmp/claude-needs-action.d")
SL_DIR = os.environ.get("AI_SL_DIR", "/tmp/claude-sl")
PS = os.environ.get("AI_PS", "/bin/ps")

HOSTS = [  # (substring of executable path, display name)
    ("iTerm", "iTerm"), ("Visual Studio Code", "VS Code"), ("Code Helper", "VS Code"),
    ("Cursor", "Cursor"), ("Ghostty", "Ghostty"), ("WezTerm", "WezTerm"),
    ("Alacritty", "Alacritty"), ("kitty", "kitty"), ("Terminal.app", "Terminal"),
    ("/tmux", "tmux"),
]
DESKTOP = "Desktop"  # host label for tools that are macOS apps themselves
ICON_TERMINAL = "\uf120"  # fa-terminal
ICON_VSCODE = "\U000f0a1e"  # md-microsoft_visual_studio_code
ICON_TMUX = "\uebc8"  # cod-terminal_tmux
ICON_UNKNOWN = "\uf128"  # fa-question
ICON_DESKTOP = "\uf108"  # fa-desktop
HOST_ICONS = {"VS Code": ICON_VSCODE, "Cursor": ICON_VSCODE, "tmux": ICON_TMUX, DESKTOP: ICON_DESKTOP, "unknown": ICON_UNKNOWN}


def clean(s):
    return str(s).replace("\t", " ").replace("\n", " ") or "-"


def trunc(s, n):
    return s if len(s) <= n else s[: n - 1] + "…"


def process_table():
    procs = {}
    try:
        out = subprocess.run([PS, "-axo", "pid=,ppid=,comm="], capture_output=True, text=True).stdout
        for line in out.splitlines():
            parts = line.split(None, 2)
            if len(parts) == 3:
                procs[int(parts[0])] = (int(parts[1]), parts[2])
    except Exception:
        pass
    return procs


def parse_tools(text):
    """AI_TOOLS "Label=regex" lines -> [(label, compiled regex)]; malformed lines are skipped."""
    tools = []
    for line in text.splitlines():
        label, sep, pattern = line.partition("=")
        if not sep or not label.strip():
            continue
        try:
            tools.append((label.strip(), re.compile(pattern)))
        except re.error:
            continue
    return tools


def parse_etime(text):
    """ps etime ([[dd-]hh:]mm:ss) -> seconds."""
    days, _, rest = text.rpartition("-")
    secs = 0
    for part in rest.split(":"):
        secs = secs * 60 + int(part)
    return secs + (int(days) * 86400 if days else 0)


def process_cwd(pid):
    try:
        out = subprocess.run(["/usr/sbin/lsof", "-a", "-d", "cwd", "-p", str(pid), "-Fn"],
                             capture_output=True, text=True, timeout=3).stdout
    except Exception:
        return ""
    for line in out.splitlines():
        if line.startswith("n"):
            return line[1:]
    return ""


def host_of(procs, pid):
    for _ in range(20):
        if pid not in procs:
            break
        ppid, comm = procs[pid]
        for needle, name in HOSTS:
            if needle in comm:
                return name
        pid = ppid
    return "unknown"


def git_branch(cwd):
    try:
        out = subprocess.run(["git", "-C", cwd, "--no-optional-locks", "branch", "--show-current"],
                             capture_output=True, text=True, timeout=2).stdout.strip()
        return out or "-"
    except Exception:
        return "-"


def short_model(m):
    m = m.replace("anthropic.", "").replace("claude-", "")
    return m


def transcript_info(sid):
    """(model, context tokens) from the last assistant entry of the transcript."""
    paths = glob.glob(os.path.join(HOME, ".claude", "projects", "*", sid + ".jsonl"))
    if not paths:
        return None, None
    try:
        with open(paths[0], "rb") as f:
            f.seek(0, os.SEEK_END)
            f.seek(max(0, f.tell() - 262144))
            lines = f.read().decode("utf-8", "replace").splitlines()
    except OSError:
        return None, None
    for line in reversed(lines):
        try:
            d = json.loads(line)
        except ValueError:
            continue
        msg = d.get("message") if d.get("type") == "assistant" else None
        usage = msg.get("usage") if isinstance(msg, dict) else None
        if usage:
            tokens = sum(usage.get(k) or 0 for k in
                         ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"))
            return short_model(msg.get("model") or "") or None, tokens
    return None, None


def model_and_ctx(sid):
    """(model, ctx display, ctx value in percent for sorting; token-only estimates assume a 200k window)."""
    model = ctx = ctx_num = None
    try:
        with open(os.path.join(SL_DIR, sid + ".json")) as f:
            d = json.load(f)
        model = d.get("model") or None
        if d.get("used_pct"):
            ctx_num = float(d["used_pct"])
            ctx = "%d%%" % round(ctx_num)
    except (OSError, ValueError):
        pass
    if model is None or ctx is None:
        t_model, tokens = transcript_info(sid)
        model = model or t_model
        if ctx is None and tokens:
            ctx = "~%dk" % round(tokens / 1000)
            ctx_num = tokens / 2000.0
    return model or "-", ctx or "-", ctx_num if ctx_num is not None else -1.0


def fmt_age(seconds):
    s = max(0, int(seconds))
    if s < 60:
        return "now" if s < 10 else "%ds" % s
    if s < 3600:
        return "%dm" % (s // 60)
    if s < 86400:
        return "%dh%02dm" % (s // 3600, s % 3600 // 60)
    return "%dd%dh" % (s // 86400, s % 86400 // 3600)


def natural(text):
    """Natural sort key: digit runs compare as numbers, text case-insensitively (never plain lexicographic)."""
    return [(0, int(t), "") if t.isdigit() else (1, 0, t.casefold()) for t in re.split(r"(\d+)", text) if t]


# Numeric columns compare as numbers (seconds / percent / pid), text columns naturally; pid breaks ties.
SORT_KEYS = {
    "tool": lambda r: (natural(r["tool"]), r["pid"]),
    "app": lambda r: (natural(r["host"]), r["pid"]),
    "session": lambda r: (natural(r["name"]), r["pid"]),
    "branch": lambda r: (natural(r["branch"]), r["pid"]),
    "model": lambda r: (natural(r["model"]), r["pid"]),
    "ctx": lambda r: (r["ctx_num"], r["pid"]),
    "age": lambda r: (r["age_s"], r["pid"]),
    "idle": lambda r: (r["idle_s"], r["pid"]),
    "pid": lambda r: (r["pid"],),
}


def process_rows(tools, procs, now):
    """Rows for tools detected by process command line (no session files); a child of a matching process is skipped."""
    try:
        out = subprocess.run([PS, "-axo", "pid=,ppid=,etime=,args="], capture_output=True, text=True).stdout
    except Exception:
        return []
    found = {}  # pid -> (ppid, tool, etime seconds, args)
    for line in out.splitlines():
        parts = line.split(None, 3)
        if len(parts) < 4:
            continue
        for label, rx in tools:
            if rx.search(parts[3]):
                try:
                    found[int(parts[0])] = (int(parts[1]), label, parse_etime(parts[2]), parts[3])
                except ValueError:
                    pass
                break
    rows = []
    for pid, (ppid, label, age_s, args) in found.items():
        if ppid in found and found[ppid][1] == label:
            continue
        is_app = ".app/Contents/MacOS/" in procs.get(pid, (0, ""))[1]
        cwd = "-" if is_app else clean(process_cwd(pid))
        model = "-"
        if label == "Ollama":
            m = re.search(r"ollama run +(\S+)", args)
            model = m.group(1) if m else "-"
        rows.append({
            "tool": label, "host": DESKTOP if is_app else host_of(procs, pid),
            "name": label if is_app else trunc(os.path.basename(cwd) or cwd, 30),
            "pid": pid, "sid": "p%d" % pid, "cwd": cwd, "status": "running", "needs": False,
            "branch": trunc(git_branch(cwd) if os.path.isdir(cwd) else "-", 24),
            "model": model, "ctx": "-", "ctx_num": -1.0,
            "age_s": age_s, "age": fmt_age(age_s), "idle_s": age_s, "idle": "-",
        })
    return rows


def main():
    procs = process_table()
    now = time.time()
    rows = []
    for f in glob.glob(os.path.join(HOME, ".claude", "sessions", "*.json")):
        try:
            d = json.load(open(f))
            pid = int(d["pid"])
        except Exception:
            continue
        try:
            os.kill(pid, 0)
        except ProcessLookupError:
            continue
        except PermissionError:
            pass
        sid = clean(d.get("sessionId", "unknown"))
        cwd = clean(d.get("cwd", ""))
        name = trunc(clean(d.get("name") or os.path.basename(cwd)), 30)
        model, ctx, ctx_num = model_and_ctx(sid)
        rows.append({
            "tool": CLAUDE, "host": host_of(procs, pid), "name": name, "pid": pid, "sid": sid, "cwd": cwd,
            "status": clean(d.get("status", "?")),
            "needs": os.path.exists(os.path.join(FLAG_DIR, sid)),
            "branch": trunc(git_branch(cwd) if os.path.isdir(cwd) else "-", 24),
            "model": model, "ctx": ctx, "ctx_num": ctx_num,
            "age_s": now - d.get("startedAt", now * 1000) / 1000,
            "idle_s": now - d.get("updatedAt", now * 1000) / 1000,
        })
        rows[-1]["age"] = fmt_age(rows[-1]["age_s"])
        rows[-1]["idle"] = fmt_age(rows[-1]["idle_s"])
    rows += process_rows(parse_tools(os.environ.get("AI_TOOLS", "")), procs, now)
    # Order from AI_SORT_BY / AI_SORT_DIR (variables.sh); invalid values fall back to idle asc
    sort_by = os.environ.get("AI_SORT_BY", "idle").lower()
    rows.sort(key=SORT_KEYS.get(sort_by, SORT_KEYS["idle"]),
              reverse=os.environ.get("AI_SORT_DIR", "asc").lower() == "desc")

    w = lambda key, title: max([len(title)] + [len(r[key]) for r in rows])
    tw, hw, nw, bw, mw = (w("tool", "TOOL"), w("host", "APP"), w("name", "SESSION"),
                          w("branch", "BRANCH"), w("model", "MODEL"))
    fmt = "%s  %-*s  %-*s  %-*s  %-*s  %-*s  %5s  %6s  %6s  %6s"
    header = fmt % ("·", tw, "TOOL", hw, "APP", nw, "SESSION", bw, "BRANCH", mw, "MODEL", "CTX", "AGE", "IDLE", "PID")  # visible first char: sketchybar measures a label with leading whitespace too narrow, clipping its end
    print("H\t" + header)
    for r in rows:
        icon = ICON_TERMINAL if r["host"] not in HOST_ICONS and r["host"] != "unknown" else HOST_ICONS.get(r["host"], ICON_UNKNOWN)
        label = fmt % (icon, tw, r["tool"], hw, r["host"], nw, r["name"], bw, r["branch"], mw, r["model"],
                       r["ctx"], r["age"], r["idle"], r["pid"])
        print("\t".join(["R", str(r["pid"]), r["sid"], r["status"], "1" if r["needs"] else "0",
                         r["cwd"], label]))
    busy = sum(r["status"] == "busy" for r in rows)
    waiting = sum(r["needs"] for r in rows)
    print("F\t%d sessions  ·  %d busy  ·  %d idle  ·  %d waiting" % (len(rows), busy, len(rows) - busy, waiting))


if __name__ == "__main__":
    main()
