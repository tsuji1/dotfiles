# dotfiles

## Windows

通常の（管理者ではない）PowerShellで、リポジトリのルートから実行します。
Windows PowerShell 5.1 / PowerShell 7 に対応し、Git Bashは不要です。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.bin\install.ps1
```

設定の配置だけ行う場合、または変更予定を確認する場合：

```powershell
.\.bin\install.ps1 -NoDeps
.\.bin\install.ps1 -WhatIf
```

- 既存の設定は `~/.dotbackup/<日時>/` に退避します。
- `.config` は項目ごとに接続します。フォルダーは管理者権限不要のジャンクション、ファイルはシンボリックリンクを使います。権限がない場合はハードリンク、別ドライブなどでそれも作れない場合はコピーに切り替えます。ハードリンク・コピーはGit更新で追従しない場合があるため、更新後は再実行してください。
- PowerShell 5.1 / 7 のプロファイルと、Windows版Neovimの設定先も用意します。
- `skills/` は `~/.claude/skills` と `~/.agents/skills` に接続します。同名の旧 `~/.codex/skills` の実体は退避します。
- 依存ツールはScoop、Git、WezTerm、PowerShell 7、mise設定内のツール、agy、Neovimプラグインを導入します。tmux/TPMはWindowsでは導入しません。Scoopを新規導入するときはCurrentUserの実行ポリシーをRemoteSignedに設定します。
- 検証用に `-HomeDirectory <一時フォルダー>` を指定できます。設定配置の確認には `-NoDeps` も付けてください。

Git Bashからの `bash .bin/install.sh` も、このPowerShellスクリプトへ転送します。

## Linux / macOS

```bash
bash .bin/install.sh
# 設定の配置だけ
bash .bin/install.sh --no-deps
```
