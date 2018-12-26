function try_source { if [[ -e "$1" ]]; then source "$1"; fi }

try_source "$HOME/.zshrc.before"

if [[ -z "$DEFAULT_USER" ]]; then
  DEFAULT_USER=wesr
fi

export PATH=$HOME/bin:$PATH
export PATH=$HOME/.dotfiles/git-diffall:$PATH
export ZSH="$HOME/.oh-my-zsh"
export SSH_PKEY="$HOME/.ssh/rsa_id"
export SSH_CLIENT=''

export LESS="-F -X -R $LESS"

# Backup variables used in the OH MY ZSH that need to be restored
ENV_HOME=$HOME
HOME=/Users/$DEFAULT_USER

ENV_ZSH=$ZSH
ZSH=$HOME/.oh-my-zsh

ENV_ZSH_THEME=$ZSH_THEME

CASE_SENSITIVE='false'
HYPHEN_INSENSITIVE='true'
ENABLE_CORRECTION='true'
COMPLETION_WAITING_DOTS='true'

if [[ -d "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" ]]; then
  ZSH_THEME='spaceship'
  SPACESHIP_PROMPT_ADD_NEWLINE=false
  SPACESHIP_PROMPT_SEPARATE_LINE=true
  SPACESHIP_EXEC_TIME_ELAPSED=30
fi

plugins=(
  fzf
  git
  sudo
  vscode
  zsh_reload
)

source $ZSH/oh-my-zsh.sh

# Restore environment variables
ZSH=$ENV_ZSH
HOME=$ENV_HOME
ZSH_THEME=$ENV_ZSH_THEME

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

function cd {
    if [[ "$#" == '0' ]]; then
        pushd "$HOME" > /dev/null
    else
        pushd "$@" > /dev/null
    fi
}

function od {
    if [[ !"$#" ]]; then
        popd > /dev/null
    else
        for i in $(seq $1); do popd > /dev/null; done
    fi
}

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias .......='cd ../../../../../..'
alias ........='cd ../../../../../../..'
alias .........='cd ../../../../../../../..'
alias ..........='cd ../../../../../../../../..'
alias ...........='cd ../../../../../../../../../..'

if [[ -n "$(which -s nvim)" ]]; then
  export EDITOR=nvim
  alias vim=nvim
else
  export EDITOR=vim
fi

alias e="$EDITOR"
alias gitk='gitk &'
alias beep='tput bel'
alias settings='e ~/.zshrc'

if which rbenv > /dev/null; then
  eval "$(rbenv init -)"
fi

try_source "$HOME/.iterm2_shell_integration.zsh"

try_source "$HOME/.zshrc.after"
