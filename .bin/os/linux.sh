#!/usr/bin/env bash
# Linux 固有のインストール (install.sh から source される)

link_os_files() {
    : # ~/.config ごとリンクされるので追加作業なし (pwsh も ~/.config/powershell を読む)
}

install_os_packages() {
    # mise で入らないもの (ビルドツールなど)
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y build-essential curl git unzip tmux
    fi
}

install_mise() {
    command -v mise >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/mise" ]] && return
    curl -fsSL https://mise.run | sh
}

install_agy() {
    command -v agy >/dev/null 2>&1 && return
    curl -fsSL https://antigravity.google/cli/install.sh | bash
}
