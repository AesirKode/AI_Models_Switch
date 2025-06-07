# ⬇️ Advanced AI Model Download Manager v2.0
# File: D:\AI_Models\System\Core\Scripts\PowerShell\ModelDownloader.ps1
# Features: Automated downloading from HuggingFace, Ollama, GitHub, and custom sources

param(
    [string]$Action = "menu",
    [string]$ModelUrl = "",
    [string]$ModelName = "",
    [string]$Category = "",
    [switch]$AutoOrganize,
    [switch]$Verbose,
    [switch]$Resume,
    [int]$MaxConcurrent = 3,
    [string]$OutputPath = ""
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
    }
    catch {
        Write-Warning "Could not load configuration file: $ConfigPath"
    }
}

# Create download directories
$DownloadPaths = @{
    Queue     = "$AI_ModelsPath\Workflows\Downloads\Queue"
    Active    = "$AI_ModelsPath\Workflows\Downloads\Active"
    Completed = "$AI_ModelsPath\Workflows\Downloads\Completed"
    Failed    = "$AI_ModelsPath\Workflows\Downloads\Failed"
    Logs      = "$AI_ModelsPath\System\Core\Logs\Downloads"
}

foreach ($path in $DownloadPaths.Values) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

# Game Console Style Colors (trademark-safe!)
$DownloadTheme = @{
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
    GameGreen  = "Green"
}

# Model source configurations
$ModelSources = @{
    HuggingFace = @{
        BaseUrl          = "https://huggingface.co"
        ApiUrl           = "https://api.huggingface.co"
        RequiresAuth     = $false
        SupportedFormats = @("safetensors", "bin", "gguf", "onnx")
    }
    Ollama      = @{
        BaseUrl          = "https://ollama.com"
        LocalUrl         = "http://localhost:11434"
        RequiresAuth     = $false
        SupportedFormats = @("gguf", "bin")
    }
    GitHub      = @{
        BaseUrl          = "https://github.com"
        ApiUrl           = "https://api.github.com"
        RequiresAuth     = $false
        SupportedFormats = @("gguf", "safetensors", "bin", "onnx")
    }
    Custom      = @{
        RequiresAuth     = $false
        SupportedFormats = @("*")
    }
}

# =============================================================================
# DOWNLOAD MANAGER FUNCTIONS
# =============================================================================

function Show-DownloadHeader {
    param([string]$Title, [string]$Subtitle = "")
    
    Clear-Host
    $headerWidth = 78
    $border = "═" * $headerWidth
    
    Write-Host "╔$border╗" -ForegroundColor $DownloadTheme.Primary
    Write-Host "║" -NoNewline -ForegroundColor $DownloadTheme.Primary
    Write-Host (" " * ([math]::Floor(($headerWidth - $Title.Length) / 2))) -NoNewline
    Write-Host $Title -NoNewline -ForegroundColor $DownloadTheme.Highlight
    Write-Host (" " * ([math]::Ceiling(($headerWidth - $Title.Length) / 2))) -NoNewline
    Write-Host "║" -ForegroundColor $DownloadTheme.Primary
    
    if ($Subtitle) {
        Write-Host "║" -NoNewline -ForegroundColor $DownloadTheme.Primary
        Write-Host (" " * ([math]::Floor(($headerWidth - $Subtitle.Length) / 2))) -NoNewline
        Write-Host $Subtitle -NoNewline -ForegroundColor $DownloadTheme.Subtitle
        Write-Host (" " * ([math]::Ceiling(($headerWidth - $Subtitle.Length) / 2))) -NoNewline
        Write-Host "║" -ForegroundColor $DownloadTheme.Primary
    }
    
    Write-Host "╚$border╝" -ForegroundColor $DownloadTheme.Primary
}

function Show-DownloadMainMenu {
    Show-DownloadHeader "⬇️ AI MODEL DOWNLOAD MANAGER" "Automated downloading from multiple sources"
    
    # Show download statistics
    Write-Host "`n📊 Download Center Status:" -ForegroundColor $DownloadTheme.Primary
    $stats = Get-DownloadStatistics
    Write-Host "   📥 Queue: $($stats.QueueCount) models waiting" -ForegroundColor $DownloadTheme.Info
    Write-Host "   🔄 Active: $($stats.ActiveCount) downloads in progress" -ForegroundColor $DownloadTheme.Info
    Write-Host "   ✅ Completed: $($stats.CompletedCount) models downloaded" -ForegroundColor $DownloadTheme.Success
    Write-Host "   ❌ Failed: $($stats.FailedCount) failed downloads" -ForegroundColor $DownloadTheme.Error
    Write-Host "   💾 Total Downloaded: $($stats.TotalSizeGB) GB" -ForegroundColor $DownloadTheme.Accent
    
    # Show system capabilities
    Write-Host "`n🌐 Available Sources:" -ForegroundColor $DownloadTheme.Primary
    Write-Host "   🤗 Hugging Face: Ready" -ForegroundColor $DownloadTheme.Success
    Write-Host "   🦙 Ollama: " -NoNewline -ForegroundColor $DownloadTheme.Info
    Test-OllamaConnection
    Write-Host "   📱 GitHub: Ready" -ForegroundColor $DownloadTheme.Success
    Write-Host "   🔗 Custom URLs: Ready" -ForegroundColor $DownloadTheme.Success
    
    Write-Host "`n🎯 DOWNLOAD OPTIONS:" -ForegroundColor $DownloadTheme.Primary
    Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor $DownloadTheme.Accent
    
    # Quick Download Options
    Write-Host "`n⚡ QUICK DOWNLOADS:" -ForegroundColor $DownloadTheme.GameBlue
    Write-Host "  1. 🤗 Download from Hugging Face" -ForegroundColor $DownloadTheme.Info
    Write-Host "  2. 🦙 Download from Ollama" -ForegroundColor $DownloadTheme.Info
    Write-Host "  3. 📱 Download from GitHub" -ForegroundColor $DownloadTheme.Info
    Write-Host "  4. 🔗 Download from Custom URL" -ForegroundColor $DownloadTheme.Info
    Write-Host "  5. 📋 Batch Download (Multiple Models)" -ForegroundColor $DownloadTheme.Info
    
    # Management Options
    Write-Host "`n🛠️ DOWNLOAD MANAGEMENT:" -ForegroundColor $DownloadTheme.GameGreen
    Write-Host "  6. 📊 View Download Queue" -ForegroundColor $DownloadTheme.Info
    Write-Host "  7. 🔄 Monitor Active Downloads" -ForegroundColor $DownloadTheme.Info
    Write-Host "  8. ✅ View Completed Downloads" -ForegroundColor $DownloadTheme.Info
    Write-Host "  9. 🗑️ Clean Failed Downloads" -ForegroundColor $DownloadTheme.Info
    Write-Host "  10. ⚙️ Download Settings" -ForegroundColor $DownloadTheme.Info
    
    # Popular Models
    Write-Host "`n🌟 POPULAR MODELS:" -ForegroundColor $DownloadTheme.GameYellow
    Write-Host "  11. 🦙 Llama 3.2 (3B)" -ForegroundColor $DownloadTheme.Info
    Write-Host "  12. 🌟 Code Llama (7B)" -ForegroundColor $DownloadTheme.Info
    Write-Host "  13. 🎨 Stable Diffusion XL" -ForegroundColor $DownloadTheme.Info
    Write-Host "  14. 🗣️ Whisper (Large)" -ForegroundColor $DownloadTheme.Info
    Write-Host "  15. 📝 Mixtral 8x7B" -ForegroundColor $DownloadTheme.Info
    
    # Navigation
    Write-Host "`n🎮 NAVIGATION:" -ForegroundColor $DownloadTheme.GameRed
    Write-Host "  h. 📚 Help & Documentation" -ForegroundColor $DownloadTheme.Info
    Write-Host "  q. 🏠 Return to Main Menu" -ForegroundColor $DownloadTheme.Info
    Write-Host "  x. ❌ Exit Download Manager" -ForegroundColor $DownloadTheme.Info
    
    Write-Host "`n═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor $DownloadTheme.Accent
    $choice = Read-Host "Select download option"
    
    Execute-DownloadChoice $choice
}

function Execute-DownloadChoice {
    param([string]$Choice)
    
    switch ($Choice.ToLower()) {
        "1" { Download-FromHuggingFace }
        "2" { Download-FromOllama }
        "3" { Download-FromGitHub }
        "4" { Download-FromCustomURL }
        "5" { Start-BatchDownload }
        "6" { Show-DownloadQueue }
        "7" { Monitor-ActiveDownloads }
        "8" { Show-CompletedDownloads }
        "9" { Clean-FailedDownloads }
        "10" { Show-DownloadSettings }
        "11" { Download-PopularModel -Model "llama3.2:3b" }
        "12" { Download-PopularModel -Model "codellama:7b" }
        "13" { Download-PopularModel -Model "stabilityai/stable-diffusion-xl-base-1.0" }
        "14" { Download-PopularModel -Model "openai/whisper-large-v3" }
        "15" { Download-PopularModel -Model "mistralai/Mixtral-8x7B-Instruct-v0.1" }
        "h" { Show-DownloadHelp }
        "q" { 
            Write-Host "`n🏠 Returning to Main Menu..." -ForegroundColor $DownloadTheme.Success
            return "main_menu"
        }
        "x" { 
            Write-Host "`n👋 Exiting Download Manager..." -ForegroundColor $DownloadTheme.Success
            return "exit"
        }
        default { 
            Write-Host "`n❌ Invalid choice: $Choice" -ForegroundColor $DownloadTheme.Error
            Start-Sleep 2
            Show-DownloadMainMenu
        }
    }
}

function Get-DownloadStatistics {
    $stats = @{
        QueueCount     = 0
        ActiveCount    = 0
        CompletedCount = 0
        FailedCount    = 0
        TotalSizeGB    = 0
    }
    
    try {
        # Count files in each directory
        $stats.QueueCount = (Get-ChildItem $DownloadPaths.Queue -File -ErrorAction SilentlyContinue).Count
        $stats.ActiveCount = (Get-ChildItem $DownloadPaths.Active -File -ErrorAction SilentlyContinue).Count
        $stats.FailedCount = (Get-ChildItem $DownloadPaths.Failed -File -ErrorAction SilentlyContinue).Count
        
        # Count completed downloads and calculate size
        $completedFiles = Get-ChildItem $DownloadPaths.Completed -File -ErrorAction SilentlyContinue
        $stats.CompletedCount = $completedFiles.Count
        $stats.TotalSizeGB = [math]::Round(($completedFiles | Measure-Object -Property Length -Sum).Sum / 1GB, 2)
    }
    catch {
        Write-Verbose "Error calculating download statistics: $($_.Exception.Message)"
    }
    
    return $stats
}

function Test-OllamaConnection {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method GET -TimeoutSec 3 -ErrorAction Stop
        Write-Host "Ready" -ForegroundColor $DownloadTheme.Success
    }
    catch {
        Write-Host "Offline" -ForegroundColor $DownloadTheme.Warning
    }
}

function Download-FromHuggingFace {
    Show-DownloadHeader "🤗 HUGGING FACE DOWNLOAD" "Download models from Hugging Face Hub"
    
    Write-Host "`n🔍 Enter Hugging Face model details:" -ForegroundColor $DownloadTheme.Primary
    
    # Get model information
    $modelId = Read-Host "Model ID (e.g., microsoft/DialoGPT-small, stabilityai/stable-diffusion-xl-base-1.0)"
    if (-not $modelId) {
        Write-Host "❌ Model ID is required" -ForegroundColor $DownloadTheme.Error
        Start-Sleep 2
        Show-DownloadMainMenu
        return
    }
    
    # Optional: specific file or revision
    $specificFile = Read-Host "Specific file (optional, leave empty for all files)"
    $revision = Read-Host "Revision/branch (optional, default: main)"
    if (-not $revision) { $revision = "main" }
    
    # Validate model exists
    Write-Host "`n🔍 Validating model..." -ForegroundColor $DownloadTheme.Info
    $modelUrl = "https://huggingface.co/$modelId"
    
    try {
        $response = Invoke-WebRequest -Uri $modelUrl -Method Head -TimeoutSec 10 -ErrorAction Stop
        Write-Host "✅ Model found on Hugging Face" -ForegroundColor $DownloadTheme.Success
    }
    catch {
        Write-Host "❌ Model not found or inaccessible: $modelId" -ForegroundColor $DownloadTheme.Error
        Start-Sleep 3
        Show-DownloadMainMenu
        return
    }
    
    # Determine download path
    $category = Determine-ModelCategory -ModelId $modelId
    $outputPath = Join-Path $AI_ModelsPath "Models\$category\HuggingFace\$($modelId.Replace('/', '_'))"
    
    Write-Host "`n📋 Download Configuration:" -ForegroundColor $DownloadTheme.Primary
    Write-Host "   🏷️ Model: $modelId" -ForegroundColor $DownloadTheme.Info
    Write-Host "   📂 Category: $category" -ForegroundColor $DownloadTheme.Info
    Write-Host "   📁 Destination: $outputPath" -ForegroundColor $DownloadTheme.Subtitle
    if ($specificFile) {
        Write-Host "   📄 File: $specificFile" -ForegroundColor $DownloadTheme.Info
    }
    Write-Host "   🌿 Revision: $revision" -ForegroundColor $DownloadTheme.Info
    
    $confirm = Read-Host "`n⚠️ Start download? (y/N)"
    if ($confirm.ToLower() -eq "y") {
        Start-HuggingFaceDownload -ModelId $modelId -OutputPath $outputPath -SpecificFile $specificFile -Revision $revision
    }
    else {
        Write-Host "❌ Download cancelled" -ForegroundColor $DownloadTheme.Error
    }
    
    Start-Sleep 2
    Show-DownloadMainMenu
}

function Download-FromOllama {
    Show-DownloadHeader "🦙 OLLAMA DOWNLOAD" "Download and manage Ollama models"
    
    Write-Host "`n🔍 Enter Ollama model details:" -ForegroundColor $DownloadTheme.Primary
    
    # Show available models
    Write-Host "📋 Popular Ollama models:" -ForegroundColor $DownloadTheme.Info
    $popularModels = @(
        "llama3.2:3b", "llama3.2:1b", "llama3.1:8b",
        "codellama:7b", "codellama:13b", "codellama:34b",
        "mistral:7b", "mixtral:8x7b",
        "phi3:mini", "phi3:medium",
        "gemma2:2b", "gemma2:9b"
    )
    
    for ($i = 0; $i -lt $popularModels.Count; $i++) {
        $color = if ($i % 2 -eq 0) { $DownloadTheme.Info } else { $DownloadTheme.Subtitle }
        Write-Host "   $($i + 1). $($popularModels[$i])" -ForegroundColor $color
    }
    
    $modelName = Read-Host "`nModel name (e.g., llama3.2:3b or custom)"
    if (-not $modelName) {
        Write-Host "❌ Model name is required" -ForegroundColor $DownloadTheme.Error
        Start-Sleep 2
        Show-DownloadMainMenu
        return
    }
    
    # Check if Ollama is running
    Write-Host "`n🔍 Checking Ollama connection..." -ForegroundColor $DownloadTheme.Info
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method GET -TimeoutSec 5
        Write-Host "✅ Ollama is running" -ForegroundColor $DownloadTheme.Success
    }
    catch {
        Write-Host "❌ Ollama is not running. Please start Ollama first." -ForegroundColor $DownloadTheme.Error
        Write-Host "   Run: ollama serve" -ForegroundColor $DownloadTheme.Subtitle
        Start-Sleep 3
        Show-DownloadMainMenu
        return
    }
    
    Write-Host "`n📋 Download Configuration:" -ForegroundColor $DownloadTheme.Primary
    Write-Host "   🏷️ Model: $modelName" -ForegroundColor $DownloadTheme.Info
    Write-Host "   🦙 Source: Ollama Registry" -ForegroundColor $DownloadTheme.Info
    Write-Host "   📁 Destination: Ollama Local Storage" -ForegroundColor $DownloadTheme.Subtitle
    
    $confirm = Read-Host "`n⚠️ Start download? (y/N)"
    if ($confirm.ToLower() -eq "y") {
        Start-OllamaDownload -ModelName $modelName
    }
    else {
        Write-Host "❌ Download cancelled" -ForegroundColor $DownloadTheme.Error
    }
    
    Start-Sleep 2
    Show-DownloadMainMenu
}

function Download-FromGitHub {
    Show-DownloadHeader "📱 GITHUB DOWNLOAD" "Download models from GitHub repositories"
    
    Write-Host "`n🔍 Enter GitHub repository details:" -ForegroundColor $DownloadTheme.Primary
    
    $repoUrl = Read-Host "Repository URL (e.g., https://github.com/user/repo)"
    if (-not $repoUrl) {
        Write-Host "❌ Repository URL is required" -ForegroundColor $DownloadTheme.Error
        Start-Sleep 2
        Show-DownloadMainMenu
        return
    }
    
    # Parse GitHub URL
    if ($repoUrl -match "github\.com/([^/]+)/([^/]+)") {
        $owner = $matches[1]
        $repo = $matches[2].Replace(".git", "")
    }
    else {
        Write-Host "❌ Invalid GitHub URL format" -ForegroundColor $DownloadTheme.Error
        Start-Sleep 2
        Show-DownloadMainMenu
        return
    }
    
    $specificFile = Read-Host "Specific file/folder (optional, leave empty for entire repo)"
    $branch = Read-Host "Branch (optional, default: main)"
    if (-not $branch) { $branch = "main" }
    
    # Validate repository
    Write-Host "`n🔍 Validating repository..." -ForegroundColor $DownloadTheme.Info
    try {
        $apiUrl = "https://api.github.com/repos/$owner/$repo"
        $response = Invoke-RestMethod -Uri $apiUrl -Method GET -TimeoutSec 10
        Write-Host "✅ Repository found: $($response.full_name)" -ForegroundColor $DownloadTheme.Success
        Write-Host "   📝 Description: $($response.description)" -ForegroundColor $DownloadTheme.Subtitle
        Write-Host "   ⭐ Stars: $($response.stargazers_count)" -ForegroundColor $DownloadTheme.Subtitle
    }
    catch {
        Write-Host "❌ Repository not found or inaccessible: $owner/$repo" -ForegroundColor $DownloadTheme.Error
        Start-Sleep 3
        Show-DownloadMainMenu
        return
    }
    
    # Determine download path
    $outputPath = Join-Path $AI_ModelsPath "Models\Language\GitHub\$($owner)_$($repo)"
    
    Write-Host "`n📋 Download Configuration:" -ForegroundColor $DownloadTheme.Primary
    Write-Host "   🏷️ Repository: $owner/$repo" -ForegroundColor $DownloadTheme.Info
    Write-Host "   📁 Destination: $outputPath" -ForegroundColor $DownloadTheme.Subtitle
    if ($specificFile) {
        Write-Host "   📄 File/Folder: $specificFile" -ForegroundColor $DownloadTheme.Info
    }
    Write-Host "   🌿 Branch: $branch" -ForegroundColor $DownloadTheme.Info
    
    $confirm = Read-Host "`n⚠️ Start download? (y/N)"
    if ($confirm.ToLower() -eq "y") {
        Start-GitHubDownload -Owner $owner -Repo $repo -OutputPath $outputPath -SpecificFile $specificFile -Branch $branch
    }
    else {
        Write-Host "❌ Download cancelled" -ForegroundColor $DownloadTheme.Error
    }
    
    Start-Sleep 2
    Show-DownloadMainMenu
}

function Download-FromCustomURL {
    Show-DownloadHeader "🔗 CUSTOM URL DOWNLOAD" "Download models from any URL"
    
    Write-Host "`n🔍 Enter custom download details:" -ForegroundColor $DownloadTheme.Primary
    
    $customUrl = Read-Host "Download URL"
    if (-not $customUrl) {
        Write-Host "❌ URL is required" -ForegroundColor $DownloadTheme.Error
        Start-Sleep 2
        Show-DownloadMainMenu
        return
    }
    
    $fileName = Read-Host "File name (optional, will auto-detect if empty)"
    if (-not $fileName) {
        # Try to extract filename from URL
        $fileName = Split-Path $customUrl -Leaf
        if (-not $fileName -or $fileName -notmatch '\.[a-zA-Z0-9]+$') {
            $fileName = "downloaded_model_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        }
    }
    
    # Determine category and output path
    $category = Determine-ModelCategory -FileName $fileName
    $outputPath = Join-Path $AI_ModelsPath "Models\$category\Custom\$fileName"
    
    Write-Host "`n📋 Download Configuration:" -ForegroundColor $DownloadTheme.Primary
    Write-Host "   🔗 URL: $customUrl" -ForegroundColor $DownloadTheme.Info
    Write-Host "   📄 File Name: $fileName" -ForegroundColor $DownloadTheme.Info
    Write-Host "   📂 Category: $category" -ForegroundColor $DownloadTheme.Info
    Write-Host "   📁 Destination: $outputPath" -ForegroundColor $DownloadTheme.Subtitle
    
    $confirm = Read-Host "`n⚠️ Start download? (y/N)"
    if ($confirm.ToLower() -eq "y") {
        Start-CustomURLDownload -Url $customUrl -OutputPath $outputPath -FileName $fileName
    }
    else {
        Write-Host "❌ Download cancelled" -ForegroundColor $DownloadTheme.Error
    }
    
    Start-Sleep 2
    Show-DownloadMainMenu
}

# =============================================================================
# DOWNLOAD EXECUTION FUNCTIONS
# =============================================================================

function Start-HuggingFaceDownload {
    param(
        [string]$ModelId,
        [string]$OutputPath,
        [string]$SpecificFile = "",
        [string]$Revision = "main"
    )
    
    Write-Host "`n🚀 Starting Hugging Face download..." -ForegroundColor $DownloadTheme.Success
    
    # Create output directory
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Check if git-lfs is available for large files
    try {
        $null = git lfs --version 2>$null
        $hasGitLFS = $true
        Write-Host "✅ Git LFS available for large files" -ForegroundColor $DownloadTheme.Success
    }
    catch {
        $hasGitLFS = $false
        Write-Host "⚠️ Git LFS not available - large files may fail" -ForegroundColor $DownloadTheme.Warning
    }
    
    try {
        # Use git clone for full repository
        if (-not $SpecificFile) {
            $cloneUrl = "https://huggingface.co/$ModelId"
            Write-Host "📦 Cloning repository: $cloneUrl" -ForegroundColor $DownloadTheme.Info
            
            if ($hasGitLFS) {
                git clone $cloneUrl $OutputPath
            }
            else {
                # Clone without LFS for smaller files only
                $env:GIT_LFS_SKIP_SMUDGE = "1"
                git clone $cloneUrl $OutputPath
                $env:GIT_LFS_SKIP_SMUDGE = ""
            }
        }
        else {
            # Download specific file using Hugging Face API
            $fileUrl = "https://huggingface.co/$ModelId/resolve/$Revision/$SpecificFile"
            $outputFile = Join-Path $OutputPath $SpecificFile
            Write-Host "📄 Downloading file: $SpecificFile" -ForegroundColor $DownloadTheme.Info
            
            Invoke-WebRequest -Uri $fileUrl -OutFile $outputFile -TimeoutSec 300
        }
        
        Write-Host "✅ Download completed successfully" -ForegroundColor $DownloadTheme.Success
        Write-Host "📁 Location: $OutputPath" -ForegroundColor $DownloadTheme.Subtitle
        
        # Move to completed folder
        $completedPath = Join-Path $DownloadPaths.Completed (Split-Path $OutputPath -Leaf)
        if (Test-Path $OutputPath) {
            Move-Item $OutputPath $completedPath -Force
            Write-Host "✅ Moved to completed downloads" -ForegroundColor $DownloadTheme.Success
        }
    }
    catch {
        Write-Host "❌ Download failed: $($_.Exception.Message)" -ForegroundColor $DownloadTheme.Error
        
        # Log error and move to failed folder if partially downloaded
        $errorLog = Join-Path $DownloadPaths.Logs "error_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $_.Exception.Message | Out-File $errorLog
    }
}

function Start-OllamaDownload {
    param([string]$ModelName)
    
    Write-Host "`n🚀 Starting Ollama download..." -ForegroundColor $DownloadTheme.Success
    Write-Host "🦙 Downloading model: $ModelName" -ForegroundColor $DownloadTheme.Info
    
    try {
        # Use Ollama CLI to pull the model
        Write-Host "📦 Executing: ollama pull $ModelName" -ForegroundColor $DownloadTheme.Subtitle
        $process = Start-Process -FilePath "ollama" -ArgumentList "pull", $ModelName -NoNewWindow -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host "✅ Model downloaded successfully" -ForegroundColor $DownloadTheme.Success
            
            # Verify the model is available
            $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method GET
            $installedModel = $response.models | Where-Object { $_.name -eq $ModelName }
            
            if ($installedModel) {
                Write-Host "✅ Model verified in Ollama" -ForegroundColor $DownloadTheme.Success
                Write-Host "📊 Size: $([math]::Round($installedModel.size / 1GB, 2)) GB" -ForegroundColor $DownloadTheme.Subtitle
            }
        }
        else {
            Write-Host "❌ Ollama download failed (Exit code: $($process.ExitCode))" -ForegroundColor $DownloadTheme.Error
        }
    }
    catch {
        Write-Host "❌ Download failed: $($_.Exception.Message)" -ForegroundColor $DownloadTheme.Error
    }
}

function Start-GitHubDownload {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$OutputPath,
        [string]$SpecificFile = "",
        [string]$Branch = "main"
    )
    
    Write-Host "`n🚀 Starting GitHub download..." -ForegroundColor $DownloadTheme.Success
    
    # Create output directory
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    try {
        if (-not $SpecificFile) {
            # Clone entire repository
            $cloneUrl = "https://github.com/$Owner/$Repo.git"
            Write-Host "📦 Cloning repository: $cloneUrl" -ForegroundColor $DownloadTheme.Info
            
            git clone --branch $Branch $cloneUrl $OutputPath
        }
        else {
            # Download specific file
            $fileUrl = "https://raw.githubusercontent.com/$Owner/$Repo/$Branch/$SpecificFile"
            $outputFile = Join-Path $OutputPath $SpecificFile
            Write-Host "📄 Downloading file: $SpecificFile" -ForegroundColor $DownloadTheme.Info
            
            # Create subdirectories if needed
            $fileDir = Split-Path $outputFile -Parent
            if (-not (Test-Path $fileDir)) {
                New-Item -ItemType Directory -Path $fileDir -Force | Out-Null
            }
            
            Invoke-WebRequest -Uri $fileUrl -OutFile $outputFile -TimeoutSec 300
        }
        
        Write-Host "✅ Download completed successfully" -ForegroundColor $DownloadTheme.Success
        Write-Host "📁 Location: $OutputPath" -ForegroundColor $DownloadTheme.Subtitle
        
        # Move to completed folder
        $completedPath = Join-Path $DownloadPaths.Completed "$($Owner)_$($Repo)"
        if (Test-Path $OutputPath) {
            Move-Item $OutputPath $completedPath -Force
            Write-Host "✅ Moved to completed downloads" -ForegroundColor $DownloadTheme.Success
        }
    }
    catch {
        Write-Host "❌ Download failed: $($_.Exception.Message)" -ForegroundColor $DownloadTheme.Error
    }
}

function Start-CustomURLDownload {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$FileName
    )
    
    Write-Host "`n🚀 Starting custom URL download..." -ForegroundColor $DownloadTheme.Success
    
    # Create output directory
    $outputDir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    try {
        Write-Host "🔗 Downloading from: $Url" -ForegroundColor $DownloadTheme.Info
        Write-Host "📄 Saving as: $FileName" -ForegroundColor $DownloadTheme.Info
        
        # Use Invoke-WebRequest with progress
        $request = [System.Net.WebRequest]::Create($Url)
        $response = $request.GetResponse()
        $totalSize = $response.ContentLength
        
        if ($totalSize -gt 0) {
            Write-Host "📊 File size: $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor $DownloadTheme.Subtitle
        }
        
        # Download with progress
        Invoke-WebRequest -Uri $Url -OutFile $OutputPath -TimeoutSec 600
        
        Write-Host "✅ Download completed successfully" -ForegroundColor $DownloadTheme.Success
        Write-Host "📁 Location: $OutputPath" -ForegroundColor $DownloadTheme.Subtitle
        
        # Verify file exists and has content
        if (Test-Path $OutputPath) {
            $fileInfo = Get-Item $OutputPath
            Write-Host "✅ File verified: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor $DownloadTheme.Success
        }
    }
    catch {
        Write-Host "❌ Download failed: $($_.Exception.Message)" -ForegroundColor $DownloadTheme.Error
    }
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

function Determine-ModelCategory {
    param(
        [string]$ModelId = "",
        [string]$FileName = ""
    )
    
    $text = "$ModelId $FileName".ToLower()
    
    # Language models
    if ($text -match "(llama|gpt|bert|t5|flan|bloom|opt|pythia|falcon|mistral|mixtral|phi|gemma|code|chat|instruct)") {
        return "Language"
    }
    
    # Vision models
    if ($text -match "(vision|image|clip|vit|dino|yolo|rcnn|stable-diffusion|diffusion|dalle|midjourney)") {
        return "Vision"
    }
    
    # Audio models
    if ($text -match "(whisper|speech|audio|tts|voice|sound|music|wav2vec)") {
        return "Audio"
    }
    
    # Embedding models
    if ($text -match "(embedding|sentence|word2vec|glove|fasttext)") {
        return "Embeddings"
    }
    
    # Default to Language for unknown models
    return "Language"
}

function Download-PopularModel {
    param([string]$Model)
    
    Write-Host "`n🌟 Downloading popular model: $Model" -ForegroundColor $DownloadTheme.GameYellow
    
    # Determine source and download method
    if ($Model -match "^[a-z0-9.-]+:[a-z0-9.-]+$") {
        # Ollama format (model:tag)
        Start-OllamaDownload -ModelName $Model
    }
    else {
        # Assume Hugging Face format
        $outputPath = Join-Path $AI_ModelsPath "Models\Language\HuggingFace\$($Model.Replace('/', '_'))"
        Start-HuggingFaceDownload -ModelId $Model -OutputPath $outputPath
    }
    
    Start-Sleep 3
    Show-DownloadMainMenu
}

# =============================================================================
# MANAGEMENT FUNCTIONS (Stubs for now)
# =============================================================================

function Show-DownloadQueue {
    Write-Host "`n📊 Download Queue - Coming soon!" -ForegroundColor $DownloadTheme.GameBlue
    Start-Sleep 2
    Show-DownloadMainMenu
}

function Monitor-ActiveDownloads {
    Write-Host "`n🔄 Active Downloads Monitor - Coming soon!" -ForegroundColor $DownloadTheme.GameGreen
    Start-Sleep 2
    Show-DownloadMainMenu
}

function Show-CompletedDownloads {
    Write-Host "`n✅ Completed Downloads - Coming soon!" -ForegroundColor $DownloadTheme.Success
    Start-Sleep 2
    Show-DownloadMainMenu
}

function Clean-FailedDownloads {
    Write-Host "`n🗑️ Cleaning Failed Downloads - Coming soon!" -ForegroundColor $DownloadTheme.Warning
    Start-Sleep 2
    Show-DownloadMainMenu
}

function Show-DownloadSettings {
    Write-Host "`n⚙️ Download Settings - Coming soon!" -ForegroundColor $DownloadTheme.Accent
    Start-Sleep 2
    Show-DownloadMainMenu
}

function Start-BatchDownload {
    Write-Host "`n📋 Batch Download - Coming soon!" -ForegroundColor $DownloadTheme.Primary
    Start-Sleep 2
    Show-DownloadMainMenu
}

function Show-DownloadHelp {
    Show-DownloadHeader "📚 DOWNLOAD MANAGER HELP" "How to use the AI Model Download Manager"
    
    Write-Host @"
🤗 HUGGING FACE:
   • Enter model ID like: microsoft/DialoGPT-small
   • Supports all model types: language, vision, audio
   • Automatically organizes by category
   
🦙 OLLAMA:
   • Requires Ollama to be running (ollama serve)
   • Use format: model:tag (e.g., llama3.2:3b)
   • Models stored in Ollama's local storage
   
📱 GITHUB:
   • Full repository URL or user/repo format
   • Can download specific files or entire repos
   • Great for custom models and code
   
🔗 CUSTOM URLs:
   • Direct download from any URL
   • Automatically detects file types
   • Perfect for custom model hosting
   
🎯 TIPS:
   • Downloads are automatically organized by type
   • Large models may take time - be patient!
   • Check your internet connection for stability
   • Failed downloads are logged for debugging
"@ -ForegroundColor $DownloadTheme.Info
    
    Write-Host "`n" -NoNewline
    Read-Host "Press Enter to return to download menu"
    Show-DownloadMainMenu
}

# =============================================================================
# MAIN EXECUTION LOGIC
# =============================================================================

# Main execution based on action parameter
if ($Action -eq "menu") {
    Show-DownloadMainMenu
}
else {
    # Direct action execution (for integration with main AI Models Manager)
    switch ($Action.ToLower()) {
        "huggingface" { Download-FromHuggingFace }
        "ollama" { Download-FromOllama }
        "github" { Download-FromGitHub }
        "custom" { Download-FromCustomURL }
        "popular" { 
            if ($ModelName) {
                Download-PopularModel -Model $ModelName
            }
            else {
                Write-Host "❌ ModelName parameter required for popular downloads" -ForegroundColor $DownloadTheme.Error
            }
        }
        default {
            Write-Host "❌ Unknown action: $Action" -ForegroundColor $DownloadTheme.Error
            Write-Host "Available actions: menu, huggingface, ollama, github, custom, popular" -ForegroundColor $DownloadTheme.Info
        }
    }
}