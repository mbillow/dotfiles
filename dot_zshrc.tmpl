export ZSH="$HOME/.dotfiles/.oh-my-zsh"
export ZSH_CUSTOM="$HOME/.dotfiles/custom"
export SPACESHIP_VENV_SHOW="false"

ZSH_THEME="spaceship"
SPACESHIP_DIR_COLOR="green"
SPACESHIP_CHAR_COLOR_SUCCESS="cyan"
SPACESHIP_DOCKER_CONTEXT_SHOW="false"
if [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
  SPACESHIP_PROMPT_ASYNC="false"
  SPACESHIP_PROMPT_ADD_NEWLINE="false"
  SPACESHIP_PROMPT_SEPARATE_LINE="false"
  SPACESHIP_CHAR_SYMBOL=" "
else
  plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
fi

source $ZSH/oh-my-zsh.sh

# User configuration

export EDITOR='vim'
export CLICOLOR=1

# Go Setup
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
export GO111MODULE=on

# Command Aliases
if type "kubecolor" > /dev/null; then
  alias kubectl="kubecolor"
fi
alias k="kubectl"
alias kns="kubectl config set-context"
if ! command -v COMMAND &> /dev/null; then
  complete -F __start_kubectl k
fi


# PyEnv Setup
export PYENV_VIRTUALENV_DISABLE_PROMPT=1

compctl -K _pyenv pyenv

_pyenv() {
  local words completions
  read -cA words

  if [ "${#words}" -eq 2 ]; then
    completions="$(pyenv commands)"
  else
    completions="$(pyenv completions ${words[2,-2]})"
  fi

  reply=(${(ps:\n:)completions})
}

if which pyenv-virtualenv-init > /dev/null 2>&1; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)";
fi


# NVM Stuff
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Consul Autocomplete
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C `which consul` consul
