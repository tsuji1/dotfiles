if status is-interactive
    # Commands to run in interactive sessions can go here
    command -q mise; and mise activate fish | source
end


# Added by Antigravity CLI installer
set -gx PATH "/home/yuzugon/.local/bin" $PATH
