function try_source { if [[ -e "$1" ]]; then source "$1"; fi }

try_source "$HOME/.zshrc.before"

if [[ -z "$DEFAULT_USER" ]]; then
  DEFAULT_USER=wesr
fi

export PATH=$HOME/bin:$PATH
export PATH=$HOME/platform-tools:$PATH
export PATH=$HOME/.dotfiles/git-diffall:$PATH
export ZSH="$HOME/.oh-my-zsh"
export SSH_PKEY="$HOME/.ssh/rsa_id"

export SESSION_TYPE="$(who -m | awk '{ print $2 }' | sed 's/[0-9]*$//')"
if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
  export SESSION_TYPE=remote/ssh
else
  case $(ps -o comm= -p $PPID) in
    sshd|*/sshd) export SESSION_TYPE=remote/ssh ;;
  esac
fi

export LESS="-F -X -R $LESS"

# Backup variables used in the OH MY ZSH that need to be restored
ENV_HOME=$HOME
ENV_ZSH=$ZSH
ENV_ZSH_THEME=$ZSH_THEME
ZSH=$HOME/.oh-my-zsh

CASE_SENSITIVE='false'
HYPHEN_INSENSITIVE='true'
ENABLE_CORRECTION='true'
COMPLETION_WAITING_DOTS='true'

if [[ -d "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" ]]; then
  ZSH_THEME='spaceship'
  SPACESHIP_PROMPT_ADD_NEWLINE=false
  SPACESHIP_PROMPT_SEPARATE_LINE=true
  SPACESHIP_EXEC_TIME_ELAPSED=30
else
  ZSH_THEME='robbyrussell'
fi

plugins=(extract fzf git sudo vi-mode zsh_reload)

if [[ "$OSTYPE" == "darwin"* ]]; then
  plugins+=(osx)
fi

if command -v code >/dev/null 2>&1; then
  plugins+=(vscode)
fi

if [[ -f "$HOME/.fzf.zsh" ]]; then
  export FZF_COMPLETION_TRIGGER='qq'
  export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow -g "!{.git,node_modules}/*" 2> /dev/null'
  export FZF_DEFAULT_OPTS="--height 40% --reverse --border"
  plugins+=(fzf)
  source "$HOME/.fzf.zsh"

  function fzf() {
    if [[ $(tput cols) > 100 ]]; then
      command fzf --preview '[[ $(file --mime {}) =~ binary ]] &&
                 echo {} is a binary file ||
                 (highlight -O ansi -l {} ||
                  coderay {} ||
                  rougify {} ||
                  cat {}) 2> /dev/null | head -255' "$@"
    else
      command fzf "$@"
    fi
  }
fi

try_source $ZSH/oh-my-zsh.sh

# Restore environment variables
ZSH=$ENV_ZSH
HOME=$ENV_HOME
ZSH_THEME=$ENV_ZSH_THEME

function cd {
  if [[ "$#" == '0' ]]; then
    pushd "$HOME" > /dev/null
  else
    pushd "$@" > /dev/null
  fi
}

function od {
  if [[ "$#" == '0' ]]; then
    popd > /dev/null
  else
    for i in $(seq $1); do popd > /dev/null; done
  fi
}

export SSH_COMMAND="$(which ssh)"
function ssh {
  if [[ -n "$iterm2_hostname" ]]; then
    export iterm2_hostname="${@:-1}"
    iterm2_print_state_data
    "$SSH_COMMAND" "$@"
    export iterm2_hostname="$(hostname)"
    iterm2_print_state_data
  else
    "$SSH_COMMAND" "$@"
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

if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
  alias vim=nvim
else
  export EDITOR=vim
fi

alias e="$EDITOR"
alias gitk='gitk &'
alias beep='tput bel'
alias settings='e ~/.zshrc'

if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi

try_source "$HOME/.iterm2_shell_integration.zsh"
try_source "$HOME/.zshrc.after"
