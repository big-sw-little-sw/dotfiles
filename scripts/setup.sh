#!/usr/bin/env bash
# setup.sh — thin wrapper to install packages and/or stow dotfiles.
# Safe to re-run: brew bundle is idempotent; stow uses -R (restow).
#
# Usage:
#   bash scripts/setup.sh                 # brew + stow (default)
#   bash scripts/setup.sh --brew          # Homebrew packages only
#   bash scripts/setup.sh --stow          # stow / heavy-links only
#   bash scripts/setup.sh --brew --stow   # same as default
#   bash scripts/setup.sh --dry-run       # preview without applying
#   bash scripts/setup.sh --stow --dry-run
#
# On Linux, heavy redirection is skipped if ~/.local-heavy is missing.
# Create it first (see scripts/check-linux-heavy.sh or README.md).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOW_DIR="$REPO_ROOT/stow"
BREW_DIR="$REPO_ROOT/brew"

usage() {
    cat <<'EOF'
Usage: bash scripts/setup.sh [options]

  (no brew/stow flags)   Run both brew and stow (default)
  --brew                 Install/update Homebrew packages
  --stow                 Stow dotfiles (and heavy redirection on Linux)
  --dry-run              Preview only; make no changes
  -h, --help             Show this help

Examples:
  bash scripts/setup.sh
  bash scripts/setup.sh --stow
  bash scripts/setup.sh --brew --dry-run
EOF
}

# ── Parse flags ───────────────────────────────────────────────
DRY_RUN=false
DO_BREW=false
DO_STOW=false
SELECTIVE=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --brew)    DO_BREW=true; SELECTIVE=true ;;
        --stow)    DO_STOW=true; SELECTIVE=true ;;
        -h|--help) usage; exit 0 ;;
        *)
            echo "Unknown argument: $arg" >&2
            usage >&2
            exit 2
            ;;
    esac
done

# Default: both. If any selector was passed, only run the selected steps.
if ! $SELECTIVE; then
    DO_BREW=true
    DO_STOW=true
fi

if $DRY_RUN; then
    echo "==> DRY RUN — no changes will be made"
fi

steps=()
$DO_BREW && steps+=("brew")
$DO_STOW && steps+=("stow")
echo "==> Steps: ${steps[*]}"

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
if $DO_BREW; then
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
fi

# ── Stow dotfiles ─────────────────────────────────────────────
# -n previews without applying; -R restows (remove + re-create) for idempotency.
if $DO_STOW; then
    STOW_FLAGS="-R"
    $DRY_RUN && STOW_FLAGS="-n -R"

    echo "==> Stowing common and $OS dotfiles..."
    cd "$STOW_DIR"
    stow $STOW_FLAGS --target="$HOME" common "$OS"

    # ── Linux heavy redirection (optional) ───────────────────────
    # heavy-dirs  → stowed into the local disk that ~/.local-heavy points at
    # heavy-links → applied into $HOME as one-hop relative symlinks (see
    #               scripts/apply-heavy-links.sh — do not `stow heavy-links`)
    if [[ "$OS" == linux ]]; then
        if [[ -L "$HOME/.local-heavy" || -d "$HOME/.local-heavy" ]]; then
            HEAVY_ROOT="$(cd "$HOME/.local-heavy" && pwd -P)"
            echo "==> ~/.local-heavy found -> $HEAVY_ROOT"
            # --no-folding: create real directories on the local disk and only symlink
            # leaf files (.gitkeep). Tree-folding would make cargo/ etc. symlinks
            # into the repo, and runtime data would land in the checkout.
            echo "==> Stowing heavy-dirs into local disk..."
            stow $STOW_FLAGS --no-folding --target="$HEAVY_ROOT" heavy-dirs
            echo "==> Applying heavy-links into \$HOME..."
            if $DRY_RUN; then
                bash "$REPO_ROOT/scripts/apply-heavy-links.sh" --dry-run
            else
                bash "$REPO_ROOT/scripts/apply-heavy-links.sh"
            fi
        else
            echo ""
            echo "WARNING: ~/.local-heavy is missing — skipping heavy redirection."
            echo "  If your home directory is space-constrained, create the anchor symlink"
            echo "  (see scripts/check-linux-heavy.sh), then re-run: bash scripts/setup.sh --stow"
            echo "  Otherwise, no action needed."
        fi
    fi
fi

echo ""
$DRY_RUN && echo "Dry run complete — re-run without --dry-run to apply." || echo "Done."
