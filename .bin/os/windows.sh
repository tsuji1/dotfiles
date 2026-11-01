#!/usr/bin/env bash
# Windows (Git Bash) 固有のインストール (install.sh から source される)

link_os_files() {
    # pwsh は Documents\PowerShell の profile を読むので、dotfiles 側を読み込むだけの
    # ファイルを置く (シンボリックリンクだと管理者権限/開発者モードが要るため)
    local docs; docs=$(powershell.exe -NoProfile -Command "[Environment]::GetFolderPath('MyDocuments')" | tr -d '\r')
    local profile_dir; profile_dir="$(cygpath -u "$docs")/PowerShell"
    local profile="$profile_dir/Microsoft.PowerShell_profile.ps1"
    local src; src=$(cygpath -w "$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1")
    mkdir -p "$profile_dir"
    if [[ -f "$profile" ]] && ! grep -q "dotfiles-loader" "$profile"; then
        mv "$profile" "$HOME/.dotbackup/Microsoft.PowerShell_profile.ps1"
    fi
    printf '# dotfiles-loader\n. "%s"\n' "$src" >"$profile"
}

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

install_agy() {
    command -v agy >/dev/null 2>&1 && return
    powershell.exe -NoProfile -Command "irm https://antigravity.google/cli/install.ps1 | iex"
}
