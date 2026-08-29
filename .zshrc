# ==============================================================================
# Zsh workstation configuration
# ==============================================================================
#
# Repository: https://github.com/meabed/zsh
#
# This is the only hand-maintained interactive-shell configuration. The
# installer links it to ~/.zshrc. Keep credentials in ~/.zsh_secrets.
#
# Quick install:
#   macOS:
#     brew install antigen atuin fzf pyenv uv zoxide
#   Debian or Ubuntu:
#     sudo apt-get update
#     sudo apt-get install -y curl fzf git zsh
#
#   Then, on either platform:
#     git clone https://github.com/meabed/zsh.git ~/.config/zsh
#     ~/.config/zsh/install.sh
#     exec zsh -l
#
# Antigen installs Oh My Zsh and every bundle declared below. Do not also run
# the standard Oh My Zsh installer or clone individual plugins.
#
# Optional Linux tool installers:
#   Atuin:  https://docs.atuin.sh/latest/guide/installation/
#   uv:     curl -LsSf https://astral.sh/uv/install.sh | sh
#   zoxide: curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
#
# Maintenance:
#   antigen update
#   zshcheck
#   zshreload
#
# History:
#   Ctrl-R     Global fuzzy search.
#   Up arrow   Global prefix search.
#   Ctrl-R again inside Atuin cycles its enabled history filters.
#   Import an existing native history once:
#     HISTFILE="$HOME/.zsh_history" atuin import zsh
#
# Managed runtime files:
#   ~/.zsh_secrets        Private values. Keep mode 600.
#   ~/.zsh_history        Native fallback history.
#   ~/.antigen/           Antigen bundles and completion cache.
#   ~/.zsh/cache/         Zsh completion data cache.
#   ~/.config/atuin/      Atuin-generated configuration.
#   ~/.local/share/atuin/ Atuin history database.
#   ~/.zshrc.zwc          Antigen-generated compiled configuration.
#
# Sources:
#   Zsh:                     https://zsh.sourceforge.io/Doc/
#   Oh My Zsh:              https://github.com/ohmyzsh/ohmyzsh
#   Antigen:                https://github.com/zsh-users/antigen
#   zsh-autosuggestions:    https://github.com/zsh-users/zsh-autosuggestions
#   zsh-completions:        https://github.com/zsh-users/zsh-completions
#   fast-syntax-highlighting:
#     https://github.com/zdharma-continuum/fast-syntax-highlighting
#   Atuin:                  https://docs.atuin.sh/
#   fzf:                    https://github.com/junegunn/fzf
#   uv:                     https://docs.astral.sh/uv/
#   zoxide:                 https://github.com/ajeetdsouza/zoxide
#   pyenv:                  https://github.com/pyenv/pyenv
#   iTerm2 integration:     https://iterm2.com/documentation-shell-integration.html
#

# Keep PATH and fpath duplicate-free as tools add entries.
typeset -U path PATH
typeset -U fpath FPATH

# Find Homebrew when a terminal starts without its shell environment.
if (( ! ${+commands[brew]} )); then
  for brew_binary in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$brew_binary" ]]; then
      eval "$("$brew_binary" shellenv)"
      break
    fi
  done
  unset brew_binary
fi

# Find Antigen from Homebrew, Linux packages, or the installer-managed clone.
antigen_file=''
for candidate in \
  /opt/homebrew/share/antigen/antigen.zsh \
  /usr/local/share/antigen/antigen.zsh \
  /home/linuxbrew/.linuxbrew/share/antigen/antigen.zsh \
  /usr/share/zsh-antigen/antigen.zsh \
  /usr/share/zsh/plugins/antigen/antigen.zsh \
  /usr/local/share/antigen/antigen.zsh \
  "$HOME/.local/share/antigen/antigen.zsh"; do
  if [[ -r "$candidate" ]]; then
    antigen_file="$candidate"
    break
  fi
done
unset candidate

if [[ -z "$antigen_file" ]]; then
  print -u2 "Antigen is missing. Run this repository's install.sh again."
  return 1
fi

# Antigen tracks the ~/.zshrc symlink's timestamp. Compare its cache with the
# real repository file so plugin changes take effect after `git pull`.
antigen_cache_file="$HOME/.antigen/init.zsh"
antigen_config_file="${${(%):-%N}:A}"
if [[ -f "$antigen_cache_file" && "$antigen_config_file" -nt "$antigen_cache_file" ]]; then
  rm -f "$antigen_cache_file"
fi
unset antigen_cache_file antigen_config_file

source "$antigen_file"
unset antigen_file

# Appearance and common command-line tools.
export LSCOLORS='exfxcxdxbxegedabagacad'
export CLICOLOR=1
export PAGER="${PAGER:-less}"
export LESS="${LESS:--giAMR}"

if (( ${+commands[subl]} )); then
  export EDITOR='subl -w'
else
  export EDITOR="${EDITOR:-vi}"
fi
export VISUAL="$EDITOR"

function zshconfig() {
  ${=EDITOR} "$HOME/.zshrc"
}

function zshcheck() {
  zsh -n "$HOME/.zshrc"
}

function zshreload() {
  exec zsh -l
}

# Load private values without placing credentials in the repository.
[[ -r "$HOME/.zsh_secrets" ]] && source "$HOME/.zsh_secrets"

# Add user-level command directories only when they exist.
export GOPATH="${GOPATH:-$HOME/workspace/go}"
user_paths=(
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/.bun/bin"
  "$HOME/.pyenv/bin"
  "$GOPATH/bin"
  "$HOME/.antigravity/antigravity/bin"
  "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
  /opt/homebrew/opt/curl/bin
  /opt/homebrew/opt/ruby/bin
  /usr/local/opt/curl/bin
  /usr/local/opt/ruby/bin
  /home/linuxbrew/.linuxbrew/opt/curl/bin
  /home/linuxbrew/.linuxbrew/opt/ruby/bin
)
for candidate in "${user_paths[@]}"; do
  [[ -d "$candidate" ]] && path=("$candidate" $path)
done
unset candidate user_paths
export PATH

# Android SDK locations differ between macOS and Linux.
case "$OSTYPE" in
  darwin*) android_home="$HOME/Library/Android/sdk" ;;
  linux*) android_home="$HOME/Android/Sdk" ;;
  *) android_home='' ;;
esac
if [[ -n "$android_home" && -d "$android_home" ]]; then
  export ANDROID_HOME="$android_home"
  export ANDROID_SDK_ROOT="$android_home"
  export ANDROID_PLATFORM_TOOLS="$android_home/platform-tools"
  [[ -d "$android_home/platform-tools" ]] && path=("$android_home/platform-tools" $path)
  [[ -d "$android_home/emulator" ]] && path=("$android_home/emulator" $path)
  alias emulator="$android_home/emulator/emulator"
fi
unset android_home

# Locate Google Cloud SDK now; load its completion adapter after compinit.
gcloud_completion_file=''
for gcloud_root in \
  /opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk \
  /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk \
  "$HOME/google-cloud-sdk" \
  /usr/local/google-cloud-sdk; do
  if [[ -r "$gcloud_root/path.zsh.inc" ]]; then
    source "$gcloud_root/path.zsh.inc"
    [[ -r "$gcloud_root/completion.zsh.inc" ]] &&
      gcloud_completion_file="$gcloud_root/completion.zsh.inc"
    break
  fi
done
unset gcloud_root

# Register completion paths before Antigen initializes compinit.
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)
[[ -s "$HOME/.bun/_bun" ]] && fpath=("$HOME/.bun" $fpath)

# Completion behavior and display.
zstyle ':completion:*' menu select
zstyle ':completion:*' completer _complete
zstyle ':completion:*' use-cache true
zstyle ':completion:*' cache-path "$HOME/.zsh/cache"
zstyle ':completion:*' group-name ''
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*:descriptions' format '- %d -'
zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Atuin prepends its own history strategy during initialization.
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Load Oh My Zsh and maintained upstream plugins.
zstyle ':omz:update' mode disabled
zstyle ':omz:plugins:iterm2' shell-integration yes
antigen use oh-my-zsh
antigen bundles <<EOBUNDLES
colored-man-pages
common-aliases
copyfile
copypath
extract
history
git
iterm2
sudo
uv
zsh-users/zsh-completions
zsh-users/zsh-autosuggestions
EOBUNDLES

# Load platform and tool plugins only where their commands can be useful.
(( ${+commands[brew]} )) && antigen bundle brew

case "$OSTYPE" in
  darwin*)
    antigen bundle macos
    ;;
  linux*)
    [[ -r /etc/debian_version ]] && antigen bundle debian
    (( ${+commands[systemctl]} )) && antigen bundle systemd
    ;;
esac

if (( ${+commands[docker]} )); then
  antigen bundle docker
  antigen bundle docker-compose
fi

(( ${+commands[gh]} )) && antigen bundle gh
(( ${+commands[kubectl]} )) && antigen bundle kubectl

# Preserve the existing prompt.
antigen theme steeef
RPROMPT="[%D{%f/%m/%y} | %D{%L:%M:%S}]"

# Load Atuin before syntax highlighting so its widgets are wrapped correctly.
if (( ${+commands[atuin]} )); then
  export ATUIN_LOG=error
  eval "$(atuin init zsh --disable-ai)"
fi

antigen bundle zdharma-continuum/fast-syntax-highlighting
antigen apply

# Initialize completion once, then load adapters that require compdef.
if (( ${+functions[_antigen_compinit]} )); then
  _antigen_compinit
elif (( ! ${+functions[compdef]} )); then
  autoload -Uz compinit
  compinit -i
fi
if [[ -n "$gcloud_completion_file" ]]; then
  source "$gcloud_completion_file"
fi
unset gcloud_completion_file

# Native history remains a fallback; Atuin owns interactive search.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=200000
SAVEHIST=100000
unsetopt share_history            # Atuin shares history without Zsh's session merging.
unsetopt inc_append_history       # This conflicts with inc_append_history_time below.
setopt append_history             # Append on save instead of replacing the history file.
setopt inc_append_history_time    # Append after execution so command duration is recorded.
setopt extended_history           # Store each command's timestamp and duration.
setopt hist_expire_dups_first     # Drop older duplicates first when history reaches its limit.
setopt hist_ignore_dups           # Skip commands that exactly repeat the previous command.
setopt hist_ignore_space          # Keep space-prefixed private commands out of native history.
setopt hist_reduce_blanks         # Collapse unnecessary blanks before saving a command.
setopt hist_verify                # Show expanded history commands before executing them.

# Interactive shell behavior.
setopt bang_hist              # Enable !-style history expansion.
setopt auto_pushd             # Add directories visited with cd to the directory stack.
setopt pushd_ignore_dups      # Keep one copy of each directory in the stack.
setopt pushd_silent           # Do not print the stack after pushd or popd.
setopt pushd_to_home          # Treat pushd without arguments as pushd "$HOME".
setopt auto_cd                # Enter a directory by typing its path without cd.
setopt auto_remove_slash      # Remove an automatically added trailing slash when appropriate.
setopt extended_glob          # Enable Zsh's extended glob operators and qualifiers.
setopt glob_dots              # Include dotfiles in wildcard matches.
setopt auto_list              # List choices when completion is ambiguous.
setopt auto_menu              # Start menu selection after repeated completion.
setopt complete_aliases       # Complete aliases without expanding them first.
setopt always_to_end          # Move the cursor to the end after inserting a completion.
setopt complete_in_word       # Complete from the cursor instead of only at the word's end.
setopt list_ambiguous         # Show candidates when completion remains ambiguous.
setopt rm_star_silent         # Do not add Zsh's extra prompt for rm with a wildcard.
unsetopt beep                 # Disable the terminal bell for shell errors.
unsetopt bg_nice              # Keep background jobs at their requested priority.
unsetopt clobber              # Require >| before truncating an existing file.
unsetopt hist_beep            # Disable the terminal bell for missing history matches.
unsetopt hup                  # Leave explicitly backgrounded jobs running when the shell exits.
unsetopt ignore_eof           # Allow Ctrl-D to exit the shell.
unsetopt list_beep            # Disable the bell for ambiguous completion.
unsetopt correct correct_all  # Avoid slow or surprising automatic spelling correction.

# Initialize optional interactive tools after completion.
if (( ${+commands[pyenv]} )); then
  export PYENV_ROOT="$(pyenv root)"
  eval "$(pyenv init - --no-rehash zsh)"
fi

if (( ${+commands[fzf]} )) && [[ -t 0 && -t 1 ]]; then
  if fzf --zsh >/dev/null 2>&1; then
    FZF_CTRL_R_COMMAND=
    source <(fzf --zsh)
    unset FZF_CTRL_R_COMMAND
  else
    # Debian and Ubuntu releases may package fzf before `fzf --zsh` existed.
    for fzf_script in \
      /usr/share/doc/fzf/examples/key-bindings.zsh \
      /usr/share/fzf/key-bindings.zsh \
      /usr/share/fzf/shell/key-bindings.zsh \
      /usr/share/doc/fzf/examples/completion.zsh \
      /usr/share/fzf/completion.zsh \
      /usr/share/fzf/shell/completion.zsh; do
      [[ -r "$fzf_script" ]] && source "$fzf_script"
    done
    unset fzf_script
  fi
fi

if (( ${+commands[zoxide]} )); then
  eval "$(zoxide init zsh)"
fi

# Reassert Atuin bindings after Oh My Zsh and fzf have registered theirs.
# Up uses global prefix search; Ctrl-R uses global fuzzy search.
if (( ${+commands[atuin]} )); then
  function _atuin_global_up_search() {
    _atuin_up_search --filter-mode global --search-mode prefix --inline-height 30
  }
  zle -N atuin-global-up-search _atuin_global_up_search
  bindkey -M emacs '^R' atuin-search
  bindkey -M viins '^R' atuin-search-viins
  bindkey -M vicmd '/' atuin-search-vicmd
  bindkey -M emacs '^[[A' atuin-global-up-search
  bindkey -M emacs '^[OA' atuin-global-up-search
fi
