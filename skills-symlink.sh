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

SKILLS_SOURCE="$SCRIPT_DIR/skills"

echo "Installing skills from $SKILLS_SOURCE into $TARGET_DIR"

# .agents/skills/<name> is the canonical, tool-agnostic install location.
# Every tool-specific directory below is just a shim pointing into it, so
# nothing but this one layer ever points back at the source repo.
SKILLS_CANONICAL_DIR="$TARGET_DIR/.agents/skills"
mkdir -p "$SKILLS_CANONICAL_DIR"

if [[ "$WITH_CLAUDE" == true ]]; then
    CLAUDE_SKILLS_DIR="$TARGET_DIR/.claude/skills"
    mkdir -p "$CLAUDE_SKILLS_DIR"
fi

if [[ "$WITH_DEVIN" == true ]]; then
    DEVIN_SKILLS_DIR="$TARGET_DIR/.devin/skills"
    mkdir -p "$DEVIN_SKILLS_DIR"
fi

if [[ "$WITH_CURSOR" == true ]]; then
    # Cursor commands are single markdown files, e.g. .cursor/commands/<name>.md
    CURSOR_COMMANDS_DIR="$TARGET_DIR/.cursor/commands"
    mkdir -p "$CURSOR_COMMANDS_DIR"
fi

if [[ "$WITH_WINDSURF" == true ]]; then
    # Windsurf workflows are single markdown files, e.g. .windsurf/workflows/<name>.md
    WINDSURF_WORKFLOWS_DIR="$TARGET_DIR/.windsurf/workflows"
    mkdir -p "$WINDSURF_WORKFLOWS_DIR"
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

    # Canonical: whole-folder symlink into .agents/skills/<name>
    canonical_link="$SKILLS_CANONICAL_DIR/$skill_name"
    if [[ -e "$canonical_link" || -L "$canonical_link" ]]; then
        rm -rf "$canonical_link"
    fi
    ln -s "$skill_dir" "$canonical_link"
    echo "Linked canonical: $canonical_link -> $skill_dir"

    if [[ "$WITH_CLAUDE" == true ]]; then
        # Claude: whole-folder symlink
        claude_link="$CLAUDE_SKILLS_DIR/$skill_name"
        if [[ -e "$claude_link" || -L "$claude_link" ]]; then
            rm -rf "$claude_link"
        fi
        ln -s "$canonical_link" "$claude_link"
        echo "Linked Claude: $claude_link -> $canonical_link"
    fi

    if [[ "$WITH_DEVIN" == true ]]; then
        # Devin: whole-folder symlink
        devin_link="$DEVIN_SKILLS_DIR/$skill_name"
        if [[ -e "$devin_link" || -L "$devin_link" ]]; then
            rm -rf "$devin_link"
        fi
        ln -s "$canonical_link" "$devin_link"
        echo "Linked Devin: $devin_link -> $canonical_link"
    fi

    if [[ "$WITH_CURSOR" == true ]]; then
        # Cursor: flat file symlink, SKILL.md doubles as the command body
        cursor_link="$CURSOR_COMMANDS_DIR/$skill_name.md"
        if [[ -e "$cursor_link" || -L "$cursor_link" ]]; then
            rm -f "$cursor_link"
        fi
        ln -s "$canonical_link/SKILL.md" "$cursor_link"
        echo "Linked Cursor: $cursor_link -> $canonical_link/SKILL.md"
    fi

    if [[ "$WITH_WINDSURF" == true ]]; then
        # Windsurf: flat file symlink, SKILL.md doubles as the workflow body
        windsurf_link="$WINDSURF_WORKFLOWS_DIR/$skill_name.md"
        if [[ -e "$windsurf_link" || -L "$windsurf_link" ]]; then
            rm -f "$windsurf_link"
        fi
        ln -s "$canonical_link/SKILL.md" "$windsurf_link"
        echo "Linked Windsurf: $windsurf_link -> $canonical_link/SKILL.md"
    fi
done

echo "Done."
