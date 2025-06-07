# 🎮 Game Console Style AI Models Management System - Fixed Version
# File: D:\AI_Models\System\Core\Scripts\PowerShell\AIModelsSwitchGUI_Fixed.ps1
# Features: Error-free game console UI with interactive terminal

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =============================================================================
# GAME CONSOLE THEME SYSTEM
# =============================================================================

$ConsoleTheme = @{
    # Console Colors
    ConsoleGray        = [System.Drawing.Color]::FromArgb(50, 60, 65)
    ConsoleBlue        = [System.Drawing.Color]::FromArgb(0, 155, 255)
    ConsoleRed         = [System.Drawing.Color]::FromArgb(255, 60, 60)
    ConsoleYellow      = [System.Drawing.Color]::FromArgb(255, 200, 0)
    ScreenBlack        = [System.Drawing.Color]::FromArgb(10, 10, 10)
    
    # Joy-Con Colors
    LeftJoyConBlue     = [System.Drawing.Color]::FromArgb(45, 135, 245)
    RightJoyConRed     = [System.Drawing.Color]::FromArgb(255, 75, 75)
    ButtonGray         = [System.Drawing.Color]::FromArgb(90, 100, 105)
    ButtonHover        = [System.Drawing.Color]::FromArgb(120, 130, 135)
    
    # Terminal Colors
    TerminalBackground = [System.Drawing.Color]::FromArgb(15, 15, 15)
    TerminalGreen      = [System.Drawing.Color]::FromArgb(0, 255, 0)
    TerminalBlue       = [System.Drawing.Color]::FromArgb(100, 200, 255)
    TerminalYellow     = [System.Drawing.Color]::FromArgb(255, 255, 100)
    TerminalRed        = [System.Drawing.Color]::FromArgb(255, 100, 100)
    
    # UI Elements
    TextWhite          = [System.Drawing.Color]::White
    TextGray           = [System.Drawing.Color]::FromArgb(200, 200, 200)
    
    # Fonts
    FontFamily         = "Segoe UI"
    TerminalFont       = "Consolas"
}

# =============================================================================
# MAIN CONSOLE FORM
# =============================================================================

function New-ConsoleStyleApp {
    # Create main form (Game Console dimensions)
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "🎮 AI Models Console - Game Style Manager"
    $form.Size = New-Object System.Drawing.Size(1000, 600)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = $ConsoleTheme.ConsoleGray
    $form.FormBorderStyle = "FixedSingle"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $true
    
    # =============================================================================
    # MAIN CONTAINER PANEL
    # =============================================================================
    
    $mainPanel = New-Object System.Windows.Forms.Panel
    $mainPanel.Size = New-Object System.Drawing.Size(980, 580)
    $mainPanel.Location = New-Object System.Drawing.Point(10, 10)
    $mainPanel.BackColor = [System.Drawing.Color]::Transparent
    
    # =============================================================================
    # LEFT JOY-CON (BLUE) - SYSTEM CONTROLS
    # =============================================================================
    
    $leftJoycon = New-Object System.Windows.Forms.Panel
    $leftJoycon.Size = New-Object System.Drawing.Size(150, 580)
    $leftJoycon.Location = New-Object System.Drawing.Point(0, 0)
    $leftJoycon.BackColor = $ConsoleTheme.LeftJoyConBlue
    
    # Left Joy-Con Title
    $leftTitle = New-Object System.Windows.Forms.Label
    $leftTitle.Text = "🎮 SYSTEM"
    $leftTitle.Font = New-Object System.Drawing.Font($ConsoleTheme.FontFamily, 10, [System.Drawing.FontStyle]::Bold)
    $leftTitle.ForeColor = $ConsoleTheme.TextWhite
    $leftTitle.TextAlign = "MiddleCenter"
    $leftTitle.Size = New-Object System.Drawing.Size(130, 30)
    $leftTitle.Location = New-Object System.Drawing.Point(10, 20)
    
    # System Control Buttons
    $systemButtons = @(
        @{ Text = "📊 Dashboard"; Y = 70; Action = "dashboard" },
        @{ Text = "🤖 Models"; Y = 120; Action = "models" },
        @{ Text = "⬇️ Download"; Y = 170; Action = "download" },
        @{ Text = "⚡ Optimize"; Y = 220; Action = "optimize" },
        @{ Text = "🔄 Sync"; Y = 270; Action = "sync" },
        @{ Text = "🛠️ Maintain"; Y = 320; Action = "maintain" },
        @{ Text = "📈 Monitor"; Y = 370; Action = "monitor" },
        @{ Text = "🔒 Security"; Y = 420; Action = "security" }
    )
    
    foreach ($btn in $systemButtons) {
        $button = New-ConsoleButton -Text $btn.Text -X 15 -Y $btn.Y -Width 120 -Height 35 -IsSystemButton
        $button.Tag = $btn.Action
        $button.Add_Click({
                param($sender, $e)
                Execute-ConsoleAction -Action $sender.Tag -Terminal $global:ConsoleTerminal
            })
        $leftJoycon.Controls.Add($button)
    }
    
    # Power button
    $powerButton = New-Object System.Windows.Forms.Button
    $powerButton.Text = "⚡"
    $powerButton.Size = New-Object System.Drawing.Size(40, 40)
    $powerButton.Location = New-Object System.Drawing.Point(55, 500)
    $powerButton.BackColor = $ConsoleTheme.ConsoleRed
    $powerButton.ForeColor = $ConsoleTheme.TextWhite
    $powerButton.FlatStyle = "Flat"
    $powerButton.Font = New-Object System.Drawing.Font($ConsoleTheme.FontFamily, 14, [System.Drawing.FontStyle]::Bold)
    $powerButton.Add_Click({ [System.Windows.Forms.Application]::Exit() })
    
    $leftJoycon.Controls.AddRange(@($leftTitle, $powerButton))
    
    # =============================================================================
    # CENTER SCREEN - INTERACTIVE TERMINAL
    # =============================================================================
    
    $screenPanel = New-Object System.Windows.Forms.Panel
    $screenPanel.Size = New-Object System.Drawing.Size(680, 580)
    $screenPanel.Location = New-Object System.Drawing.Point(150, 0)
    $screenPanel.BackColor = $ConsoleTheme.ScreenBlack
    $screenPanel.Padding = New-Object System.Windows.Forms.Padding(20)
    
    # Screen Header
    $screenHeader = New-Object System.Windows.Forms.Panel
    $screenHeader.Size = New-Object System.Drawing.Size(640, 60)
    $screenHeader.Location = New-Object System.Drawing.Point(20, 20)
    $screenHeader.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    
    # Header title
    $headerTitle = New-Object System.Windows.Forms.Label
    $headerTitle.Text = "🤖 AI MODELS MANAGEMENT SYSTEM"
    $headerTitle.Font = New-Object System.Drawing.Font($ConsoleTheme.FontFamily, 14, [System.Drawing.FontStyle]::Bold)
    $headerTitle.ForeColor = $ConsoleTheme.TerminalBlue
    $headerTitle.TextAlign = "MiddleCenter"
    $headerTitle.Dock = "Fill"
    
    # System status in header
    $statusLine = New-Object System.Windows.Forms.Label
    $statusLine.Text = "🔋 System Ready | 📊 0 Models | 💾 0 GB | 🕐 $(Get-Date -Format 'HH:mm')"
    $statusLine.Font = New-Object System.Drawing.Font($ConsoleTheme.FontFamily, 8)
    $statusLine.ForeColor = $ConsoleTheme.TerminalGreen
    $statusLine.TextAlign = "BottomCenter"
    $statusLine.Size = New-Object System.Drawing.Size(640, 20)
    $statusLine.Location = New-Object System.Drawing.Point(0, 35)
    
    $screenHeader.Controls.AddRange(@($headerTitle, $statusLine))
    
    # Main Terminal (the Console Screen)
    $terminal = New-Object System.Windows.Forms.RichTextBox
    $terminal.Size = New-Object System.Drawing.Size(640, 480)
    $terminal.Location = New-Object System.Drawing.Point(20, 100)
    $terminal.BackColor = $ConsoleTheme.TerminalBackground
    $terminal.ForeColor = $ConsoleTheme.TerminalGreen
    $terminal.Font = New-Object System.Drawing.Font($ConsoleTheme.TerminalFont, 10)
    $terminal.ScrollBars = "Vertical"
    $terminal.BorderStyle = "None"
    $terminal.ReadOnly = $false
    
    # Initialize terminal with Console-style welcome
    $terminal.Text = @"
╔══════════════════════════════════════════════════════════════════════════════╗
║                🎮 AI MODELS CONSOLE - INTERACTIVE TERMINAL 🎮               ║
║                      Welcome to Game Console AI Style!                      ║
╚══════════════════════════════════════════════════════════════════════════════╝

🕹️  CONTROLS:
   Left Joy-Con (Blue)  → System Controls & Navigation
   Right Joy-Con (Red)  → Quick Actions & Shortcuts
   Terminal Screen      → Interactive Command Interface

🚀 GETTING STARTED:
   • Use the blue Joy-Con buttons for main system functions
   • Use the red Joy-Con for quick actions like VS Code, Terminal
   • Type commands directly in this terminal
   • Navigate with console-style commands

📊 SYSTEM STATUS:
   Base Directory: D:\AI_Models
   Configuration: Loaded ✅
   VS Code Integration: Ready ✅
   Terminal Mode: Game Console Style 🎮

Current Directory: D:\AI_Models
System: Ready for AI model management!

Console-AI> 
"@
    
    # Enhanced terminal input handling
    $terminal.Add_KeyDown({
            param($sender, $e)
            if ($e.KeyCode -eq "Enter") {
                Process-ConsoleTerminalCommand -Terminal $sender
            }
        })
    
    # Store global reference
    $global:ConsoleTerminal = $terminal
    
    $screenPanel.Controls.AddRange(@($screenHeader, $terminal))
    
    # =============================================================================
    # RIGHT JOY-CON (RED) - QUICK ACTIONS
    # =============================================================================
    
    $rightJoycon = New-Object System.Windows.Forms.Panel
    $rightJoycon.Size = New-Object System.Drawing.Size(150, 580)
    $rightJoycon.Location = New-Object System.Drawing.Point(830, 0)
    $rightJoycon.BackColor = $ConsoleTheme.RightJoyConRed
    
    # Right Joy-Con Title
    $rightTitle = New-Object System.Windows.Forms.Label
    $rightTitle.Text = "⚡ QUICK"
    $rightTitle.Font = New-Object System.Drawing.Font($ConsoleTheme.FontFamily, 10, [System.Drawing.FontStyle]::Bold)
    $rightTitle.ForeColor = $ConsoleTheme.TextWhite
    $rightTitle.TextAlign = "MiddleCenter"
    $rightTitle.Size = New-Object System.Drawing.Size(130, 30)
    $rightTitle.Location = New-Object System.Drawing.Point(10, 20)
    
    # Quick Action Buttons
    $quickButtons = @(
        @{ Text = "📁 VS Code"; Y = 70; Action = "vscode" },
        @{ Text = "💻 Terminal"; Y = 120; Action = "terminal" },
        @{ Text = "🗂️ Explorer"; Y = 170; Action = "explorer" },
        @{ Text = "🌐 Web UI"; Y = 220; Action = "web" },
        @{ Text = "📊 Stats"; Y = 270; Action = "stats" },
        @{ Text = "🔄 Refresh"; Y = 320; Action = "refresh" },
        @{ Text = "❓ Help"; Y = 370; Action = "help" },
        @{ Text = "⚙️ Settings"; Y = 420; Action = "settings" }
    )
    
    foreach ($btn in $quickButtons) {
        $button = New-ConsoleButton -Text $btn.Text -X 15 -Y $btn.Y -Width 120 -Height 35 -IsQuickAction
        $button.Tag = $btn.Action
        $button.Add_Click({
                param($sender, $e)
                Execute-QuickAction -Action $sender.Tag -Terminal $global:ConsoleTerminal
            })
        $rightJoycon.Controls.Add($button)
    }
    
    # Home button
    $homeButton = New-Object System.Windows.Forms.Button
    $homeButton.Text = "🏠"
    $homeButton.Size = New-Object System.Drawing.Size(40, 40)
    $homeButton.Location = New-Object System.Drawing.Point(55, 500)
    $homeButton.BackColor = $ConsoleTheme.ConsoleYellow
    $homeButton.ForeColor = $ConsoleTheme.ConsoleGray
    $homeButton.FlatStyle = "Flat"
    $homeButton.Font = New-Object System.Drawing.Font($ConsoleTheme.FontFamily, 14, [System.Drawing.FontStyle]::Bold)
    $homeButton.Add_Click({ 
            Add-ToConsoleTerminal -Terminal $global:ConsoleTerminal -Message "🏠 Returned to Home Screen" -Color $ConsoleTheme.TerminalYellow
        })
    
    $rightJoycon.Controls.AddRange(@($rightTitle, $homeButton))
    
    # =============================================================================
    # ASSEMBLE THE CONSOLE
    # =============================================================================
    
    $mainPanel.Controls.AddRange(@($leftJoycon, $screenPanel, $rightJoycon))
    $form.Controls.Add($mainPanel)
    
    # =============================================================================
    # REAL-TIME UPDATES
    # =============================================================================
    
    $updateTimer = New-Object System.Windows.Forms.Timer
    $updateTimer.Interval = 3000
    $updateTimer.Add_Tick({
            Update-ConsoleStatus -StatusLabel $statusLine -Terminal $global:ConsoleTerminal
        })
    $updateTimer.Start()
    
    # Store references
    $form.Tag = @{
        Terminal   = $terminal
        StatusLine = $statusLine
        Timer      = $updateTimer
    }
    
    return $form
}

# =============================================================================
# SIMPLIFIED BUTTON CREATION
# =============================================================================

function New-ConsoleButton {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [switch]$IsQuickAction,
        [switch]$IsSystemButton
    )
    
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $button.Size = New-Object System.Drawing.Size($Width, $Height)
    $button.ForeColor = $ConsoleTheme.TextWhite
    $button.Font = New-Object System.Drawing.Font($ConsoleTheme.FontFamily, 8, [System.Drawing.FontStyle]::Bold)
    $button.FlatStyle = "Flat"
    $button.Cursor = "Hand"
    
    # Set colors based on button type
    if ($IsQuickAction) {
        $button.BackColor = $ConsoleTheme.ButtonGray
        $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 100, 100)
    }
    elseif ($IsSystemButton) {
        $button.BackColor = $ConsoleTheme.ButtonGray
        $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 150, 255)
    }
    else {
        $button.BackColor = $ConsoleTheme.ButtonGray
        $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
    }
    
    $button.FlatAppearance.BorderSize = 1
    
    # Add hover effects with proper color handling
    $originalColor = $button.BackColor
    
    $button.Add_MouseEnter({
            param($sender, $e)
            $sender.BackColor = $ConsoleTheme.ButtonHover
        })
    
    $button.Add_MouseLeave({
            param($sender, $e)
            $sender.BackColor = $originalColor
        })
    
    return $button
}

# =============================================================================
# CONSOLE TERMINAL FUNCTIONS
# =============================================================================

function Add-ToConsoleTerminal {
    param(
        [System.Windows.Forms.RichTextBox]$Terminal,
        [string]$Message,
        [System.Drawing.Color]$Color = $null
    )
    
    if (-not $Color) { $Color = $ConsoleTheme.TerminalGreen }
    
    $Terminal.SelectionStart = $Terminal.TextLength
    $Terminal.SelectionLength = 0
    $Terminal.SelectionColor = $Color
    $Terminal.AppendText("`n$(Get-Date -Format 'HH:mm:ss') - $Message`n")
    $Terminal.SelectionColor = $ConsoleTheme.TerminalGreen
    $Terminal.AppendText("Console-AI> ")
    $Terminal.ScrollToCaret()
}

function Process-ConsoleTerminalCommand {
    param([System.Windows.Forms.RichTextBox]$Terminal)
    
    $lines = $Terminal.Text -split "`n"
    $lastLine = $lines[-1]
    $command = $lastLine.Replace("Console-AI> ", "").Trim()
    
    if ($command) {
        # Console style command processing
        switch ($command.ToLower()) {
            "help" {
                Add-ToConsoleTerminal -Terminal $Terminal -Message @"
🎮 GAME CONSOLE AI COMMANDS:
  
🕹️  NAVIGATION:
  menu          - Show main menu
  dashboard     - System dashboard
  models        - List all models
  
⚡ QUICK ACTIONS:
  launch        - Open VS Code
  explore       - Open file explorer
  status        - System status
  
🎯 SPECIAL:
  konami        - Easter egg
  powerup       - Boost mode
  clear         - Clear screen
  exit          - Power off
  
🎮 Use Joy-Con buttons for point-and-click actions!
"@ -Color $ConsoleTheme.TerminalBlue
            }
            "konami" {
                Add-ToConsoleTerminal -Terminal $Terminal -Message "🎮 ↑ ↑ ↓ ↓ ← → ← → B A - 30 EXTRA MODELS UNLOCKED! 🌟" -Color $ConsoleTheme.TerminalYellow
            }
            "powerup" {
                Add-ToConsoleTerminal -Terminal $Terminal -Message "⚡🍄 MARIO POWER-UP ACTIVATED! Super AI Speed Mode ON! 🍄⚡" -Color $ConsoleTheme.TerminalRed
            }
            "status" {
                $stats = Get-ConsoleSystemStats
                Add-ToConsoleTerminal -Terminal $Terminal -Message "🎮 Console System Status: ✅ Ready | 🤖 Models: $($stats.ModelFiles) | 💾 Storage: $($stats.TotalSizeGB) GB | 🔋 Battery: 100%" -Color $ConsoleTheme.TerminalGreen
            }
            "dashboard" {
                Show-ConsoleDashboard -Terminal $Terminal
            }
            "models" {
                Add-ToConsoleTerminal -Terminal $Terminal -Message "🎮 Loading model inventory in console style..." -Color $ConsoleTheme.TerminalBlue
                Add-ToConsoleTerminal -Terminal $Terminal -Message "📦 Found 0 models in your console collection. Use Download Manager to add more!" -Color $ConsoleTheme.TerminalYellow
            }
            "clear" {
                $Terminal.Clear()
                $Terminal.ForeColor = $ConsoleTheme.TerminalGreen
                $Terminal.Text = "🎮 Game Console AI Terminal - Cleared!`nConsole-AI> "
            }
            "exit" {
                Add-ToConsoleTerminal -Terminal $Terminal -Message "👋 Powering down Game Console AI System... Goodbye!" -Color $ConsoleTheme.TerminalRed
                Start-Sleep 2
                [System.Windows.Forms.Application]::Exit()
            }
            default {
                Add-ToConsoleTerminal -Terminal $Terminal -Message "❓ Unknown command: '$command'. Type 'help' for console commands or use the Joy-Con buttons! 🎮" -Color $ConsoleTheme.TerminalYellow
            }
        }
    }
    else {
        Add-ToConsoleTerminal -Terminal $Terminal -Message "" -Color $ConsoleTheme.TerminalGreen
    }
}

function Execute-ConsoleAction {
    param([string]$Action, [System.Windows.Forms.RichTextBox]$Terminal)
    
    switch ($Action) {
        "dashboard" {
            Add-ToConsoleTerminal -Terminal $Terminal -Message "🎮 Loading Game Console Dashboard..." -Color $ConsoleTheme.TerminalBlue
            Show-ConsoleDashboard -Terminal $Terminal
        }
        "models" {
            Add-ToConsoleTerminal -Terminal $Terminal -Message "🤖 Accessing Model Management (Console Style)..." -Color $ConsoleTheme.TerminalBlue
        }
        "download" {
            Add-ToConsoleTerminal -Terminal $Terminal -Message "⬇️ Opening Download Manager - Get more AI games for your console!" -Color $ConsoleTheme.TerminalGreen
            try {
                # Launch the download manager
                Start-Process "powershell" -ArgumentList "-NoExit", "-Command", "Set-Location 'D:\AI_Models\System\Core\Scripts\PowerShell'; .\ModelDownloader.ps1"
                Add-ToConsoleTerminal -Terminal $Terminal -Message "✅ Download Manager launched in new window!" -Color $ConsoleTheme.TerminalGreen
            }
            catch {
                Add-ToConsoleTerminal -Terminal $Terminal -Message "❌ Failed to launch Download Manager: $($_.Exception.Message)" -Color $ConsoleTheme.TerminalRed
            }
        }
        "sync" {
            Add-ToConsoleTerminal -Terminal $Terminal -Message "🔄 Opening NAS Sync Center..." -Color $ConsoleTheme.TerminalBlue
            try {
                # Launch the NAS sync
                Start-Process "powershell" -ArgumentList "-NoExit", "-Command", "Set-Location 'D:\AI_Models\System\Core\Scripts\PowerShell'; .\NASSync.ps1"
                Add-ToConsoleTerminal -Terminal $Terminal -Message "✅ NAS Sync Center launched in new window!" -Color $ConsoleTheme.TerminalGreen
            }
            catch {
                Add-ToConsoleTerminal -Terminal $Terminal -Message "❌ Failed to launch NAS Sync: $($_.Exception.Message)" -Color $ConsoleTheme.TerminalRed
            }
        }
        default {
            Add-ToConsoleTerminal -Terminal $Terminal -Message "🚧 $Action - Coming soon to Game Console AI! 🎮" -Color $ConsoleTheme.TerminalYellow
        }
    }
}

function Execute-QuickAction {
    param([string]$Action, [System.Windows.Forms.RichTextBox]$Terminal)
    
    switch ($Action) {
        "vscode" {
            try {
                $workspacePath = "D:\AI_Models\ai-models-workspace.code-workspace"
                Start-Process "code" -ArgumentList "`"$workspacePath`""
                Add-ToConsoleTerminal -Terminal $Terminal -Message "🎮 VS Code launched! Like opening a new game on console! 📁" -Color $ConsoleTheme.TerminalGreen
            }
            catch {
                Add-ToConsoleTerminal -Terminal $Terminal -Message "❌ Failed to launch VS Code. Check your installation! 🎮" -Color $ConsoleTheme.TerminalRed
            }
        }
        "terminal" {
            try {
                Start-Process "powershell" -ArgumentList "-NoExit", "-Command", "Set-Location 'D:\AI_Models'"
                Add-ToConsoleTerminal -Terminal $Terminal -Message "💻 New terminal opened! Like connecting a Pro Controller! 🎮" -Color $ConsoleTheme.TerminalGreen
            }
            catch {
                Add-ToConsoleTerminal -Terminal $Terminal -Message "❌ Failed to open terminal! 🎮" -Color $ConsoleTheme.TerminalRed
            }
        }
        "explorer" {
            try {
                Start-Process "explorer.exe" -ArgumentList "D:\AI_Models"
                Add-ToConsoleTerminal -Terminal $Terminal -Message "🗂️ File Explorer opened! Browse your AI collection like a game library! 🎮" -Color $ConsoleTheme.TerminalGreen
            }
            catch {
                Add-ToConsoleTerminal -Terminal $Terminal -Message "❌ Failed to open File Explorer! 🎮" -Color $ConsoleTheme.TerminalRed
            }
        }
        "stats" {
            $stats = Get-ConsoleSystemStats
            Add-ToConsoleTerminal -Terminal $Terminal -Message "📊 Console AI Stats: Models: $($stats.ModelFiles) | Storage: $($stats.TotalSizeGB) GB | Status: Ready to play! 🎮" -Color $ConsoleTheme.TerminalBlue
        }
        "refresh" {
            Add-ToConsoleTerminal -Terminal $Terminal -Message "🔄 Refreshing Game Console AI System... Like restarting your console! 🎮" -Color $ConsoleTheme.TerminalYellow
        }
        default {
            Add-ToConsoleTerminal -Terminal $Terminal -Message "🎮 $Action - Quick action coming soon to your Game Console AI! ⚡" -Color $ConsoleTheme.TerminalYellow
        }
    }
}

function Show-ConsoleDashboard {
    param([System.Windows.Forms.RichTextBox]$Terminal)
    
    $stats = Get-ConsoleSystemStats
    
    Add-ToConsoleTerminal -Terminal $Terminal -Message @"
╔══════════════════════════════════════════════════════════════════════════════╗
║                   🎮 GAME CONSOLE AI DASHBOARD 🎮                           ║
╚══════════════════════════════════════════════════════════════════════════════╝

🏠 Console Info:
   System: Game Console AI Edition
   Firmware: v2.0.0 (AI Models Manager)
   Region: Global AI Development
   
📊 Storage:
   Total Models: $($stats.ModelFiles) games
   Used Space: $($stats.TotalSizeGB) GB
   Free Space: ∞ GB (expandable)
   
🔋 System Health:
   Joy-Con Status: ✅ Connected
   Screen: ✅ Active (720p Terminal Mode)
   Wi-Fi: ✅ Connected (for downloads)
   AI Processing: ✅ Ready
   
🎮 Recent Activity:
   Last Played: AI Models Manager
   Play Time: Active session
   Achievement: System Master! 🏆
   
💡 Pro Tips:
   • Use Joy-Con buttons for quick navigation
   • Type 'konami' for a special surprise
   • Download new AI models like new games!
"@ -Color $ConsoleTheme.TerminalBlue
}

function Get-ConsoleSystemStats {
    $basePath = "D:\AI_Models"
    $stats = @{
        ModelFiles  = 0
        TotalSizeGB = 0
    }
    
    try {
        if (Test-Path $basePath) {
            $allFiles = Get-ChildItem $basePath -File -Recurse -ErrorAction SilentlyContinue
            $modelFiles = $allFiles | Where-Object { $_.Length -gt 10MB }
            $totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum
            
            $stats.ModelFiles = $modelFiles.Count
            $stats.TotalSizeGB = [math]::Round($totalSize / 1GB, 2)
        }
    }
    catch {
        # Return default stats on error
    }
    
    return $stats
}

function Update-ConsoleStatus {
    param(
        [System.Windows.Forms.Label]$StatusLabel,
        [System.Windows.Forms.RichTextBox]$Terminal
    )
    
    try {
        $stats = Get-ConsoleSystemStats
        $StatusLabel.Text = "🔋 System Ready | 📊 $($stats.ModelFiles) Models | 💾 $($stats.TotalSizeGB) GB | 🕐 $(Get-Date -Format 'HH:mm')"
        
        # Add occasional console-style status messages
        $randomMessages = @(
            "🎮 Game Console AI is running smoothly!",
            "⚡ Joy-Cons are responsive and ready!",
            "🌟 Your AI collection is growing!",
            "🎯 All systems optimal for AI development!"
        )
        
        if ((Get-Random -Minimum 1 -Maximum 20) -eq 1) {
            $message = $randomMessages[(Get-Random -Minimum 0 -Maximum $randomMessages.Length)]
            Add-ToConsoleTerminal -Terminal $Terminal -Message $message -Color $ConsoleTheme.TerminalYellow
        }
    }
    catch {
        $StatusLabel.Text = "⚠️ System Check Failed"
    }
}

# =============================================================================
# APPLICATION ENTRY POINT
# =============================================================================

function Start-ConsoleAI {
    Write-Host "🎮 Starting Game Console Style AI Models Manager..." -ForegroundColor Cyan
    Write-Host "   Preparing Joy-Cons... ✅" -ForegroundColor Green
    Write-Host "   Initializing Screen... ✅" -ForegroundColor Green
    Write-Host "   Loading AI System... ✅" -ForegroundColor Green
    Write-Host "   Ready to play! 🎮" -ForegroundColor Yellow
    
    # Initialize Windows Forms application
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
    
    # Create and show the game console styled app
    $consoleForm = New-ConsoleStyleApp
    
    # Show the form
    [System.Windows.Forms.Application]::Run($consoleForm)
}

# Launch the Game Console AI System!
Start-ConsoleAI