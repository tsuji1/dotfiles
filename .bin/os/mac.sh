#!/usr/bin/env bash
# macOS 固有のインストール (install.sh から source される)

link_os_files() {
    : # ~/.config ごとリンクされるので追加作業なし (pwsh も ~/.config/powershell を読む)
}

install_os_packages() {
    if ! command -v brew >/dev/null 2>&1; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    # GUI アプリなど mise で入らないもの
    brew install tmux
    brew install --cask wezterm karabiner-elements
}

install_mise() {
    command -v mise >/dev/null 2>&1 && return
    brew install mise
}

install_agy() {
    command -v agy >/dev/null 2>&1 && return
    curl -fsSL https://antigravity.google/cli/install.sh | bash
}
