#!/usr/bin/env python3
"""
agent-memory-hub — sync script.

Collects memories from each installed agent into this repo (the shared hub),
regenerates memory/INDEX.md, and (optionally) commits changes to git.

Active sources (auto-detected, skipped silently if absent):
  - Claude Code : ~/.claude/projects/*/memory/*.md
  - Hermes      : auto-detects ~/.hermes, ~/.config/hermes, %LOCALAPPDATA%/hermes
  - OpenCode    : writes directly into memory/opencode/ (this repo)

Usage:
    python sync_memory.py            # sync + git commit (if anything changed)
    python sync_memory.py --push     # sync + commit + push
    python sync_memory.py --no-git   # sync only, no git operations
    python sync_memory.py --status   # show hub status
"""

import os
import sys
import json
import shutil
import sqlite3
import hashlib
import subprocess
from pathlib import Path
from datetime import datetime

HOME = Path(os.path.expanduser("~"))
HUB = Path(__file__).resolve().parent.parent
MEMORY = HUB / "memory"
SYNC_STATE = HUB / "scripts" / "sync_state.json"

CLAUDE_PROJECTS = HOME / ".claude" / "projects"

# Hermes: auto-detect across common install locations
_HERMES_CANDIDATES = [
    HOME / ".hermes",                                          # legacy / Linux default
    HOME / ".config" / "hermes",                               # XDG (Linux/macOS)
    Path(os.environ.get("LOCALAPPDATA", "")) / "hermes",       # Windows %LOCALAPPDATA%
    Path(os.environ.get("APPDATA", "")) / "hermes",            # Windows %APPDATA%
]
HERMES_DIR = next((p for p in _HERMES_CANDIDATES if p.is_dir()), HOME / ".hermes")
HERMES_DB = HERMES_DIR / "state.db"

HERMES_ROOT_FILES = ["MEMORY.md", "USER.md", "SOUL.md", "IDENTITY.md"]


# ---------- state ----------

def load_state():
    if SYNC_STATE.exists():
        return json.loads(SYNC_STATE.read_text(encoding="utf-8"))
    return {"last_sync": None, "file_hashes": {}}


def save_state(state):
    SYNC_STATE.parent.mkdir(parents=True, exist_ok=True)
    state["last_sync"] = datetime.now().isoformat()
    SYNC_STATE.write_text(json.dumps(state, indent=2, ensure_ascii=False), encoding="utf-8")


def file_hash(path):
    h = hashlib.md5()
    h.update(Path(path).read_bytes())
    return h.hexdigest()


def copy_if_changed(src, dst_dir, state, prefix):
    """Copy file into dst_dir if content changed. Returns True if copied."""
    if not Path(src).exists():
        return False
    dst = Path(dst_dir) / Path(src).name
    key = f"{prefix}/{Path(src).name}"
    src_hash = file_hash(src)
    if state["file_hashes"].get(key) == src_hash and dst.exists():
        return False
    dst_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    state["file_hashes"][key] = src_hash
    return True


# ---------- sources ----------

def sync_claude(state):
    """Copy Claude Code project memories. Auto-discovers all project dirs —
    no hardcoded username paths."""
    synced = 0
    if not CLAUDE_PROJECTS.exists():
        return 0
    for proj in sorted(CLAUDE_PROJECTS.glob("*")):
        mem_dir = proj / "memory"
        if not mem_dir.is_dir():
            continue
        for f in mem_dir.glob("*.md"):
            if copy_if_changed(f, MEMORY / "claude", state, "claude"):
                synced += 1
    return synced


def sync_hermes_root_files(state):
    synced = 0
    for name in HERMES_ROOT_FILES:
        f = HERMES_DIR / name
        if copy_if_changed(f, MEMORY / "hermes", state, "hermes"):
            synced += 1
    return synced


def sync_hermes_sessions(state):
    """Export Hermes sessions (state.db) to markdown, one file per session.

    NOTE: files are named with the FULL session id. Truncating to a date
    prefix collides (multiple sessions share the same date) and silently
    overwrites earlier exports.
    """
    if not HERMES_DB.exists():
        return 0
    conn = sqlite3.connect(str(HERMES_DB))
    c = conn.cursor()
    try:
        sessions = c.execute(
            "SELECT id, started_at, title FROM sessions ORDER BY started_at"
        ).fetchall()
    except sqlite3.OperationalError:
        conn.close()
        return 0

    out_dir = MEMORY / "hermes"
    out_dir.mkdir(parents=True, exist_ok=True)
    synced = 0

    def fmt_ts(ts):
        try:
            return datetime.fromtimestamp(float(ts)).isoformat()
        except (TypeError, ValueError):
            return str(ts)

    for session_id, started_at, title in sessions:
        try:
            messages = c.execute(
                "SELECT role, content, timestamp FROM messages "
                "WHERE session_id = ? ORDER BY timestamp",
                (session_id,),
            ).fetchall()
        except sqlite3.OperationalError:
            break
        if not messages:
            continue

        safe_id = str(session_id).replace("/", "_").replace("\\", "_").replace(":", "_")
        out_file = out_dir / f"{safe_id}.md"
        key = f"hermes/{safe_id}.md"

        lines = [f"# Session: {title or safe_id}\n"]
        lines.append(f"Started: {fmt_ts(started_at)}\n\n")
        for role, content, msg_time in messages:
            lines.append(f"**{role}** ({fmt_ts(msg_time)}):\n{str(content)[:500]}\n\n")

        content_str = "".join(lines)
        content_hash = hashlib.md5(content_str.encode("utf-8")).hexdigest()
        if state["file_hashes"].get(key) == content_hash and out_file.exists():
            continue
        out_file.write_text(content_str, encoding="utf-8")
        state["file_hashes"][key] = content_hash
        synced += 1

    conn.close()
    return synced


# ---------- index ----------

def generate_index():
    lines = ["# Memory Index\n"]
    lines.append(f"Generated: {datetime.now().isoformat()}\n\n")
    for agent_dir in sorted(MEMORY.iterdir()):
        if not agent_dir.is_dir():
            continue
        files = sorted(agent_dir.glob("*.md"))
        if not files:
            continue
        lines.append(f"## {agent_dir.name.upper()} ({len(files)} files)\n\n")
        for f in files:
            lines.append(f"- [{f.name}]({agent_dir.name}/{f.name}) ({f.stat().st_size} bytes)\n")
        lines.append("\n")
    (MEMORY / "INDEX.md").write_text("".join(lines), encoding="utf-8")


# ---------- git ----------

def git(args):
    return subprocess.run(
        ["git", "-C", str(HUB)] + args,
        capture_output=True, text=True, encoding="utf-8", errors="replace",
    )


def git_commit_if_changed(push=False):
    """Commit hub changes if the worktree is dirty. Returns True if committed."""
    if git(["rev-parse", "--is-inside-work-tree"]).stdout.strip() != "true":
        print("  (not a git repo, skipping git step)")
        return False
    status = git(["status", "--porcelain"])
    if not status.stdout.strip():
        print("  git: nothing to commit")
        return False
    git(["add", "-A"])
    msg = f"memory sync {datetime.now().strftime('%Y-%m-%d %H:%M')}"
    r = git(["commit", "-m", msg])
    if r.returncode != 0:
        print(f"  git commit failed: {r.stderr.strip()}")
        return False
    print(f"  git: committed ({msg})")
    if push:
        p = git(["push"])
        if p.returncode == 0:
            print("  git: pushed")
        else:
            print(f"  git push failed: {p.stderr.strip()}")
    return True


# ---------- status ----------

def show_status():
    state = load_state()
    print(f"Hub: {HUB}")
    print(f"Last sync: {state.get('last_sync', 'Never')}")
    print(f"Tracked files: {len(state.get('file_hashes', {}))}")
    print()
    for agent_dir in sorted(MEMORY.iterdir()):
        if agent_dir.is_dir():
            count = len(list(agent_dir.glob('*.md')))
            print(f"  {agent_dir.name}: {count} files")
    sources = [
        ("Claude Code projects", CLAUDE_PROJECTS),
        ("Hermes dir", HERMES_DIR),
        ("Hermes db", HERMES_DB),
    ]
    print()
    for name, p in sources:
        print(f"  source {name}: {'found' if p.exists() else 'not present'}")


# ---------- main ----------

def main():
    args = sys.argv[1:]
    if "--status" in args:
        show_status()
        return

    use_git = "--no-git" not in args
    push = "--push" in args

    MEMORY.mkdir(parents=True, exist_ok=True)
    state = load_state()

    print("=== agent-memory-hub sync ===")
    print(f"Time: {datetime.now().isoformat()}\n")

    print("[1/4] Claude Code memories...")
    print(f"  {sync_claude(state)} files")

    print("[2/4] Hermes root files...")
    print(f"  {sync_hermes_root_files(state)} files")

    print("[3/4] Hermes sessions...")
    print(f"  {sync_hermes_sessions(state)} sessions")

    print("[4/4] Generating index...")
    generate_index()
    print("  memory/INDEX.md updated")

    save_state(state)

    if use_git:
        git_commit_if_changed(push=push)

    print("\nDone.")


if __name__ == "__main__":
    main()
