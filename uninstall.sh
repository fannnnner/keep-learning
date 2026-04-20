#!/bin/bash
# keep-learning uninstaller
#
# Usage:  bash ~/.keep-learning/uninstall.sh
#         bash ~/.keep-learning/uninstall.sh --yes     # skip confirmation
#         bash ~/.keep-learning/uninstall.sh --keep-cache  # remove symlinks only, keep repo cache
#
# What it does:
#   1. Find every symlink in ~/.claude/skills/ pointing at ~/.keep-learning/skills/
#   2. List them, ask for confirmation (unless --yes)
#   3. Remove the symlinks
#   4. Remove the cache at ~/.keep-learning/ (unless --keep-cache)

set -euo pipefail

CACHE_DIR="${KEEP_LEARNING_CACHE_DIR:-${HOME}/.keep-learning}"
SKILLS_DIR="${KEEP_LEARNING_SKILLS_DIR:-${HOME}/.claude/skills}"

SKIP_CONFIRM=0
KEEP_CACHE=0
for arg in "$@"; do
    case "$arg" in
        --yes|-y)      SKIP_CONFIRM=1 ;;
        --keep-cache)  KEEP_CACHE=1 ;;
        -h|--help)
            sed -n '2,11p' "$0" | sed 's/^# *//'
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            exit 1
            ;;
    esac
done

# ── Colors ──
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    BOLD=$(tput bold); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3); RED=$(tput setaf 1); RESET=$(tput sgr0)
else
    BOLD=""; GREEN=""; YELLOW=""; RED=""; RESET=""
fi

# ── Find our symlinks ──
# We only remove symlinks that point into our cache directory — never touch real directories
# or symlinks to something else.
TO_REMOVE=()
if [ -d "$SKILLS_DIR" ]; then
    while IFS= read -r link; do
        [ -z "$link" ] && continue
        target=$(readlink "$link" 2>/dev/null || echo "")
        case "$target" in
            "${CACHE_DIR}"/*) TO_REMOVE+=("$link") ;;
        esac
    done < <(find "$SKILLS_DIR" -maxdepth 1 -type l 2>/dev/null)
fi

# ── Plan summary ──
echo "${BOLD}keep-learning uninstaller${RESET}"
echo ""
if [ ${#TO_REMOVE[@]} -eq 0 ]; then
    echo "No symlinks found pointing at ${CACHE_DIR}"
else
    echo "Will remove these symlinks:"
    for link in "${TO_REMOVE[@]}"; do
        target=$(readlink "$link")
        echo "  ${RED}-${RESET} $link ${YELLOW}→${RESET} $target"
    done
fi

if [ "$KEEP_CACHE" -eq 0 ] && [ -d "$CACHE_DIR" ]; then
    echo ""
    echo "Will remove cache directory:"
    echo "  ${RED}-${RESET} $CACHE_DIR"
fi

# ── Confirm ──
if [ "$SKIP_CONFIRM" -eq 0 ]; then
    echo ""
    read -r -p "Proceed? [y/N] " reply
    case "$reply" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "Aborted."; exit 0 ;;
    esac
fi

# ── Execute ──
for link in "${TO_REMOVE[@]:-}"; do
    [ -z "$link" ] && continue
    rm -f "$link"
    echo "${GREEN}✓${RESET} removed $link"
done

if [ "$KEEP_CACHE" -eq 0 ] && [ -d "$CACHE_DIR" ]; then
    rm -rf "$CACHE_DIR"
    echo "${GREEN}✓${RESET} removed $CACHE_DIR"
fi

echo ""
echo "Done."
