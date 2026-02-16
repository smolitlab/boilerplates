#!/usr/bin/env bash
set -euo pipefail
export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$HOME/bin"

# Prevent running as root (except for individual sudo commands)
if [ "$(id -u)" -eq 0 ]; then
  echo "\033[31mERROR: Please do NOT run this script as root or with sudo.\033[0m"
  echo "Run as your normal user. The script will use sudo only where needed."
  exit 1
fi

# Farben
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
blue() { printf "\033[34m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }

blue "[1/16] System aktualisieren & Basiswerkzeuge installieren"
sudo apt-get update -y
sudo apt-get install -y  git curl wget unzip jq ca-certificates gnupg software-properties-common dnsutils iputils-ping net-tools pipx zsh

blue "[3/16] Git Credential Helper"
git config --global credential.helper store

blue "[4/16] create directories"

mkdir -p ~/.kube
chmod 700 -R ~/.kube

mkdir -p ~/.ssh
chmod 700 ~/.ssh


blue "[5/16] Mise-en-pase installieren"
if ! command -v mise >/dev/null 2>&1; then
  sudo install -dm 755 /etc/apt/keyrings
  curl -fSs https://mise.jdx.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.asc 1> /dev/null
  echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.asc] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
  sudo apt update -y
  sudo apt install -y mise
else
  yellow "mise bereits vorhanden."
fi

# Install all tools with mise
# Copy config.toml to mise config directory
blue "[6/16] config.toml nach mise kopieren"
mkdir -p "$HOME/.config/mise"
if [ -f "$(dirname "$0")/config.toml" ]; then
  cp "$(dirname "$0")/config.toml" "$HOME/.config/mise/config.toml"
  green "config.toml erfolgreich kopiert."
else
  yellow "config.toml nicht gefunden, bitte manuell kopieren."
fi
mise install


# -------------------------------
# Oh-My-Zsh
# -------------------------------
blue "[7/16] Oh-My-Zsh installieren"

OMZ_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$OMZ_DIR/custom}"

if [ ! -d "$OMZ_DIR" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  yellow "Oh-My-Zsh bereits vorhanden."
fi

# Plugins

blue "[8/16] Oh-My-Zsh Plugins & Powerlevel10k installieren"

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# Remove and re-clone zsh-autosuggestions
rm -rf "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" && \
  green "zsh-autosuggestions erfolgreich installiert." || yellow "Fehler beim Installieren von zsh-autosuggestions."

# Remove and re-clone zsh-syntax-highlighting
rm -rf "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" && \
  green "zsh-syntax-highlighting erfolgreich installiert." || yellow "Fehler beim Installieren von zsh-syntax-highlighting."

# Remove and re-clone powerlevel10k theme
rm -rf "$ZSH_CUSTOM/themes/powerlevel10k"
mkdir -p "$ZSH_CUSTOM/plugins" "$ZSH_CUSTOM/themes"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" && \
  green "powerlevel10k erfolgreich installiert." || yellow "Fehler beim Installieren von powerlevel10k."


# -------------------------------
# ~/.zshrc schreiben
# -------------------------------
blue "[9/16] ~/.zshrc schreiben"

# Ensure HOME is set
if [ -z "${HOME:-}" ]; then
  yellow "HOME is not set. Cannot write ~/.zshrc."
else
  cat > "$HOME/.zshrc" <<"EOF"
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
# Remove all Windows paths from PATH in WSL to avoid fallback to Windows executables
export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$HOME/bin"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Schnelle Git-Prompts, keine teuren Statuschecks
git config --global oh-my-zsh.hide-status 1 >/dev/null 2>&1 || true
git config --global oh-my-zsh.hide-dirty 1 >/dev/null 2>&1 || true

source $ZSH/oh-my-zsh.sh

# p10k settings
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status time)
typeset -g POWERLEVEL9K_TIME_FORMAT='%H:%M:%S'
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false

# History settings
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
export HISTSIZE=50000
export SAVEHIST=50000

# Aliases
alias k='kubectl'
alias ll='ls -laFh --color=auto'
alias tf='tofu'
alias tg='terragrunt'

# kubectl autocomplete
if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion zsh)
  compdef k=kubectl
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

eval "$(/usr/bin/mise activate zsh)"

EOF

if [ $? -eq 0 ]; then
    green "~/.zshrc erfolgreich geschrieben."
  else
    yellow "Fehler beim Schreiben von ~/.zshrc."
  fi

  # Copy default .p10k.zsh if not present
  if [ ! -f "$HOME/.p10k.zsh" ]; then
    if [ -f "$(dirname "$0")/dotfiles/.p10k.zsh" ]; then
      cp "$(dirname "$0")/dotfiles/.p10k.zsh" "$HOME/.p10k.zsh" && \
        green "~/.p10k.zsh aus dotfiles erfolgreich kopiert." || yellow "Fehler beim Kopieren von .p10k.zsh aus dotfiles."
    else
      yellow ".p10k.zsh nicht in dotfiles gefunden, bitte manuell kopieren."
    fi
  fi
fi


# -------------------------------
# ZSH als Default Shell (erst jetzt!)
# -------------------------------
blue "[10/16] ZSH als Default-Shell setzen"

if [ "$(basename "$SHELL")" != "zsh" ]; then
  chsh -s "$(command -v zsh)" "$USER" || true
fi

green "Bootstrap erfolgreich abgeschlossen!"
green "Bitte führe in Windows PowerShell aus:    wsl --shutdown"
green "Danach neue WSL-Sitzung öffnen."