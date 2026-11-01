#!/usr/bin/env bash
set -ue

# from https://qiita.com/yutkat/items/c6c7584d9795799ee164

helpmsg() {
    command echo "Usage: $0 [--help | -h] [--debug | -d] [--no-deps]" 0>&2
    command echo "  --no-deps  シンボリックリンクだけ張り、依存ツールは入れない" 0>&2
    command echo ""
}

link_to_homedir() {
    command echo "backup old dotfiles..."
    if [ ! -d "$HOME/.dotbackup" ]; then
        command echo "$HOME/.dotbackup not found. Auto Make it"
        command mkdir "$HOME/.dotbackup"
    fi

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    local dotdir=$(dirname ${script_dir})
    if [[ "$HOME" != "$dotdir" ]]; then
        for f in $dotdir/.??*; do
            [[ $(basename $f) == ".git" ]] && continue
            if [[ -L "$HOME/$(basename $f)" ]]; then
                command rm -f "$HOME/$(basename $f)"
            fi
            if [[ -e "$HOME/$(basename $f)" ]]; then
                command mv "$HOME/$(basename $f)" "$HOME/.dotbackup"
            fi
            command ln -snf $f $HOME
        done
    else
        command echo "same install src dest"
    fi
}

no_deps=false
while [ $# -gt 0 ]; do
    case ${1} in
    --no-deps)
        no_deps=true
        ;;
    --debug | -d)
        set -uex
        ;;
    --help | -h)
        helpmsg
        exit 1
        ;;
    *) ;;
    esac
    shift
done

install_deps() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    local os
    case "$(uname -s)" in
    Linux) os=linux ;;
    Darwin) os=mac ;;
    MINGW* | MSYS* | CYGWIN*) os=windows ;;
    *)
        command echo "unsupported OS: $(uname -s)" >&2
        return 1
        ;;
    esac

    # OS ごとの install_os_packages / install_mise を読み込む
    source "$script_dir/os/$os.sh"

    command echo "[$os] installing OS packages..."
    install_os_packages
    command echo "[$os] installing mise..."
    install_mise
    export PATH="$HOME/.local/bin:$PATH"

    # ここから先は全 OS 共通: ~/.config/mise/config.toml のツールを一括インストール
    command echo "installing tools with mise..."
    mise install
}

link_to_homedir
if [[ $no_deps == false ]]; then
    install_deps
fi
# git config --global include.path "~/.gitconfig_shared"
command echo -e "\e[1;36m Install completed!!!! \e[m"
