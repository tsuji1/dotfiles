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

case "$(uname -s)" in
Linux) os=linux ;;
Darwin) os=mac ;;
MINGW* | MSYS* | CYGWIN*) os=windows ;;
*)
    command echo "unsupported OS: $(uname -s)" >&2
    exit 1
    ;;
esac
# OS ごとの link_os_files / install_os_packages / install_mise を読み込む
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/os/$os.sh"

install_deps() {
    command echo "[$os] installing OS packages..."
    install_os_packages
    command echo "[$os] installing mise..."
    install_mise
    export PATH="$HOME/.local/bin:$PATH"

    # ここから先は全 OS 共通: ~/.config/mise/config.toml のツールを一括インストール
    command echo "installing tools with mise..."
    mise install

    setup_nvim
}

# nvim を headless で起動し、lazy-lock.json の版でプラグインを入れる (build も走る)
setup_nvim() {
    local log="${XDG_STATE_HOME:-$HOME/.local/state}/nvim-install.log"
    mkdir -p "$(dirname "$log")"
    command echo "installing nvim plugins... (log: $log)"
    if ! mise exec -- nvim --headless "+Lazy! restore" +qa >"$log" 2>&1; then
        command echo "nvim plugin install failed:" >&2
        tail -n 20 "$log" >&2
        return 1
    fi
}

link_to_homedir
link_os_files
if [[ $no_deps == false ]]; then
    install_deps
fi
# git config --global include.path "~/.gitconfig_shared"
command echo -e "\e[1;36m Install completed!!!! \e[m"
