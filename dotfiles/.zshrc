function try_source { if [[ -e "$1" ]]; then source "$1"; fi }
function exists { command -v "$1" >/dev/null 2>&1; return $? }

# export DISABLE_AUTO_UPDATE='true'

# TODO: Support multiple additional imports
try_source "$ZSH_ADDITIONAL_IMPORTS"
try_source "$HOME/.iterm2_shell_integration.zsh"

export ZSH="$HOME/.oh-my-zsh"
export NVM_DIR="$HOME/.nvm"

if [ -d /mnt/c/QMK_MSYS ]; then
  # USB integrations on WSL are inadequate for QMK, use the Windows utils directly.
  export DFU_PROGRAMMER=/mnt/c/QMK_MSYS/mingw64/bin/dfu-programmer.exe
  export DFU_UTIL=/mnt/c/QMK_MSYS/mingw64/bin/dfu-util.exe
  export TEENSY_LOADER_CLI=/mnt/c/QMK_MSYS/mingw64/bin/teensy_loader_cli.exe
  export BATCHISP=/mnt/c/QMK_MSYS/mingw64/bin/batchisp.exe
fi

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
if exists tmux; then
  # if [[ -z "$TMUX" && "$SESSION_TYPE" == remote/ssh ]]; then
  if [[ -z "$TMUX" ]]; then
    export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=1
    TERM=xterm-256color
    sid="$(tmux ls | sed '/(attached)$/d' | sed 's/:.*//' | tail -n 1)"
    tmux ${ITERM_SHELL_INTEGRATION_INSTALLED:+-CC} ${sid:+attach} ${sid:+-t} $sid
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

if exists fzf; then
  export FZF_COMPLETION_TRIGGER='qq'
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow 2>/dev/null'
  export FZF_DEFAULT_OPTS="--height 40% --reverse --border"
  if [[ -f "$HOME/.fzf.zsh" ]]; then
    source "$HOME/.fzf.zsh"
  fi

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

if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  # Backup variables used in the OH MY ZSH that need to be restored
  ENV_HOME=$HOME
  ENV_ZSH_THEME=$ZSH_THEME
  ENV_ZSH=$ZSH
  ZSH="$HOME/.oh-my-zsh"
  export ZSH_DISABLE_COMPFIX=true
  if [[ -d "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" ]]; then
    ZSH_THEME='spaceship'
    SPACESHIP_PROMPT_ADD_NEWLINE=false
    SPACESHIP_PROMPT_SEPARATE_LINE=true
    SPACESHIP_CHAR_SUFFIX=' '
    SPACESHIP_EXEC_TIME_ELAPSED=30
  else
    ZSH_THEME='robbyrussell'
  fi

  export KEYTIMEOUT=1
  plugins=(extract git sudo vi-mode wd)

  if [[ "$OSTYPE" == "darwin"* ]]; then
    plugins+=(osx)
  fi

  if exists code; then
    plugins+=(vscode)
  fi

  if exists fzf; then
    plugins+=(fzf)
  fi

  try_source $ZSH/oh-my-zsh.sh

  # Restore environment variables
  ZSH=${ENV_ZSH:-$ZSH}
  HOME=${ENV_HOME:-$HOME}
  ZSH_THEME=${ENV_ZSH_THEME:-$ZSH_THEME}
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
  popd "$@" > /dev/null
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

function .. {
  dir='..'
  times=${1:-1}
  while [[ $((times--)) > 1 ]]; do
    dir="$dir/.."
  done
  cd $dir
}

function withspaces {
  awk -F: '{if(f!=$1)print ""; f=$1; print $0;}'
}

function kill-port {
    echo "Killing $(lsof -t -i tcp:$1 | wc -l) processes"
    lsof -t -i tcp:$1 | xargs kill -9
    echo "$(lsof -t -i tcp:$1 | wc -l) processes remaining"
}

function delta-colorscheme {
  if [[ -z "$1" ]]; then
    if [[ "$DELTA_FEATURES" == '+light' ]]; then
      echo 'Delta: Switching to dark colorscheme'
      export DELTA_FEATURES='+dark'
    else
      echo 'Delta: Switching to light colorscheme'
      export DELTA_FEATURES='+light'
    fi
  else
    export DELTA_FEATURES="+$1"
  fi
}

if [[ -n "$TMUX" ]]; then
  alias detach='tmux detach'
fi

if exists nvim; then
  export EDITOR=nvim
  alias vim=nvim
else
  export EDITOR=vim
fi

alias e="$EDITOR"
alias gitk='gitk &'
alias beep='tput bel'
alias settings='e ~/.zshrc'

if exists rbenv; then
  eval "$(rbenv init -)"
fi

if exists pyenv; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

try_source "$HOME/.zshrc.after"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f ~/.local/bin/mise ] && eval "$(~/.local/bin/mise activate zsh)"
# exists fnm && eval "`fnm env --use-on-cd`"
# exists phpenv && eval "$(phpenv init -)"