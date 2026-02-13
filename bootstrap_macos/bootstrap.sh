#!/usr/bin/env bash
set -euo pipefail

# Farben
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
blue() { printf "\033[34m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }

blue "[1/13] Homebrew & Basiswerkzeuge installieren"

# Xcode Command Line Tools (optional, no-op if already installed)
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install || true
fi

# Homebrew installieren, falls nicht vorhanden
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Homebrew in PATH eintragen (Apple Silicon & Intel)
  if [ -d "/opt/homebrew/bin" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -d "/usr/local/Homebrew" ]; then
    eval "$(/usr/local/bin/brew shellenv || true)"
  fi
fi

brew update
brew install \
  git curl wget unzip jq \
  gnupg

# Git Credential Helper
git config --global --replace-all credential.helper store

# -------------------------------
# GitHub CLI
# -------------------------------
blue "[2/13] GitHub CLI installieren (oder pruefen)"

if ! command -v gh >/dev/null 2>&1; then
  brew install gh
else
  yellow "GitHub CLI bereits vorhanden."
fi

gh --version | head -n 1

# -------------------------------
# Azure CLI
# -------------------------------
blue "[3/13] Azure CLI installieren (oder prüfen)"

if ! command -v az >/dev/null 2>&1; then
  brew install azure-cli
else
  yellow "Azure CLI bereits vorhanden."
fi

# -------------------------------
# kubectl
# -------------------------------
blue "[4/13] kubectl installieren"

if ! command -v kubectl >/dev/null 2>&1; then
  brew install kubectl
else
  yellow "kubectl bereits vorhanden."
fi

# -------------------------------
# Helm
# -------------------------------
blue "[5/13] Helm installieren"

if ! command -v helm >/dev/null 2>&1; then
  brew install helm
else
  yellow "Helm bereits vorhanden."
fi

# -------------------------------
# k9s
# -------------------------------
blue "[6/13] k9s installieren"

if ! command -v k9s >/dev/null 2>&1; then
  brew install k9s
else
  yellow "k9s bereits vorhanden."
fi

# -------------------------------
# Terragrunt
# -------------------------------
blue "[7/13] Terragrunt installieren"

if ! command -v terragrunt >/dev/null 2>&1; then
  brew install terragrunt
else
  yellow "Terragrunt bereits vorhanden."
fi

# -------------------------------
# OpenTofu
# -------------------------------
blue "[8/13] OpenTofu installieren"

if ! command -v tofu >/dev/null 2>&1; then
  brew install opentofu
else
  yellow "OpenTofu bereits vorhanden."
fi

# -------------------------------
# ZSH
# -------------------------------
blue "[9/13] ZSH installieren"

if ! command -v zsh >/dev/null 2>&1; then
  brew install zsh
fi

# -------------------------------
# Oh-My-Zsh
# -------------------------------
blue "[10/13] Oh-My-Zsh installieren"

OMZ_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$OMZ_DIR/custom}"

if [ ! -d "$OMZ_DIR" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  yellow "Oh-My-Zsh bereits vorhanden."
fi

# Plugins
blue "[11/13] Oh-My-Zsh Plugins & Powerlevel10k installieren"

git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || true
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || true
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "$ZSH_CUSTOM/themes/powerlevel10k" 2>/dev/null || true

# Ensure plugin and theme directories exist
mkdir -p "$ZSH_CUSTOM/plugins" "$ZSH_CUSTOM/themes"

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
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" && \
  green "powerlevel10k erfolgreich installiert." || yellow "Fehler beim Installieren von powerlevel10k."


# -------------------------------
# ~/.zshrc schreiben
# -------------------------------
blue "[12/13] ~/.zshrc schreiben"

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
export PATH="/opt/homebrew/opt/curl/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$HOME/bin:$PATH"

# curl (keg-only) compiler flags
export LDFLAGS="-L/opt/homebrew/opt/curl/lib"
export CPPFLAGS="-I/opt/homebrew/opt/curl/include"

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
alias ks='k9s'
alias ll='ls -laFh --color=auto'
alias tf='tofu'
alias tg='terragrunt'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

EOF
  if [ $? -eq 0 ]; then
    green "~/.zshrc erfolgreich geschrieben."
  else
    yellow "Fehler beim Schreiben von ~/.zshrc."
  fi

  # Copy .p10k.zsh from dotfiles if not present
  if [ ! -f "$HOME/.p10k.zsh" ]; then
    if [ -f "$(dirname "$0")/../dotfiles/.p10k.zsh" ]; then
      cp "$(dirname "$0")/../dotfiles/.p10k.zsh" "$HOME/.p10k.zsh" && \
        green "~/.p10k.zsh aus dotfiles erfolgreich kopiert." || yellow "Fehler beim Kopieren von .p10k.zsh aus dotfiles."
    else
      yellow ".p10k.zsh nicht in dotfiles gefunden, bitte manuell kopieren."
    fi
  fi
fi


# -------------------------------
# ZSH als Default Shell (erst jetzt!)
# -------------------------------
blue "[13/13] ZSH als Default-Shell setzen"

if [ "$(basename "$SHELL")" != "zsh" ]; then
  chsh -s "$(command -v zsh)" "$USER" || true
fi

green "Bootstrap (macOS) erfolgreich abgeschlossen!"
