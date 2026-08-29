# Zsh workstation setup

This repository contains one portable, hand-maintained [`.zshrc`](.zshrc).
Antigen downloads current Oh My Zsh libraries and plugins at install time; the
repository does not vendor an Oh My Zsh snapshot.

For maintenance decisions, primary research, known failure modes, and the
continuation checklist, read [`AGENTS.md`](AGENTS.md).

The configuration provides:

- the `steeef` prompt;
- Git and common Oh My Zsh aliases;
- Docker and Docker Compose v2 aliases and completion;
- guarded macOS, Homebrew, Debian, and systemd helpers;
- colored man pages, archive extraction, and clipboard helpers;
- Atuin global history search;
- `fzf` shell widgets;
- `zoxide` directory jumping;
- `uv` and `uvx` completions and aliases;
- additional Zsh completions and fast syntax highlighting;
- Docker, Bun, Google Cloud, pyenv, Android, and iTerm2 integration when those
  tools exist.

Every optional integration is guarded. A missing optional command does not
break shell startup.

## macOS

macOS includes `/bin/zsh`, which is sufficient. Install Homebrew, then run:

```sh
git clone https://github.com/meabed/zsh.git ~/.config/zsh
~/.config/zsh/install.sh --packages
chsh -s /bin/zsh
exec /bin/zsh -l
```

Package mode installs these Homebrew formulae:

```text
antigen atuin btop curl fzf git htop jq ncdu pyenv ripgrep rsync
tmux tree uv wget zoxide
```

macOS already provides tools such as `dig`, `lsof`, `time`, `unzip`, and `zip`.
Install Docker Desktop separately if you want the Docker integration.

Do not install Oh My Zsh separately. Antigen installs it when the first shell
starts.

## Debian and Ubuntu

Install curl and Git so you can clone this repository:

```sh
sudo apt-get update
sudo apt-get install -y curl git
git clone https://github.com/meabed/zsh.git ~/.config/zsh
~/.config/zsh/install.sh --packages
chsh -s "$(command -v zsh)"
exec zsh -l
```

Package mode installs these Debian or Ubuntu packages:

```text
btop ca-certificates curl dnsutils fzf git htop jq less locales lsof
ncdu ripgrep rsync tar time tmux tree unzip wget zip zsh
```

It also installs the latest Atuin, uv, and zoxide releases and tracks pyenv's
`master` branch. Their installers do not append extra shell configuration.
Antigen is cloned when no system installation exists.

Review downloaded installers before executing them if the machine's security
policy requires it.

## What the installer does

`install.sh`:

1. optionally installs recommended tools with `--packages`;
2. validates the repository's `.zshrc`;
3. checks for Zsh and Git;
4. finds Antigen or clones it when missing;
5. backs up an existing `~/.zshrc`;
6. links this repository's `.zshrc` to `~/.zshrc`;
7. creates a private `~/.zsh_secrets` file when needed;
8. reports any missing optional shell tools.

Without `--packages`, it changes no system packages. It never changes the login
shell automatically.

## History and navigation

- **Up arrow:** global prefix history search.
- **Ctrl-R:** global fuzzy history search.
- **Ctrl-R again inside Atuin:** cycle its enabled filters, including directory
  history.
- **Ctrl-T:** choose a file with `fzf`.
- **Alt-C:** choose a directory with `fzf`.
- **z query:** jump to a frequently used directory with `zoxide`.
- **zi:** choose a known directory interactively.

Import an existing Zsh history once:

```sh
HISTFILE="$HOME/.zsh_history" atuin import zsh
```

Atuin keeps its database in `~/.local/share/atuin`. Native Zsh continues to
write `~/.zsh_history` as a fallback.

The duration and relative-time columns in Atuin are display metadata. They are
not part of the saved command.

## uv plugin

The Oh My Zsh `uv` plugin generates current completions for both `uv` and
`uvx`. It also provides aliases including:

| Alias | Command |
| --- | --- |
| `uva` | `uv add` |
| `uvi` | `uv init` |
| `uvl` | `uv lock` |
| `uvr` | `uv run` |
| `uvs` | `uv sync` |
| `uvv` | `uv venv` |

Run `alias | grep '^uv'` to list every active alias.

## Shell plugins

The core plugin set works on macOS and Linux:

- `docker` and `docker-compose` load when Docker exists. Compose aliases use
  `docker compose` when the legacy `docker-compose` command is absent.
- `colored-man-pages`, `extract`, `copyfile`, and `copypath` improve common
  terminal tasks.
- `sudo` makes `Esc Esc` add or remove `sudo` at the start of the command line.
- `brew` and `macos` load only on supported machines.
- `debian` and `systemd` load only on matching Linux systems.
- `gh` and `kubectl` load only when their commands exist.

The configuration does not load history, directory-jump, or fuzzy-search
plugins that duplicate Atuin, zoxide, or fzf.

## Local values

Put tokens and machine-specific environment variables in
`~/.zsh_secrets`. Keep that file private:

```sh
chmod 600 ~/.zsh_secrets
```

Never commit `.zsh_secrets`, history databases, or completion caches.

## Maintenance

Update this configuration and its plugins deliberately:

```sh
git -C ~/.config/zsh pull --ff-only
~/.config/zsh/install.sh --packages
antigen update
```

To update every Homebrew package instead, use:

```sh
brew upgrade
```

Useful commands defined by the configuration:

- `zshconfig` opens `~/.zshrc`;
- `zshcheck` validates it;
- `zshreload` starts a fresh login shell.

## Verification

```sh
zsh -n ~/.zshrc
atuin doctor
exec zsh -l
```

Shell startup should be silent. The configuration initializes `compinit`
once and keeps the terminal-provided `TERM` value.

## Sources

- [Zsh documentation](https://zsh.sourceforge.io/Doc/)
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [Antigen](https://github.com/zsh-users/antigen)
- [Atuin](https://docs.atuin.sh/)
- [fzf](https://github.com/junegunn/fzf)
- [uv](https://docs.astral.sh/uv/)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-completions](https://github.com/zsh-users/zsh-completions)
- [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
- [iTerm2 shell integration](https://iterm2.com/documentation-shell-integration.html)
