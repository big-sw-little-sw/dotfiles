#!/usr/bin/env bash
# bootstrap.sh — thin wrapper to install packages and stow dotfiles.
#
# Usage:
#   bash scripts/bootstrap.sh
#
# On Linux, heavy redirection is skipped if ~/.local-heavy is missing.
# Create it first (see scripts/check-linux-heavy.sh or README.md).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOW_DIR="$REPO_ROOT/stow"
BREW_DIR="$REPO_ROOT/brew"

# ── Detect OS ────────────────────────────────────────────────
case "$(uname -s)" in
    Darwin) OS=macos ;;
    Linux)  OS=linux ;;
    *)      echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac

echo "==> Detected OS: $OS"

# ── Homebrew packages ─────────────────────────────────────────
echo "==> Installing common packages..."
brew bundle --file "$BREW_DIR/Brewfile.common"

echo "==> Installing $OS packages..."
brew bundle --file "$BREW_DIR/Brewfile.$OS"

# ── Stow dotfiles ─────────────────────────────────────────────
echo "==> Stowing common and $OS dotfiles..."
cd "$STOW_DIR"
stow --target="$HOME" common "$OS"

# ── Linux heavy redirection (optional) ───────────────────────
if [[ "$OS" == linux ]]; then
    if [[ -L "$HOME/.local-heavy" || -d "$HOME/.local-heavy" ]]; then
        echo "==> ~/.local-heavy found; stowing heavy packages..."
        stow --target="$HOME" linux-heavy-dirs linux-heavy-links
    else
        echo ""
        echo "WARNING: ~/.local-heavy is missing — skipping heavy redirection."
        echo "  Run scripts/check-linux-heavy.sh for setup instructions."
        echo "  Once created, re-run:"
        echo "    cd $STOW_DIR && stow linux-heavy-dirs linux-heavy-links"
    fi
fi

echo ""
echo "Done."
