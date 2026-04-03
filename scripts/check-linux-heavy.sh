#!/usr/bin/env bash
# check-linux-heavy.sh — verify ~/.local-heavy anchor symlink status

set -euo pipefail

ANCHOR="$HOME/.local-heavy"

if [[ -L "$ANCHOR" ]]; then
    target="$(readlink "$ANCHOR")"
    echo "OK: ~/.local-heavy exists and points to: $target"
    if [[ -d "$ANCHOR" ]]; then
        echo "OK: target directory exists and is accessible."
    else
        echo "WARNING: target directory does not exist yet: $target"
        echo "  Create it with: mkdir -p $target"
    fi
elif [[ -e "$ANCHOR" ]]; then
    echo "WARNING: ~/.local-heavy exists but is NOT a symlink."
    echo "  It appears to be a real directory. Heavy stow packages expect it to be a symlink."
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
    echo "Then stow the heavy packages:"
    echo "  cd /path/to/dotfiles/stow"
    echo "  stow -R heavy-dirs heavy-links"
fi
