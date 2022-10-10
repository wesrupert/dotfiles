oh-my-posh init pwsh --config "$($env:LOCALAPPDATA)\Programs\oh-my-posh\themes\spaceshipfixed.omp.json" | Invoke-Expression

if (Get-Command 'fnm' -ErrorAction 'SilentlyContinue') {
  fnm env --use-on-cd | Out-String | Invoke-Expression
}

# Aliases {{{

function .. { cd .. }
function ... { cd ..\.. }
function .... { cd ..\..\.. }
function ..... { cd ..\..\..\.. }
function ..code { cd ~\Code }

function Toggle-Theme {
  . "$($env:LOCALAPPDATA)\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\windowsTerminal_themeToggler.ps1" *> out-null
}

# }}}

# Options {{{

Set-PSReadLineOption -PredictionSource History -ErrorAction 'SilentlyContinue' *> out-null
Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction 'SilentlyContinue' *> out-null
Set-PSReadLineOption -EditMode Windows -ErrorAction 'SilentlyContinue' *> out-null

# }}}

# Auto Build and Run
# To use:
# - <C-S-b> -> Build
# - <C-S-s> -> Start
# - <C-S-t> -> Test
# - <C-S-w> -> Watch
# {{{
# Inspired by Scott's profile https://gist.github.com/shanselman/25f5550ad186189e0e68916c6d7f44c3

Set-PSReadLineKeyHandler -Key Ctrl+Shift+b `
-BriefDescription BuildCurrentDirectory `
-LongDescription "Build the current directory" `
-ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    if(Test-Path -Path ".\package.json") {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("npm run build")
    }else {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet build")
    }
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key Ctrl+Shift+t `
-BriefDescription BuildCurrentDirectory `
-LongDescription "Build the current directory" `
-ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    if(Test-Path -Path ".\package.json") {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("npm run test")
    }else {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet test")
    }
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key Ctrl+Shift+s `
-BriefDescription StartCurrentDirectory `
-LongDescription "Start the current directory" `
-ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    if(Test-Path -Path ".\package.json") {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("npm start")
    }else {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet run")
    }
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key Ctrl+Shift+w `
-BriefDescription StartCurrentDirectory `
-LongDescription "Watch the current directory" `
-ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    if(Test-Path -Path ".\package.json") {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("npm run watch")
    }else {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet watch")
    }
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

# }}}

# CD Improved
# To use:
# - cd ...       | Transformed into into cd ..\.. (extra dot is an extra level),
# - cd ^         | Transformed into cd <<script i.e. profile>> directory
# - cd \*doc     | Transformed into cd \*\Doc*\
# - cd =         | Transformed into an item from the stack. = is the first each extra = goes one deeper in the stack
# - cd -         | Pops an item from the location stack. 3 or more - will do an extra pop.
#                | Note: -- means "all the rest are a strings", so two levels needs -- --
# - cd ~         | Now supports tab expansion
# - cd ~~        | Tab completes "Special" folders (e.g. MyDocuments, Desktop, ProgramFiles)
# - cd ~~Name\   | Transorms to or tab completes the special folder
# - cd\ cd.. cd~ | Push to the appropriate location
# - cd HK[tab]   | Expand to HKCU: and HKLM: and similarly for other drives.
# {{{
#Taken from https://gist.github.com/jhoneill/47f5151b22a1dabb4ddc79c083162f77

Remove-Item -Path Alias:\cd -ErrorAction SilentlyContinue

class PathTransformAttribute : System.Management.Automation.ArgumentTransformationAttribute  {
  [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
    switch -regex ($InputData) {
      "^=+"        {return ($inputData -replace "^=+", (Get-Location -Stack).ToArray()[$Matches[0].Length -1].Path); break}
      "^\^"        {return ($inputData -replace "^\^", $PSScriptRoot)                              ; break }
      "^\\\*|^/\*" {return ($pwd.path  -replace "^(.*$($InputData.substring(2)).*?)[/\\].*$",'$1') ; break }
      "^\.{3}"     {return ($InputData -replace "(?<=^\.[.\\]*)(?=\.{2,}(\\|$))",  ".\")           ; break}
      "^~~[a-z]+" {try {return ($InputData -replace "~~\w+", ( [System.Environment]::GetFolderPath(($InputData -replace "~~([a-z]+).*$",'$1'))) )} catch {};break}
    }
    return ($InputData)
  }
}

class ValidatePathAttribute :  System.Management.Automation.ValidateArgumentsAttribute {
  [string]$Exemption = "" #"^-+$"
    [boolean]$ContainersOnly = $false
      [int]$MaxItems = -1
        [void] Validate([object] $arguments , [System.Management.Automation.EngineIntrinsics]$EngineIntrinsics) {
          if ($this.Exemption -and $arguments -match $this.Exemption) {return}                    #Exempt some things eg  "-"" or "----""
            elseif ($arguments -match "^(\w+):\\?" -and (Get-PSDrive $Matches[1] -ErrorAction SilentlyContinue) ) {return}    #Allow drives
          else {
            if ($this.ContainersOnly) {$count = (Get-Item -Path $arguments -ErrorAction SilentlyContinue).where({$_.psIscontainer}).count}
            else                      {$count = (Get-Item -Path $arguments -ErrorAction SilentlyContinue).count }
            if ($count -eq 0 -and $this.maxitems -ge 0) {
              throw [System.Management.Automation.ValidationMetadataException]::new("'$arguments' does not exist.")
            }
            elseif ($this.Maxitems -ge 0 -and $count -gt $this.maxitems) {
              throw  [System.Management.Automation.ValidationMetadataException]::new("'$arguments' resolved to multiple $count items. Maximum allowed is $($this.Maxitems)")
            }
          }
          return
        }
}

class PathCompleter : System.Management.Automation.IArgumentCompleter {
  [System.Collections.Generic.IEnumerable[System.Management.Automation.CompletionResult]] CompleteArgument(
      [string]$CommandName, [string]$ParameterName, [string]$WordToComplete,
      [System.Management.Automation.Language.CommandAst]$CommandAst, [System.Collections.IDictionary] $FakeBoundParameters
      )
  {
    $results = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
      $dots    = [regex]"^\.\.(\.*)(\\|$|/)" #find two dots, any more dots (captured), followed by / \ or end of string
      $sep     = [system.io.path]::DirectorySeparatorChar
      $wtc     = ""
      switch -regex ($wordToComplete) {
#.. alone doesn't expand,  expand  .. followed by n dots (and possibly \ or /)  to ..\ n+1 times
        $dots        {$newPath = "..$Sep" * (1 + $dots.Matches($wordToComplete)[0].Groups[1].Length)
          $wtc = $dots.Replace($wordtocomplete,$newPath) ; break }
        "^\^$"       {$wtc = $PSScriptRoot                           ; break }  # ^ [tab] ==> PS profile dir
          "^\.$"       {$wtc = ""                                      ; break }  # . and ~ alone don't expand.
          "^~$"        {$wtc = $env:USERPROFILE                        ; break }
#for 1 = sign tab through the location stack.
        "^=$"        { foreach ($stackPath in (Get-Location -Stack).ToArray().Path) {
          if ($stackpath -match "[ ']") {$stackpath = '"' + $stackPath + '"'}
          $results.Add([System.Management.Automation.CompletionResult]::new($stackPath))
        }
        return $results ; continue
        }
#replace string of = signs with the item that many up the location stack
        "^=+$"       {$wtc = (Get-Location -Stack).ToArray()[$wordToComplete.Length -1].Path  ; continue }
#if path is c:\here\there\everywhere\stuff convert "\*the"  to "c:\here\there"
        "^\\\*|^/\*" {$wtc = $pwd.path -replace "^(.*$($WordToComplete.substring(2)).*?)[/\\].*$",'$1' ; continue }
        "^~~[a-z]+[\\/]" {
          try {$wtc =  [System.Environment]::GetFolderPath(($wordToComplete -replace "~~([a-z]+).*$",'$1')) + ($wordToComplete -replace "~~[a-z]+(.*$)",'$1')  }
          catch {}
          break
        }
        "^~~" {    [enum]::GetNames([System.Environment+SpecialFolder]) |
          Where-Object {$_ -match "^\w+$" -and [System.Environment]::GetFolderPath($_) -and $_ -like "$($wordToComplete.substring(2))*" } |
            Sort-Object |
            ForEach-Object  {$results.Add([System.Management.Automation.CompletionResult]::new("~~$_")) }
          return $results ; continue
        }
        default      {$wtc = $wordToComplete}
      }
    foreach ($result in [System.Management.Automation.CompletionCompleters]::CompleteFilename($wtc) ) {
      if ($result.resultType -eq "ProviderContainer" -or  $CommandName -notin @("cd","dir")) {$results.Add($result)}
    }
    foreach ($result in $Global:ExecutionContext.SessionState.Drive.GetAll().name -like "$wordTocomplete*") {
      $results.Add([System.Management.Automation.CompletionResult]::new("$result`:"))
    }
    return   $results
  }
}

function cd {
  <#
    .ForwardHelpTargetName Microsoft.PowerShell.Management\Push-Location
    .ForwardHelpCategory Cmdlet
#>
    [CmdletBinding(DefaultParameterSetName='Path')]
    param(
        [Parameter(ParameterSetName='Path', Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [PathTransform()]
        [ArgumentCompleter([PathCompleter])]
        [ValidatePath(Exemption="^-+$",ContainersOnly=$true,MaxItems=1)]
        [string]$Path,

        [Parameter(ParameterSetName='LiteralPath', ValueFromPipelineByPropertyName=$true)]
        [Alias('PSPath','LP')]
        [string]$LiteralPath,

        [switch]$PassThru,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [string]$StackName
        )
      process {
        if ($Path -match "^-+$") {foreach ($i in (1..$Path.Length)) {Pop-Location }}
        elseif ($Path -or $LiteralPath)          {Push-Location @PSBoundParameters }
      }
}
Set-Alias -Name "cd-" -Value Pop-Location
Set-Alias -Name "od" -Value Pop-Location
Function cd.. {Push-Location -Path ..}
Function cd\  {Push-Location -Path \ }
Function cd~  {Push-Location -Path ~}

# }}}

# Import local additions {{{

$psAfter = "$PSScriptRoot\Microsoft.PowerShell_profile.after.ps1"
if (Test-Path -Path $psAfter) {
  . $psAfter
}

# }}}

# vim: foldmethod=marker
