function Dir-Install {
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

# Install features
Dir-Install -Dir 'configs' -Path "$HOME\.config"
Dir-Install -Dir 'dotfiles' -Path "$HOME"
Dir-Install -Dir 'windows' -Path "$HOME"

$firefoxprofiles = "$($env:APPDATA)\Mozilla\Firefox\Profiles"
Get-ChildItem "$firefoxprofiles" | Foreach-Object {
    $profile = $_.FullName
    $dest = "$profile\chrome"
    New-Item -Type Directory $dest -ErrorAction SilentlyContinue
    Dir-Install -Dir 'firefox' -Path "$dest"
}

echo 'Done!'
