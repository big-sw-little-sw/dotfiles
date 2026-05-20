# Agent guidance dotfiles notes

This is a human deployment note, not an agent instruction file. Do not symlink this file into any tool guidance path.

## Short answer

Keep `common` as the canonical guidance text only. Keep tool-facing agent guidance in separate Stow packages.

```text
common
- Canonical text only:
  ~/.config/agent-guidance/global-agent-defaults.md

agent-guidance-claude / agent-guidance-codex / ...
- Normal mode: tool directories live directly under $HOME.

heavy-links + heavy-dirs + agent-guidance-heavy
- Heavy mode: tool directories are redirected through ~/.local-heavy.
```

Do not put all tool-facing guidance under `common` unless you want every machine to install every tool's guidance files and you never plan to redirect those tool directories through heavy storage.

## Why not put all agent guidance under `common`?

Putting everything under `common` is convenient because your existing setup already stows `common`. The cost is hidden ownership.

If `common` owns files like these:

```text
~/.claude/CLAUDE.md
~/.codex/AGENTS.md
~/.pi/agent/AGENTS.md
~/.config/opencode/AGENTS.md
```

then every machine gets those tool directories, even if the tool is not used there. It also conflicts with heavy mode, where the whole tool directory may be redirected:

```text
~/.claude -> ~/.local-heavy/agent-tools/claude
```

For a given tool path, pick one owner:

```text
Normal owner:
- agent-guidance-claude owns ~/.claude/CLAUDE.md

Heavy owner:
- heavy-links owns ~/.claude
- heavy-dirs owns the ~/.local-heavy skeleton
- agent-guidance-heavy owns ~/.local-heavy/agent-tools/claude/CLAUDE.md
```

`common` should not also own nested files under that same tool directory.

## Package responsibilities

```text
stow/common/
- Canonical global guidance text.
- Safe to stow everywhere.

stow/agent-guidance-*/
- Normal-mode tool-facing guidance files.
- Use when the tool directory lives directly under $HOME.

stow/heavy-links/
- $HOME redirects into ~/.local-heavy.
- Storage policy only.

stow/heavy-dirs/
- ~/.local-heavy skeleton directories and .gitkeep files only.
- No durable guidance files here.

stow/agent-guidance-heavy/
- Heavy-mode durable guidance files inside ~/.local-heavy targets.
- Separate from heavy-dirs so no .gitignore allowlist is needed.
```

## Copying these packages into dotfiles

The Stow tree contains symlinks for heavy-directory redirection. Copy it with `rsync -a` or `cp -a`. Do not use plain `cp -r`.

```bash
rsync -a agent-design-guidance-v1.8/dotfiles/stow/ ~/sw/code/dotfiles/stow/
rsync -a agent-design-guidance-v1.8/dotfiles/README_AGENT_GUIDANCE.md ~/sw/code/dotfiles/README_AGENT_GUIDANCE.md
```

## Scenario 1: macOS or Linux without heavy redirection

Use this when tool directories should live directly under `$HOME`.

Choose only the tools you want:

```bash
cd ~/sw/code/dotfiles/stow

stow -n -R --target="$HOME" common \
  agent-guidance-claude \
  agent-guidance-codex \
  agent-guidance-opencode \
  agent-guidance-pi \
  agent-guidance-cline

# If the dry-run looks good:
stow -R --target="$HOME" common \
  agent-guidance-claude \
  agent-guidance-codex \
  agent-guidance-opencode \
  agent-guidance-pi \
  agent-guidance-cline
```

For a single tool:

```bash
stow -n -R --target="$HOME" common agent-guidance-claude
stow -R --target="$HOME" common agent-guidance-claude
```

### Normal-mode directory-folding warning

GNU Stow may fold a missing directory by making the whole directory a symlink into the dotfiles package. For tool directories that generate runtime data, that is usually undesirable.

Before stowing a normal tool-guidance package, either pre-create the tool directories:

```bash
mkdir -p ~/.claude ~/.codex ~/.config/opencode ~/.pi/agent ~/.cline/rules
```

or stow that package with no folding, if your Stow version supports it:

```bash
stow --no-folding -R --target="$HOME" agent-guidance-claude
```

## Scenario 2: Linux with heavy redirection for agent tool dirs

Use this when agent tool directories should live under `~/.local-heavy`.

Prerequisite: `~/.local-heavy` exists and points to a machine-local disk.

```bash
cd ~/sw/code/dotfiles/stow
stow -n -R --target="$HOME" common linux heavy-dirs heavy-links agent-guidance-heavy

# If the dry-run looks good:
stow -R --target="$HOME" common linux heavy-dirs heavy-links agent-guidance-heavy
```

Do not also stow the normal package for the same redirected tool path.

For example, choose one:

```text
Claude normal:
- agent-guidance-claude

Claude heavy:
- heavy-dirs + heavy-links + agent-guidance-heavy
```

Do not use both for `~/.claude`.

Heavy mode adds these agent redirects:

```text
~/.claude           -> ~/.local-heavy/agent-tools/claude
~/.codex            -> ~/.local-heavy/agent-tools/codex
~/.config/opencode  -> ~/.local-heavy/agent-tools/opencode
~/.pi               -> ~/.local-heavy/agent-tools/pi
~/.cline            -> ~/.local-heavy/agent-tools/cline
~/.cursor           -> ~/.local-heavy/agent-tools/cursor
~/.agents           -> ~/.local-heavy/agent-tools/agents
~/.clinerules       -> ~/.local-heavy/agent-tools/clinerules
```

`agent-guidance-heavy` places guidance files for Claude, Codex, OpenCode, Pi, and Cline inside those heavy targets.

## Scenario 3: Existing local tool directories

Before stowing, check whether a path already exists:

```bash
ls -la ~/.claude ~/.codex ~/.config/opencode ~/.pi ~/.cline ~/.agents ~/.clinerules 2>/dev/null
```

If a path is a real directory with data you want to keep, do not delete it casually.

For normal mode:

- If the directory already exists, Stow can place the guidance file inside it.
- If Stow reports a conflict on an existing guidance file, inspect and back it up before replacing it.

For heavy mode:

1. Move the existing directory aside.
2. Stow `heavy-dirs heavy-links agent-guidance-heavy`.
3. Copy wanted runtime content into the new heavy target.
4. Remove the backup only after verifying the tool works.

Example for Claude:

```bash
mv ~/.claude ~/.claude.bak
cd ~/sw/code/dotfiles/stow
stow -R --target="$HOME" heavy-dirs heavy-links agent-guidance-heavy
rsync -a ~/.claude.bak/ ~/.claude/
```

Then verify:

```bash
readlink ~/.claude
ls -la ~/.claude/CLAUDE.md
```

## Scenario 4: Existing project repos

Dotfiles global guidance and `my-agent-config` project skills are separate concerns.

For an existing project repo:

```bash
cd /path/to/project
python .agent-config/user/common/setup.py install
```

That installs project-local skills and commands. It does not replace the dotfiles global guidance packages.

Use dotfiles for always-on home-level guidance. Use `my-agent-config` for reusable project/global skills.

## Scenario 5: Updating the dotfiles repo later

After pulling dotfiles updates, re-run Stow with the same package set you chose for that machine.

Normal mode example:

```bash
cd ~/sw/code/dotfiles
git pull
cd stow
stow -n -R --target="$HOME" common macos agent-guidance-claude agent-guidance-codex
stow -R --target="$HOME" common macos agent-guidance-claude agent-guidance-codex
```

Heavy mode example:

```bash
cd ~/sw/code/dotfiles
git pull
cd stow
stow -n -R --target="$HOME" common linux heavy-dirs heavy-links agent-guidance-heavy
stow -R --target="$HOME" common linux heavy-dirs heavy-links agent-guidance-heavy
```

Your current `scripts/setup.sh` may stow only `common`, the OS package, and heavy packages. If you want agent guidance packages to be applied automatically, update `setup.sh` to include the same package set you otherwise run manually.

## Scenario 6: Switching a tool from normal to heavy mode

Example: Claude was normal and you now want it heavy.

```bash
cd ~/sw/code/dotfiles/stow
stow -D --target="$HOME" agent-guidance-claude
```

Then migrate the existing directory:

```bash
mv ~/.claude ~/.claude.bak
stow -R --target="$HOME" heavy-dirs heavy-links agent-guidance-heavy
rsync -a ~/.claude.bak/ ~/.claude/
```

Verify before deleting the backup:

```bash
readlink ~/.claude
ls -la ~/.claude/CLAUDE.md
```

## Scenario 7: Switching a tool from heavy to normal mode

Example: Claude was heavy and you now want it normal.

This is less common. Be careful because `heavy-links` may own more than Claude.

If all heavy paths are being removed:

```bash
cd ~/sw/code/dotfiles/stow
stow -D --target="$HOME" agent-guidance-heavy heavy-links heavy-dirs
```

Then restore or create the normal directory and stow the normal package:

```bash
mkdir -p ~/.claude
stow -R --target="$HOME" agent-guidance-claude
```

If only one tool should stop being heavy while others remain heavy, the current grouped `heavy-links` package is not ideal. Split the relevant heavy path into a per-tool package first, or handle the migration manually.

## Setup script integration

There are two reasonable choices.

### Keep package choice manual

Do nothing to `scripts/setup.sh`. Continue to run `stow` manually for agent guidance packages after setup.

This is explicit and safest while the package choices are still settling.

### Teach setup.sh about agent guidance

Add selected package names to the setup script. For example:

```bash
# macOS normal guidance example
stow $STOW_FLAGS --target="$HOME" common "$OS" \
  agent-guidance-claude \
  agent-guidance-codex
```

For Linux heavy mode, add `agent-guidance-heavy` to the existing heavy package command:

```bash
stow $STOW_FLAGS --target="$HOME" heavy-dirs heavy-links agent-guidance-heavy
```

Keep this machine/profile-specific. Do not hide normal vs heavy decisions inside `common`.

## Source of truth for guidance text

The canonical text is:

```text
stow/common/.config/agent-guidance/global-agent-defaults.md
```

Tool-facing files in normal and heavy Stow packages are regular-file copies for copy/Stow robustness. If you change the canonical global defaults, refresh those copies before committing.

Suggested refresh command from the dotfiles repo root:

```bash
src=stow/common/.config/agent-guidance/global-agent-defaults.md
cp "$src" stow/agent-guidance-claude/.claude/CLAUDE.md
cp "$src" stow/agent-guidance-codex/.codex/AGENTS.md
cp "$src" stow/agent-guidance-opencode/.config/opencode/AGENTS.md
cp "$src" stow/agent-guidance-pi/.pi/agent/AGENTS.md
cp "$src" stow/agent-guidance-cline/.cline/rules/global-agent-defaults.md
cp "$src" stow/agent-guidance-heavy/.local-heavy/agent-tools/claude/CLAUDE.md
cp "$src" stow/agent-guidance-heavy/.local-heavy/agent-tools/codex/AGENTS.md
cp "$src" stow/agent-guidance-heavy/.local-heavy/agent-tools/opencode/AGENTS.md
cp "$src" stow/agent-guidance-heavy/.local-heavy/agent-tools/pi/agent/AGENTS.md
cp "$src" stow/agent-guidance-heavy/.local-heavy/agent-tools/cline/rules/global-agent-defaults.md
```

## Verification commands

Normal mode examples:

```bash
readlink ~/.claude/CLAUDE.md
cat ~/.claude/CLAUDE.md | head
```

Heavy mode examples:

```bash
readlink ~/.claude
ls -la ~/.local-heavy/agent-tools/claude/CLAUDE.md
cat ~/.claude/CLAUDE.md | head
```

Run a Stow dry-run before applying changes:

```bash
cd ~/sw/code/dotfiles/stow
stow -n -R --target="$HOME" common agent-guidance-claude
```
