# Managed by GNU Stow — edit in dotfiles/stow/common/.zshrc

# ── Starship prompt ──────────────────────────────────────────
eval "$(starship init zsh)"

# ── zoxide (smarter cd) ──────────────────────────────────────
eval "$(zoxide init zsh)"

# ── fzf key bindings ─────────────────────────────────────────
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ── Aliases ──────────────────────────────────────────────────
alias ls='eza --group-directories-first'
alias ll='eza -lh --group-directories-first'
alias la='eza -lah --group-directories-first'
alias tree='eza --tree'
alias cat='bat --paging=never'
alias grep='rg'
alias find='fd'
alias top='btm'
alias ps='procs'
alias du='dust'
alias lg='lazygit'
alias ld='lazydocker'

# ── PATH additions ────────────────────────────────────────────
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.krew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
