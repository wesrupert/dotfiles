function try_source { if [[ -e "$1" ]]; then source "$1"; fi }

export DISABLE_AUTO_UPDATE='true'

# TODO: Support multiple additional imports
try_source "$HOME/.zshrc.before"
try_source "$ZSH_ADDITIONAL_IMPORTS"

try_source "$HOME/.iterm2_shell_integration.zsh"

export PATH=$PATH:$HOME/bin
export PATH=$PATH:$HOME/platform-tools
export PATH=$PATH:$HOME/.dotfiles/git-diffall
export PATH=$PATH:/usr/local/bin/python
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

# Run this check early so that we don't do extra work if we're relaunching
if command -v tmux >/dev/null 2>&1; then
  if [[ -z "$TMUX" && "$SESSION_TYPE" == remote/ssh ]]; then
    TERM=screen-256color-bce
    export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=1
    flag=${ITERM_SHELL_INTEGRATION_INSTALLED:+-CC}
    session="$(tmux ls | sed '/(attached)$/d' | sed 's/:.*//' | tail -n 1)"
    if [[ -n "$session" ]]; then
      tmux $flag attach -t "$session"
    else
      tmux $flag
    fi
    exit
  fi
fi

if [[ -z "$DEFAULT_USER" ]]; then
  DEFAULT_USER=wesr
fi

export LESS="-F -X -R $LESS"

CASE_SENSITIVE='false'
HYPHEN_INSENSITIVE='true'
ENABLE_CORRECTION='true'
COMPLETION_WAITING_DOTS='true'
setopt globdots

if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  # Backup variables used in the OH MY ZSH that need to be restored
  ENV_HOME=$HOME
  ENV_ZSH_THEME=$ZSH_THEME
  ENV_ZSH=$ZSH
  ZSH="$HOME/.oh-my-zsh"
  if [[ -d "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" ]]; then
    ZSH_THEME='spaceship'
    SPACESHIP_PROMPT_ADD_NEWLINE=false
    SPACESHIP_PROMPT_SEPARATE_LINE=true
    SPACESHIP_EXEC_TIME_ELAPSED=30
  else
    ZSH_THEME='robbyrussell'
  fi

  plugins=(extract git sudo vi-mode zsh_reload)

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

    alias fzh="fzf --history '${FZF_HISTORY_DIR:-TMPDIR}'"
  fi

  try_source $ZSH/oh-my-zsh.sh

  # Restore environment variables
  ZSH=$ENV_ZSH
  HOME=$ENV_HOME
  ZSH_THEME=$ENV_ZSH_THEME
fi

# 0 -- vanilla completion (abc => abc)
# 1 -- smart case completion (abc => Abc)
# 2 -- word flex completion (abc => A-big-Car)
# 3 -- full flex completion (abc => ABraCadabra)
zstyle ':completion:*' matcher-list '' \
  'm:{a-z\-}={A-Z\_}' \
  'r:[^[:alpha:]]||[[:alpha:]]=** r:|=* m:{a-z\-}={A-Z\_}' \
  'r:|?=** m:{a-z\-}={A-Z\_}'

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
  if [[ -n "$ITERM_SHELL_INTEGRATION_INSTALLED" ]]; then
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

if [[ -n "$TMUX" ]]; then
  alias detach='tmux detach'
fi

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

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

try_source "$HOME/.zshrc.after"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
