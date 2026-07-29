#!/usr/bin/env bash
# check-linux-heavy.sh — verify ~/.local-heavy anchor symlink status
# and print the commands to apply heavy packages.

set -euo pipefail

ANCHOR="$HOME/.local-heavy"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

print_apply_instructions() {
    echo "Apply heavy packages (skeleton onto local disk, links into \$HOME):"
    echo ""
    echo "  cd $REPO_ROOT/stow"
    echo "  HEAVY_ROOT=\"\$(cd ~/.local-heavy && pwd -P)\""
    echo "  stow -R --no-folding --target=\"\$HEAVY_ROOT\" heavy-dirs"
    echo "  bash $REPO_ROOT/scripts/apply-heavy-links.sh"
    echo "  # optional:"
    echo "  # stow -R --no-folding --target=\"\$HEAVY_ROOT\" agent-guidance-heavy"
    echo ""
    echo "Or simply: bash $REPO_ROOT/scripts/setup.sh --stow"
}

if [[ -L "$ANCHOR" ]]; then
    target="$(readlink "$ANCHOR")"
    echo "OK: ~/.local-heavy exists and points to: $target"
    if [[ -d "$ANCHOR" ]]; then
        heavy_root="$(cd "$ANCHOR" && pwd -P)"
        echo "OK: target directory exists and is accessible: $heavy_root"
    else
        echo "WARNING: target directory does not exist yet: $target"
        echo "  Create it with: mkdir -p \"$target\""
    fi
    echo ""
    print_apply_instructions
elif [[ -e "$ANCHOR" ]]; then
    echo "WARNING: ~/.local-heavy exists but is NOT a symlink."
    echo "  It appears to be a real directory. Prefer a symlink to local disk."
    echo ""
    print_apply_instructions
else
    echo "MISSING: ~/.local-heavy does not exist."
    echo ""
    echo "To enable heavy storage redirection, create the anchor symlink once per machine:"
    echo ""
    echo "  # Replace the path below with your machine's local disk location:"
    echo "  LOCAL_DISK=/path/to/local/disk/home-mirror"
    echo "  mkdir -p \"\$LOCAL_DISK\""
    echo "  ln -s \"\$LOCAL_DISK\" ~/.local-heavy"
    echo ""
    echo "Then apply heavy packages:"
    echo ""
    print_apply_instructions
fi
