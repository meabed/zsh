#!/bin/sh

set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
source_file="$repo_dir/.zshrc"
target_file="${ZDOTDIR:-$HOME}/.zshrc"
antigen_dir="$HOME/.local/share/antigen"

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
