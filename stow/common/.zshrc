# Managed by GNU Stow — edit in dotfiles/stow/common/.zshrc
# Thin loader: source every fragment in ~/.zshrc.d in lexical order.
# Drop a ~/.zshrc.d/99-local.zsh for machine-specific overrides (not in git).

for _f in "${ZDOTDIR:-$HOME}"/.zshrc.d/*.zsh(N); do
  source "$_f"
done
unset _f
