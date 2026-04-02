# ── Homebrew (Linuxbrew) ──────────────────────────────────────
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# ── Required by some container/OCI tools ─────────────────────
export UID
export GID

# ── Cargo env (Rust toolchain) ────────────────────────────────
[ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# ── NVM ───────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
