# vim:ft=zsh ts=2 sw=2 sts=2

rvm_current() {
  rvm current 2>/dev/null
}

rbenv_version() {
  rbenv version 2>/dev/null | awk '{print $1}'
}

PROMPT='
%{$fg_bold[yellow]%}%! =>%{$reset_color%} %{$fg_bold[white]%}%*%{$reset_color%} : %{$fg_bold[red]%}%n%{$reset_color%} %{$fg_bold[yellow]%}@%{$reset_color%} %{$fg_bold[cyan]%}%M%{$reset_color%} %{$fg_bold[yellow]%}${PWD/#$HOME/~}%{$reset_color%}$(git_prompt_info) %{$fg_bold[magenta]%}$%{$reset_color%} '

ZSH_THEME_GIT_PROMPT_PREFIX=" on %{$fg[magenta]%} "
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}!"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[green]%}?"
ZSH_THEME_GIT_PROMPT_CLEAN=""

RPROMPT='%{$fg_bold[red]%}$(rbenv_version)%{$reset_color%}'