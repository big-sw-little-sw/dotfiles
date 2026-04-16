# ── Homebrew (Linuxbrew) ──────────────────────────────────────
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# ── Required by some container/OCI tools ─────────────────────
export UID
export GID

# ── Cargo env (Rust toolchain) ────────────────────────────────
[ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# ── NVM (lazy load) ───────────────────────────────────────────
# NVM_DIR is set in 00-common.zsh; node/npm/npx etc. are on PATH via the
# alias resolution there.  Only `nvm` itself needs a lazy shim here.
nvm() {
  unfunction nvm
  local nvm_sh="$NVM_DIR/nvm.sh"
  if [[ -s "$nvm_sh" ]]; then
    source "$nvm_sh"
  else
    print -u2 "nvm: nvm.sh not found at $nvm_sh"
    return 127
  fi
  nvm "$@"
}
