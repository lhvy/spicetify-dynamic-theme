# Copyright 2019 khanhas. GPL license.
# Edited from project Denoland install script (https://github.com/denoland/deno_install)
param (
  [string] $version
)

$PSMinVersion = 3

if ($v) {
  $version = $v
}

# Helper functions for pretty terminal output.
function Write-Part ([string] $Text) {
  Write-Host $Text -NoNewline
}

function Write-Emphasized ([string] $Text) {
  Write-Host $Text -NoNewLine -ForegroundColor "Cyan"
}

function Write-Done {
  Write-Host " > " -NoNewline
  Write-Host "OK" -ForegroundColor "Green"
}

if ($PSVersionTable.PSVersion.Major -gt $PSMinVersion) {
  $ErrorActionPreference = "Stop"

  # Enable TLS 1.2 since it is required for connections to GitHub.
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

  $checkSpice = Get-Command spicetify -ErrorAction Silent
  if ($null -eq $checkSpice) {
    Write-Host -ForegroundColor Red "Spicetify not found"
    Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/khanhas/spicetify-cli/master/install.ps1" | Invoke-Expression
  }

  if (-not $version) {
    # Determine latest release via GitHub API.
    $latest_release_uri =
    "https://api.github.com/repos/JulienMaille/spicetify-dynamic-theme/releases/latest"
    Write-Part "DOWNLOADING    "; Write-Emphasized $latest_release_uri
    $latest_release_json = Invoke-WebRequest -Uri $latest_release_uri -UseBasicParsing
    Write-Done

    $version = ($latest_release_json | ConvertFrom-Json).tag_name -replace "v", ""
  }

  # Check ~\spicetify-cli\Themes directory already exists
  $sp_dir = "${HOME}\spicetify-cli\Themes"
  if (-not (Test-Path $sp_dir)) {
    Write-Part "MAKING FOLDER  "; Write-Emphasized $sp_dir
    New-Item -Path $sp_dir -ItemType Directory | Out-Null
    Write-Done
  }

  # Download release.
  $zip_file = "${sp_dir}\${version}.zip"
  $download_uri = "https://github.com/JulienMaille/spicetify-dynamic-theme/archive/refs/tags/${version}.zip"
  Write-Part "DOWNLOADING    "; Write-Emphasized $download_uri
  Invoke-WebRequest -Uri $download_uri -UseBasicParsing -OutFile $zip_file
  Write-Done

  # Extract theme from .zip file.
  Write-Part "EXTRACTING     "; Write-Emphasized $zip_file
  Write-Part " into "; Write-Emphasized ${sp_dir};
  Expand-Archive -Path $zip_file -DestinationPath $sp_dir -Force
  Write-Done

  # Remove .zip file.
  Write-Part "REMOVING       "; Write-Emphasized $zip_file
  Remove-Item -Path $zip_file
  Write-Done

  # Check ~\.spicetify.\Themes directory already exists
  $spicePath = spicetify -c | Split-Path
  $sp_dot_dir = "$spicePath\Themes\DefaultDynamic"
  if (-not (Test-Path $sp_dot_dir)) {
    Write-Part "MAKING FOLDER  "; Write-Emphasized $sp_dot_dir
    New-Item -Path $sp_dot_dir -ItemType Directory | Out-Null
    Write-Done
  }

  # Copy to .spicetify.
  Write-Part "COPYING        "; Write-Emphasized $sp_dot_dir
  Copy-Item -Path "${sp_dir}\spicetify-dynamic-theme-${version}\*" -Destination $sp_dot_dir -Recurse -Force
  Write-Done

  # Installing.
  Write-Part "INSTALLING";
  cd $sp_dot_dir
  Copy-Item default-dynamic.js ..\..\Extensions
  Copy-Item Vibrant.min.js ..\..\Extensions
  spicetify config extensions dribbblish-dynamic.js- extensions dribbblish.js-
  spicetify config extensions default-dynamic.js extensions Vibrant.min.js
  spicetify config current_theme DefaultDynamic
  spicetify config inject_css 1 replace_colors 1 overwrite_assets 1
  Write-Done

  Write-Part "APPLYING";
  $backupVer = $configFile -match "^version"
  $version = ConvertFrom-StringData $backupVer[0]
  if ($version.version.Length -gt 0) {
    spicetify apply
  } else {
    spicetify backup apply
  }
}
else {
  Write-Part "`nYour Powershell version is less than "; Write-Emphasized "$PSMinVersion";
  Write-Part "`nPlease, update your Powershell downloading the "; Write-Emphasized "'Windows Management Framework'"; Write-Part " greater than "; Write-Emphasized "$PSMinVersion"
}
