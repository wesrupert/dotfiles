# see https://github.com/microsoft/terminal/issues/4066#issuecomment-991775872

# Feature deprecated
# # A Light colorScheme is bound as counterpart to one and only one Dark colorScheme.
# # To configure two colorSchemes as a pair, select one of them as default in dark mode,
# # switch to light mode, select the other as default, then switch back to dark mode;
# # the script will now toggle this pair correctly for any other profile.

param(
  [String] $themeMode, # if not provided, default to the opposite of the mode recorded in the config file
  [String] $configFile # if not provided, default to the one in the same directory where settsings.json is
)

&{
  $WTsettingsDir = Join-Path -Path $env:LocalAppData -ChildPath "\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\"
  $WTsettingsFile = Join-Path -Path $WTsettingsDir -ChildPath "settings.json"
  $WTsettingsTempry = Join-Path -Path $WTsettingsDir -ChildPath "themetoggler.settings.tmp.json"
  $WTsettingsBackup = Join-Path -Path $WTsettingsDir -ChildPath "themetoggler.settings.bak.json"
  $togglerScript = Join-Path -Path $WTsettingsDir -ChildPath "windowsTerminal_themeToggler.ps1"
  $togglerConfigFile = Join-Path -Path $WTsettingsDir -ChildPath "themetoggler.config.json"


  if (-not (Test-Path -Path $WTsettingsFile -PathType Leaf)) {
    Write-Error -Message "Windows Terminal settings file not found. Is Windows Terminal properly installed?" -ErrorAction Stop
  }


  if (-not (Test-Path -Path $togglerScript -PathType Leaf)) {
    Write-Host "Saving this script locally."
    try {
        $null = New-Item -ItemType File -Path $togglerScript -Force -ErrorAction Stop
        $MyInvocation.MyCommand.ScriptContents | Set-Content -Path $togglerScript
        Write-Host "Script locally stored."
    }
    catch {
        throw $_.Exception.Message
    }
  }


  $WTsettingshandle = [System.IO.File]::Open($WTsettingsFile, "open", "readwrite", "read")
  Copy-Item $WTsettingsFile $WTsettingsBackup -Force -ErrorAction Stop # backup settings.json
  Write-Host "settings backed up at $WTsettingsBackup"
  try{
    $WTsettings = Get-Content $WTsettingsfile -Encoding utf8 | ConvertFrom-Json
    $validSchemes = $WTsettings.schemes | ForEach-Object name


    if (-not(Test-Path -Path $togglerConfigFile -PathType Leaf)) {
      Write-Host "Toggler configuration file not found. Generating a default one."
      try {
          $null = New-Item -ItemType File -Path $togglerConfigFile -Force -ErrorAction Stop
          $togglerConfig = [PSCustomObject]@{
            themeMode = "";
            Light = [PSCustomObject]@{"target" = ""};
            Dark  = [PSCustomObject]@{"target" = ""};
          }
          $togglerConfig | ConvertTo-Json | Set-Content -Path $togglerConfigFile
          Write-Host "Default [$togglerConfigFile] generated."
      }
      catch {
          throw $_.Exception.Message
      }
    }
    $togglerConfig = Get-Content $togglerConfigFile -Encoding utf8 | ConvertFrom-Json


    function setProfileTheme {
      param (
        $WTprofile,
        [String] $colorScheme
      )

      if($validSchemes -contains $colorScheme){ # check that the colorScheme is defined in settings.json
        Write-Host "profile $(if ([bool] $WTprofile.PSObject.Properties["guid"]){
          "($($WTprofile.name))"} else {"defaults"}) now using colorScheme `"$colorScheme`""
        $WTprofile.colorScheme = $colorScheme
      } else {
        Write-Warning "In ($WTprofile): colorScheme `"$colorScheme`" is invalid; remains unchanged"
      }
    }


    # $themeMode default values
    if (-not [bool] $themeMode){
      $themeMode = if ([bool] $togglerConfig.themeMode){
        if ($togglerConfig.themeMode -eq "Dark"){
          "Light"
        } else {
          "Dark"
        }
      } elseif ([bool] (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize").AppsUseLightTheme){
        "Light"
      } else {
        "Dark"
      }
    }


    if ($themeMode -eq $togglerConfig.themeMode){
      Write-Host "theme mode already match the desired mode. To force refresh, toggle the mode back and forth."
      exit
    }


    function updateRecord {
      param (
        $colorScheme
      )
      if (-not [bool] $togglerConfig.Light.($colorScheme)){ # a new colorScheme to put in the record
        Write-Host "new colorScheme `"$colorScheme`" registered as a Dark scheme"
        $togglerConfig.Light | Add-Member -MemberType NoteProperty -Name $colorScheme -Value $colorScheme
      } if (-not [bool] $togglerConfig.Dark.($colorScheme)){
        Write-Host "new colorScheme `"$colorScheme`" registered as a Light scheme"
        $togglerConfig.Dark  | Add-Member -MemberType NoteProperty -Name $colorScheme -Value $colorScheme
      }

      if ($themeMode -eq "Dark"){ # update for colorScheme already in the record
        Write-Host "updated pair  [dark] $($togglerConfig.Dark.($colorScheme)) <=> $colorScheme [light]"
        $togglerConfig.Light.($togglerConfig.Dark.($colorScheme)) = $colorScheme
      }
    }


    function toggleProfileTheme {
      param (
        $WTprofile,
        $mode=$themeMode
      )
      if ([bool] $WTprofile.PSObject.Properties["guid"]){
        Write-Host "toggling profile ($($WTprofile.name)) into $mode mode"
      } else {
        Write-Host "toggling profile defaults into $mode mode"
      }
      $prevmode = if ($mode -eq "Dark") {"Light"} else {"Dark"}

      # if (-not [bool] ($WTprofile.PSObject.Properties["guid"])){ # profiles.default
      #   if ($WTprofile.colorScheme -ne $togglerConfig.$prevmode.($togglerConfig.$mode.($colorScheme))){
      #     Write-Host "updating for colorScheme `"$($WTprofile.colorScheme)`""
      #     updateRecord $WTprofile.colorScheme
      #   }
      # }

      # for all profiles, including profiles.default
      if ([bool] $togglerConfig.$mode.($WTprofile.colorScheme)){ # toggle only if the colorScheme is in the record
        setProfileTheme $WTprofile $togglerConfig.$mode.($WTprofile.colorScheme)
      } elseif (( $WTprofile.colorScheme -match "$prevmode$" ) -and # auto toggle for obvious colorSchemes
                (($WTprofile.colorScheme -replace "$prevmode$", "$mode") -in $validSchemes)){
        setProfileTheme $WTprofile ($WTprofile.colorScheme -replace "$prevmode$", "$mode")
      }
    }


    $WTdefault = $WTsettings.profiles.defaults
    if ([bool] $WTdefault.PSObject.Properties["colorScheme"]){
      toggleProfileTheme $WTdefault
    }

    foreach ($WTprofile in $WTsettings.profiles.list) {
        if ([bool] $WTprofile.PSObject.Properties["colorScheme"]){
          toggleProfileTheme $WTprofile
        }
    }

    $WTsettings | ConvertTo-Json -Depth 10 | Set-Content $WTsettingsTempry
    $toggleSuccess = $true
  } catch {
    throw $_.Exception.Message
  } finally {
    $WTsettingshandle.close()
  }

  if($toggleSuccess){
    Copy-Item $WTsettingsTempry $WTsettingsFile -Force -ErrorAction Stop
    Write-Host "settings flushed."
    Remove-Item $WTsettingsTempry

    $togglerConfig.themeMode = $themeMode
    $togglerConfig | ConvertTo-Json | Set-Content -Path $togglerConfigFile
  }
}
