<#
.SYNOPSIS
    User Folder Relocator – safely moves Windows user folders (Documents, Downloads, Pictures, etc.)
    to another drive while updating registry paths (both hives).

.DESCRIPTION
    This script relocates known Windows user folders to a new base path (e.g. D:\Gerhard).
    Features include:
    - Dry-run mode for safe preview
    - Registry updates for known folders (User Shell Folders + Shell Folders)
    - File moves via robocopy
    - Progress display and logging
    - Skip/continue prompts if folders already redirected

.VERSION
    1.2.0

.AUTHOR
    Richard Dvořák (r3dvorak on GitHub)

.LASTUPDATED
    2025-09-09

.LICENSE
    GNU General Public License v3.0
#>

# Mapping of friendly names to registry keys
$folderMap = @{
    "Documents" = "Personal"
    "Music"     = "My Music"
    "Pictures"  = "My Pictures"
    "Downloads" = "{374DE290-123F-4565-9164-39C4925E467B}"
    "Desktop"   = "Desktop"
    "Favorites" = "Favorites"
    "Videos"    = "My Video"
    "Contacts"  = "{56784854-C6CB-462B-8169-88E350ACB882}"
}

# Ask user for base path
$basePath = Read-Host "Enter the new base path (e.g. D:\Gerhard)"

# Log file
$logFile = Join-Path $PSScriptRoot "UserFolderMove.log"

function Write-Log {
    param([string]$message, [string]$color = "White")
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$timestamp  $message"
    Add-Content -Path $logFile -Value $line
    Write-Host $message -ForegroundColor $color
}

Write-Log "=== Starting User Folder Move Script v1.2.0 ==="

# Ensure base path exists
if (-not (Test-Path $basePath)) {
    Write-Log "Base path '$basePath' does not exist." Yellow
    $confirm = Read-Host "Do you want to create it? (Y/N)"
    if ($confirm -match '^[Yy]$') {
        New-Item -ItemType Directory -Path $basePath | Out-Null
        Write-Log "Created $basePath" Green
    }
    else {
        Write-Log "Aborting script. No folders were moved." Red
        exit
    }
}

# Ask for dry-run
$dryRun = Read-Host "Run in dry-run mode (no changes made)? (Y/N)"
$dryRun = $dryRun -match '^[Yy]$'

# Folder selection
Write-Host "`nSelect which folders to move (comma-separated numbers, or press Enter for all):"
$i = 1
$choices = @{}
foreach ($key in $folderMap.Keys) {
    Write-Host "[$i] $key"
    $choices[$i] = $key
    $i++
}
$inputSel = Read-Host "Enter your choice"
if ([string]::IsNullOrWhiteSpace($inputSel)) {
    $selectedFolders = $folderMap.Keys
}
else {
    $indexes = $inputSel -split "," | ForEach-Object { $_.Trim() }
    $selectedFolders = $indexes | ForEach-Object { $choices[[int]$_] }
}

Write-Log "Selected folders: $($selectedFolders -join ', ')"

# Registry hives
$regPathUserShell = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
$regPathShell = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"

$total = $selectedFolders.Count
$count = 0

foreach ($friendly in $selectedFolders) {
    $count++
    $percent = [math]::Round(($count / $total) * 100, 0)
    Write-Progress -Activity "Moving user folders" -Status "$friendly ($count of $total)" -PercentComplete $percent

    $regName = $folderMap[$friendly]
    $newPath = Join-Path $basePath $friendly
    $oldPath = $null

    try {
        $oldPath = (Get-ItemProperty -Path $regPathUserShell -Name $regName).$regName
    }
    catch {
        Write-Log "? Registry key $regName for $friendly not found. Skipping." Yellow
        continue
    }

    if ($oldPath -ieq $newPath) {
        Write-Log "? $friendly already redirected to $newPath" Yellow
        $choice = Read-Host "Skip $friendly? (Y=skip / N=continue anyway)"
        if ($choice -match '^[Yy]$') { continue }
    }

    if ($dryRun) {
        Write-Log "[Dry-Run] Would move $friendly from $oldPath to $newPath" Yellow
        Write-Log "[Dry-Run] Would update registry $regName -> $newPath (both hives)" Yellow
    }
    else {
        Write-Log "Moving $friendly from $oldPath to $newPath" Cyan

        if (-not (Test-Path $newPath)) {
            New-Item -ItemType Directory -Path $newPath | Out-Null
            Write-Log "Created $newPath" Green
        }

        # Update both registry hives
        Set-ItemProperty -Path $regPathUserShell -Name $regName -Value $newPath
        Set-ItemProperty -Path $regPathShell     -Name $regName -Value $newPath
        Write-Log "Updated registry $regName -> $newPath (both hives)"

        # Move files
        if ($oldPath -and (Test-Path $oldPath)) {
            robocopy "$oldPath" "$newPath" /E /MOVE /IS /IT /R:1 /W:1 | Out-Null
            Write-Log "Moved files from $oldPath to $newPath"
        }
        else {
            Write-Log "No source found for $friendly (old path empty)" Yellow
        }
    }
}

Write-Progress -Activity "Moving user folders" -Completed

if (-not $dryRun) {
    Write-Log "Restarting Explorer to apply changes..." Green
    Stop-Process -Name explorer -Force
    Start-Process explorer
}
else {
    Write-Log "Dry-Run finished. No changes were made." Green
}

Write-Log "=== Script Finished v1.2.0 ==="
