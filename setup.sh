#!/usr/bin/env bash
# agent-memory-hub setup script (Linux / macOS)
# Usage:
#   bash setup.sh             # install in-place
#   bash setup.sh --force     # overwrite existing pointer files
#   bash setup.sh --fresh     # wipe accumulated memories (keep skeleton)

set -euo pipefail

SHARED_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORCE=0
FRESH=0
[[ "${1:-}" == "--force" ]] && FORCE=1
[[ "${1:-}" == "--fresh" ]] && FRESH=1

echo "=== agent-memory-hub setup ==="
echo "Hub directory: $SHARED_DIR"
echo ""

expand_template() {
    sed "s|{{SHARED}}|$SHARED_DIR|g" "$1"
}

install_pointer() {
    local template="$1" dest="$2" agent="$3"
    if [[ -e "$dest" ]]; then
        if [[ $FORCE -eq 1 ]]; then
            expand_template "$template" > "$dest"
            echo "  [$agent] updated: $dest"
        else
            echo "  [$agent] skipped (exists, use --force to overwrite): $dest"
        fi
        return
    fi
    expand_template "$template" > "$dest"
    echo "  [$agent] installed: $dest"
}

if [[ $FRESH -eq 1 ]]; then
    read -p "This deletes all accumulated memories under memory/. Continue? (y/N) " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        find "$SHARED_DIR/memory" -mindepth 1 -maxdepth 1 -type d ! -name consolidated -exec rm -rf {} +
        rm -f "$SHARED_DIR/scripts/sync_state.json"
        echo "Memories wiped. Skeleton kept."
    else
        echo "Aborted."; exit 1
    fi
fi

echo "Detecting installed agents..."

# OpenCode
if command -v opencode >/dev/null 2>&1 || [[ -d "$HOME/.config/opencode" ]]; then
    install_pointer "$SHARED_DIR/agents/opencode/AGENTS.md" "$HOME/AGENTS.md" "OpenCode"
else
    echo "  [OpenCode] not detected, skipped"
fi

# Claude Code
if [[ -d "$HOME/.claude" ]]; then
    install_pointer "$SHARED_DIR/agents/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md" "Claude"
else
    echo "  [Claude] not detected, skipped"
fi

# Hermes
if [[ -d "$HOME/.hermes" ]]; then
    install_pointer "$SHARED_DIR/agents/hermes/MEMORY.md" "$HOME/.hermes/MEMORY.md" "Hermes"
    install_pointer "$SHARED_DIR/agents/hermes/USER.md" "$HOME/.hermes/USER.md" "Hermes"
else
    echo "  [Hermes] not detected, skipped"
fi

# QClaw
if [[ -d "$HOME/.qclaw/workspace" ]]; then
    install_pointer "$SHARED_DIR/agents/qclaw/MEMORY.md" "$HOME/.qclaw/workspace/MEMORY.md" "QClaw"
else
    echo "  [QClaw] not detected, skipped"
fi

# OpenClaw
if [[ -d "$HOME/.openclaw/workspace" ]]; then
    install_pointer "$SHARED_DIR/agents/openclaw/MEMORY.md" "$HOME/.openclaw/workspace/MEMORY.md" "OpenClaw"
else
    echo "  [OpenClaw] not detected, skipped"
fi

echo ""
echo "Running first sync..."
if command -v python3 >/dev/null 2>&1; then
    python3 "$SHARED_DIR/scripts/sync_memory.py"
elif command -v python >/dev/null 2>&1; then
    python "$SHARED_DIR/scripts/sync_memory.py"
else
    echo "Python not found. Install Python 3.8+ and run: python3 scripts/sync_memory.py" >&2
fi

echo ""
if git -C "$SHARED_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [[ -z "$(git -C "$SHARED_DIR" remote)" ]]; then
        echo "No git remote configured."
        echo "To sync memories across devices, create a PRIVATE repo and run:"
        echo "  git remote add origin <your-private-repo-url>"
        echo "  git push -u origin main"
    fi
fi

echo ""
echo "Setup done."
