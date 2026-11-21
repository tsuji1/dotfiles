#Requires -Version 5.1
<#
.SYNOPSIS
Install dotfiles on Windows without Git Bash.
.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File .\.bin\install.ps1 -NoDeps
.EXAMPLE
.\.bin\install.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Alias('no-deps')]
    [switch]$NoDeps,
    [string]$HomeDirectory = $env:USERPROFILE
)

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Use .bin/install.sh on Linux or macOS.' }
$DotDirectory = Split-Path -Parent $PSScriptRoot
$HomeDirectory = [IO.Path]::GetFullPath($HomeDirectory)
$BackupDirectory = Join-Path $HomeDirectory ('.dotbackup\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
$NativeHome = $HomeDirectory.TrimEnd('\') -eq $env:USERPROFILE.TrimEnd('\')
if ($NativeHome) {
    $DocumentsDirectory = [Environment]::GetFolderPath('MyDocuments')
    $LocalDirectory = $env:LOCALAPPDATA
} else {
    # An alternate home also isolates the Windows-specific destinations.
    $DocumentsDirectory = Join-Path $HomeDirectory 'Documents'
    $LocalDirectory = Join-Path $HomeDirectory 'AppData\Local'
}

function Backup-Path([string]$Path) {
    # Documents may be redirected to OneDrive or a different drive.
    if ($Path.StartsWith($HomeDirectory + '\', [StringComparison]::OrdinalIgnoreCase)) {
        $relative = $Path.Substring($HomeDirectory.Length).TrimStart('\', '/')
    } else {
        $relative = Join-Path 'redirected' ($Path -replace '[:\\/]', '_')
    }
    $destination = Join-Path $BackupDirectory $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Move-Item -LiteralPath $Path -Destination $destination
    Write-Host "Backed up: $Path -> $destination"
}

function Resolve-DirectoryLinks([string]$Path) {
    # Resolve links in parent directories too. For example, an old install may
    # already link HOME/.config to this repository's .config directory.
    $resolved = [IO.Path]::GetFullPath($Path)
    for ($depth = 0; $depth -lt 32; $depth++) {
        $cursor = $resolved
        $changed = $false
        while ($cursor) {
            $item = Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
            if ($item -and $item.LinkType -in @('Junction', 'SymbolicLink')) {
                $target = @($item.Target)[0]
                if (-not [IO.Path]::IsPathRooted($target)) {
                    $target = Join-Path (Split-Path -Parent $cursor) $target
                }
                $resolved = [IO.Path]::GetFullPath($target + $resolved.Substring($cursor.Length))
                $changed = $true
                break
            }
            $cursor = Split-Path -Parent $cursor
        }
        if (-not $changed) { return $resolved.TrimEnd('\') }
    }
    throw "Too many linked directories in $Path"
}

function Link-Path([string]$Source, [string]$Destination, [switch]$KeepExisting) {
    $sourceItem = Get-Item -LiteralPath $Source -Force
    $existing = Get-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
    if ($KeepExisting -and $existing) { return }
    if ((Resolve-DirectoryLinks $Source) -eq (Resolve-DirectoryLinks $Destination)) { return }
    if ($existing -and $existing.LinkType) {
        foreach ($target in $existing.Target) {
            if ($target -and [IO.Path]::IsPathRooted($target) -and
                [IO.Path]::GetFullPath($target).TrimEnd('\') -eq $Source.TrimEnd('\')) { return }
        }
    }
    if (-not $PSCmdlet.ShouldProcess($Destination, "Link to $Source (back up existing entry)")) { return }
    if ($existing) { Backup-Path $Destination }
    New-Item -ItemType Directory -Path (Split-Path -Parent $Destination) -Force | Out-Null
    if ($sourceItem.PSIsContainer) {
        # Junctions do not require Developer Mode or elevation.
        New-Item -ItemType Junction -Path $Destination -Target $Source | Out-Null
    } else {
        try {
            New-Item -ItemType SymbolicLink -Path $Destination -Target $Source -ErrorAction Stop | Out-Null
        } catch {
            try {
                New-Item -ItemType HardLink -Path $Destination -Target $Source -ErrorAction Stop | Out-Null
            } catch {
                if ($KeepExisting) {
                    [IO.File]::Copy($Source, $Destination)
                    Write-Warning "Copied $Destination as a local file."
                } else {
                    Copy-Item -LiteralPath $Source -Destination $Destination
                    Write-Warning "Copied $Destination; rerun the installer after updating dotfiles."
                }
            }
        }
    }
    Write-Host "Linked: $Destination"
}

function Convert-ConfigLink([string]$Source, [string]$Destination, [switch]$RelinkCopied) {
    $existing = Get-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
    if (-not ($existing -and $existing.LinkType -in @('Junction', 'SymbolicLink'))) { return }
    if ((Resolve-DirectoryLinks $Destination) -ne (Resolve-DirectoryLinks $Source)) { return }
    if (-not $PSCmdlet.ShouldProcess($Destination, 'Move active settings to a local directory')) { return }

    $staging = $Destination + '.dotfiles-' + [Guid]::NewGuid().ToString('N')
    $previous = $staging + '-link'
    try {
        # Copy reparse points as links and keep the original directory available until the copy succeeds.
        & robocopy.exe $Source $staging /E /SL /SJ /R:0 /W:0 /NFL /NDL /NJH /NJS /NP | Out-Host
        if ($LASTEXITCODE -ge 8) { throw "Could not copy active settings from $Source" }
        if ($RelinkCopied) { Add-ConfigDefaults $staging -RelinkCopied }
        Rename-Item -LiteralPath $Destination -NewName (Split-Path -Leaf $previous)
        try {
            if ((Get-Item -LiteralPath $previous -Force).LinkType -notin @('Junction', 'SymbolicLink')) {
                throw "Configuration changed during migration: $Destination"
            }
            Rename-Item -LiteralPath $staging -NewName (Split-Path -Leaf $Destination)
        } catch {
            Rename-Item -LiteralPath $previous -NewName (Split-Path -Leaf $Destination)
            throw
        }
        [IO.Directory]::Delete($previous)
    } finally {
        if ([IO.Directory]::Exists($staging)) { [IO.Directory]::Delete($staging, $true) }
    }
}

function Get-ConfigPaths {
    if ((Test-Path -LiteralPath (Join-Path $DotDirectory '.git')) -and
        (Get-Command git -ErrorAction SilentlyContinue)) {
        Invoke-Checked 'git' @('-C', $DotDirectory, '-c', 'core.quotepath=false', 'ls-files', '--', '.config')
    } else {
        Get-ChildItem -LiteralPath (Join-Path $DotDirectory '.config') -Recurse -Force -File | ForEach-Object {
            $_.FullName.Substring($DotDirectory.Length + 1).Replace('\', '/')
        }
    }
}

function Add-ConfigDefaults([string]$Root, [switch]$RelinkCopied) {
    $rootItem = Get-Item -LiteralPath $Root -Force -ErrorAction SilentlyContinue
    if ($rootItem -and -not $rootItem.PSIsContainer) { return }
    foreach ($path in (Get-ConfigPaths)) {
        $isGhTemplate = $path -eq '.config/gh/config.yml'
        if ((Split-Path -Leaf $path) -eq '.DS_Store' -or ($path.StartsWith('.config/gh/') -and -not $isGhTemplate)) { continue }
        $source = Join-Path $DotDirectory $path
        $destination = Join-Path $Root $path.Substring('.config/'.Length)
        if (-not (Get-Item -LiteralPath $source -Force -ErrorAction SilentlyContinue)) { continue }
        $existing = Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
        if ($existing -and (-not $RelinkCopied -or $isGhTemplate -or $existing.PSIsContainer)) { continue }
        $parent = Split-Path -Parent $destination
        $cursor = $parent
        while ($cursor -and $cursor -ne $Root) {
            $item = Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
            if ($item -and (-not $item.PSIsContainer -or $item.LinkType)) { break }
            $cursor = Split-Path -Parent $cursor
        }
        if ($cursor -ne $Root) { continue }

        if ($isGhTemplate) {
            if ($PSCmdlet.ShouldProcess($destination, 'Copy local gh defaults')) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
                [IO.File]::Copy($source, $destination)
            }
        } else {
            if ($existing) { [IO.File]::Delete($destination) }
            Link-Path $source $destination -KeepExisting
        }
    }
}

function Install-ConfigFiles {
    if ($HomeDirectory -eq $DotDirectory) { return }
    $root = Join-Path $HomeDirectory '.config'
    $sourceRoot = Join-Path $DotDirectory '.config'
    if ((Resolve-DirectoryLinks $root) -eq (Resolve-DirectoryLinks $sourceRoot)) {
        Convert-ConfigLink $sourceRoot $root -RelinkCopied
    } else {
        Convert-ConfigLink (Join-Path $sourceRoot 'gh') (Join-Path $root 'gh')
        Add-ConfigDefaults $root
    }
}

function Write-ProfileLoader([string]$Path) {
    $source = Join-Path $DotDirectory '.config\powershell\Microsoft.PowerShell_profile.ps1'
    $content = "# dotfiles-loader`r`n. '" + $source.Replace("'", "''") + "'`r`n"
    if ((Test-Path -LiteralPath $Path -PathType Leaf) -and
        [IO.File]::ReadAllText($Path) -eq $content) { return }
    if (-not $PSCmdlet.ShouldProcess($Path, 'Write PowerShell profile loader (back up existing entry)')) { return }
    if (Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue) { Backup-Path $Path }
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    # BOM keeps non-ASCII paths readable in Windows PowerShell 5.1 too.
    [IO.File]::WriteAllText($Path, $content, (New-Object Text.UTF8Encoding($true)))
}

function Invoke-Checked([string]$Command, [string[]]$Arguments) {
    $global:LASTEXITCODE = 0
    & $Command @Arguments
    if (-not $?) { throw "Command failed: $Command $Arguments" }
    if ($LASTEXITCODE -ne 0) { throw "Command failed ($LASTEXITCODE): $Command $Arguments" }
}

function Update-ProcessPath {
    $scoopRoot = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $env:USERPROFILE 'scoop' }
    $env:PATH = (Join-Path $scoopRoot 'shims') + ';' +
        [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + $env:PATH
}

function Install-Dependencies {
    Update-ProcessPath
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        # Scoop's installer runs in a child process so its exit cannot exit this script.
        Invoke-Checked 'powershell.exe' @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command',
            'Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Invoke-RestMethod https://get.scoop.sh | Invoke-Expression')
        Update-ProcessPath
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Invoke-Checked 'scoop' @('install', 'git') }
    $buckets = & scoop bucket list
    if (-not $?) { throw 'Unable to list Scoop buckets.' }
    if (-not ($buckets | Where-Object { $_.Name -eq 'extras' })) { Invoke-Checked 'scoop' @('bucket', 'add', 'extras') }
    foreach ($tool in @('wezterm', 'mise', 'pwsh')) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { Invoke-Checked 'scoop' @('install', $tool) }
    }
    Update-ProcessPath

    # Use the installed config even if XDG_CONFIG_HOME is customized.
    $config = Join-Path $HomeDirectory '.config\mise\config.toml'
    $oldConfig = $env:MISE_GLOBAL_CONFIG_FILE
    try {
        $env:MISE_GLOBAL_CONFIG_FILE = $config
        Push-Location $HomeDirectory
        try {
            Invoke-Checked 'mise' @('trust', $config)
            Invoke-Checked 'mise' @('install')
            if (-not (Get-Command agy -ErrorAction SilentlyContinue)) {
                Invoke-Checked 'powershell.exe' @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command',
                    'Invoke-RestMethod https://antigravity.google/cli/install.ps1 | Invoke-Expression')
            }
            # tmux/TPM are Unix-only. Install Neovim plugins on native Windows.
            $state = if ($env:XDG_STATE_HOME) { $env:XDG_STATE_HOME } else { Join-Path $HomeDirectory '.local\state' }
            $log = Join-Path $state 'nvim-install.log'
            New-Item -ItemType Directory -Path $state -Force | Out-Null
            Write-Host "Installing Neovim plugins (log: $log)..."
            # Windows PowerShell treats native stderr as ErrorRecords; Neovim
            # writes normal progress there, so use its exit code to detect failure.
            $previousPreference = $ErrorActionPreference
            try {
                $ErrorActionPreference = 'Continue'
                & mise exec -- nvim --headless '+Lazy! restore' '+qa' *> $log
            } finally { $ErrorActionPreference = $previousPreference }
            if ($LASTEXITCODE -ne 0) {
                Get-Content -LiteralPath $log -Tail 20 | Write-Host
                throw "Neovim plugin install failed. See $log"
            }
        } finally { Pop-Location }
    } finally { $env:MISE_GLOBAL_CONFIG_FILE = $oldConfig }
}

# Repository metadata is never installed into HOME.
Get-ChildItem -LiteralPath $DotDirectory -Force | Where-Object {
    $_.Name.StartsWith('.') -and $_.Name -notin @('.git', '.gitignore', '.config', '.codex', '.claude', '.DS_Store')
} | ForEach-Object { Link-Path $_.FullName (Join-Path $HomeDirectory $_.Name) }
Install-ConfigFiles

$nvimConfig = if ($NativeHome -and $env:XDG_CONFIG_HOME) { Join-Path $env:XDG_CONFIG_HOME 'nvim' } else { Join-Path $LocalDirectory 'nvim' }
Link-Path (Join-Path $DotDirectory '.config\nvim') $nvimConfig -KeepExisting
Write-ProfileLoader (Join-Path $DocumentsDirectory 'PowerShell\Microsoft.PowerShell_profile.ps1')
Write-ProfileLoader (Join-Path $DocumentsDirectory 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1')

# Never replace agent home directories: they also contain credentials and sessions.
$codexConfig = Join-Path $HomeDirectory '.codex\config.toml'
$codexDefault = [IO.File]::ReadAllText((Join-Path $DotDirectory '.codex\defaults.toml')).Trim()
if ($codexDefault -cnotmatch '^model = "[a-zA-Z0-9._-]+"$') {
    throw 'Expected a single model assignment in .codex/defaults.toml.'
}
$codexItem = Get-Item -LiteralPath $codexConfig -Force -ErrorAction SilentlyContinue
$codexLink = $codexItem -and $codexItem.LinkType
$existing = if (Test-Path -LiteralPath $codexConfig -PathType Leaf) {
    [IO.File]::ReadAllText($codexConfig)
} else { '' }
$newline = if ($existing.Contains("`r`n")) { "`r`n" } else { "`n" }
$lines = [regex]::Split($existing, '\r?\n')
$modelIndex = -1
for ($index = 0; $index -lt $lines.Length; $index++) {
    if ($lines[$index] -match '^\s*\[') { break }
    if ($lines[$index] -cmatch '^\s*(model|"model"|''model'')\s*=') {
        if ($lines[$index] -cnotmatch '^\s*(model|"model"|''model'')\s*=\s*("[a-zA-Z0-9._-]+"|''[a-zA-Z0-9._-]+'')(\s*#.*|\s*)$') {
            throw 'Expected a single-line model ID in the local Codex config.'
        }
        $modelIndex = $index
        break
    }
}
if ($modelIndex -ge 0) {
    $lines[$modelIndex] = $lines[$modelIndex] -creplace '^(\s*)(model|"model"|''model'')\s*=\s*("[a-zA-Z0-9._-]+"|''[a-zA-Z0-9._-]+'')', ('${1}' + $codexDefault)
    $updated = $lines -join $newline
} else {
    $updated = $codexDefault + $newline + $existing
}
if (($updated -cne $existing -or $codexLink) -and
    $PSCmdlet.ShouldProcess($codexConfig, 'Apply shared Codex model')) {
    $directory = Split-Path -Parent $codexConfig
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $temporary = Join-Path $directory ([IO.Path]::GetRandomFileName())
    try {
        [IO.File]::WriteAllText($temporary, $updated)
        if ($codexItem) {
            Backup-Path $codexConfig
            if ($codexLink -and $existing.Length) {
                [IO.File]::WriteAllText((Join-Path $BackupDirectory '.codex\config.previous.toml'), $existing)
            }
        }
        Move-Item -LiteralPath $temporary -Destination $codexConfig
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary }
    }
}

foreach ($relative in @('.codex\keybindings.json', '.claude\settings.json')) {
    Link-Path (Join-Path $DotDirectory $relative) (Join-Path $HomeDirectory $relative)
}

Get-ChildItem -LiteralPath (Join-Path $DotDirectory 'skills') -Directory | ForEach-Object {
    if (Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md')) {
        foreach ($directory in @('.claude\skills', '.agents\skills')) {
            Link-Path $_.FullName (Join-Path $HomeDirectory (Join-Path $directory $_.Name))
        }
        $legacy = Join-Path $HomeDirectory ('.codex\skills\' + $_.Name)
        $item = Get-Item -LiteralPath $legacy -Force -ErrorAction SilentlyContinue
        if ($item -and -not $item.LinkType -and $PSCmdlet.ShouldProcess($legacy, 'Back up legacy duplicate skill')) {
            Backup-Path $legacy
        }
    }
}

if (-not $NoDeps -and $PSCmdlet.ShouldProcess('Windows tools', 'Install Scoop, Git, WezTerm, PowerShell 7, mise tools, agy and Neovim plugins')) {
    Install-Dependencies
}
if (-not $WhatIfPreference) {
    Write-Host "Install completed. Backups (if any): $BackupDirectory"
    Write-Host 'Restart PowerShell to load the profile.'
}
