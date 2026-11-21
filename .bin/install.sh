#!/usr/bin/env bash
set -ue

# from https://qiita.com/yutkat/items/c6c7584d9795799ee164

helpmsg() {
    command echo "Usage: $0 [--help | -h] [--debug | -d] [--no-deps]" 0>&2
    command echo "  --no-deps  シンボリックリンクだけ張り、依存ツールは入れない" 0>&2
    command echo ""
}

link_to_homedir() {
    local f name
    command echo "backup old dotfiles..."
    if [ ! -d "$HOME/.dotbackup" ]; then
        command echo "$HOME/.dotbackup not found. Auto Make it"
        command mkdir "$HOME/.dotbackup"
    fi

    if [[ "$HOME" != "$dotdir" ]]; then
        for f in "$dotdir"/.??*; do
            name="${f##*/}"
            case "$name" in
                .git | .config | .codex | .claude) continue ;;
            esac
            if [[ -L "$HOME/$name" ]]; then
                command rm -f "$HOME/$name"
            fi
            if [[ -e "$HOME/$name" ]]; then
                command mv "$HOME/$name" "$HOME/.dotbackup"
            fi
            command ln -snf "$f" "$HOME"
        done
    else
        command echo "same install src dest"
    fi
}

link_agent_settings() {
    local dotdir="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)")"
    local backup="$HOME/.dotbackup/agent-settings/$(date +%Y%m%d%H%M%S)-$$"
    local relative source dest
    local config="$HOME/.codex/config.toml" model input temporary
    model="$(cat "$dotdir/.codex/defaults.toml")"
    if ! [[ "$model" =~ ^model\ =\ \"[a-zA-Z0-9._-]+\"$ ]]; then
        echo 'Expected a single model assignment in .codex/defaults.toml.' >&2
        return 1
    fi
    mkdir -p "$(dirname "$config")"
    input=/dev/null
    if [[ -f "$config" ]]; then input="$config"; fi
    temporary="$(mktemp "$HOME/.codex/.config.XXXXXXXX")"
    if ! awk -v model="$model" '
        BEGIN { quote = sprintf("%c", 39); key = "(model|\"model\"|" quote "model" quote ")" }
        !table && /^[[:space:]]*\[/ { table = 1 }
        !table && $0 ~ ("^[[:space:]]*" key "[[:space:]]*=") {
            assignment = key "[[:space:]]*=[[:space:]]*(\"[a-zA-Z0-9._-]+\"|" quote "[a-zA-Z0-9._-]+" quote ")"
            if ($0 !~ ("^[[:space:]]*" assignment "([[:space:]]*#.*|[[:space:]]*)$")) exit 1
            sub(assignment, model)
            found = 1
        }
        { lines[NR] = $0 }
        END {
            if (!found) print model
            for (i = 1; i <= NR; i++) print lines[i]
        }
    ' "$input" > "$temporary"; then
        rm -f "$temporary"
        echo 'Expected a single-line model ID in the local Codex config.' >&2
        return 1
    fi
    if [[ -L "$config" ]] || ! cmp -s "$temporary" "$config"; then
        if [[ -e "$config" || -L "$config" ]]; then
            mkdir -p "$backup/.codex"
            cp -p "$config" "$backup/.codex/config.toml" 2>/dev/null ||
                cp -P "$config" "$backup/.codex/config.toml"
        fi
        mv -f "$temporary" "$config"
    else
        rm -f "$temporary"
    fi
    for relative in .codex/keybindings.json .claude/settings.json; do
        source="$dotdir/$relative"
        dest="$HOME/$relative"
        [[ "$source" == "$dest" ]] && continue
        if [[ -L "$dest" && "$(readlink "$dest")" == "$source" ]]; then
            continue
        fi
        if [[ -e "$dest" || -L "$dest" ]]; then
            mkdir -p "$backup/$(dirname "$relative")"
            command mv "$dest" "$backup/$relative"
        fi
        mkdir -p "$(dirname "$dest")"
        command ln -s "$source" "$dest"
    done
}

config_files() {
    if [[ -e "$dotdir/.git" ]] && command -v git >/dev/null 2>&1; then
        command git -C "$dotdir" ls-files -z -- .config
    else
        # A source archive can be installed before Git is available.
        cd "$dotdir" && command find .config ! -type d -print0
    fi
}

ensure_config_directory() {
    local dir="$1" root="$2"
    [[ "$dir" == "$root" ]] && return 0
    ensure_config_directory "${dir%/*}" "$root" || return 1
    [[ -L "$dir" || ( -e "$dir" && ! -d "$dir" ) ]] && return 1
    [[ -d "$dir" ]] || command mkdir -p "$dir" || exit 1
}

install_config_files() (
    set -o pipefail
    local root="$1" migrating="${2:-false}"
    local path source target parent
    config_files | while IFS= read -r -d '' path; do
        case "$path" in
            .config/gh/config.yml) ;;
            .config/gh/* | */.DS_Store) continue ;;
        esac
        source="$dotdir/$path"
        [[ -f "$source" || -L "$source" ]] || continue
        target="$root/${path#.config/}"
        parent="${target%/*}"
        ensure_config_directory "$parent" "$root" || continue

        if [[ "$path" == .config/gh/config.yml ]]; then
            # gh can rewrite its configuration. Keep its defaults local, too.
            [[ -e "$target" || -L "$target" ]] || command cp -pn "$source" "$parent/"
        else
            # A migrated file is a snapshot of the same source the old link used.
            if [[ "$migrating" == true && ! -d "$target" ]]; then
                command rm -f "$target"
            fi
            [[ -e "$target" || -L "$target" ]] || command ln -s "$source" "$parent/"
        fi
    done
)

migrate_config_link() (
    local root="$1" staging
    staging="$(command mktemp -d "$HOME/.config.dotfiles.XXXXXXXX")"
    trap '
        if [[ ( -e "$staging/previous" || -L "$staging/previous" ) && ! -e "$root" && ! -L "$root" ]]; then
            command mv "$staging/previous" "$root"
        fi
        command rm -rf "$staging/.config"
        command rmdir "$staging"
    ' EXIT

    # Stage a complete snapshot of the active settings, including ignored files.
    command mkdir "$staging/.config"
    command cp -pPR "$root/." "$staging/.config/"
    install_config_files "$staging/.config" true

    [[ -L "$root" && "$root" -ef "$dotdir/.config" ]] || return 1
    command mv "$root" "$staging/previous"
    [[ -L "$staging/previous" ]] || return 1
    command mv "$staging/.config" "$HOME/"
    command rm "$staging/previous"
)

link_config_files() {
    local root="$HOME/.config"
    [[ "$HOME" == "$dotdir" ]] && return 0
    if [[ -L "$root" && "$root" -ef "$dotdir/.config" ]]; then
        migrate_config_link "$root"
    elif [[ ! "$root" -ef "$dotdir/.config" ]]; then
        [[ ! -d "$root" && ( -e "$root" || -L "$root" ) ]] && return 0
        command mkdir -p "$root"
        install_config_files "$root"
    fi
}

# dotfiles/skills/<name> を Claude Code と Codex のユーザー Skills にリンクする。
# ~/.claude や ~/.agents は認証情報などを含むため丸ごとリンクせず、Skill ごとにリンクする。
link_agent_skills() {
    local src="$dotdir/skills"
    [[ -d "$src" ]] || return 0
    local backup="$HOME/.dotbackup/skills/$(date +%Y%m%d%H%M%S)"
    local targets=("$HOME/.claude/skills" "$HOME/.agents/skills")

    command echo "linking agent skills..."
    for skill in "$src"/*/; do
        skill="${skill%/}"
        [[ -f "$skill/SKILL.md" ]] || continue
        local name="$(basename "$skill")"

        for dir in "${targets[@]}"; do
            mkdir -p "$dir"
            local dest="$dir/$name"
            if [[ -L "$dest" ]]; then
                command rm -f "$dest"
            elif [[ -e "$dest" ]]; then
                mkdir -p "$backup/$(basename "$(dirname "$dir")")"
                command mv "$dest" "$backup/$(basename "$(dirname "$dir")")/"
            fi
            command ln -sn "$skill" "$dest"
        done

        # 旧来の Codex の置き場所 (~/.codex/skills) に同名の実体があれば二重読み込みを避けるため退避
        local legacy="$HOME/.codex/skills/$name"
        if [[ -e "$legacy" && ! -L "$legacy" ]]; then
            mkdir -p "$backup/.codex"
            command mv "$legacy" "$backup/.codex/"
        fi
    done

    # リンク先が消えた Skill のリンクを掃除
    for dir in "${targets[@]}"; do
        for l in "$dir"/*; do
            [[ -L "$l" && ! -e "$l" && "$(readlink "$l")" == "$src/"* ]] && command rm -f "$l"
        done
    done
    return 0
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
MINGW* | MSYS* | CYGWIN*)
    # Native Windows setup lives in PowerShell; keep this entry point compatible.
    ps_args=()
    [[ $no_deps == true ]] && ps_args+=(-NoDeps)
    exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File \
        "$(cygpath -w "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/install.ps1")" "${ps_args[@]}"
    ;;
*)
    command echo "unsupported OS: $(uname -s)" >&2
    exit 1
    ;;
esac
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
dotdir="${script_dir%/*}"
source "$script_dir/os/$os.sh"

install_deps() {
    command echo "[$os] installing OS packages..."
    install_os_packages
    command echo "[$os] installing mise..."
    install_mise
    export PATH="$HOME/.local/bin:$PATH"

    # ここから先は全 OS 共通: ~/.config/mise/config.toml のツールを一括インストール
    command echo "installing tools with mise..."
    mise install

    # mise で入らないもの (OS ごとの公式インストーラー)
    command echo "[$os] installing agy..."
    install_agy

    setup_tmux
    setup_nvim
}

# TPM が未取得の場合だけインストールする
setup_tmux() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ ! -d "$tpm_dir" ]]; then
        command echo "installing tmux plugin manager..."
        mkdir -p "$(dirname "$tpm_dir")"
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    fi
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
link_config_files
link_agent_settings
link_agent_skills
if [[ $no_deps == false ]]; then
    install_deps
fi
# git config --global include.path "~/.gitconfig_shared"
command echo -e "\e[1;36m Install completed!!!! \e[m"
