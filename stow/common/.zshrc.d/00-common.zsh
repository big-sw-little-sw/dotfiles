# ── Prompt / shell enhancements ──────────────────────────────
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"

# ── History ───────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

# ── Python ────────────────────────────────────────────────────
export PIPENV_VENV_IN_PROJECT=true

# ── PATH ──────────────────────────────────────────────────────
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# ── Node / NVM ────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"

# Resolve nvm's default alias to its bin dir and add it to PATH eagerly.
# This makes `npm install -g` binaries available without sourcing nvm.sh,
# and works on both macOS and Linux regardless of how nvm was installed.
() {
  [[ -d "$NVM_DIR" ]] || return
  local ver="$NVM_DIR/alias/default"
  [[ -r "$ver" ]] || return
  ver=$(< "$ver")
  local i=0
  while [[ -f "$NVM_DIR/alias/$ver" && $((++i)) -lt 5 ]]; do
    ver=$(< "$NVM_DIR/alias/$ver")
  done
  local bin="$NVM_DIR/versions/node/$ver/bin"
  # If the aliased version isn't installed, fall back to the latest installed node.
  if [[ ! -d "$bin" ]]; then
    local fallback
    fallback=$(ls -t "$NVM_DIR/versions/node/" 2>/dev/null | head -1)
    [[ -n "$fallback" ]] && bin="$NVM_DIR/versions/node/$fallback/bin"
  fi
  [[ -d "$bin" ]] && export PATH="$bin:$PATH"
}

# ── Aliases ───────────────────────────────────────────────────
alias ls='eza --color=always --icons=always'
alias ll='eza --color=always --git --icons=always -lga'
alias la='eza --color=always --icons=always -a'
alias tree='eza --tree'
