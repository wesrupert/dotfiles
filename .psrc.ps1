# Imports {{{ {{{ {{{

Import-Module 'C:\tools\poshgit\dahlbyk-posh-git-a4faccd\src\posh-git.psd1'

# }}} }}} }}}

# Aliases {{{

function settings { GVim C:\Users\wesr\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 }

Set-Alias -Option AllScope ls List-Compact
Set-Alias open explorer
function .. { cd .. }
function ... { cd ..\.. }
function .... { cd ..\..\.. }
function ..... { cd ..\..\..\.. }
function ...... { cd ..\..\..\..\.. }
function ....... { cd ..\..\..\..\..\.. }
function ........ { cd ..\..\..\..\..\..\.. }
function ......... { cd ..\..\..\..\..\..\..\.. }
function .......... { cd ..\..\..\..\..\..\..\..\.. }
function ........... { cd ..\..\..\..\..\..\..\..\..\.. }
Set-Alias mklink Make-Link

Set-Alias gdt Git-Difftool

Set-Alias clock Clear-Lock
Set-Alias glock Get-Lock
Set-Alias online GoTo-Remote

Set-Alias pr Start-Review
Set-Alias cr Start-Review

Set-Alias which Get-Command

function fzc { fzf | clip }

# }}}

# Functions {{{

function global:Set-MyPrompt { # {{{
    [System.ConsoleColor]$global:cDelim  = [System.ConsoleColor]::Blue
    [System.ConsoleColor]$global:cDir    = [System.ConsoleColor]::Gray
    [System.ConsoleColor]$global:cRepo   = [System.ConsoleColor]::Magenta
    [System.ConsoleColor]$global:cArch   = [System.ConsoleColor]::DarkMagenta
    [System.ConsoleColor]$global:cLock   = [System.ConsoleColor]::Yellow
    [System.ConsoleColor]$global:cBranch = [System.ConsoleColor]::DarkYellow
    $global:promptWidth = 80
    $global:showDirInfo = $true
    
    function global:prompt {
        # NOTE: Write-Prompt/Write-VcsStatus come from posh-git
        $realLASTEXITCODE = $LASTEXITCODE
        $global:GitPromptLength = 0

        if ($GitPromptSettings) {
            $GitPromptSettings.BeforeForegroundColor = $cDelim
                $GitPromptSettings.AfterForegroundColor = $cDelim
                $GitPromptSettings.BranchForegroundColor = $cBranch
                $GitPromptSettings.BranchIdenticalStatusToForegroundColor = $cBranch
        }

        $dirs = $pwd.ProviderPath.Split('\')
        if ($dirs.Length -ge 2 -and ($dirs[0] -eq 'S:' -or $dirs -eq 'A:') -and $dirs[1]) {
            Write-Prompt $dirs[0] $cDir
            Write-Prompt '\' $cDelim
            Write-Prompt $dirs[1] $cRepo
            if ($dirs.Length -ge 3) {
                for ($i = 3; $i -lt $dirs.Length; $i++) { Write-Prompt '.' $cDir }
                Write-Prompt '\' $cDelim
                Write-Prompt "$($dirs[$dirs.Length - 1])" $cDir
            }

            if ($env:_BuildArch) {
                Write-Prompt ' (' $cDelim
                Write-Prompt "$($env:_BuildArch)$($env:_BuildType)" $cArch
                Write-Prompt ')' $cDelim
            }
        } else {
            Write-Prompt "$($pwd.ProviderPath)" $cDir
        }

        if ($showDirInfo) {
            $gci = $(gci .)
            $dirs = $($gci | Where-Object { $_.PSIsContainer }).Count ; $files = $($gci.Count - $dirs)
            Write-Prompt ' ┤' $cDelim
            Write-Prompt "📂$dirs 💾$files" $cDir
            Write-Prompt '├' $cDelim
        }

        Write-VcsStatus

        if ($env:LOCK -and $(Test-Path $env:LOCK)) {
            Write-Prompt ' |' $cDelim
            Write-Prompt 'L' $cLock
            Write-Prompt '|' $cDelim
        }

        if ($Host.UI.RawUI.WindowSize.Width -lt $global:promptWidth) {
            Write-Host ' ¬' # Newline
        } else {
            Write-Prompt ' '
        }

        Write-Prompt '➤'

        $global:LASTEXITCODE = $realLASTEXITCODE
        return ' '
    }
} # }}}

# Log-Command function {{{

Add-Type -TypeDefinition @"
    public enum ContentType {
        Command,
        Instruction,
        Warning,
        Error,
        Information,
        SubInfo,
        Other
    }
"@

function Get-TypeColor([ContentType]$type) { # {{{
    switch ($type) {
        'Command'     { if ($env:COMMANDCOLOR)     { $env:COMMANDCOLOR     } else { 'Magenta' } }
        'Instruction' { if ($env:INSTRUCTIONCOLOR) { $env:INSTRUCTIONCOLOR } else { 'Yellow'  } }
        'Warning'     { if ($env:WARNINGCOLOR)     { $env:WARNINGCOLOR     } else { 'Yellow'  } }
        'Error'       { if ($env:ERRORCOLOR)       { $env:ERRORCOLOR       } else { 'Red'     } }
        'Information' { if ($env:INFORMATIONCOLOR) { $env:INFORMATIONCOLOR } else { 'Magenta' } }
        'SubInfo'     { if ($env:SUBINFOCOLOR)     { $env:SUBINFOCOLOR     } else { 'Gray'    } }
        'Other'       { if ($env:DEFAULTCOLOR)     { $env:DEFAULTCOLOR     } else { 'Black'   } }
    }
} # }}}

function Log-Command([switch]$NoNewline, [string]$caller) { # {{{
    if ($caller -ne '') { Write-Host "$caller - " -NoNewline -ForegroundColor $(Get-TypeColor([ContentType]::Command)) }
    foreach ($section in $args) {
        if ($section -is [System.Array]) {
            $content = ([system.Array]$section)[0]
            $color = ([System.Array]$section)[1]
        } else {
            $content = $section
            $color = [ContentType]::Information
        }
        Write-Host "$content" -NoNewline -ForegroundColor $(Get-TypeColor($color))
    }
    if (-not $NoNewline) { Write-Host '' }
} # }}}

# }}}

# System helper functions {{{

function Find([string]$text, [string]$filter) { # {{{
    findstr /sinp /c:$text $(if ($filter) { $filter } else { '*' }) 2> $null 
} # }}}

function VFind([switch]$noignorecase, [switch]$regex, [string]$text) { # {{{
    $flags = '/snp'
    $vimflag = '\V'
    $vimtext = $text
    if (-not $noignorecase) { $flags += 'i' }
    if ($regex) {
        $flags += 'r'
        $vimflag = ''
        $vimtext = $text.Replace('.*', '[^·]*')
    }
    findstr $flags /c:$text "$pwd\*" 2> $null | gvim.exe -s A:\Share\Scripts\vimfind.vim -c "syn match VimfindTarget /$vimflag$vimtext/|hi VimfindTarget guifg=DarkBlue" +0 -
} # }}}

function GVim([switch]$newwindow, [object]$eval) { # {{{
    if ($eval -is [ScriptBlock]) {
        $eval.Invoke() | ForEach-Object {
            Write-Host "Opening $($_.Name)" -ForegroundColor $(Get-TypeColor([ContentType]::Command))
            Gvim -newwindow:$newwindow $_.FullName
        }
    } else {
        $root = $(git rev-parse --show-toplevel 2>$null)
        if ($eval -and $eval.StartsWith('/') -and $root -ne '') {
            $eval = "$root\..$($eval.Replace('/', '\'))"
        }

        $source = $(if ($eval) { $eval } else { '' })
        & nvim-qt.exe $source
    }
} # }}}

function Git-Difftool([string]$ref) { # {{{
    $root = $(git rev-parse --show-toplevel)
    $diffscript = {
        param($ref, $path)
        cd "$((Split-Path -parent $path)[0])"
        & git difftool "$ref" --no-prompt $path
    }
    $jobs = @()
    $(git diff --name-only "$ref") | ForEach-Object {
        $jobs += Start-Job -ScriptBlock $diffscript -ArgumentList $ref, $(Get-FullPath("$root/$_"))
    }

    $jobs | Wait-Job | Out-Null
    $jobs | Remove-Job
} # }}}

function Touch([string]$filename) { # {{{
    $([system.String]::Join(" ", $args)) | Out-File $filename -Encoding ASCII 
} # }}}

function GoTo-Remote([switch]$push, [string]$remote) { # {{{
    if (-not $remote) { $remote = 'origin' }
    $type = if ($push) { 'push' } else { 'fetch' }

    $output = $(git remote -v)
    if (-not $output) {
        return
    }

    $matches = $null
    if ([string]$output -notmatch "$remote\s*(.*)\ \($type\)") {
        $remotes = ''
        $output | Foreach-Object {
            if ([string]$_ -match "([^\s]*).*\ \($type\)") {
                $remotes += ', ' + $matches[1]
            }
        }
        if ($remotes) {
            Write-Output "Unable to locate remote $remote. Remotes found:$($remotes.Substring(1, $remotes.Length - 1))"
        } else {
            Write-Output 'Unable to locate any remotes.'
        }
        return
    }
    $remoteUrl = $matches[1]

    $matches = $null
    if ($remoteUrl -notmatch '(?:[A-Za-z0-9]+(?:::)?@|http(?:s?)\:\/\/)([A-Za-z0-9._\-]+)(?::|/)([A-Za-z0-9_\-\/]+)(?:\.git)?$') {
        Write-Host "Unable to parse url from $remoteUrl"
        return
    }

    $url = "https://$($matches[1].Replace('\', '/'))/$($matches[2].Replace('\', '/'))"
    if ($url -ne $remoteUrl) {
        Write-output "Found $($matches[0]). Opening $url."
    }

    explorer $url
} # }}}

function List-Compact([switch]$copyable) { # {{{
    $dirColor = 'Blue' # Directories are first
    $regexStrings = @(
        @('^\.?[^\.]*$',                                                                    'DarkGray' ), # Untyped files / Dotfiles
        @('^README',                                                                        'DarkGray' ), # Readme files
        @('\.exe$',                                                                         'Green'    ), # Exe files
        @('\.(exe|dll|bat|cmd|sh|py|pl|ps1|psm1|vbs|rb|reg|vim)$',                          'DarkGreen'), # Other executables
        @('\.(xml|java|h|c|cpp|cs|ts|js|html|css|xaml|resx|json|py|rb|jrc)$',               'Yellow'   ), # Source files
        @('\.([^\.]*proj)|(sln|vsdconfig(xml)?)$',                                          'Magenta'  ), # Project files
        @('\.(txt|md|list)$',                                                               'DarkBlue' ), # Text files
        @('\.(txt|doc(x?)|xls(x?)|onenote)$',                                               'DarkBlue' ), # Office files
        @('\.(zip|tar|gz|rar|jar|war)$',                                                    'Yellow'   ), # Archive files
        @('(~)|(\.(bac?k|log)[^\.]*)|(\.(err|wa?rn|ddc|props|targets|config|map|ini|rc))$', 'Gray'     ), # Aux files
        @('.',                                                                              'White'    )  # Catch-all
    )
    $regexOpt = ([Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [Text.RegularExpressions.RegexOptions]::Compiled)
    $regexes = $regexStrings | ForEach-Object {
        New-Object PSObject -Property @{
            Regex=$(New-Object System.Text.RegularExpressions.Regex($_[0], $regexOpt))
            Color=$_[1]
        }
    }

    $sep = ' '
    $rightpad = 3
    $indentStr = if ($copyable) { '' } else { '│ ' }

    $width = $Host.UI.RawUI.BufferSize.Width - $rightpad
    $writeAction = {
        param($str, $color, $counter)
        if ($str -match '\s') {
            $str = '[' + $str + ']'
        }

        if ($($counter + $str.Length + $sep.Length) -gt $width) {
            if ($($counter + $str.Length) -gt $width) {
                Write-Host ''
                $str += $sep
                $counter = 0
            }
        } else {
            $str += $sep
        }

        if ($counter -eq 0) {
            Write-Host $indentStr -NoNewline -ForegroundColor 'White'
            $counter += $indentStr.Length
        }

        Write-Host $str -NoNewline -ForegroundColor $color
        $counter += $str.Length
        return $counter
    }

    $dir = if ($args -and $args[0]) { if ($args[0].Contains('*')) { $args[0] } else { Get-FullPath $args[0] } } else { (pwd) }
    $header = $(if ($copyable) { '─' } else { '┌' }) + '── Contents of '

    $headerWidth = $Host.UI.RawUI.BufferSize.Width - 1
    if (($header.Length + 3) -gt $headerWidth) {
        $pwd = "$(pwd)"
        $header += '...'
        $end = ' ───'
        $end = $end.PadRight($end.Length + $rightpad, ' ')
        $remaining = $headerWidth + 1 - ($header.Length + $end.Length)
        $start = $pwd.Length - ($remaining)
        $header += $pwd.Substring($start, $remaining) + $end
    } else {
        $header = "$header$dir ".PadRight($headerWidth, '─')
    }

    Write-Host $header

    $counter = 0
    $elems = gci $dir
    $dirCount = 0; $fileCount = 0
    $elems | Where-Object { $_.Mode.StartsWith('d') } | Foreach-Object {
        $dirCount++
        $counter = & $writeAction $_.Name $dirColor $counter
    }
    $elems | Where-Object { -not $_.Mode.StartsWith('d') } | Foreach-Object {
        $fileCount++
        foreach ($regex in $regexes) {
            $color = $regex.Color
            if ($_.Name -match $regex.Regex) {
                break
            }
        }

        $counter = & $writeAction $_.Name $color $counter
    }

    if ($counter -ne 0) { Write-Host '' }
    Write-Host ($(if ($copyable) { '─' } else { '└' }) + "── 📂$dirCount ─ 💾$fileCount ").PadRight($headerWidth, '─')
} # }}}

function Get-FullPath([string]$relative) { # {{{
    $path = $relative.Replace('/', '\')
    if (-not $path.StartsWith('\\')) {
        if ($path -match '^[A-Za-z]:') {
            if (-not $path.Contains('\')) {
                $path = $path + '\'
            } else {
                $path = $path
            }
        } else {
            $path = Join-Path (pwd) $path
        }

echo $path
        $path = [IO.Path]::GetFullPath($path)
    }

    return $path
} # }}}

function Notify-Me { # {{{
    $address = ''
    if ($global:NOTIFYMECREDENTIALS) {
        $address = $global:NOTIFYMECREDENTIALS.UserName
    } else {
        Set-Notifyme
        if (-not $global:NOTIFYMECREDENTIALS) {
            # User canceled - exit
            return
        }
    }

    $msg = New-Object Net.Mail.MailMessage
    $msg.From = $address
    $msg.ReplyTo = $address
    $msg.To.Add($address)
    $msg.Subject = 'Ping!'
    if ($args) { $msg.Body = [system.String]::Join(' ', $args) } else { $msg.Body = '' }

    $smtp = new-object Net.Mail.SmtpClient('smtp.office365.com', 587)
    $smtp.EnableSsl = $true
    $smtp.Credentials = $global:NOTIFYMECREDENTIALS.GetNetworkCredential()

    Log-Command 'send' 'Sending request to ' @($address, [ContentType]::Subinfo)
    try {
        $smtp.Send($msg)
        $smtp.Dispose()
        $done = $true
    }
    catch {
        $done = $false
        $global:NOTIFYMECREDENTIALS = $null
        Log-Command 'send' @('Request rejected. Please reenter.', [ContentType]::Error)
        return
    }

    Log-Command 'send' 'Notification sent to ' @($address, [ContentType]::Subinfo)
} # }}}

function Set-Notifyme { # {{{
    Log-Command 'send' 'Please enter your credentials (or press Ctrl-C to abort):'
    if (-not $(Test-Path env:\USERNAME)) {
        $env:USERNAME = $(Read-Host 'Alias')
    }
    $address = "$($env:USERNAME)@microsoft.com"
    $password = Read-Host "Password for $address" -AsSecureString
    $global:NOTIFYMECREDENTIALS = New-Object System.Management.Automation.PSCredential($address, $password)
} # }}}

function Message-Box([switch]$alert, [string]$title, [string]$content) { # {{{
    $iconflag = 0x40
    if ($alert) { $iconflag = 0x30 }
    $(New-Object -ComObject Wscript.Shell).Popup($content, 0, $title, 0x0 + 0x1000 + $iconflag) | Out-Null
} # }}}

function Rename-Substring([switch]$verbose, [string]$from, [string]$to) { # {{{
    ForEach ($file in $(gci -r "*$from*")) {
        if (-not $file.Mode.StartsWith('d')) {
            $source = $file.Fullname
            $destination = "$($file.DirectoryName)\$($file.Name.Replace($from, $to))"
            if ($verbose) { echo "Moving {$source} to {$destination}!" }
            move $source $destination
        }
    }
} # }}}

function Get-SystemColors { # {{{
    foreach ($color in [Enum]::GetValues([System.ConsoleColor])) {
        Write-Host $color -ForegroundColor $color
    }
} # }}}

function Update-Newlines([string]$path, [string]$newline) { # {{{
    if (-not $(Test-Path($path))) { return }
    $file = (gci $path)
    $contents = Get-Content $file
    $sw = [System.IO.StreamWriter]($file.FullName)
    $sw.NewLine = $newline
    ForEach ($line in $contents) { $sw.WriteLine($line) }
    $sw.Flush()
    $sw.Close()
} # }}}

function Make-Link([switch]$hard, [string]$link, [string]$target) { # {{{
    if (Test-Path $link) { Write-Output "Destination [$link] exists!" ; return }
    if (-not (Test-Path $target)) { Write-Output "Target [$target] does not exist!" ; return }

    $flags = ''
    if ($hard) { $flags += ' /H' }
    if ($(gi $target).PSIsContainer) { $flags += ' /D' }

    if ($link -match ' ' -and (-not $link.StartsWith('"'))) { $link = '"' + $link + '"' }
    if ($target -match ' ' -and (-not $target.StartsWith('"'))) { $target = '"' + $target + '"' }

    & cmd.exe /c "mklink$flags $link $target"
} # }}}

function dos2unix([string]$file) { # {{{
    Update-Newlines $file "`n" 
} # }}}
function unix2dos([string]$file) { # {{{
    Update-Newlines $file "`r`n" 
} # }}}

function eofunix([string]$file) { # {{{
    Write-Output ((Get-Content $file -Delimiter [String].Empty) -match "[^`r]`n") 
} # }}}
function eofdos([string]$file) { # {{{
    Write-Output ((Get-Content $file -Delimiter [String].Empty) -match "`r`n") 
} # }}}
function eofboth([string]$file) { # {{{
    Write-Output ($(eofunix $file) -and $(eofdos $file)) 
} # }}}


function Wait-Morning { Sleep($(((Get-Date 9am).AddDays(1) - $(Get-Date)).TotalSeconds)) }

# }}}

# Pipe/lock functions {{{

function Ensure-LockPath { # {{{
    if (-not $env:LOCK) {
        $pwd = "$(pwd)"
        $path = $pwd.Substring(3)
        $path = $pwd.Substring(0, $path.IndexOf('\') + 3)
        $env:LOCK = "$path.lock"
    }
    if (-not $env:Result) {
        $env:Result = "$($env:Lock)-result"
    }
} # }}}

function Get-Lock([switch]$force, [switch]$noprogress, [int]$interval = 10) { # {{{
    Ensure-LockPath
    if (Test-Path $env:LOCK) {
        if ($force) { Clear-Lock -noprogress:$noprogress }

        if (-not ($noprogress -or $force)) { Log-Command -NoNewline 'lock' 'Waiting for {' @($env:LOCK, [ContentType]::SubInfo) '} to clear...' }
        while (Test-Path $env:LOCK) {
            Sleep($interval)
            if (-not $noprogress) { Write-Host '.' -NoNewline -ForegroundColor $(Get-TypeColor([ContentType]::Command)) }
        }
        if (-not $noprogress) { Write-Host '' }
    }

    Touch $env:LOCK
    Log-Command 'lock' 'Locked {' @([string]$env:LOCK, [ContentType]::SubInfo) '} file.'
} # }}}

function Clear-Lock([switch]$noprogress) { # {{{
    Ensure-LockPath
    if (Test-Path $env:LOCK) { Remove-Item $env:LOCK }
    if (-not $noprogress) { Log-Command 'lock' 'Cleared {' @("$($env:LOCK)", [ContentType]::SubInfo) '} file.' }
} # }}}

function Get-Result { # {{{
    Ensure-LockPath
    return $(if (Test-Path $env:Result) { Get-Content $env:Result } else { '' })
} # }}}

function Set-Result([string]$result) { # {{{
    Ensure-LockPath
    if ($result) { $result > $env:RESULT } elseif (Test-Path $env:RESULT) { Remove-Item $env:RESULT }
} # }}}

function Clear-Result { # {{{
    Set-Result ''
    Log-Command 'rslt' 'Cleared {' @($env:RESULT, [ContentType]::SubInfo) '} file.' 
} # }}}

function Pipe([switch]$notifyme, [switch]$popup, [switch]$start, [switch]$end, [switch]$lock) { # {{{
    if ($args.Length -eq 0) {
        Log-Command 'pipe' 'To use: ' @('pipe {command 1} {command 2} {command 3} ...', [ContentType]::Instruction)
        return
    }
    $lock = $lock -or $start -or $end

    if ($notifyme -and -not $global:NOTIFYMECREDENTIALS) { Set-Notifyme }
    if ($start) { Clear-Lock ; Clear-Result }
    if ($lock) { Get-Lock }

    if ($(Get-Result) -ne '') {
        Log-Command 'pipe' @('ERROR OCCURED IN PREVIOUS PIPE', [ContentType]::Error) '. Command piping aborted.'
        if (-not $end) { Log-Command 'pipe' 'Please call pipe with ' @('-start', [ContentType]::Instruction) ', or call ' @('Clear-Result', [ContentType]::Instruction) ' before rerunning pipe.' }

        $error = 'ERROR OCCURRED IN PREVIOUS PIPE. Command piping aborted.'
        if ($notifyme) {
            Notify-Me "pipe - $error"
            Notify-Me "pipe - $(Get-Result)"
        }

        if ($end) { Clear-Result }
        if ($lock) { Clear-Lock }

        if ($popup) { Message-Box -alert 'pipe - ERROR OCCURRED' $error }
        return
    }

    $global:LASTEXITCODE = $null
    $commands = $(if ($args -and ($args[0] -is [System.Array])) { $args[0] } else { $args })
    foreach ($command in $commands) {
        Log-Command 'pipe' @("[$(Get-Location)] ", [ContentType]::Subinfo) 'Executing ' @("{$command}", [ContentType]::Subinfo) ':'

        $Error.Clear()
        Invoke-Command $command

        if ($Error -or $LASTEXITCODE) {
            Log-Command 'pipe' @('ERROR OCCURED', [ContentType]::Error) '. Command piping stopped at ' @("{$command}", [ContentType]::Subinfo) '.'

            $error = "Command piping stopped at {$($command)}. Commands requested: {$([system.String]::Join("} {", $commands))}."
            Set-Result $error
            if ($notifyme) { Notify-Me "pipe - ERROR OCCURRED. $error" }

            if ($end) { Clear-Result }
            if ($lock) { Clear-Lock }

            if ($popup) { Message-Box -alert 'pipe - ERROR OCCURRED' $error }
            return
        }

        Write-Host ''
    }

    Log-Command 'pipe' 'Commands completed: ' @("{$([system.String]::Join("} {", $commands))}", [ContentType]::Subinfo) '.'
    $result = "pipe - Commands completed: {$([system.String]::Join("} {", $commands))}."
    if ($notifyme) { Notify-Me "pipe - Done! $result" }

    if ($end) { Clear-Result }
    if ($lock) { Clear-Lock }

    if ($popup) { Message-Box 'pipe - DONE' $result }
} # }}}

# }}}

# }}}

Set-MyPrompt

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# Custom profile
$CustomProfile = "$env:HOME\.custompsrc.ps1"
if (Test-Path($CustomProfile)) {
  . $CustomProfile
}

# vim: foldmethod=marker foldlevel=1
