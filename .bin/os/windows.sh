#!/usr/bin/env bash
# Windows (Git Bash) 固有のインストール (install.sh から source される)

install_os_packages() {
    if ! command -v scoop >/dev/null 2>&1; then
        powershell.exe -NoProfile -Command \
            "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; irm get.scoop.sh | iex"
        export PATH="$HOME/scoop/shims:$PATH"
    fi
    # GUI アプリなど mise で入らないもの
    scoop bucket add extras || true
    scoop install wezterm
}

install_mise() {
    command -v mise >/dev/null 2>&1 && return
    scoop install mise
}
