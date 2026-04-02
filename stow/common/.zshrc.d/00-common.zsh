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

# ── Aliases ───────────────────────────────────────────────────
alias ls='eza --color=always --icons=always'
alias ll='eza --color=always --git --icons=always -lga'
alias la='eza --color=always --icons=always -a'
alias tree='eza --tree'
alias cat='bat --paging=never'
alias grep='rg'
alias find='fd'
alias top='btm'
alias ps='procs'
alias du='dust'
alias lg='lazygit'
alias ld='lazydocker'
