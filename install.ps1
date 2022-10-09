param(
  [Parameter(HelpMessage="Automatically install work applications")]
  [switch]$w = $False,
  [Parameter(HelpMessage="Automatically install personal applications")]
  [switch]$h = $False,
  [Parameter(HelpMessage="Skip all package installation")]
  [switch]$n = $False
)

function Install-Dir {
  param ([string]$dir, [string]$path)
    echo "Installing $dir to $path..."
    Get-ChildItem "$PSScriptRoot\$dir" | Foreach-Object {
      $orig = $_.FullName
        $file = $_.Name
        $dest = "$path\$file"
        if (-not (Test-Path -Path $dest)) {
          New-Item -ItemType SymbolicLink -Target $orig -Path $dest -ErrorAction Stop
        }
    }
}

function Install-File {
  param ([string]$file, [string]$dest)
    echo "Installing $file to $dest..."
    $props = Get-ChildItem "$PSScriptRoot\$file"
    $orig = $props.FullName
    if (-not (Test-Path -Path $dest)) {
      $destPath = [System.IO.Path]::GetDirectoryName($dest)
      if (-not (Test-Path -Path $destPath)) {
        New-Item $destPath -ItemType Directory
      }
      New-Item -ItemType SymbolicLink -Target $orig -Path $dest -ErrorAction Stop
    }
}

function Install-WingetPackages {
  param ([string[]]$packages)
    $packages.ForEach({
      winget list -e --id $_
      if ($?) {
        Write-Host "$_ already installed, skipping..."
      } else {
        Write-Host "Installing $_..."
        winget install -e -s winget --accept-package-agreements --accept-source-agreements --id $_
      }
    })
}

# Install packages
if (-not $n) {
  Write-Host 'Installing common packages...'
    Install-WingetPackages (
        '7zip.7zip', 'AgileBits.1Password', 'ApacheFriends.Xampp.8.1',
        'Armin2208.WindowsAutoNightMode', 'Git.Git', 'GitHub.cli', 'Google.Chrome',
        'JanDeDobbeleer.OhMyPosh', 'Lexikos.AutoHotkey', 'Logitech.GHUB',
        'Logitech.OptionsPlus', 'Microsoft.PowerShell.Preview', 'Microsoft.PowerToys',
        'Microsoft.VisualStudioCode', 'Microsoft.WindowsTerminal', 'Mozilla.Firefox',
        'Neovim.Neovim.Nightly', 'Obsidian.Obsidian', 'Python.Python.3.10',
        'Spotify.Spotify', 'SyncTrayzor.SyncTrayzor', 'Yarn.Yarn', 'Zoom.Zoom'
        )

    if ($h -or ((-not $w) -and ($(Read-Host -Prompt 'Install home packages? (y/N)') -eq 'y'))) {
      Write-Host 'Installing home packages...'
        Install-WingetPackages (
            'Discord.Discord', 'Foxit.FoxitReader', 'Mojang.MinecraftLauncher',
            'OpenWhisperSystems.Signal', 'Samsung.DeX', 'Telegram.TelegramDesktop',
            'Ultimaker.Cura', 'Valve.Steam', 'VideoLAN.VLC'
            )
    }

# Work
  if ($w -or ((-not $h) -and ($(Read-Host -Prompt 'Install work packages? (y/N)') -eq 'y'))) {
    Write-Host 'Installing work packages...'
      Install-WingetPackages (
          'Asana.Asana', 'Figma.Figma', 'GitHub.GitHubDesktop',
          'Hashicorp.Vagrant', 'Loom.Loom', 'Oracle.VirtualBox',
          'SlackTechnologies.Slack'
          )
  }
}

# Install features
Install-Dir -Dir 'configs' -Path "$HOME\.config"
Install-Dir -Dir 'dotfiles' -Path "$HOME"
Install-File 'windows\profile.ps1' $PROFILE
Install-File 'windows\layers.ahk' 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\layers.ahk'

# This one auto-installs itself
windows\windowsTerminal_themeToggler.ps1

$firefoxprofiles = "$($env:APPDATA)\Mozilla\Firefox\Profiles"
Get-ChildItem "$firefoxprofiles" | Foreach-Object {
  $profile = $_.FullName
    $dest = "$profile\chrome"
    New-Item -Type Directory $dest -ErrorAction SilentlyContinue
    Install-Dir -Dir 'firefox' -Path "$dest"
}

echo 'Done!'
