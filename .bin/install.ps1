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

function Link-Path([string]$Source, [string]$Destination) {
    $sourceItem = Get-Item -LiteralPath $Source -Force
    $existing = Get-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
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
                Copy-Item -LiteralPath $Source -Destination $Destination
                Write-Warning "Copied $Destination; rerun the installer after updating dotfiles."
            }
        }
    }
    Write-Host "Linked: $Destination"
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

# Match the shell installer's dotfiles, but merge .config by entry so other apps'
# settings remain in place. Repository metadata is never installed into HOME.
Get-ChildItem -LiteralPath $DotDirectory -Force | Where-Object {
    $_.Name.StartsWith('.') -and $_.Name -notin @('.git', '.gitignore', '.config', '.DS_Store')
} | ForEach-Object { Link-Path $_.FullName (Join-Path $HomeDirectory $_.Name) }
Get-ChildItem -LiteralPath (Join-Path $DotDirectory '.config') -Force | Where-Object {
    $_.Name -ne '.DS_Store'
} | ForEach-Object { Link-Path $_.FullName (Join-Path $HomeDirectory ('.config\' + $_.Name)) }

$nvimConfig = if ($NativeHome -and $env:XDG_CONFIG_HOME) { Join-Path $env:XDG_CONFIG_HOME 'nvim' } else { Join-Path $LocalDirectory 'nvim' }
Link-Path (Join-Path $DotDirectory '.config\nvim') $nvimConfig
Write-ProfileLoader (Join-Path $DocumentsDirectory 'PowerShell\Microsoft.PowerShell_profile.ps1')
Write-ProfileLoader (Join-Path $DocumentsDirectory 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1')

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
