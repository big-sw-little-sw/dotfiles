#!/usr/bin/env bash
# bootstrap.sh — thin wrapper to install packages and stow dotfiles.
# Safe to re-run: brew bundle is idempotent; stow uses -R (restow).
#
# Usage:
#   bash scripts/bootstrap.sh            # apply
#   bash scripts/bootstrap.sh --dry-run  # preview: show missing packages and stow conflicts
#
# On Linux, heavy redirection is skipped if ~/.local-heavy is missing.
# Create it first (see scripts/check-linux-heavy.sh or README.md).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOW_DIR="$REPO_ROOT/stow"
BREW_DIR="$REPO_ROOT/brew"

# ── Parse flags ───────────────────────────────────────────────
DRY_RUN=false
for arg in "$@"; do
    [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

if $DRY_RUN; then
    echo "==> DRY RUN — no changes will be made"
fi

# ── Detect OS ────────────────────────────────────────────────
case "$(uname -s)" in
    Darwin) OS=macos ;;
    Linux)  OS=linux ;;
    *)      echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac

echo "==> Detected OS: $OS"

# ── Homebrew packages ─────────────────────────────────────────
# In dry-run mode, `brew bundle check` shows missing packages but exits non-zero
# if anything is absent — suppress that so the script continues to the stow preview.
if $DRY_RUN; then
    echo "==> Checking common packages (dry run)..."
    brew bundle check --verbose --file "$BREW_DIR/Brewfile.common" || true

    echo "==> Checking $OS packages (dry run)..."
    brew bundle check --verbose --file "$BREW_DIR/Brewfile.$OS" || true
else
    echo "==> Installing common packages..."
    brew bundle --file "$BREW_DIR/Brewfile.common"

    echo "==> Installing $OS packages..."
    brew bundle --file "$BREW_DIR/Brewfile.$OS"
fi

# ── Stow dotfiles ─────────────────────────────────────────────
# -n previews without applying; -R restows (remove + re-create) for idempotency.
STOW_FLAGS="-R"
$DRY_RUN && STOW_FLAGS="-n -R"

echo "==> Stowing common and $OS dotfiles..."
cd "$STOW_DIR"
stow $STOW_FLAGS --target="$HOME" common "$OS"

# ── Linux heavy redirection (optional) ───────────────────────
if [[ "$OS" == linux ]]; then
    if [[ -L "$HOME/.local-heavy" || -d "$HOME/.local-heavy" ]]; then
        echo "==> ~/.local-heavy found; stowing heavy packages..."
        stow $STOW_FLAGS --target="$HOME" heavy-dirs heavy-links
    else
        echo ""
        echo "WARNING: ~/.local-heavy is missing — skipping heavy redirection."
        echo "  If your home directory is space-constrained, create the anchor symlink"
        echo "  (see scripts/check-linux-heavy.sh), then re-run bootstrap.sh."
        echo "  Otherwise, no action needed."
    fi
fi

echo ""
$DRY_RUN && echo "Dry run complete — re-run without --dry-run to apply." || echo "Done."
