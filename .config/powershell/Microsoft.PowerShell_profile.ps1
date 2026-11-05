function coder {
    param (
        [string]$remoteHost, # $1 に相当
        [string]$filePath     # $2 に相当
    )
    & code --remote "ssh-remote+$remoteHost" $filePath
}


function Touch($file) {
    # Resolve-Path の結果を取得
    $resolved = Resolve-Path -Path $file -ErrorAction SilentlyContinue
    if ($resolved) {
        # Resolve-Path が成功した場合、.Path プロパティを使う
        $fullPath = $resolved.Path
    } else {
        # 失敗した場合、現在のディレクトリと結合
        $fullPath = Join-Path -Path (Get-Location) -ChildPath $file
    }

    # ファイルが存在しない場合は作成
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType File -Path $fullPath | Out-Null
    }

    # 最終更新時刻を現在時刻に更新
    [System.IO.File]::SetLastWriteTime($fullPath, (Get-Date))
}

$GhCopilot = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\gh-copilot.ps1"
if (Test-Path $GhCopilot) { . $GhCopilot }

# mise で入れたツールを PATH に通す
if (Get-Command mise -ErrorAction SilentlyContinue) {
  mise activate pwsh | Out-String | Invoke-Expression
}

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
