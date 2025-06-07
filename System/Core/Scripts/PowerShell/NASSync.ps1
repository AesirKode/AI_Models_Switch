# 🔄 Enhanced NAS Synchronization System v2.0
# File: D:\AI_Models\System\Core\Scripts\PowerShell\NASSync.ps1
# Features: Professional NAS sync with real-time monitoring and Game Console integration

param(
    [string]$Action = "menu",
    [string]$Direction = "both",
    [string]$NASPath = "",
    [switch]$DryRun,
    [switch]$Verbose,
    [switch]$Force,
    [switch]$QuickMode,
    [string]$Filter = "",
    [int]$Threads = 8
)

# =============================================================================
# SYSTEM INITIALIZATION & CONFIGURATION
# =============================================================================

# Import system configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ConfigPath = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "Configuration\system.json"
$AI_ModelsPath = "D:\AI_Models"

if (Test-Path $ConfigPath) {
    try {
        $Config = Get-Content $ConfigPath | ConvertFrom-Json
        $AI_ModelsPath = $Config.paths.base
        $DefaultNASPath = $env:AI_MODELS_NAS_PATH ?? "\\10.0.0.252\Models\AI_Models"
    }
    catch {
        Write-Warning "Could not load configuration file: $ConfigPath"
        $DefaultNASPath = "\\10.0.0.252\Models\AI_Models"
    }
}
else {
    $DefaultNASPath = "\\10.0.0.252\Models\AI_Models"
}

# Use provided NAS path or default
if (-not $NASPath) {
    $NASPath = $DefaultNASPath
}

# Create logs directory
$LogPath = "$AI_ModelsPath\System\Core\Logs\Sync"
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

# Game Console Style Colors (avoiding trademark issues!)
$SyncTheme = @{
    Primary    = "Cyan"
    Success    = "Green" 
    Warning    = "Yellow"
    Error      = "Red"
    Info       = "White"
    Accent     = "Magenta"
    Highlight  = "Blue"
    Subtitle   = "DarkGray"
    GameBlue   = "Blue"
    GameRed    = "Red"
    GameYellow = "Yellow"
}

# =============================================================================
# ADVANCED NAS SYNC FUNCTIONS
# =============================================================================

function Show-SyncHeader {
    param([string]$Title, [string]$Subtitle = "")
    
    Clear-Host
    $headerWidth = 78
    $border = "═" * $headerWidth
    
    Write-Host "╔$border╗" -ForegroundColor $SyncTheme.Primary
    Write-Host "║" -NoNewline -ForegroundColor $SyncTheme.Primary
    Write-Host (" " * ([math]::Floor(($headerWidth - $Title.Length) / 2))) -NoNewline
    Write-Host $Title -NoNewline -ForegroundColor $SyncTheme.Highlight
    Write-Host (" " * ([math]::Ceiling(($headerWidth - $Title.Length) / 2))) -NoNewline
    Write-Host "║" -ForegroundColor $SyncTheme.Primary
    
    if ($Subtitle) {
        Write-Host "║" -NoNewline -ForegroundColor $SyncTheme.Primary
        Write-Host (" " * ([math]::Floor(($headerWidth - $Subtitle.Length) / 2))) -NoNewline
        Write-Host $Subtitle -NoNewline -ForegroundColor $SyncTheme.Subtitle
        Write-Host (" " * ([math]::Ceiling(($headerWidth - $Subtitle.Length) / 2))) -NoNewline
        Write-Host "║" -ForegroundColor $SyncTheme.Primary
    }
    
    Write-Host "╚$border╝" -ForegroundColor $SyncTheme.Primary
}

function Test-NASConnection {
    param([string]$Path, [switch]$Silent)
    
    if (-not $Silent) {
        Write-Host "`n🔍 Testing NAS connection..." -ForegroundColor $SyncTheme.Info
        Write-Host "   Target: $Path" -ForegroundColor $SyncTheme.Subtitle
    }
    
    try {
        if (Test-Path $Path -ErrorAction Stop) {
            # Test write access
            $testFile = Join-Path $Path ".sync_test_$(Get-Date -Format 'yyyyMMddHHmmss')"
            try {
                "test" | Out-File -FilePath $testFile -ErrorAction Stop
                Remove-Item $testFile -Force -ErrorAction SilentlyContinue
                
                if (-not $Silent) {
                    Write-Host "   ✅ Connection successful with write access" -ForegroundColor $SyncTheme.Success
                }
                return @{ Connected = $true; Writable = $true; Error = $null }
            }
            catch {
                if (-not $Silent) {
                    Write-Host "   ⚠️ Connected but read-only access" -ForegroundColor $SyncTheme.Warning
                }
                return @{ Connected = $true; Writable = $false; Error = "Read-only access" }
            }
        }
        else {
            if (-not $Silent) {
                Write-Host "   ❌ Path not accessible" -ForegroundColor $SyncTheme.Error
            }
            return @{ Connected = $false; Writable = $false; Error = "Path not accessible" }
        }
    }
    catch {
        if (-not $Silent) {
            Write-Host "   ❌ Connection failed: $($_.Exception.Message)" -ForegroundColor $SyncTheme.Error
        }
        return @{ Connected = $false; Writable = $false; Error = $_.Exception.Message }
    }
}

function Get-SyncStatistics {
    param([string]$LocalPath, [string]$RemotePath)
    
    $stats = @{
        LocalFiles         = 0
        LocalSize          = 0
        RemoteFiles        = 0
        RemoteSize         = 0
        LocalDirs          = 0
        RemoteDirs         = 0
        LastLocalModified  = $null
        LastRemoteModified = $null
    }
    
    try {
        # Local statistics
        if (Test-Path $LocalPath) {
            $localItems = Get-ChildItem $LocalPath -Recurse -ErrorAction SilentlyContinue
            $localFiles = $localItems | Where-Object { -not $_.PSIsContainer }
            $localDirs = $localItems | Where-Object { $_.PSIsContainer }
            
            $stats.LocalFiles = $localFiles.Count
            $stats.LocalDirs = $localDirs.Count
            $stats.LocalSize = ($localFiles | Measure-Object -Property Length -Sum).Sum
            $stats.LastLocalModified = ($localFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
        }
        
        # Remote statistics (if accessible)
        $nasTest = Test-NASConnection -Path $RemotePath -Silent
        if ($nasTest.Connected) {
            $remoteItems = Get-ChildItem $RemotePath -Recurse -ErrorAction SilentlyContinue
            $remoteFiles = $remoteItems | Where-Object { -not $_.PSIsContainer }
            $remoteDirs = $remoteItems | Where-Object { $_.PSIsContainer }
            
            $stats.RemoteFiles = $remoteFiles.Count
            $stats.RemoteDirs = $remoteDirs.Count
            $stats.RemoteSize = ($remoteFiles | Measure-Object -Property Length -Sum).Sum
            $stats.LastRemoteModified = ($remoteFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
        }
    }
    catch {
        Write-Verbose "Error calculating sync statistics: $($_.Exception.Message)"
    }
    
    return $stats
}

function Show-SyncMainMenu {
    Show-SyncHeader "🔄 NAS SYNCHRONIZATION CENTER" "Professional Network Storage Management"
    
    # Show current configuration
    Write-Host "`n📊 Current Configuration:" -ForegroundColor $SyncTheme.Primary
    Write-Host "   🏠 Local Path: $AI_ModelsPath" -ForegroundColor $SyncTheme.Info
    Write-Host "   🌐 NAS Path: $NASPath" -ForegroundColor $SyncTheme.Info
    Write-Host "   🕐 Current Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $SyncTheme.Subtitle
    
    # Test connections and show status
    Write-Host "`n🔍 Connection Status:" -ForegroundColor $SyncTheme.Primary
    
    # Local status
    if (Test-Path $AI_ModelsPath) {
        Write-Host "   ✅ Local: Ready" -ForegroundColor $SyncTheme.Success
    }
    else {
        Write-Host "   ❌ Local: Not accessible" -ForegroundColor $SyncTheme.Error
    }
    
    # NAS status
    $nasStatus = Test-NASConnection -Path $NASPath -Silent
    if ($nasStatus.Connected) {
        $accessType = if ($nasStatus.Writable) { "Read/Write" } else { "Read-Only" }
        Write-Host "   ✅ NAS: Connected ($accessType)" -ForegroundColor $SyncTheme.Success
    }
    else {
        Write-Host "   ❌ NAS: $($nasStatus.Error)" -ForegroundColor $SyncTheme.Error
    }
    
    # Show statistics if both are accessible
    if ((Test-Path $AI_ModelsPath) -and $nasStatus.Connected) {
        Write-Host "`n📈 Storage Overview:" -ForegroundColor $SyncTheme.Primary
        $stats = Get-SyncStatistics -LocalPath $AI_ModelsPath -RemotePath $NASPath
        
        Write-Host "   📁 Local: $($stats.LocalFiles) files, $([math]::Round($stats.LocalSize / 1GB, 2)) GB" -ForegroundColor $SyncTheme.Info
        Write-Host "   🌐 NAS: $($stats.RemoteFiles) files, $([math]::Round($stats.RemoteSize / 1GB, 2)) GB" -ForegroundColor $SyncTheme.Info
        
        if ($stats.LastLocalModified) {
            Write-Host "   🕐 Last Local Change: $($stats.LastLocalModified.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor $SyncTheme.Subtitle
        }
        if ($stats.LastRemoteModified) {
            Write-Host "   🕐 Last NAS Change: $($stats.LastRemoteModified.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor $SyncTheme.Subtitle
        }
    }
    
    Write-Host "`n🎯 SYNCHRONIZATION OPTIONS:" -ForegroundColor $SyncTheme.Primary
    Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor $SyncTheme.Accent
    
    # Sync Operations
    Write-Host "`n🔄 SYNC OPERATIONS:" -ForegroundColor $SyncTheme.Highlight
    Write-Host "  1. ⬆️  Upload to NAS (Local → NAS)" -ForegroundColor $SyncTheme.Info
    Write-Host "  2. ⬇️  Download from NAS (NAS → Local)" -ForegroundColor $SyncTheme.Info
    Write-Host "  3. 🔄 Two-Way Sync (Bidirectional)" -ForegroundColor $SyncTheme.Info
    Write-Host "  4. ⚡ Quick Sync (Recent changes only)" -ForegroundColor $SyncTheme.Info
    Write-Host "  5. 🔍 Compare & Preview" -ForegroundColor $SyncTheme.Info
    
    # Advanced Operations
    Write-Host "`n🛠️  ADVANCED OPTIONS:" -ForegroundColor $SyncTheme.Highlight
    Write-Host "  6. ⚙️  Configure NAS Settings" -ForegroundColor $SyncTheme.Info
    Write-Host "  7. 📊 Detailed Sync Report" -ForegroundColor $SyncTheme.Info
    Write-Host "  8. 🧹 Clean Sync Logs" -ForegroundColor $SyncTheme.Info
    Write-Host "  9. 🔧 Test & Repair Connection" -ForegroundColor $SyncTheme.Info
    
    # Quick Actions (Game Console Style)
    Write-Host "`n🎮 QUICK ACTIONS:" -ForegroundColor $SyncTheme.GameBlue
    Write-Host "  q. 🏠 Return to Main Menu" -ForegroundColor $SyncTheme.Info
    Write-Host "  x. ❌ Exit Sync Center" -ForegroundColor $SyncTheme.Info
    
    Write-Host "`n═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor $SyncTheme.Accent
    $choice = Read-Host "Select sync operation"
    
    Execute-SyncChoice $choice
}

function Execute-SyncChoice {
    param([string]$Choice)
    
    switch ($Choice.ToLower()) {
        "1" { Start-SyncOperation -Direction "upload" }
        "2" { Start-SyncOperation -Direction "download" }
        "3" { Start-SyncOperation -Direction "bidirectional" }
        "4" { Start-SyncOperation -Direction "quick" }
        "5" { Show-SyncPreview }
        "6" { Configure-NASSettings }
        "7" { Show-DetailedReport }
        "8" { Clear-SyncLogs }
        "9" { Test-RepairConnection }
        "q" { 
            Write-Host "`n🏠 Returning to Main Menu..." -ForegroundColor $SyncTheme.Success
            return "main_menu"
        }
        "x" { 
            Write-Host "`n👋 Exiting Sync Center..." -ForegroundColor $SyncTheme.Success
            return "exit"
        }
        default { 
            Write-Host "`n❌ Invalid choice: $Choice" -ForegroundColor $SyncTheme.Error
            Start-Sleep 2
            Show-SyncMainMenu
        }
    }
}

function Start-SyncOperation {
    param([string]$Direction)
    
    Show-SyncHeader "🔄 SYNC OPERATION" "Professional Network Storage Synchronization"
    
    # Verify connections before starting
    Write-Host "`n🔍 Pre-sync validation..." -ForegroundColor $SyncTheme.Info
    
    if (-not (Test-Path $AI_ModelsPath)) {
        Write-Host "❌ Local path not accessible: $AI_ModelsPath" -ForegroundColor $SyncTheme.Error
        Read-Host "Press Enter to continue"
        Show-SyncMainMenu
        return
    }
    
    $nasStatus = Test-NASConnection -Path $NASPath
    if (-not $nasStatus.Connected) {
        Write-Host "❌ NAS not accessible: $($nasStatus.Error)" -ForegroundColor $SyncTheme.Error
        Read-Host "Press Enter to continue"
        Show-SyncMainMenu
        return
    }
    
    if ($Direction -in @("upload", "bidirectional") -and -not $nasStatus.Writable) {
        Write-Host "❌ NAS is read-only, cannot upload" -ForegroundColor $SyncTheme.Error
        Read-Host "Press Enter to continue"
        Show-SyncMainMenu
        return
    }
    
    Write-Host "✅ All connections verified" -ForegroundColor $SyncTheme.Success
    
    # Show operation details
    Write-Host "`n📋 Sync Operation Details:" -ForegroundColor $SyncTheme.Primary
    Write-Host "   Direction: " -NoNewline -ForegroundColor $SyncTheme.Info
    
    switch ($Direction) {
        "upload" { 
            Write-Host "⬆️  Upload (Local → NAS)" -ForegroundColor $SyncTheme.GameBlue
            $robocopyDirection = @($AI_ModelsPath, $NASPath)
        }
        "download" { 
            Write-Host "⬇️  Download (NAS → Local)" -ForegroundColor $SyncTheme.GameRed
            $robocopyDirection = @($NASPath, $AI_ModelsPath)
        }
        "bidirectional" { 
            Write-Host "🔄 Two-Way Sync" -ForegroundColor $SyncTheme.GameYellow
            Write-Host "   ⚠️  Note: Will perform upload first, then download" -ForegroundColor $SyncTheme.Warning
        }
        "quick" { 
            Write-Host "⚡ Quick Sync (Recent changes)" -ForegroundColor $SyncTheme.Accent
            $robocopyDirection = @($AI_ModelsPath, $NASPath)
        }
    }
    
    Write-Host "   Threads: $Threads" -ForegroundColor $SyncTheme.Info
    Write-Host "   Log Path: $LogPath" -ForegroundColor $SyncTheme.Subtitle
    
    if ($DryRun) {
        Write-Host "   🔍 DRY RUN MODE - No actual changes will be made" -ForegroundColor $SyncTheme.Warning
    }
    
    # Confirm operation
    Write-Host "`n⚠️  Ready to start sync operation." -ForegroundColor $SyncTheme.Warning
    $confirm = Read-Host "Continue? (y/N)"
    
    if ($confirm.ToLower() -ne "y") {
        Write-Host "❌ Operation cancelled" -ForegroundColor $SyncTheme.Error
        Start-Sleep 2
        Show-SyncMainMenu
        return
    }
    
    # Execute sync based on direction
    switch ($Direction) {
        "upload" { Sync-ToNAS }
        "download" { Sync-FromNAS }
        "bidirectional" { 
            Write-Host "`n🔄 Starting bidirectional sync..." -ForegroundColor $SyncTheme.Primary
            Sync-ToNAS
            Write-Host "`n⏳ Pausing between sync directions..." -ForegroundColor $SyncTheme.Info
            Start-Sleep 3
            Sync-FromNAS
        }
        "quick" { Sync-Quick }
    }
    
    Write-Host "`n" -NoNewline
    Read-Host "Press Enter to return to sync menu"
    Show-SyncMainMenu
}

function Sync-ToNAS {
    Write-Host "`n⬆️  UPLOADING TO NAS..." -ForegroundColor $SyncTheme.GameBlue
    Write-Host "   Source: $AI_ModelsPath" -ForegroundColor $SyncTheme.Info
    Write-Host "   Destination: $NASPath" -ForegroundColor $SyncTheme.Info
    
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $logFile = Join-Path $LogPath "sync_to_nas_$timestamp.log"
    
    $robocopyArgs = @(
        $AI_ModelsPath,
        $NASPath,
        "/MIR", # Mirror directory tree
        "/R:3", # Retry 3 times on failed copies
        "/W:10", # Wait 10 seconds between retries
        "/MT:$Threads", # Multi-threaded copy
        "/XD", "Cache", # Exclude cache directories
        "/XD", "System\Core\Logs", # Exclude log directories
        "/XD", "Workflows\Downloads\Active", # Exclude active downloads
        "/XF", "*.tmp", # Exclude temporary files
        "/XF", "*.temp", # Exclude temp files
        "/XF", "*.downloading", # Exclude partial downloads
        "/LOG:$logFile", # Log to file
        "/TEE", # Output to console and log
        "/NP", # No progress percentage
        "/NDL", # No directory list
        "/NFL"                     # No file list (unless error)
    )
    
    if ($DryRun) { 
        $robocopyArgs += "/L"      # List only (dry run)
        Write-Host "   🔍 DRY RUN MODE ACTIVE" -ForegroundColor $SyncTheme.Warning
    }
    if ($Verbose) { 
        $robocopyArgs += "/V"      # Verbose output
    }
    
    Write-Host "`n🚀 Starting upload..." -ForegroundColor $SyncTheme.Success
    Write-Host "   Log file: $logFile" -ForegroundColor $SyncTheme.Subtitle
    
    try {
        $startTime = Get-Date
        robocopy @robocopyArgs
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        # Robocopy exit codes interpretation
        $exitCode = $LASTEXITCODE
        switch ($exitCode) {
            0 { Write-Host "`n✅ Sync completed - No files copied" -ForegroundColor $SyncTheme.Info }
            1 { Write-Host "`n✅ Sync completed successfully" -ForegroundColor $SyncTheme.Success }
            2 { Write-Host "`n✅ Sync completed - Some extra files/directories detected" -ForegroundColor $SyncTheme.Info }
            3 { Write-Host "`n✅ Sync completed successfully with extras" -ForegroundColor $SyncTheme.Success }
            { $_ -ge 4 } { Write-Host "`n⚠️ Sync completed with warnings (Exit code: $exitCode)" -ForegroundColor $SyncTheme.Warning }
            { $_ -ge 8 } { Write-Host "`n❌ Sync failed with errors (Exit code: $exitCode)" -ForegroundColor $SyncTheme.Error }
        }
        
        Write-Host "   Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor $SyncTheme.Subtitle
        
    }
    catch {
        Write-Host "`n❌ Upload failed: $($_.Exception.Message)" -ForegroundColor $SyncTheme.Error
    }
}

function Sync-FromNAS {
    Write-Host "`n⬇️  DOWNLOADING FROM NAS..." -ForegroundColor $SyncTheme.GameRed
    Write-Host "   Source: $NASPath" -ForegroundColor $SyncTheme.Info
    Write-Host "   Destination: $AI_ModelsPath" -ForegroundColor $SyncTheme.Info
    
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $logFile = Join-Path $LogPath "sync_from_nas_$timestamp.log"
    
    $robocopyArgs = @(
        $NASPath,
        $AI_ModelsPath,
        "/MIR", # Mirror directory tree
        "/R:3", # Retry 3 times on failed copies
        "/W:10", # Wait 10 seconds between retries
        "/MT:$Threads", # Multi-threaded copy
        "/XD", "Cache", # Exclude cache directories
        "/XD", "System\Core\Logs", # Exclude log directories
        "/XD", "Workflows\Downloads\Active", # Exclude active downloads
        "/XF", "*.tmp", # Exclude temporary files
        "/XF", "*.temp", # Exclude temp files
        "/XF", "*.downloading", # Exclude partial downloads
        "/LOG:$logFile", # Log to file
        "/TEE", # Output to console and log
        "/NP", # No progress percentage
        "/NDL", # No directory list
        "/NFL"                     # No file list (unless error)
    )
    
    if ($DryRun) { 
        $robocopyArgs += "/L"      # List only (dry run)
        Write-Host "   🔍 DRY RUN MODE ACTIVE" -ForegroundColor $SyncTheme.Warning
    }
    if ($Verbose) { 
        $robocopyArgs += "/V"      # Verbose output
    }
    
    Write-Host "`n🚀 Starting download..." -ForegroundColor $SyncTheme.Success
    Write-Host "   Log file: $logFile" -ForegroundColor $SyncTheme.Subtitle
    
    try {
        $startTime = Get-Date
        robocopy @robocopyArgs
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        # Robocopy exit codes interpretation
        $exitCode = $LASTEXITCODE
        switch ($exitCode) {
            0 { Write-Host "`n✅ Sync completed - No files copied" -ForegroundColor $SyncTheme.Info }
            1 { Write-Host "`n✅ Sync completed successfully" -ForegroundColor $SyncTheme.Success }
            2 { Write-Host "`n✅ Sync completed - Some extra files/directories detected" -ForegroundColor $SyncTheme.Info }
            3 { Write-Host "`n✅ Sync completed successfully with extras" -ForegroundColor $SyncTheme.Success }
            { $_ -ge 4 } { Write-Host "`n⚠️ Sync completed with warnings (Exit code: $exitCode)" -ForegroundColor $SyncTheme.Warning }
            { $_ -ge 8 } { Write-Host "`n❌ Sync failed with errors (Exit code: $exitCode)" -ForegroundColor $SyncTheme.Error }
        }
        
        Write-Host "   Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor $SyncTheme.Subtitle
        
    }
    catch {
        Write-Host "`n❌ Download failed: $($_.Exception.Message)" -ForegroundColor $SyncTheme.Error
    }
}

function Sync-Quick {
    Write-Host "`n⚡ QUICK SYNC (RECENT CHANGES)..." -ForegroundColor $SyncTheme.Accent
    Write-Host "   Only syncing files modified in the last 24 hours" -ForegroundColor $SyncTheme.Info
    
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $logFile = Join-Path $LogPath "sync_quick_$timestamp.log"
    
    # Get yesterday's date for MAXAGE parameter
    $yesterday = (Get-Date).AddDays(-1).ToString("yyyyMMdd")
    
    $robocopyArgs = @(
        $AI_ModelsPath,
        $NASPath,
        "/E", # Copy subdirectories including empty ones
        "/MAXAGE:$yesterday", # Only files newer than yesterday
        "/R:3", # Retry 3 times on failed copies
        "/W:10", # Wait 10 seconds between retries
        "/MT:$Threads", # Multi-threaded copy
        "/XD", "Cache", # Exclude cache directories
        "/XD", "System\Core\Logs", # Exclude log directories
        "/XF", "*.tmp", # Exclude temporary files
        "/XF", "*.temp", # Exclude temp files
        "/LOG:$logFile", # Log to file
        "/TEE", # Output to console and log
        "/NP", # No progress percentage
        "/NDL"                     # No directory list
    )
    
    if ($DryRun) { 
        $robocopyArgs += "/L"      # List only (dry run)
        Write-Host "   🔍 DRY RUN MODE ACTIVE" -ForegroundColor $SyncTheme.Warning
    }
    
    Write-Host "`n🚀 Starting quick sync..." -ForegroundColor $SyncTheme.Success
    Write-Host "   Log file: $logFile" -ForegroundColor $SyncTheme.Subtitle
    
    try {
        $startTime = Get-Date
        robocopy @robocopyArgs
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-Host "`n✅ Quick sync completed" -ForegroundColor $SyncTheme.Success
        Write-Host "   Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor $SyncTheme.Subtitle
        
    }
    catch {
        Write-Host "`n❌ Quick sync failed: $($_.Exception.Message)" -ForegroundColor $SyncTheme.Error
    }
}

function Show-SyncPreview {
    Show-SyncHeader "🔍 SYNC PREVIEW" "Compare local and NAS contents"
    
    Write-Host "`n📊 Analyzing differences..." -ForegroundColor $SyncTheme.Info
    
    $stats = Get-SyncStatistics -LocalPath $AI_ModelsPath -RemotePath $NASPath
    
    Write-Host "`n📈 Storage Comparison:" -ForegroundColor $SyncTheme.Primary
    Write-Host "   📁 Local Files: $($stats.LocalFiles) ($([math]::Round($stats.LocalSize / 1GB, 2)) GB)" -ForegroundColor $SyncTheme.Info
    Write-Host "   🌐 NAS Files: $($stats.RemoteFiles) ($([math]::Round($stats.RemoteSize / 1GB, 2)) GB)" -ForegroundColor $SyncTheme.Info
    
    $sizeDiff = $stats.LocalSize - $stats.RemoteSize
    $fileDiff = $stats.LocalFiles - $stats.RemoteFiles
    
    Write-Host "`n🔄 Differences:" -ForegroundColor $SyncTheme.Primary
    if ($fileDiff -gt 0) {
        Write-Host "   📄 Local has $fileDiff more files" -ForegroundColor $SyncTheme.GameBlue
    }
    elseif ($fileDiff -lt 0) {
        Write-Host "   📄 NAS has $([math]::Abs($fileDiff)) more files" -ForegroundColor $SyncTheme.GameRed
    }
    else {
        Write-Host "   📄 Same number of files" -ForegroundColor $SyncTheme.Success
    }
    
    if ($sizeDiff -gt 0) {
        Write-Host "   💾 Local is $([math]::Round($sizeDiff / 1GB, 2)) GB larger" -ForegroundColor $SyncTheme.GameBlue
    }
    elseif ($sizeDiff -lt 0) {
        Write-Host "   💾 NAS is $([math]::Round([math]::Abs($sizeDiff) / 1GB, 2)) GB larger" -ForegroundColor $SyncTheme.GameRed
    }
    else {
        Write-Host "   💾 Same total size" -ForegroundColor $SyncTheme.Success
    }
    
    Write-Host "`n🕐 Last Modified:" -ForegroundColor $SyncTheme.Primary
    if ($stats.LastLocalModified) {
        Write-Host "   📁 Local: $($stats.LastLocalModified.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor $SyncTheme.Info
    }
    if ($stats.LastRemoteModified) {
        Write-Host "   🌐 NAS: $($stats.LastRemoteModified.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor $SyncTheme.Info
    }
    
    Write-Host "`n" -NoNewline
    Read-Host "Press Enter to return to sync menu"
    Show-SyncMainMenu
}

function Configure-NASSettings {
    Show-SyncHeader "⚙️  NAS CONFIGURATION" "Network Storage Settings"
    
    Write-Host "`n🔧 Current Settings:" -ForegroundColor $SyncTheme.Primary
    Write-Host "   🌐 NAS Path: $NASPath" -ForegroundColor $SyncTheme.Info
    Write-Host "   🧵 Threads: $Threads" -ForegroundColor $SyncTheme.Info
    Write-Host "   📁 Local Path: $AI_ModelsPath" -ForegroundColor $SyncTheme.Info
    
    Write-Host "`n⚙️  Configuration Options:" -ForegroundColor $SyncTheme.Primary
    Write-Host "  1. 🌐 Change NAS Path" -ForegroundColor $SyncTheme.Info
    Write-Host "  2. 🧵 Adjust Thread Count" -ForegroundColor $SyncTheme.Info
    Write-Host "  3. 🔍 Test Current Settings" -ForegroundColor $SyncTheme.Info
    Write-Host "  4. 💾 Save Configuration" -ForegroundColor $SyncTheme.Info
    Write-Host "  0. 🔙 Return to Sync Menu" -ForegroundColor $SyncTheme.Info
    
    $choice = Read-Host "`nSelect configuration option"
    
    switch ($choice) {
        "1" {
            $newPath = Read-Host "Enter new NAS path"
            if ($newPath) {
                $NASPath = $newPath
                Write-Host "✅ NAS path updated to: $NASPath" -ForegroundColor $SyncTheme.Success
            }
        }
        "2" {
            $newThreads = Read-Host "Enter number of threads (1-32)"
            if ($newThreads -match '^\d+$' -and [int]$newThreads -ge 1 -and [int]$newThreads -le 32) {
                $Threads = [int]$newThreads
                Write-Host "✅ Thread count updated to: $Threads" -ForegroundColor $SyncTheme.Success
            }
            else {
                Write-Host "❌ Invalid thread count" -ForegroundColor $SyncTheme.Error
            }
        }
        "3" {
            Test-NASConnection -Path $NASPath
        }
        "4" {
            # Save to environment variable
            [Environment]::SetEnvironmentVariable("AI_MODELS_NAS_PATH", $NASPath, "User")
            Write-Host "✅ Configuration saved" -ForegroundColor $SyncTheme.Success
        }
        "0" {
            Show-SyncMainMenu
            return
        }
    }
    
    Start-Sleep 2
    Configure-NASSettings
}

function Show-DetailedReport {
    Show-SyncHeader "📊 DETAILED SYNC REPORT" "Comprehensive synchronization analysis"
    
    Write-Host "`n📋 Generating detailed report..." -ForegroundColor $SyncTheme.Info
    
    # Get recent log files
    $recentLogs = Get-ChildItem $LogPath -Filter "*.log" -ErrorAction SilentlyContinue | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 5
    
    if ($recentLogs.Count -eq 0) {
        Write-Host "📭 No sync logs found" -ForegroundColor $SyncTheme.Warning
    }
    else {
        Write-Host "`n📄 Recent Sync Operations:" -ForegroundColor $SyncTheme.Primary
        foreach ($log in $recentLogs) {
            $logType = if ($log.Name -match "to_nas") { "⬆️  Upload" }
            elseif ($log.Name -match "from_nas") { "⬇️  Download" }
            elseif ($log.Name -match "quick") { "⚡ Quick" }
            else { "🔄 Sync" }
            
            Write-Host "   $logType - $($log.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')) - $($log.Name)" -ForegroundColor $SyncTheme.Info
        }
        
        Write-Host "`n📖 View log details? (Enter log number 1-$($recentLogs.Count), or 0 to skip)" -ForegroundColor $SyncTheme.Accent
        $choice = Read-Host "Choice"
        
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $recentLogs.Count) {
            $selectedLog = $recentLogs[[int]$choice - 1]
            Write-Host "`n📋 Log: $($selectedLog.Name)" -ForegroundColor $SyncTheme.Primary
            Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor $SyncTheme.Accent
            
            # Show last 20 lines of log
            $logContent = Get-Content $selectedLog.FullName -Tail 20 -ErrorAction SilentlyContinue
            foreach ($line in $logContent) {
                Write-Host "   $line" -ForegroundColor $SyncTheme.Subtitle
            }
        }
    }
    
    Write-Host "`n" -NoNewline
    Read-Host "Press Enter to return to sync menu"
    Show-SyncMainMenu
}

function Clear-SyncLogs {
    Show-SyncHeader "🧹 CLEAN SYNC LOGS" "Log file maintenance"
    
    $logFiles = Get-ChildItem $LogPath -Filter "*.log" -ErrorAction SilentlyContinue
    
    if ($logFiles.Count -eq 0) {
        Write-Host "`n📭 No log files found" -ForegroundColor $SyncTheme.Info
    }
    else {
        Write-Host "`n📄 Found $($logFiles.Count) log files" -ForegroundColor $SyncTheme.Info
        $totalSize = ($logFiles | Measure-Object -Property Length -Sum).Sum
        Write-Host "   Total size: $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor $SyncTheme.Subtitle
        
        $confirm = Read-Host "`n⚠️  Delete all log files? (y/N)"
        if ($confirm.ToLower() -eq "y") {
            try {
                $logFiles | Remove-Item -Force
                Write-Host "✅ All log files deleted" -ForegroundColor $SyncTheme.Success
            }
            catch {
                Write-Host "❌ Error deleting logs: $($_.Exception.Message)" -ForegroundColor $SyncTheme.Error
            }
        }
        else {
            Write-Host "❌ Operation cancelled" -ForegroundColor $SyncTheme.Error
        }
    }
    
    Start-Sleep 2
    Show-SyncMainMenu
}

function Test-RepairConnection {
    Show-SyncHeader "🔧 TEST & REPAIR" "Connection diagnostics and repair"
    
    Write-Host "`n🔍 Running comprehensive connection test..." -ForegroundColor $SyncTheme.Info
    
    # Test local path
    Write-Host "`n📁 Testing local path..." -ForegroundColor $SyncTheme.Primary
    if (Test-Path $AI_ModelsPath) {
        Write-Host "   ✅ Local path accessible" -ForegroundColor $SyncTheme.Success
        
        # Test write access
        try {
            $testFile = Join-Path $AI_ModelsPath ".sync_test"
            "test" | Out-File -FilePath $testFile -ErrorAction Stop
            Remove-Item $testFile -Force
            Write-Host "   ✅ Local write access confirmed" -ForegroundColor $SyncTheme.Success
        }
        catch {
            Write-Host "   ❌ Local write access failed: $($_.Exception.Message)" -ForegroundColor $SyncTheme.Error
        }
    }
    else {
        Write-Host "   ❌ Local path not accessible" -ForegroundColor $SyncTheme.Error
    }
    
    # Test NAS connection
    Write-Host "`n🌐 Testing NAS connection..." -ForegroundColor $SyncTheme.Primary
    $nasStatus = Test-NASConnection -Path $NASPath
    
    if ($nasStatus.Connected) {
        Write-Host "   ✅ NAS connection successful" -ForegroundColor $SyncTheme.Success
        if ($nasStatus.Writable) {
            Write-Host "   ✅ NAS write access confirmed" -ForegroundColor $SyncTheme.Success
        }
        else {
            Write-Host "   ⚠️ NAS is read-only" -ForegroundColor $SyncTheme.Warning
        }
    }
    else {
        Write-Host "   ❌ NAS connection failed: $($nasStatus.Error)" -ForegroundColor $SyncTheme.Error
        
        # Offer repair suggestions
        Write-Host "`n🔧 Repair suggestions:" -ForegroundColor $SyncTheme.Accent
        Write-Host "   1. Check network connectivity" -ForegroundColor $SyncTheme.Info
        Write-Host "   2. Verify NAS path is correct" -ForegroundColor $SyncTheme.Info
        Write-Host "   3. Check credentials/permissions" -ForegroundColor $SyncTheme.Info
        Write-Host "   4. Try accessing NAS through File Explorer" -ForegroundColor $SyncTheme.Info
    }
    
    # Test robocopy availability
    Write-Host "`n🛠️  Testing robocopy..." -ForegroundColor $SyncTheme.Primary
    try {
        $null = robocopy 2>&1
        Write-Host "   ✅ Robocopy available" -ForegroundColor $SyncTheme.Success
    }
    catch {
        Write-Host "   ❌ Robocopy not available" -ForegroundColor $SyncTheme.Error
    }
    
    Write-Host "`n" -NoNewline
    Read-Host "Press Enter to return to sync menu"
    Show-SyncMainMenu
}

# =============================================================================
# MAIN EXECUTION LOGIC
# =============================================================================

# Main execution based on action parameter
if ($Action -eq "menu") {
    Show-SyncMainMenu
}
else {
    # Direct action execution (for integration with main AI Models Manager)
    switch ($Action.ToLower()) {
        "to" { 
            Write-Host "🔄 Starting upload to NAS..." -ForegroundColor $SyncTheme.GameBlue
            Sync-ToNAS 
        }
        "from" { 
            Write-Host "🔄 Starting download from NAS..." -ForegroundColor $SyncTheme.GameRed
            Sync-FromNAS 
        }
        "quick" { 
            Write-Host "🔄 Starting quick sync..." -ForegroundColor $SyncTheme.Accent
            Sync-Quick 
        }
        "test" {
            Test-NASConnection -Path $NASPath
        }
        default {
            Write-Host "❌ Unknown action: $Action" -ForegroundColor $SyncTheme.Error
            Write-Host "Available actions: menu, to, from, quick, test" -ForegroundColor $SyncTheme.Info
        }
    }
}