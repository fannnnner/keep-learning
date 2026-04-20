#!/bin/bash
# keep-learning installer
#
# Quick install:  curl -sSL https://raw.githubusercontent.com/fannnnner/keep-learning/main/install.sh | bash
# Custom target:  KEEP_LEARNING_SKILLS_DIR=~/.kiro/skills bash install.sh
#
# What it does:
#   1. Clone (or git pull) the repo into ~/.keep-learning/
#   2. Parse registry.yaml to get the list of skills to install
#   3. For each skill: symlink ~/.claude/skills/<name> -> ~/.keep-learning/skills/<name>
#
# Symlinks mean `curl ... | bash` a second time is an update — git pull propagates
# automatically without re-symlinking.

set -euo pipefail

OWNER="fannnnner"
REPO="keep-learning"
REPO_URL="${REPO_URL:-https://github.com/${OWNER}/${REPO}.git}"
CACHE_DIR="${KEEP_LEARNING_CACHE_DIR:-${HOME}/.keep-learning}"
SKILLS_DIR="${KEEP_LEARNING_SKILLS_DIR:-${HOME}/.claude/skills}"

# ── Colors (only if terminal supports them) ──
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    BOLD=$(tput bold); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3); RED=$(tput setaf 1); RESET=$(tput sgr0)
else
    BOLD=""; GREEN=""; YELLOW=""; RED=""; RESET=""
fi

info()  { echo "${BOLD}${GREEN}✓${RESET} $*"; }
warn()  { echo "${BOLD}${YELLOW}!${RESET} $*"; }
error() { echo "${BOLD}${RED}✗${RESET} $*" >&2; }

# ── Dependency check ──
for cmd in git awk; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        error "Missing required command: $cmd"
        exit 1
    fi
done

# ── Clone or update repo ──
if [ -d "${CACHE_DIR}/.git" ]; then
    info "Updating cache at ${CACHE_DIR}"
    if ! git -C "${CACHE_DIR}" pull --ff-only >/dev/null 2>&1; then
        warn "git pull failed (maybe local changes?), using cached version"
    fi
else
    info "Cloning ${REPO_URL} to ${CACHE_DIR}"
    rm -rf "${CACHE_DIR}"
    git clone --depth=1 "${REPO_URL}" "${CACHE_DIR}" >/dev/null 2>&1
fi

# ── Parse registry.yaml ──
# Minimal YAML parser: extracts "name" + "path" pairs under "skills:" list.
# Works for our strict schema — don't reuse this on arbitrary YAML.
REGISTRY="${CACHE_DIR}/registry.yaml"
if [ ! -f "$REGISTRY" ]; then
    error "registry.yaml not found in repo"
    exit 1
fi

parse_skills() {
    awk '
        /^skills:/ { in_skills=1; next }
        in_skills && /^[^[:space:]#]/ { in_skills=0 }
        in_skills && /^[[:space:]]+- name:/ {
            sub(/^[[:space:]]+- name:[[:space:]]*/, "")
            name=$0
        }
        in_skills && /^[[:space:]]+path:/ {
            sub(/^[[:space:]]+path:[[:space:]]*/, "")
            print name " " $0
        }
    ' "$1"
}

SKILLS_LIST=$(parse_skills "$REGISTRY")
if [ -z "$SKILLS_LIST" ]; then
    error "No skills found in registry.yaml"
    exit 1
fi

# ── Install each skill via symlink ──
mkdir -p "${SKILLS_DIR}"

INSTALLED=0
SKIPPED=0
while IFS=' ' read -r name path; do
    [ -z "$name" ] && continue

    SRC="${CACHE_DIR}/${path}"
    DST="${SKILLS_DIR}/${name}"

    if [ ! -d "$SRC" ]; then
        warn "skill '${name}': source ${SRC} not found, skipping"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # If DST exists as a real directory (not symlink), don't overwrite
    if [ -d "$DST" ] && [ ! -L "$DST" ]; then
        warn "skill '${name}': ${DST} is a real directory (not a symlink), skipping to avoid data loss"
        warn "  → back up your changes, then remove ${DST} and re-run this installer"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # If DST is a stale symlink or wrong target, replace it
    if [ -L "$DST" ] || [ -e "$DST" ]; then
        rm -f "$DST"
    fi

    ln -s "$SRC" "$DST"
    info "skill '${name}': ${DST} → ${SRC}"
    INSTALLED=$((INSTALLED + 1))
done <<< "$SKILLS_LIST"

# ── Summary ──
echo ""
if [ "$INSTALLED" -gt 0 ]; then
    info "Installed ${INSTALLED} skill(s) at ${SKILLS_DIR}"
fi
if [ "$SKIPPED" -gt 0 ]; then
    warn "Skipped ${SKIPPED} skill(s)"
fi
echo ""
echo "Next:"
echo "  • Restart Claude Code to pick up new skills"
echo "  • Re-run this script to update: git pulls the cache, symlinks are unchanged"
echo "  • To uninstall:  bash ${CACHE_DIR}/uninstall.sh"
