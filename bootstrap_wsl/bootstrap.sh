#!/usr/bin/env bash
set -euo pipefail
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
sudo apt-get install -y \
  git curl wget unzip jq ca-certificates gnupg software-properties-common \
  dnsutils iputils-ping net-tools

# Git Credential Helper
git config --global credential.helper store

# -------------------------------
# GitHub CLI
# -------------------------------
blue "[2/16] GitHub CLI installieren (oder pruefen)"

if ! command -v gh >/dev/null 2>&1; then
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y gh
else
  yellow "GitHub CLI bereits vorhanden."
fi

gh --version | head -n 1

# -------------------------------
# Azure CLI
# -------------------------------
blue "[3/16] Azure CLI installieren (oder prüfen)"

if ! command -v az >/dev/null 2>&1; then
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo -E bash
else
  yellow "Azure CLI bereits vorhanden."
fi

# -------------------------------
# kubelogin
# -------------------------------
blue "[4/16] kubelogin installieren"

if ! command -v kubelogin >/dev/null 2>&1; then
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/microsoft.gpg >/dev/null

  UBUNTU_CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/microsoft-ubuntu-${UBUNTU_CODENAME}-prod ${UBUNTU_CODENAME} main" \
    | sudo tee /etc/apt/sources.list.d/microsoft-ubuntu-prod.list >/dev/null

  sudo apt-get update -y
  sudo apt-get install -y kubelogin
else
  yellow "kubelogin bereits vorhanden."
fi

kubelogin --version | head -n 1

# -------------------------------
# kubectl
# -------------------------------
blue "[5/16] kubectl installieren"

if ! command -v kubectl >/dev/null 2>&1; then
  KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  blue "kubectl Version: $KUBECTL_VERSION"
  sudo curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    -o /usr/local/bin/kubectl
  sudo chmod +x /usr/local/bin/kubectl
else
  yellow "kubectl bereits vorhanden."
fi

# -------------------------------
# stern
# -------------------------------
blue "[6/16] stern installieren"

if ! command -v stern >/dev/null 2>&1; then
  STERN_VERSION="$(curl -fsSL https://api.github.com/repos/stern/stern/releases/latest | grep tag_name | cut -d '"' -f 4)"
  blue "stern Version: $STERN_VERSION"
  curl -fsSL \
    "https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${STERN_VERSION#v}_linux_amd64.tar.gz" \
    -o /tmp/stern.tar.gz
  tar -C /tmp -xzf /tmp/stern.tar.gz stern
  sudo mv /tmp/stern /usr/local/bin/stern
  sudo chmod +x /usr/local/bin/stern
else
  yellow "stern bereits vorhanden."
fi

# -------------------------------
# sveltosctl
# -------------------------------
blue "[7/16] sveltosctl installieren"

if ! command -v sveltosctl >/dev/null 2>&1; then
  SVELTOS_VERSION="$(curl -fsSL https://api.github.com/repos/projectsveltos/sveltosctl/releases/latest | grep tag_name | cut -d '"' -f 4)"
  blue "sveltosctl Version: $SVELTOS_VERSION"
  sudo wget -qO /usr/local/bin/sveltosctl \
    "https://github.com/projectsveltos/sveltosctl/releases/download/${SVELTOS_VERSION}/sveltosctl-linux-amd64"
  sudo chmod +x /usr/local/bin/sveltosctl
else
  yellow "sveltosctl bereits vorhanden."
fi

# -------------------------------
# Helm
# -------------------------------
blue "[8/16] Helm installieren"

if ! command -v helm >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  yellow "Helm bereits vorhanden."
fi

# -------------------------------
# k9s
# -------------------------------
blue "[9/16] k9s installieren"

if ! command -v k9s >/dev/null 2>&1; then
  K9S_VERSION="$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)"
  blue "k9s Version: $K9S_VERSION"
  curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz" \
    -o /tmp/k9s.tar.gz
  tar -C /tmp -xzf /tmp/k9s.tar.gz k9s
  sudo mv /tmp/k9s /usr/local/bin/k9s
  sudo chmod +x /usr/local/bin/k9s
else
  yellow "k9s bereits vorhanden."
fi

# -------------------------------
# Terragrunt (Binary)
# -------------------------------
blue "[10/16] Terragrunt installieren"

if ! command -v terragrunt >/dev/null 2>&1; then
  TG_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep tag_name | cut -d '"' -f 4)
  sudo wget -qO /usr/local/bin/terragrunt \
    "https://github.com/gruntwork-io/terragrunt/releases/download/${TG_VERSION}/terragrunt_linux_amd64"
  sudo chmod +x /usr/local/bin/terragrunt
else
  yellow "Terragrunt bereits vorhanden."
fi

# -------------------------------
# OpenTofu (GitHub Binary → 100% Proxy-Safe)
# -------------------------------
blue "[11/16] OpenTofu installieren (GitHub Binary)"

if ! command -v tofu >/dev/null 2>&1; then
  VERSION=$(curl -fsSL https://api.github.com/repos/opentofu/opentofu/releases/latest \
      | grep tag_name | cut -d '"' -f 4 | cut -d "v" -f 2)

  blue "OpenTofu Version: $VERSION"

  curl -fsSL \
    "https://github.com/opentofu/opentofu/releases/download/v${VERSION}/tofu_${VERSION}_linux_amd64.zip" \
    -o /tmp/tofu.zip

  unzip -o /tmp/tofu.zip -d /tmp/
  sudo mv /tmp/tofu /usr/local/bin/tofu
  sudo chmod +x /usr/local/bin/tofu
else
  yellow "OpenTofu bereits vorhanden."
fi

# -------------------------------
# ZSH
# -------------------------------
blue "[12/16] ZSH installieren"

if ! command -v zsh >/dev/null 2>&1; then
  sudo apt-get install -y zsh
fi

# -------------------------------
# Oh-My-Zsh
# -------------------------------
blue "[13/16] Oh-My-Zsh installieren"

OMZ_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$OMZ_DIR/custom}"

if [ ! -d "$OMZ_DIR" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  yellow "Oh-My-Zsh bereits vorhanden."
fi

# Plugins

blue "[14/16] Oh-My-Zsh Plugins & Powerlevel10k installieren"

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
blue "[15/16] ~/.zshrc schreiben"

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
export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$HOME/bin:$PATH"

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

EOF
  if [ $? -eq 0 ]; then
    green "~/.zshrc erfolgreich geschrieben."
  else
    yellow "Fehler beim Schreiben von ~/.zshrc."
  fi

  # Copy default .p10k.zsh if not present
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
blue "[16/16] ZSH als Default-Shell setzen"

if [ "$(basename "$SHELL")" != "zsh" ]; then
  chsh -s "$(command -v zsh)" "$USER" || true
fi

green "Bootstrap erfolgreich abgeschlossen!"
green "Bitte führe in Windows PowerShell aus:    wsl --shutdown"
green "Danach neue WSL-Sitzung öffnen."

