#!/bin/bash
# Package each skill in skills/ into a .skill zip at repo root.
#
# Usage:  ./build.sh              # build all skills listed in registry.yaml
#         ./build.sh meta-learn   # build only one
#
# Output:  <skill-name>.skill  (at repo root)
#
# A .skill file is just a zip archive containing <skill-name>/SKILL.md and
# <skill-name>/references/... Ready to upload, share, or commit.

set -euo pipefail

cd "$(dirname "$0")"

# ── Parse skill names from registry.yaml (same minimal awk parser as install.sh) ──
parse_skill_names() {
    awk '
        /^skills:/ { in_skills=1; next }
        in_skills && /^[^[:space:]#]/ { in_skills=0 }
        in_skills && /^[[:space:]]+- name:/ {
            sub(/^[[:space:]]+- name:[[:space:]]*/, "")
            print
        }
    ' registry.yaml
}

# ── Determine which skills to build ──
if [ $# -gt 0 ]; then
    SKILLS=("$@")
else
    # macOS ships bash 3.2 which lacks readarray; use a portable loop instead
    SKILLS=()
    while IFS= read -r name; do
        [ -n "$name" ] && SKILLS+=("$name")
    done < <(parse_skill_names)
fi

if [ ${#SKILLS[@]} -eq 0 ]; then
    echo "No skills found"
    exit 1
fi

# ── Build each ──
for name in "${SKILLS[@]}"; do
    src="skills/${name}"
    out="skills/${name}/${name}.skill"

    if [ ! -d "$src" ]; then
        echo "✗ skill not found: $src"
        exit 1
    fi

    if [ ! -f "$src/SKILL.md" ]; then
        echo "✗ missing SKILL.md in $src"
        exit 1
    fi

    # Write to a tempfile first to avoid the zip reading its own output mid-build
    # (because $out lives inside the source dir we're zipping).
    tmp="/tmp/${name}-$$-$RANDOM.skill"
    rm -f "$tmp" "$out"

    # cd into skills/ so the zip's top-level dir is <skill-name>/, not skills/<skill-name>/
    # Exclude the .skill file itself so rebuilds don't accumulate old packages.
    (cd skills && zip -qr "$tmp" "$name" \
        -x "${name}/${name}.skill" \
        -x "${name}/evals/*" \
        -x "${name}/.DS_Store" \
        -x "${name}/**/.DS_Store")

    mv "$tmp" "$out"

    size=$(du -h "$out" | cut -f1)
    echo "✓ built ${out} (${size})"
done
