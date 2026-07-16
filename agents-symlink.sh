#!/usr/bin/env bash
set -euo pipefail

WITH_DEVIN=false
WITH_CLAUDE=false
WITH_CURSOR=false
WITH_WINDSURF=false
args=()

for arg in "$@"; do
    case "$arg" in
        --devin)
            WITH_DEVIN=true
            ;;
        --claude)
            WITH_CLAUDE=true
            ;;
        --cursor)
            WITH_CURSOR=true
            ;;
        --windsurf)
            WITH_WINDSURF=true
            ;;
        --all)
            WITH_DEVIN=true
            WITH_CLAUDE=true
            WITH_CURSOR=true
            WITH_WINDSURF=true
            ;;
        *)
            args+=("$arg")
            ;;
    esac
done

# Default to installing for every supported tool so the target project
# is compatible with whichever agentic tool the user happens to run.
if [[ "$WITH_DEVIN" == false && "$WITH_CLAUDE" == false && "$WITH_CURSOR" == false && "$WITH_WINDSURF" == false ]]; then
    WITH_DEVIN=true
    WITH_CLAUDE=true
    WITH_CURSOR=true
    WITH_WINDSURF=true
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

if [[ -z "${args[0]:-}" ]]; then
    echo "Usage: $0 <target-project-dir> [--claude] [--devin] [--cursor] [--windsurf] [--all]" >&2
    exit 1
fi
TARGET_DIR=$(cd "${args[0]}" && pwd)

AGENTS_SOURCE="$SCRIPT_DIR/agents"

echo "Installing agents from $AGENTS_SOURCE into $TARGET_DIR"

# .agents/agents/<name> is the canonical, tool-agnostic install location.
# Every tool-specific directory below is just a shim pointing into it, so
# nothing but this one layer ever points back at the source repo.
AGENTS_CANONICAL_DIR="$TARGET_DIR/.agents/agents"
mkdir -p "$AGENTS_CANONICAL_DIR"

if [[ "$WITH_CLAUDE" == true ]]; then
    CLAUDE_AGENTS_DIR="$TARGET_DIR/.claude/agents"
    mkdir -p "$CLAUDE_AGENTS_DIR"
fi

if [[ "$WITH_DEVIN" == true ]]; then
    DEVIN_AGENTS_DIR="$TARGET_DIR/.devin/agents"
    mkdir -p "$DEVIN_AGENTS_DIR"
fi

if [[ "$WITH_CURSOR" == true || "$WITH_WINDSURF" == true ]]; then
    echo "NOTE: Cursor and Windsurf have no file-based subagent/persona convention today, so agents are not installed for them (skills/commands still are)."
fi

shopt -s nullglob
for agent_dir in "$AGENTS_SOURCE"/*/; do
    agent_dir=${agent_dir%/}
    agent_name=$(basename "$agent_dir")
    agent_file="$agent_dir/AGENT.md"

    if [[ ! -f "$agent_file" ]]; then
        echo "SKIP $agent_name — no AGENT.md at $agent_file"
        continue
    fi

    # Canonical: whole-folder symlink into .agents/agents/<name>
    canonical_link="$AGENTS_CANONICAL_DIR/$agent_name"
    if [[ -e "$canonical_link" || -L "$canonical_link" ]]; then
        rm -rf "$canonical_link"
    fi
    ln -s "$agent_dir" "$canonical_link"
    echo "Linked canonical: $canonical_link -> $agent_dir"

    if [[ "$WITH_CLAUDE" == true ]]; then
        # Claude: flat file symlink pointing at the canonical AGENT.md
        claude_link="$CLAUDE_AGENTS_DIR/$agent_name.md"
        if [[ -e "$claude_link" || -L "$claude_link" ]]; then
            rm -f "$claude_link"
        fi
        ln -s "$canonical_link/AGENT.md" "$claude_link"
        echo "Linked Claude: $claude_link -> $canonical_link/AGENT.md"
    fi

    if [[ "$WITH_DEVIN" == true ]]; then
        # Devin: whole-folder symlink, same shape as canonical already
        devin_link="$DEVIN_AGENTS_DIR/$agent_name"
        if [[ -e "$devin_link" || -L "$devin_link" ]]; then
            rm -rf "$devin_link"
        fi
        ln -s "$canonical_link" "$devin_link"
        echo "Linked Devin: $devin_link -> $canonical_link"
    fi
done

echo "Done."
