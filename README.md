# Zsh workstation setup

This repository contains one portable, hand-maintained [`.zshrc`](.zshrc).
Antigen downloads current Oh My Zsh libraries and plugins at install time; the
repository does not vendor an Oh My Zsh snapshot.

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

macOS includes `/bin/zsh`, which is sufficient. Install Homebrew, then install
the command-line tools:

```sh
brew install antigen atuin fzf pyenv uv zoxide
git clone https://github.com/meabed/zsh.git ~/.config/zsh
~/.config/zsh/install.sh
chsh -s /bin/zsh
exec /bin/zsh -l
```

Do not install Oh My Zsh separately. Antigen installs it when the first shell
starts.

## Debian and Ubuntu

Install the required system packages:

```sh
sudo apt-get update
sudo apt-get install -y curl fzf git zsh
```

The installer uses a packaged Antigen installation when available. Otherwise,
it clones Antigen into `~/.local/share/antigen`.

Install the optional tools you want. The same Homebrew command works on Linux
when Linuxbrew is available:

```sh
brew install atuin fzf pyenv uv zoxide
```

Without Linuxbrew, use each project's supported installation method:

```sh
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh |
  sh -s -- --non-interactive
curl -LsSf https://astral.sh/uv/install.sh | sh
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh |
  sh
```

Review downloaded installers before executing them if the machine's security
policy requires it. pyenv's Linux build dependencies and installer are
documented at <https://github.com/pyenv/pyenv#installation>.

Install the configuration last so another installer cannot replace it:

```sh
git clone https://github.com/meabed/zsh.git ~/.config/zsh
~/.config/zsh/install.sh
chsh -s "$(command -v zsh)"
exec zsh -l
```

## What the installer does

`install.sh`:

1. validates the repository's `.zshrc`;
2. checks for Zsh and Git;
3. finds Antigen or clones it when missing;
4. backs up an existing `~/.zshrc`;
5. links this repository's `.zshrc` to `~/.zshrc`;
6. creates a private `~/.zsh_secrets` file when needed;
7. reports missing optional tools without installing them.

It does not change the login shell or install system packages.

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
antigen update
```

Update optional Homebrew packages separately:

```sh
brew upgrade atuin fzf pyenv uv zoxide
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
