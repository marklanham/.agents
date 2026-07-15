#!/usr/bin/env bash
set -euo pipefail

WITH_DEVIN=false
WITH_CLAUDE=false
args=()

for arg in "$@"; do
    case "$arg" in
        --devin)
            WITH_DEVIN=true
            ;;
        --claude)
            WITH_CLAUDE=true
            ;;
        *)
            args+=("$arg")
            ;;
    esac
done

# Default to Claude-style installation (flat .md files in .claude/agents)
# because the skill prompts in this library expect .claude/agents/<name>.md.
if [[ "$WITH_DEVIN" == false && "$WITH_CLAUDE" == false ]]; then
    WITH_CLAUDE=true
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TARGET_DIR="${args[0]:-$SCRIPT_DIR/../access-epos-evo}"
TARGET_DIR=$(cd "$TARGET_DIR" && pwd)

AGENTS_SOURCE="$SCRIPT_DIR/agents"

echo "Installing agents from $AGENTS_SOURCE into $TARGET_DIR"

if [[ "$WITH_CLAUDE" == true ]]; then
    CLAUDE_AGENTS_DIR="$TARGET_DIR/.claude/agents"
    mkdir -p "$CLAUDE_AGENTS_DIR"
fi

if [[ "$WITH_DEVIN" == true ]]; then
    DEVIN_AGENTS_DIR="$TARGET_DIR/.devin/agents"
    mkdir -p "$DEVIN_AGENTS_DIR"
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

    if [[ "$WITH_CLAUDE" == true ]]; then
        # Claude: flat file symlink pointing at the canonical AGENT.md
        claude_link="$CLAUDE_AGENTS_DIR/$agent_name.md"
        if [[ -e "$claude_link" || -L "$claude_link" ]]; then
            rm -f "$claude_link"
        fi
        ln -s "$agent_file" "$claude_link"
        echo "Linked Claude: $claude_link -> $agent_file"
    fi

    if [[ "$WITH_DEVIN" == true ]]; then
        # Devin: whole-folder symlink, same shape as canonical already
        devin_link="$DEVIN_AGENTS_DIR/$agent_name"
        if [[ -e "$devin_link" || -L "$devin_link" ]]; then
            rm -rf "$devin_link"
        fi
        ln -s "$agent_dir" "$devin_link"
        echo "Linked Devin: $devin_link -> $agent_dir"
    fi
done

echo "Done."
