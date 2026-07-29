#!/usr/bin/env bash
# apply-heavy-links.sh — materialize heavy-links redirects into $HOME.
#
# Why not `stow heavy-links`?
# GNU Stow installs package symlinks as symlinks-to-those-symlinks. Relative
# targets like `.local-heavy/cargo` then resolve against the package directory
# (stow/heavy-links/), not $HOME, so the redirects would be broken.
# This script copies the link *intent* from the package into $HOME as one-hop
# relative symlinks through the ~/.local-heavy anchor.
#
# Usage:
#   bash scripts/apply-heavy-links.sh            # apply
#   bash scripts/apply-heavy-links.sh --dry-run  # preview
#   bash scripts/apply-heavy-links.sh --delete   # remove managed links

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG="$REPO_ROOT/stow/heavy-links"

DRY_RUN=false
DELETE=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --delete)  DELETE=true ;;
        *) echo "Unknown argument: $arg" >&2; exit 2 ;;
    esac
done

if [[ ! -d "$PKG" ]]; then
    echo "ERROR: heavy-links package not found: $PKG" >&2
    exit 1
fi

conflicts=0
applied=0
removed=0
skipped=0
found=0

# Use find -print (newline-separated). Paths in this package have no newlines.
while IFS= read -r link; do
    [[ -z "$link" ]] && continue
    found=$((found + 1))
    rel="${link#"$PKG"/}"
    target="$(readlink "$link")"
    dest="$HOME/$rel"

    if $DELETE; then
        if [[ -L "$dest" ]]; then
            current="$(readlink "$dest")"
            if [[ "$current" == "$target" ]]; then
                if $DRY_RUN; then
                    echo "DELETE $dest"
                else
                    rm "$dest"
                    echo "removed $dest"
                fi
                removed=$((removed + 1))
            else
                echo "SKIP $dest (points to $current, expected $target)"
                skipped=$((skipped + 1))
            fi
        elif [[ -e "$dest" ]]; then
            echo "SKIP $dest (exists but is not a symlink)"
            skipped=$((skipped + 1))
        fi
        continue
    fi

    # Apply / restow
    if [[ -L "$dest" ]]; then
        current="$(readlink "$dest")"
        if [[ "$current" == "$target" ]]; then
            skipped=$((skipped + 1))
            continue
        fi
        if $DRY_RUN; then
            echo "REPLACE $dest -> $target  (was $current)"
        else
            ln -sfn "$target" "$dest"
            echo "replaced $dest -> $target"
        fi
        applied=$((applied + 1))
        continue
    fi

    if [[ -e "$dest" ]]; then
        echo "CONFLICT: $dest exists and is not a symlink (not owned by heavy-links)"
        conflicts=$((conflicts + 1))
        continue
    fi

    if $DRY_RUN; then
        echo "LINK $dest -> $target"
    else
        mkdir -p "$(dirname "$dest")"
        ln -sfn "$target" "$dest"
        echo "linked $dest -> $target"
    fi
    applied=$((applied + 1))
done < <(find "$PKG" -type l | LC_ALL=C sort)

if ((found == 0)); then
    echo "WARNING: no symlinks found in $PKG"
    exit 0
fi

echo ""
if $DELETE; then
    echo "Done. removed=$removed skipped=$skipped"
else
    echo "Done. applied=$applied skipped=$skipped conflicts=$conflicts"
fi

if ((conflicts > 0)); then
    echo "Resolve conflicts (back up / move the real path), then re-run." >&2
    exit 1
fi
