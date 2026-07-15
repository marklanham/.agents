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

# Default to Claude-style installation (directories in .claude/skills)
# to match the agents and avoid duplicate skill registration in Devin.
if [[ "$WITH_DEVIN" == false && "$WITH_CLAUDE" == false ]]; then
    WITH_CLAUDE=true
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TARGET_DIR="${args[0]:-$SCRIPT_DIR/../access-epos-evo}"
TARGET_DIR=$(cd "$TARGET_DIR" && pwd)

SKILLS_SOURCE="$SCRIPT_DIR/skills"

echo "Installing skills from $SKILLS_SOURCE into $TARGET_DIR"

if [[ "$WITH_CLAUDE" == true ]]; then
    CLAUDE_SKILLS_DIR="$TARGET_DIR/.claude/skills"
    mkdir -p "$CLAUDE_SKILLS_DIR"
fi

if [[ "$WITH_DEVIN" == true ]]; then
    DEVIN_SKILLS_DIR="$TARGET_DIR/.devin/skills"
    mkdir -p "$DEVIN_SKILLS_DIR"
fi

shopt -s nullglob
for skill_dir in "$SKILLS_SOURCE"/*/; do
    skill_dir=${skill_dir%/}
    skill_name=$(basename "$skill_dir")
    skill_file="$skill_dir/SKILL.md"

    if [[ ! -f "$skill_file" ]]; then
        echo "SKIP $skill_name — no SKILL.md at $skill_file"
        continue
    fi

    if [[ "$WITH_CLAUDE" == true ]]; then
        # Claude: whole-folder symlink
        claude_link="$CLAUDE_SKILLS_DIR/$skill_name"
        if [[ -e "$claude_link" || -L "$claude_link" ]]; then
            rm -rf "$claude_link"
        fi
        ln -s "$skill_dir" "$claude_link"
        echo "Linked Claude: $claude_link -> $skill_dir"
    fi

    if [[ "$WITH_DEVIN" == true ]]; then
        # Devin: whole-folder symlink
        devin_link="$DEVIN_SKILLS_DIR/$skill_name"
        if [[ -e "$devin_link" || -L "$devin_link" ]]; then
            rm -rf "$devin_link"
        fi
        ln -s "$skill_dir" "$devin_link"
        echo "Linked Devin: $devin_link -> $skill_dir"
    fi
done

echo "Done."
