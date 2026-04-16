# ── Cargo env (Rust toolchain) ────────────────────────────────
[ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# ── NVM (lazy load; avoids slowing down every shell open) ─────
# NVM_DIR is set in 00-common.zsh; node/npm/npx etc. are on PATH via the
# alias resolution there.  Only `nvm` itself needs a lazy shim here.
nvm() {
  unfunction nvm
  local nvm_sh="/opt/homebrew/opt/nvm/nvm.sh"
  if [[ -s "$nvm_sh" ]]; then
    source "$nvm_sh"
  else
    print -u2 "nvm: nvm.sh not found at $nvm_sh"
    return 127
  fi
  nvm "$@"
}

# ── SDKMAN ────────────────────────────────────────────────────
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
