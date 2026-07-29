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
# Stow mode is chosen by ~/.local-heavy:
#   present (Linux)  → heavy-dirs + agent-guidance-heavy + heavy-links
#   absent           → normal agent-guidance-* into $HOME (--no-folding)
#
# On Linux without the anchor, heavy redirection is skipped. Create it first
# if needed (see scripts/check-linux-heavy.sh or README.md).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOW_DIR="$REPO_ROOT/stow"
BREW_DIR="$REPO_ROOT/brew"

# Normal-mode agent guidance packages (mutually exclusive with agent-guidance-heavy).
AGENT_GUIDANCE_NORMAL=(
    agent-guidance-claude
    agent-guidance-codex
    agent-guidance-cursor
    agent-guidance-opencode
    agent-guidance-pi
    agent-guidance-cline
)

usage() {
    cat <<'EOF'
Usage: bash scripts/setup.sh [options]

  (no brew/stow flags)   Run both brew and stow (default)
  --brew                 Install/update Homebrew packages
  --stow                 Stow dotfiles (+ agent guidance; heavy if ~/.local-heavy)
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

    # Heavy mode: Linux + ~/.local-heavy anchor.
    # Normal mode: everywhere else (macOS, or Linux without the anchor).
    USE_HEAVY=false
    if [[ "$OS" == linux ]] && [[ -L "$HOME/.local-heavy" || -d "$HOME/.local-heavy" ]]; then
        USE_HEAVY=true
    fi

    if $USE_HEAVY; then
        HEAVY_ROOT="$(cd "$HOME/.local-heavy" && pwd -P)"
        echo "==> ~/.local-heavy found -> $HEAVY_ROOT (heavy mode)"
        # --no-folding: create real directories on the local disk and only symlink
        # leaf files. Tree-folding would make cargo/ etc. symlinks into the repo,
        # and runtime data would land in the checkout.
        echo "==> Stowing heavy-dirs + agent-guidance-heavy into local disk..."
        stow $STOW_FLAGS --no-folding --target="$HEAVY_ROOT" \
            heavy-dirs agent-guidance-heavy
        echo "==> Applying heavy-links into \$HOME..."
        if $DRY_RUN; then
            bash "$REPO_ROOT/scripts/apply-heavy-links.sh" --dry-run
        else
            bash "$REPO_ROOT/scripts/apply-heavy-links.sh"
        fi
    else
        if [[ "$OS" == linux ]]; then
            echo "==> ~/.local-heavy missing — normal mode (no heavy redirection)."
            echo "    Create the anchor (see scripts/check-linux-heavy.sh) and re-run"
            echo "    setup.sh --stow if you want caches on local disk."
        else
            echo "==> Normal mode (no ~/.local-heavy heavy workflow on this OS)."
        fi
        echo "==> Stowing normal agent-guidance packages into \$HOME..."
        stow $STOW_FLAGS --no-folding --target="$HOME" \
            "${AGENT_GUIDANCE_NORMAL[@]}"
    fi
fi

echo ""
$DRY_RUN && echo "Dry run complete — re-run without --dry-run to apply." || echo "Done."
