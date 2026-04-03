# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) and [Homebrew](https://brew.sh).

## What this repo does

| Concern | Tool | Split |
|---|---|---|
| Dotfiles | GNU Stow | `common` / `macos` / `linux` |
| Packages | `brew bundle` | `Brewfile.common` / `.macos` / `.linux` |
| Heavy storage redirection | GNU Stow | `heavy-links` + `heavy-dirs` |

**Heavy storage redirection** (optional): On machines where `$HOME` is space-constrained (NFS quota, small partition, etc.), tool-generated caches (Cargo, Rust, npm, Maven, VS Code Server, JetBrains, etc.) are redirected to a local disk via a user-created anchor symlink `~/.local-heavy`. The repo contains the symlink skeletons; each machine/user creates the anchor once. Machines without storage pressure can skip this entirely.

---

## Prerequisites

### macOS

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install GNU Stow
brew install stow
```

### Linux

```bash
# 1. Install Homebrew (Linuxbrew)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Follow the post-install instructions to add brew to your PATH.

# 2. Install GNU Stow (distro package or via brew)
# Ubuntu/Debian:
sudo apt install stow
# Or via brew:
brew install stow
```

> `brew bundle` (used to install from Brewfiles) is bundled with Homebrew — no extra install needed.

---

## Setup

`setup.sh` handles everything: detects your OS, installs packages via `brew bundle`, and stows dotfiles. It is safe to re-run at any time — `brew bundle` is idempotent and stow is invoked with `-R` (restow), which removes then re-creates symlinks. This handles re-runs, post-pull updates, conflict recovery, and new package additions cleanly.

```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles

bash scripts/setup.sh            # apply
bash scripts/setup.sh --dry-run  # preview: show missing packages and stow conflicts
```

On Linux, if `~/.local-heavy` exists, the heavy redirection packages are stowed automatically. See [Linux: heavy storage redirection](#linux-heavy-storage-redirection) for setup.

---

## Troubleshooting

**Stow reports a conflict**

Stow refuses to overwrite existing files or symlinks — including ones left over from a previous tool install. Use a dry run first to see all conflicts at once:

```bash
cd ~/dotfiles/stow
stow -n -R --target="$HOME" common        # preview conflicts without changing anything
```

For each conflicting path, back it up and remove it, then re-run:

```bash
mv ~/.zshrc ~/.zshrc.bak                  # conflicting dotfile — back up and remove
rm ~/.cargo                               # conflicting foreign symlink — just remove
cd ~/dotfiles/stow && stow -R --target="$HOME" common heavy-links
```

If the conflicting path is a real directory with content you want to keep (e.g. `~/.cargo` with existing crates), move it, restow, then migrate the content:

```bash
mv ~/.cargo ~/.cargo.bak
cd ~/dotfiles/stow && stow -R --target="$HOME" heavy-links
mv ~/.cargo.bak/* ~/.cargo/               # ~/.cargo now points to ~/.local-heavy/cargo
```

**`~/.local-heavy` is missing on Linux**

```bash
bash ~/dotfiles/scripts/check-linux-heavy.sh
```

The script prints whether the anchor exists, where it points, and copy/paste instructions if it's missing.

**Heavy paths not resolving correctly**

Verify the anchor exists and points to a real directory:

```bash
ls -la ~/.local-heavy    # should show -> /path/to/local/disk
ls ~/.local-heavy/       # should list subdirectories
```

---

## Manual brew and stow commands

Use these when you want fine-grained control, or on Linux without Homebrew.

### Brew

```bash
# Install / update — safe to rerun at any time
brew bundle --file brew/Brewfile.common
brew bundle --file brew/Brewfile.macos    # macOS only
brew bundle --file brew/Brewfile.linux    # Linux only

# Audit drift: packages installed but not in any Brewfile
brew leaves
```

### Stow

Always run stow from the `stow/` directory (or pass `-d stow/` from the repo root).

Prefer `stow -R` (restow) over plain `stow` — it removes then re-creates symlinks, making it safe to re-run after pulling updates, recovering from conflicts, or adding new packages.

```bash
cd ~/dotfiles/stow

# Dry run — preview what would be linked
stow -n -R --target="$HOME" common

# Apply (or re-apply safely)
stow -R --target="$HOME" common

# Remove links for a package
stow -D --target="$HOME" common
```

**macOS**

```bash
cd ~/dotfiles/stow
stow -R --target="$HOME" common macos
```

**Linux (no heavy redirection)**

```bash
cd ~/dotfiles/stow
stow -R --target="$HOME" common linux
```

---

## Linux: heavy storage redirection

Do this when `$HOME` is space-constrained and you want Cargo, Rust, npm, Maven, VS Code Server, JetBrains caches, etc. redirected to local disk.

### Step 1 — create the anchor symlink (machine-local, NOT in git)

```bash
# Replace with the path to your local disk. This is machine-specific and
# must never be committed to the repo.
LOCAL_DISK=/path/to/local/disk/home-mirror
mkdir -p "$LOCAL_DISK"
ln -s "$LOCAL_DISK" ~/.local-heavy
```

On a work machine with a shared workspace this might look like:

```bash
LOCAL_DISK=/local/mnt/workspace/$USER/home-mirror
```

On a personal Linux box it might be a local SSD:

```bash
LOCAL_DISK=/data/home-mirror
```

### Step 2 — run setup.sh (or stow manually)

```bash
bash ~/dotfiles/scripts/setup.sh
# heavy packages are stowed automatically when ~/.local-heavy exists
```

Or manually:

```bash
cd ~/dotfiles/stow
stow -R --target="$HOME" heavy-dirs heavy-links
```

### What this changes

- `heavy-dirs` stows the directory skeleton under `~/.local-heavy/`, using `.gitkeep` files to track structure without tracking runtime content.
- `heavy-links` stows symlinks in `$HOME` so that paths like `~/.cargo`, `~/.cache/uv`, `~/.vscode-server`, etc. resolve through `~/.local-heavy` and land on local disk.

To check anchor status at any time:

```bash
bash ~/dotfiles/scripts/check-linux-heavy.sh
```

### Paths redirected

| Home path | Redirects to |
|---|---|
| `~/.cargo` | `~/.local-heavy/cargo` |
| `~/.rustup` | `~/.local-heavy/rustup` |
| `~/.nvm` | `~/.local-heavy/nvm` |
| `~/.npm` | `~/.local-heavy/npm` |
| `~/.pnpm-store` | `~/.local-heavy/pnpm-store` |
| `~/.m2` | `~/.local-heavy/m2` |
| `~/.krew` | `~/.local-heavy/krew` |
| `~/.vscode-server` | `~/.local-heavy/vscode-server` |
| `~/.vscode-remote-containers` | `~/.local-heavy/vscode-remote-containers` |
| `~/.cache/JetBrains` | `~/.local-heavy/cache/JetBrains` |
| `~/.cache/sccache` | `~/.local-heavy/cache/sccache` |
| `~/.cache/uv` | `~/.local-heavy/cache/uv` |
| `~/.cache/pip` | `~/.local-heavy/cache/pip` |
| `~/.cache/helm` | `~/.local-heavy/cache/helm` |
| `~/.cache/pre-commit` | `~/.local-heavy/cache/pre-commit` |
| `~/.local/pipx` | `~/.local-heavy/local/pipx` |
| `~/.local/share/containers` | `~/.local-heavy/local/share/containers` |
| `~/.local/share/pipx` | `~/.local-heavy/local/share/pipx` |
| `~/.local/share/uv` | `~/.local-heavy/local/share/uv` |
| `~/.local/share/pnpm` | `~/.local-heavy/local/share/pnpm` |

---

## How to add a new dotfile

1. Place the file inside the appropriate stow package directory, mirroring the `$HOME` path:
   ```
   stow/common/.config/foo/config
   ```
2. Stow it:
   ```bash
   cd ~/dotfiles/stow
   stow -R --target="$HOME" common
   ```
3. Commit.

---

## How to add a new heavy path

Say you want to redirect `~/.new-tool` to local storage.

1. **Add the symlink** in `stow/heavy-links/`:
   ```bash
   cd ~/dotfiles/stow/heavy-links
   ln -s .local-heavy/new-tool .new-tool
   ```
   For nested paths like `~/.cache/new-tool`:
   ```bash
   ln -s ../.local-heavy/cache/new-tool .cache/new-tool
   ```

2. **Add the skeleton directory** in `stow/heavy-dirs/`:
   ```bash
   mkdir -p ~/dotfiles/stow/heavy-dirs/.local-heavy/new-tool
   touch    ~/dotfiles/stow/heavy-dirs/.local-heavy/new-tool/.gitkeep
   ```

3. `.gitignore` already covers `stow/heavy-dirs/.local-heavy/**/*` with an exception for `.gitkeep`, so no changes needed there.

4. Re-stow:
   ```bash
   cd ~/dotfiles/stow
   stow -R --target="$HOME" heavy-dirs heavy-links
   ```

5. Commit.

---

## Shell configuration (`.zshrc.d` fragments)

`~/.zshrc` is a thin loader that sources every `*.zsh` file in `~/.zshrc.d/` in lexical order. Config is split across fragments:

| Fragment | Stow package | What lives here |
|---|---|---|
| `~/.zshrc.d/00-common.zsh` | `common` | starship, zoxide, fzf, history, common aliases, shared PATH |
| `~/.zshrc.d/50-macos.zsh` | `macos` | NVM lazy-load (homebrew), SDKMAN, cargo env |
| `~/.zshrc.d/50-linux.zsh` | `linux` | Linuxbrew shellenv, cargo env, NVM, UID/GID export |
| `~/.zshrc.d/99-local.zsh` | *(not in git)* | Machine-specific: work certs, internal paths, personal tools |

Stow handles the OS split — `50-macos.zsh` and `50-linux.zsh` are mutually exclusive across machines. The loader silently skips missing fragments, so no OS guards are needed inside any file.

### Machine-local overrides (`99-local.zsh`)

Create this file by hand on each machine. It is never committed. Example content for a **work Linux** machine:

```zsh
# ~/.zshrc.d/99-local.zsh  — work Linux example (NOT in git)

# Local workspace aliases (path is machine-specific)
alias cdws='cd /local/mnt/workspace/$USER'
alias cdsw='cd /local/mnt/workspace/$USER/sw'

# pyenv (PYENV_ROOT is deliberately non-standard on this machine)
export PYENV_ROOT="$HOME/ws/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Work proxy / CA cert for Node
export NODE_EXTRA_CA_CERTS="/path/to/company-ca-bundle.pem"

# Local tool installs
export PATH="$PATH:/path/to/local/tools/bin"

# SSH agent cleanup on shell exit
trap 'test -n "$SSH_AGENT_PID" && eval `$(usr/bin/ssh-agent -k)`' 0
```

Example for a **work macOS** machine:

```zsh
# ~/.zshrc.d/99-local.zsh  — work macOS example (NOT in git)

# Work CA cert (Netskope / corporate MITM)
export NODE_EXTRA_CA_CERTS="/Library/Application Support/CompanyAgent/ca-bundle.pem"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ghcup
[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env"

# postgres (brew-installed, version-pinned)
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
```

Example for a **personal macOS** machine:

```zsh
# ~/.zshrc.d/99-local.zsh  — personal macOS example (NOT in git)

# Volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Local nvim build
export PATH="$HOME/tools/nvim-macos/bin:$PATH"

# VS Code CLI
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
```

---

## Important notes

- **Do not store secrets in this repo.** Git identity (name/email) lives in `~/.gitconfig.local` on each machine — create it once, never commit it:
  ```gitconfig
  # ~/.gitconfig.local
  [user]
      name  = Your Name
      email = you@example.com
  ```
- **`~/.local-heavy` is machine-local.** It must be created per machine/user and must never be committed.
- **The repo must not contain absolute work paths or usernames.** All paths in tracked files are relative or use `$HOME`/`~` placeholders.
