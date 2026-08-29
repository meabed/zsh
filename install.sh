#!/bin/sh

set -eu

usage() {
  printf 'Usage: %s [--packages]\n' "$0"
  printf '  --packages  Install recommended macOS or Debian/Ubuntu tools first.\n'
}

install_packages=0
case "${1:-}" in
  '') ;;
  --packages)
    install_packages=1
    shift
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if [ "$#" -ne 0 ]; then
  usage >&2
  exit 2
fi

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    printf 'error: sudo or a root shell is required to install system packages\n' >&2
    return 1
  fi
}

install_recommended_packages() {
  export PATH="$HOME/.atuin/bin:$HOME/.local/bin:$HOME/.pyenv/bin:$PATH"

  case "$(uname -s)" in
    Darwin)
      if ! command -v brew >/dev/null 2>&1; then
        printf 'error: Homebrew is required for --packages on macOS\n' >&2
        return 1
      fi

      printf 'scope: install recommended Homebrew formulae\n'
      brew install \
        antigen atuin btop curl fzf git htop jq ncdu pyenv ripgrep rsync \
        tmux tree uv wget zoxide
      ;;
    Linux)
      if ! command -v apt-get >/dev/null 2>&1; then
        printf 'error: --packages currently supports Debian and Ubuntu Linux\n' >&2
        return 1
      fi

      printf 'scope: install recommended Debian or Ubuntu packages\n'
      run_as_root apt-get update
      run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        btop ca-certificates curl dnsutils fzf git htop jq less locales lsof \
        ncdu ripgrep rsync tar time tmux tree unzip wget zip zsh

      run_as_root localedef -i en_US -f UTF-8 en_US.UTF-8
      run_as_root update-locale LANG=en_US.UTF-8

      atuin_installer=$(curl --proto '=https' --tlsv1.2 -LsSf \
        https://github.com/atuinsh/atuin/releases/latest/download/atuin-installer.sh)
      printf '%s\n' "$atuin_installer" | ATUIN_NO_MODIFY_PATH=1 sh
      unset atuin_installer

      uv_installer=$(curl --proto '=https' --tlsv1.2 -LsSf \
        https://astral.sh/uv/install.sh)
      printf '%s\n' "$uv_installer" | UV_NO_MODIFY_PATH=1 sh
      unset uv_installer

      zoxide_installer=$(curl --proto '=https' --tlsv1.2 -LsSf \
        https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh)
      printf '%s\n' "$zoxide_installer" | sh
      unset zoxide_installer

      if [ -d "$HOME/.pyenv/.git" ]; then
        git -C "$HOME/.pyenv" pull --ff-only
      elif [ -e "$HOME/.pyenv" ]; then
        printf 'error: %s exists but is not a Git checkout\n' "$HOME/.pyenv" >&2
        return 1
      else
        git clone --depth=1 https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
      fi
      ;;
    *)
      printf 'error: --packages supports macOS, Debian, and Ubuntu\n' >&2
      return 1
      ;;
  esac

  printf 'ok: recommended packages are installed\n'
}

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
source_file="$repo_dir/.zshrc"
target_file="${ZDOTDIR:-$HOME}/.zshrc"
antigen_dir="$HOME/.local/share/antigen"

if [ "$install_packages" -eq 1 ]; then
  install_recommended_packages
fi

printf 'scope: install %s as %s\n' "$source_file" "$target_file"

mkdir -p "$(dirname -- "$target_file")"

if ! command -v zsh >/dev/null 2>&1; then
  printf 'error: zsh is required; install it with your system package manager\n' >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  printf 'error: git is required; install it with your system package manager\n' >&2
  exit 1
fi

if ! zsh -n "$source_file"; then
  printf 'error: %s failed zsh syntax validation\n' "$source_file" >&2
  exit 1
fi
printf 'ok: zsh configuration is valid\n'

antigen_file=''
for candidate in \
  /opt/homebrew/share/antigen/antigen.zsh \
  /usr/local/share/antigen/antigen.zsh \
  /home/linuxbrew/.linuxbrew/share/antigen/antigen.zsh \
  /usr/share/zsh-antigen/antigen.zsh \
  /usr/share/zsh/plugins/antigen/antigen.zsh \
  "$antigen_dir/antigen.zsh"; do
  if [ -r "$candidate" ]; then
    antigen_file="$candidate"
    break
  fi
done

if [ -z "$antigen_file" ]; then
  mkdir -p "$(dirname -- "$antigen_dir")"
  git clone --depth=1 https://github.com/zsh-users/antigen.git "$antigen_dir"
  antigen_file="$antigen_dir/antigen.zsh"
  printf 'ok: cloned Antigen to %s\n' "$antigen_dir"
else
  printf 'ok: found Antigen at %s\n' "$antigen_file"
fi

if [ -e "$target_file" ] || [ -L "$target_file" ]; then
  current_link=$(readlink "$target_file" 2>/dev/null || true)
  if [ "$current_link" = "$source_file" ]; then
    printf 'ok: %s already links to this repository\n' "$target_file"
  else
    backup_file="$target_file.backup.$(date +%Y%m%d-%H%M%S)"
    mv "$target_file" "$backup_file"
    ln -s "$source_file" "$target_file"
    printf 'ok: backed up the previous configuration to %s\n' "$backup_file"
    printf 'ok: linked %s to %s\n' "$target_file" "$source_file"
  fi
else
  ln -s "$source_file" "$target_file"
  printf 'ok: linked %s to %s\n' "$target_file" "$source_file"
fi

if [ -f "$target_file.zwc" ]; then
  rm -f "$target_file.zwc"
  printf 'ok: removed stale compiled configuration %s\n' "$target_file.zwc"
fi

secrets_file="$HOME/.zsh_secrets"
if [ ! -e "$secrets_file" ]; then
  umask 077
  : >"$secrets_file"
  printf 'ok: created %s\n' "$secrets_file"
fi
chmod 600 "$secrets_file"

missing_optional=''
for command_name in atuin fzf pyenv uv zoxide; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    missing_optional="$missing_optional $command_name"
  fi
done

if [ -n "$missing_optional" ]; then
  printf 'summary: installed; optional commands not found:%s\n' "$missing_optional"
else
  printf 'summary: installed; all optional commands are available\n'
fi

printf 'next: chsh -s "$(command -v zsh)"\n'
printf 'next: exec zsh -l\n'
