# ── Cargo env (Rust toolchain) ────────────────────────────────
[ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# ── NVM (lazy load; avoids slowing down every shell open) ─────
export NVM_DIR="$HOME/.nvm"

_nvm_lazy_load() {
  local nvm_sh="/opt/homebrew/opt/nvm/nvm.sh"
  unalias nvm 2>/dev/null
  if [ -s "$nvm_sh" ]; then
    . "$nvm_sh"
  else
    print -u2 "nvm lazy-load: nvm.sh not found at $nvm_sh"
    return 127
  fi
  unfunction _nvm_lazy_load 2>/dev/null
}

# Shim binaries that appear only after nvm sets PATH.
for _cmd in node npm npx corepack yarn pnpm; do
  eval "
  function $_cmd() {
    _nvm_lazy_load || return \$?
    unfunction $_cmd 2>/dev/null
    command $_cmd \"\$@\"
  }"
done
unset _cmd

_nvm_invoke() {
  _nvm_lazy_load || return $?
  typeset -f nvm >/dev/null || { print -u2 "nvm: function unavailable after load"; return 127; }
  nvm "$@"
}
alias nvm='_nvm_invoke'

# ── SDKMAN ────────────────────────────────────────────────────
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
