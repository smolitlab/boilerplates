# Setting for my Workplace Setup

## ZSH and P10K Setup

To change the Powerlevel10k you can run "p10k configure" the result will be saved in .p10k.zsh.

## MacOS

    VScode

    VS Code User Settings Speicherort: 
    
    ~/Library/Application Support/Code/User/settings.json
    ~/Library/Application Support/Code/User/keybindings.json
    

## WSL - Ubuntu

    Bootstrap Script

    Git line endings:

        core.autocrlf=false
        core.eol=lf
        core.safecrlf=warn

    VS Code Remote Settings Speicherort:

        ~/.vscode-server/data/Machine/settings.json

## Windows

    VScode

    VS Code User Settings Speicherort: 

        %APPDATA%\Code\User\settings.json
        %APPDATA%\Code\User\keybindings.json

    Bootstrap Script:

        ./bootstrap-windows.ps1

## Line endings

Standard fuer diese Arbeitsumgebung ist LF, auch auf Windows. Das vermeidet CRLF/LF-Diffs beim Arbeiten zwischen Windows, WSL, VS Code und Git.

Zentrale Defaults:

- Git global: `core.autocrlf=false`, `core.eol=lf`, `core.safecrlf=warn`
- VS Code: `"files.eol": "\n"`
- Repositories sollten zusaetzlich eine `.gitattributes` mit `* text=auto eol=lf` haben, wenn LF fuer alle Mitwirkenden erzwungen werden soll.

## Vaults

Dieses Repository enthaelt wiederverwendbare Arbeitsumgebungs- und Dotfiles-Konfiguration. Vault-Inhalte gehoeren nicht hierher.

Der Windows-/WSL-Arbeitsplatz und der private Mac koennen dasselbe Boilerplates-Repository nutzen. Der private Mac verwendet aber einen eigenen privaten Vault.
