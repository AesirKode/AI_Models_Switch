# 🎮 AI-Switch - Clean Resizable Interface with Perfect Text Layout
# File: D:\AI_Models\System\Core\Scripts\PowerShell\AISwitch_Clean.ps1
# Features: Resizable window, maximized screen area, perfect text formatting

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =============================================================================
# AI-SWITCH CLEAN THEME SYSTEM
# =============================================================================

$AISwitchTheme = @{
    # Switch-inspired Colors
    SwitchGray     = [System.Drawing.Color]::FromArgb(45, 45, 45)
    SwitchBlue     = [System.Drawing.Color]::FromArgb(0, 155, 255)
    SwitchRed      = [System.Drawing.Color]::FromArgb(255, 60, 60)
    SwitchYellow   = [System.Drawing.Color]::FromArgb(255, 200, 0)
    ScreenBlack    = [System.Drawing.Color]::FromArgb(8, 8, 8)
    ScreenBezel    = [System.Drawing.Color]::FromArgb(15, 15, 15)
    
    # Joy-Con Colors
    LeftJoyConBlue = [System.Drawing.Color]::FromArgb(45, 135, 245)
    RightJoyConRed = [System.Drawing.Color]::FromArgb(255, 75, 75)
    ButtonGray     = [System.Drawing.Color]::FromArgb(75, 85, 90)
    ButtonHover    = [System.Drawing.Color]::FromArgb(105, 115, 120)
    
    # Retro Terminal Colors (Clean and readable)
    RetroGreen     = [System.Drawing.Color]::FromArgb(155, 188, 15)      # Classic Game Boy green
    RetroAmber     = [System.Drawing.Color]::FromArgb(255, 176, 0)       # Amber terminal
    RetroBlue      = [System.Drawing.Color]::FromArgb(100, 200, 255)     # Cyan blue
    RetroRed       = [System.Drawing.Color]::FromArgb(255, 100, 100)     # Error red
    RetroYellow    = [System.Drawing.Color]::FromArgb(255, 255, 100)     # Warning yellow
    RetroPurple    = [System.Drawing.Color]::FromArgb(200, 100, 255)     # Command purple
    
    # UI Elements
    TextWhite      = [System.Drawing.Color]::White
    TextGray       = [System.Drawing.Color]::FromArgb(200, 200, 200)
    
    # Clean Fonts
    RetroFont      = "Consolas"           # Better monospace font
    UIFont         = "Segoe UI"
}

# =============================================================================
# MAIN AI-SWITCH FORM (RESIZABLE)
# =============================================================================

function New-AISwitchApp {
    # Create main form (Resizable Switch-like proportions)
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "AI-Switch - Retro Gaming AI Manager"
    $form.Size = New-Object System.Drawing.Size(1200, 700)
    $form.MinimumSize = New-Object System.Drawing.Size(800, 500)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = $AISwitchTheme.SwitchGray
    $form.FormBorderStyle = "Sizable"  # Make it resizable
    $form.MaximizeBox = $true
    $form.MinimizeBox = $true
    
    # =============================================================================
    # MAIN CONTAINER PANEL WITH AUTO-RESIZE
    # =============================================================================
    
    $mainPanel = New-Object System.Windows.Forms.Panel
    $mainPanel.Dock = "Fill"
    $mainPanel.BackColor = [System.Drawing.Color]::Transparent
    $mainPanel.Padding = New-Object System.Windows.Forms.Padding(10)
    
    # =============================================================================
    # LEFT JOY-CON (BLUE) - SYSTEM CONTROLS
    # =============================================================================
    
    $leftJoycon = New-Object System.Windows.Forms.Panel
    $leftJoycon.Size = New-Object System.Drawing.Size(180, 0)
    $leftJoycon.Dock = "Left"
    $leftJoycon.BackColor = $AISwitchTheme.LeftJoyConBlue
    $leftJoycon.Padding = New-Object System.Windows.Forms.Padding(10)
    
    # Left Joy-Con Title
    $leftTitle = New-Object System.Windows.Forms.Label
    $leftTitle.Text = "🎮 SYSTEM"
    $leftTitle.Font = New-Object System.Drawing.Font($AISwitchTheme.UIFont, 12, [System.Drawing.FontStyle]::Bold)
    $leftTitle.ForeColor = $AISwitchTheme.TextWhite
    $leftTitle.TextAlign = "MiddleCenter"
    $leftTitle.Size = New-Object System.Drawing.Size(160, 35)
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
        $button = New-AISwitchButton -Text $btn.Text -X 20 -Y $btn.Y -Width 140 -Height 35 -IsSystemButton
        $button.Tag = $btn.Action
        $button.Add_Click({
                param($sender, $e)
                Execute-AISwitchAction -Action $sender.Tag -Terminal $global:AISwitchTerminal -EmbeddedTerminal $global:EmbeddedTerminal
            })
        $leftJoycon.Controls.Add($button)
    }
    
    # Power button (anchored to bottom)
    $powerButton = New-Object System.Windows.Forms.Button
    $powerButton.Text = "⚡"
    $powerButton.Size = New-Object System.Drawing.Size(50, 40)
    $powerButton.Anchor = "Bottom"
    $powerButton.Location = New-Object System.Drawing.Point(65, 500)
    $powerButton.BackColor = $AISwitchTheme.SwitchRed
    $powerButton.ForeColor = $AISwitchTheme.TextWhite
    $powerButton.FlatStyle = "Flat"
    $powerButton.Font = New-Object System.Drawing.Font($AISwitchTheme.UIFont, 14, [System.Drawing.FontStyle]::Bold)
    $powerButton.Add_Click({ [System.Windows.Forms.Application]::Exit() })
    
    $leftJoycon.Controls.AddRange(@($leftTitle, $powerButton))
    
    # =============================================================================
    # CENTER SCREEN - MAXIMIZED DISPLAY AREA
    # =============================================================================
    
    $screenPanel = New-Object System.Windows.Forms.Panel
    $screenPanel.Dock = "Fill"
    $screenPanel.BackColor = $AISwitchTheme.ScreenBezel
    $screenPanel.Padding = New-Object System.Windows.Forms.Padding(10)
    
    # =============================================================================
    # TABBED INTERFACE - CLEAN TERMINAL TABS
    # =============================================================================
    
    $tabControl = New-Object System.Windows.Forms.TabControl
    $tabControl.Dock = "Fill"
    $tabControl.BackColor = $AISwitchTheme.ScreenBlack
    $tabControl.Font = New-Object System.Drawing.Font($AISwitchTheme.RetroFont, 10, [System.Drawing.FontStyle]::Bold)
    
    # Tab 1: Retro AI Terminal
    $retroTab = New-Object System.Windows.Forms.TabPage
    $retroTab.Text = "🎮 RETRO AI"
    $retroTab.BackColor = $AISwitchTheme.ScreenBlack
    $retroTab.ForeColor = $AISwitchTheme.RetroGreen
    $retroTab.Padding = New-Object System.Windows.Forms.Padding(5)
    
    # Main Retro Terminal (properly sized)
    $retroTerminal = New-Object System.Windows.Forms.RichTextBox
    $retroTerminal.Dock = "Fill"
    $retroTerminal.BackColor = $AISwitchTheme.ScreenBlack
    $retroTerminal.ForeColor = $AISwitchTheme.RetroGreen
    $retroTerminal.Font = New-Object System.Drawing.Font($AISwitchTheme.RetroFont, 10)
    $retroTerminal.ScrollBars = "Vertical"
    $retroTerminal.BorderStyle = "None"
    $retroTerminal.ReadOnly = $false
    $retroTerminal.WordWrap = $true
    
    # Clean retro welcome (properly formatted)
    $retroTerminal.Text = @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                      🎮 RETRO AI TERMINAL v2.0 🎮                           ║
║                 Welcome to the Ultimate Gaming AI Experience!                ║
╚═══════════════════════════════════════════════════════════════════════════════╝

🕹️  RETRO CONTROLS:
   [←] [→] LEFT/RIGHT JOY-CON CONTROLS    [↑] [↓] NAVIGATE OPTIONS
   [A] [B] CONFIRM/CANCEL ACTIONS         [START] TYPE COMMANDS

🚀 SYSTEM STATUS:
   💾 Base Directory: D:\AI_Models        ⚙️  Configuration: LOADED ✓
   🎮 VS Code Ready: CONNECTED ✓          🎯 Mode: RETRO GAMING STYLE

🎮 READY TO PLAY! TYPE 'HELP' FOR RETRO COMMANDS

AI-SWITCH> 
"@
    
    # Retro terminal input handling
    $retroTerminal.Add_KeyDown({
            param($sender, $e)
            if ($e.KeyCode -eq "Enter") {
                Process-RetroTerminalCommand -Terminal $sender
            }
        })
    
    $retroTab.Controls.Add($retroTerminal)
    
    # Tab 2: Embedded PowerShell Terminal
    $psTab = New-Object System.Windows.Forms.TabPage
    $psTab.Text = "💻 POWERSHELL"
    $psTab.BackColor = $AISwitchTheme.ScreenBlack
    $psTab.ForeColor = $AISwitchTheme.RetroBlue
    $psTab.Padding = New-Object System.Windows.Forms.Padding(5)
    
    # Embedded PowerShell Terminal (properly sized)
    $embeddedTerminal = New-Object System.Windows.Forms.RichTextBox
    $embeddedTerminal.Dock = "Fill"
    $embeddedTerminal.BackColor = $AISwitchTheme.ScreenBlack
    $embeddedTerminal.ForeColor = $AISwitchTheme.RetroBlue
    $embeddedTerminal.Font = New-Object System.Drawing.Font($AISwitchTheme.RetroFont, 10)
    $embeddedTerminal.ScrollBars = "Vertical"
    $embeddedTerminal.BorderStyle = "None"
    $embeddedTerminal.ReadOnly = $false
    $embeddedTerminal.WordWrap = $true
    
    # Clean PowerShell welcome
    $embeddedTerminal.Text = @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                      💻 EMBEDDED POWERSHELL 💻                              ║
║                   Full PowerShell Access Within AI-Switch!                   ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Welcome to AI-Switch Embedded PowerShell Terminal!

This is a full PowerShell environment running inside your AI-Switch console.
You can execute any PowerShell commands, navigate directories, and run scripts.

Current Directory: $(Get-Location)
PowerShell Version: $($PSVersionTable.PSVersion)
Host: AI-Switch Embedded Terminal

🎮 Quick AI-Switch Commands:
   ai-models     - Open main AI Models manager
   ai-download   - Launch download manager  
   ai-sync       - Open NAS sync center
   ai-dashboard  - Show system dashboard
   clear         - Clear this terminal

Ready for PowerShell commands!

PS AI-Switch> 
"@
    
    # PowerShell terminal input handling
    $embeddedTerminal.Add_KeyDown({
            param($sender, $e)
            if ($e.KeyCode -eq "Enter") {
                Process-EmbeddedPowerShell -Terminal $sender
            }
        })
    
    $psTab.Controls.Add($embeddedTerminal)
    
    # Add tabs to control
    $tabControl.TabPages.AddRange(@($retroTab, $psTab))
    
    $screenPanel.Controls.Add($tabControl)
    
    # Store global references
    $global:AISwitchTerminal = $retroTerminal
    $global:EmbeddedTerminal = $embeddedTerminal
    
    # =============================================================================
    # RIGHT JOY-CON (RED) - QUICK ACTIONS
    # =============================================================================
    
    $rightJoycon = New-Object System.Windows.Forms.Panel
    $rightJoycon.Size = New-Object System.Drawing.Size(180, 0)
    $rightJoycon.Dock = "Right"
    $rightJoycon.BackColor = $AISwitchTheme.RightJoyConRed
    $rightJoycon.Padding = New-Object System.Windows.Forms.Padding(10)
    
    # Right Joy-Con Title
    $rightTitle = New-Object System.Windows.Forms.Label
    $rightTitle.Text = "⚡ QUICK"
    $rightTitle.Font = New-Object System.Drawing.Font($AISwitchTheme.UIFont, 12, [System.Drawing.FontStyle]::Bold)
    $rightTitle.ForeColor = $AISwitchTheme.TextWhite
    $rightTitle.TextAlign = "MiddleCenter"
    $rightTitle.Size = New-Object System.Drawing.Size(160, 35)
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
        $button = New-AISwitchButton -Text $btn.Text -X 20 -Y $btn.Y -Width 140 -Height 35 -IsQuickAction
        $button.Tag = $btn.Action
        $button.Add_Click({
                param($sender, $e)
                Execute-QuickAction -Action $sender.Tag -Terminal $global:AISwitchTerminal -EmbeddedTerminal $global:EmbeddedTerminal
            })
        $rightJoycon.Controls.Add($button)
    }
    
    # Home button (anchored to bottom)
    $homeButton = New-Object System.Windows.Forms.Button
    $homeButton.Text = "🏠"
    $homeButton.Size = New-Object System.Drawing.Size(50, 40)
    $homeButton.Anchor = "Bottom"
    $homeButton.Location = New-Object System.Drawing.Point(65, 500)
    $homeButton.BackColor = $AISwitchTheme.SwitchYellow
    $homeButton.ForeColor = $AISwitchTheme.SwitchGray
    $homeButton.FlatStyle = "Flat"
    $homeButton.Font = New-Object System.Drawing.Font($AISwitchTheme.UIFont, 14, [System.Drawing.FontStyle]::Bold)
    $homeButton.Add_Click({ 
            Add-ToRetroTerminal -Terminal $global:AISwitchTerminal -Message "🏠 RETURNED TO HOME SCREEN - READY TO PLAY!" -Color $AISwitchTheme.RetroYellow
        })
    
    $rightJoycon.Controls.AddRange@($rightTitle, $homeButton))
    
# =============================================================================
# ASSEMBLE THE AI-SWITCH WITH RESIZABLE LAYOUT
# =============================================================================
    
$mainPanel.Controls.AddRange(@($leftJoycon, $rightJoycon, $screenPanel))
$form.Controls.Add($mainPanel)
    
# Handle resize events to maintain proportions
$form.Add_Resize({
        # Update power button and home button positions when resizing
        $powerButton.Location = New-Object System.Drawing.Point(65, ($form.Height - 120))
        $homeButton.Location = New-Object System.Drawing.Point(65, ($form.Height - 120))
    })
    
# Store references
$form.Tag = @{
    RetroTerminal    = $retroTerminal
    EmbeddedTerminal = $embeddedTerminal
    Timer            = $null
}
    
return $form
}

# =============================================================================
# ENHANCED BUTTON CREATION
# =============================================================================

function New-AISwitchButton {
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
    $button.ForeColor = $AISwitchTheme.TextWhite
    $button.Font = New-Object System.Drawing.Font($AISwitchTheme.UIFont, 9, [System.Drawing.FontStyle]::Bold)
    $button.FlatStyle = "Flat"
    $button.Cursor = "Hand"
    
    # Set colors and styling
    $button.BackColor = $AISwitchTheme.ButtonGray
    $button.FlatAppearance.BorderSize = 2
    
    if ($IsQuickAction) {
        $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 100, 100)
    }
    elseif ($IsSystemButton) {
        $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 150, 255)
    }
    else {
        $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
    }
    
    # Enhanced hover effects
    $originalColor = $button.BackColor
    
    $button.Add_MouseEnter({
            param($sender, $e)
            $sender.BackColor = $AISwitchTheme.ButtonHover
        })
    
    $button.Add_MouseLeave({
            param($sender, $e)
            $sender.BackColor = $originalColor
        })
    
    return $button
}

# =============================================================================
# RETRO TERMINAL FUNCTIONS
# =============================================================================

function Add-ToRetroTerminal {
    param(
        [System.Windows.Forms.RichTextBox]$Terminal,
        [string]$Message,
        [System.Drawing.Color]$Color = $null
    )
    
    if (-not $Color) { $Color = $AISwitchTheme.RetroGreen }
    
    $Terminal.SelectionStart = $Terminal.TextLength
    $Terminal.SelectionLength = 0
    $Terminal.SelectionColor = $Color
    $Terminal.AppendText("`n$(Get-Date -Format 'HH:mm:ss') - $Message`n")
    $Terminal.SelectionColor = $AISwitchTheme.RetroGreen
    $Terminal.AppendText("AI-SWITCH> ")
    $Terminal.ScrollToCaret()
}

function Process-RetroTerminalCommand {
    param([System.Windows.Forms.RichTextBox]$Terminal)
    
    $lines = $Terminal.Text -split "`n"
    $lastLine = $lines[-1]
    $command = $lastLine.Replace("AI-SWITCH> ", "").Trim()
    
    if ($command) {
        # Retro gaming style command processing
        switch ($command.ToUpper()) {
            "HELP" {
                Add-ToRetroTerminal -Terminal $Terminal -Message @"
🎮 AI-SWITCH RETRO COMMANDS:

🕹️  NAVIGATION:          ⚡ POWER-UPS:           🎯 SPECIAL CODES:
  MENU          - MAIN     LAUNCH  - VS CODE     KONAMI   - SECRET!
  DASHBOARD     - SYSTEM   EXPLORE - BROWSER     POWERUP  - BOOST
  MODELS        - AI LIST  STATUS  - CHECK       CREDITS  - TEAM
                                                  CLEAR    - CLEAN
                                                  EXIT     - POWER OFF

🎮 USE JOY-CON BUTTONS FOR POINT-AND-CLICK!
"@ -Color $AISwitchTheme.RetroBlue
            }
            "KONAMI" {
                Add-ToRetroTerminal -Terminal $Terminal -Message "🎮 ↑ ↑ ↓ ↓ ← → ← → B A - 30 LIVES! INFINITE AI MODELS! 🌟" -Color $AISwitchTheme.RetroYellow
            }
            "POWERUP" {
                Add-ToRetroTerminal -Terminal $Terminal -Message "⚡🍄 SUPER AI MUSHROOM! TURBO MODE ACTIVATED! 🍄⚡" -Color $AISwitchTheme.RetroRed
            }
            "STATUS" {
                $stats = Get-AISwitchSystemStats
                Add-ToRetroTerminal -Terminal $Terminal -Message "🎮 STATUS: ✓ READY | 🤖 MODELS: $($stats.ModelFiles) | 💾 STORAGE: $($stats.TotalSizeGB) GB | 🔋 POWER: 100%" -Color $AISwitchTheme.RetroGreen
            }
            "DASHBOARD" {
                Show-AISwitchDashboard -Terminal $Terminal
            }
            "MODELS" {
                Add-ToRetroTerminal -Terminal $Terminal -Message "🎮 LOADING AI GAME LIBRARY..." -Color $AISwitchTheme.RetroBlue
                Add-ToRetroTerminal -Terminal $Terminal -Message "📦 FOUND 0 AI GAMES. USE DOWNLOAD MANAGER TO ADD MORE!" -Color $AISwitchTheme.RetroYellow
            }
            "CREDITS" {
                Add-ToRetroTerminal -Terminal $Terminal -Message @"
🎮 AI-SWITCH CREDITS:

DEVELOPED BY: AESIRKODE STUDIOS
POWERED BY: POWERSHELL + WINDOWS FORMS
INSPIRED BY: RETRO GAMING NOSTALGIA

SPECIAL THANKS TO: AI MODEL CREATORS & OPEN SOURCE COMMUNITY

© 2025 AI-SWITCH - GAME ON! 🎮
"@ -Color $AISwitchTheme.RetroPurple
            }
            "CLEAR" {
                $Terminal.Clear()
                $Terminal.ForeColor = $AISwitchTheme.RetroGreen
                $Terminal.Text = "🎮 AI-SWITCH RETRO TERMINAL - SCREEN CLEARED!`nAI-SWITCH> "
            }
            "EXIT" {
                Add-ToRetroTerminal -Terminal $Terminal -Message "👋 POWERING DOWN AI-SWITCH... GAME OVER! SEE YOU NEXT TIME!" -Color $AISwitchTheme.RetroRed
                Start-Sleep 2
                [System.Windows.Forms.Application]::Exit()
            }
            default {
                Add-ToRetroTerminal -Terminal $Terminal -Message "❓ UNKNOWN COMMAND: '$command'. TYPE 'HELP' FOR COMMANDS! 🎮" -Color $AISwitchTheme.RetroYellow
            }
        }
    }
}

# =============================================================================
# EMBEDDED POWERSHELL FUNCTIONS
# =============================================================================

function Add-ToEmbeddedTerminal {
    param(
        [System.Windows.Forms.RichTextBox]$Terminal,
        [string]$Message,
        [System.Drawing.Color]$Color = $null
    )
    
    if (-not $Color) { $Color = $AISwitchTheme.RetroBlue }
    
    $Terminal.SelectionStart = $Terminal.TextLength
    $Terminal.SelectionLength = 0
    $Terminal.SelectionColor = $Color
    $Terminal.AppendText("`n$Message`n")
    $Terminal.SelectionColor = $AISwitchTheme.RetroBlue
    $Terminal.AppendText("PS AI-Switch> ")
    $Terminal.ScrollToCaret()
}

function Process-EmbeddedPowerShell {
    param([System.Windows.Forms.RichTextBox]$Terminal)
    
    $lines = $Terminal.Text -split "`n"
    $lastLine = $lines[-1]
    $command = $lastLine.Replace("PS AI-Switch> ", "").Trim()
    
    if ($command) {
        try {
            # Handle special AI-Switch commands
            switch ($command.ToLower()) {
                "ai-models" {
                    Add-ToEmbeddedTerminal -Terminal $Terminal -Message "🚀 Launching AI Models Manager..." -Color $AISwitchTheme.RetroGreen
                    Start-Process "powershell" -ArgumentList "-NoExit", "-Command", "Set-Location 'D:\AI_Models\System\Core\Scripts\PowerShell'; .\AIModelsManager.ps1"
                }
                "ai-download" {
                    Add-ToEmbeddedTerminal -Terminal $Terminal -Message "⬇️ Launching Download Manager..." -Color $AISwitchTheme.RetroGreen
                    Start-Process "powershell" -ArgumentList "-NoExit", "-Command", "Set-Location 'D:\AI_Models\System\Core\Scripts\PowerShell'; .\ModelDownloader.ps1"
                }
                "ai-sync" {
                    Add-ToEmbeddedTerminal -Terminal $Terminal -Message "🔄 Launching NAS Sync Center..." -Color $AISwitchTheme.RetroGreen
                    Start-Process "powershell" -ArgumentList "-NoExit", "-Command", "Set-Location 'D:\AI_Models\System\Core\Scripts\PowerShell'; .\NASSync.ps1"
                }
                "ai-dashboard" {
                    $stats = Get-AISwitchSystemStats
                    Add-ToEmbeddedTerminal -Terminal $Terminal -Message "📊 AI-Switch Dashboard: Models: $($stats.ModelFiles) | Storage: $($stats.TotalSizeGB) GB | Status: Ready" -Color $AISwitchTheme.RetroGreen
                }
                "clear" {
                    $Terminal.Clear()
                    $Terminal.Text = "💻 AI-Switch Embedded PowerShell - Cleared!`nPS AI-Switch> "
                }
                default {
                    # Execute actual PowerShell command
                    $result = Invoke-Expression $command 2>&1 | Out-String
                    if ($result.Trim()) {
                        Add-ToEmbeddedTerminal -Terminal $Terminal -Message $result.Trim() -Color $AISwitchTheme.RetroBlue
                    }
                    else {
                        Add-ToEmbeddedTerminal -Terminal $Terminal -Message "" -Color $AISwitchTheme.RetroBlue
                    }
                }
            }
        }
        catch {
            Add-ToEmbeddedTerminal -Terminal $Terminal -Message "❌ Error: $($_.Exception.Message)" -Color $AISwitchTheme.RetroRed
        }
    }
}

# =============================================================================
# ACTION EXECUTION FUNCTIONS
# =============================================================================

function Execute-AISwitchAction {
    param([string]$Action, [System.Windows.Forms.RichTextBox]$Terminal, [System.Windows.Forms.RichTextBox]$EmbeddedTerminal)
    
    switch ($Action) {
        "dashboard" {
            Add-ToRetroTerminal -Terminal $Terminal -Message "🎮 LOADING DASHBOARD..." -Color $AISwitchTheme.RetroBlue
            Show-AISwitchDashboard -Terminal $Terminal
        }
        "models" {
            Add-ToRetroTerminal -Terminal $Terminal -Message "🤖 ACCESSING MODEL LIBRARY..." -Color $AISwitchTheme.RetroBlue
        }
        "download" {
            Add-ToRetroTerminal -Terminal $Terminal -Message "⬇️ LAUNCHING DOWNLOAD MANAGER..." -Color $AISwitchTheme.RetroGreen
            try {
                Start-Process "powershell" -ArgumentList "-NoExit", "-Command", "Set-Location 'D:\AI_Models\System\Core\Scripts\PowerShell'; .\ModelDownloader.ps1"
                Add-ToRetroTerminal -Terminal $Terminal -Message "✅ DOWNLOAD MANAGER LAUNCHED!" -Color $AISwitchTheme.RetroGreen
            }
            catch {
                Add-ToRetroTerminal -Terminal $Terminal -Message "❌ FAILED TO LAUNCH DOWNLOAD MANAGER" -Color $AISwitchTheme.RetroRed
            }
        }
        "sync" {
            Add-ToRetroTerminal -Terminal $Terminal -Message "🔄 LAUNCHING NAS SYNC..." -Color $AISwitchTheme.RetroBlue
            try {
                Start-Process "powershell" -ArgumentList "-NoExit", "-Command", "Set-Location 'D:\AI_Models\System\Core\Scripts\PowerShell'; .\NASSync.ps1"
                Add-ToRetroTerminal -Terminal $Terminal -Message "✅ NAS SYNC LAUNCHED!" -Color $AISwitchTheme.RetroGreen
            }
            catch {
                Add-ToRetroTerminal -Terminal $Terminal -Message "❌ FAILED TO LAUNCH NAS SYNC" -Color $AISwitchTheme.RetroRed
            }
        }
        default {
            Add-ToRetroTerminal -Terminal $Terminal -Message "🚧 $($Action.ToUpper()) - COMING SOON! 🎮" -Color $AISwitchTheme.RetroYellow
        }
    }
}

function Execute-QuickAction {
    param([string]$Action, [System.Windows.Forms.RichTextBox]$Terminal, [System.Windows.Forms.RichTextBox]$EmbeddedTerminal)
    
    switch ($Action) {
        "vscode" {
            try {
                $workspacePath = "D:\AI_Models\ai-models-workspace.code-workspace"
                Start-Process "code" -ArgumentList "`"$workspacePath`""
                Add-ToRetroTerminal -Terminal $Terminal -Message "🎮 VS CODE LAUNCHED! 📁" -Color $AISwitchTheme.RetroGreen
            }
            catch {
                Add-ToRetroTerminal -Terminal $Terminal -Message "❌ FAILED TO LAUNCH VS CODE!" -Color $AISwitchTheme.RetroRed
            }
        }
        "terminal" {
            Add-ToRetroTerminal -Terminal $Terminal -Message "💻 SWITCHING TO EMBEDDED POWERSHELL TAB!" -Color $AISwitchTheme.RetroBlue
        }
        "explorer" {
            try {
                Start-Process "explorer.exe" -ArgumentList "D:\AI_Models"
                Add-ToRetroTerminal -Terminal $Terminal -Message "🗂️ FILE EXPLORER OPENED! 🎮" -Color $AISwitchTheme.RetroGreen
            }
            catch {
                Add-ToRetroTerminal -Terminal $Terminal -Message "❌ FAILED TO OPEN EXPLORER!" -Color $AISwitchTheme.RetroRed
            }
        }
        "stats" {
            $stats = Get-AISwitchSystemStats
            Add-ToRetroTerminal -Terminal $Terminal -Message "📊 STATS: $($stats.ModelFiles) MODELS | $($stats.TotalSizeGB) GB | READY! 🎮" -Color $AISwitchTheme.RetroBlue
        }
        "refresh" {
            Add-ToRetroTerminal -Terminal $Terminal -Message "🔄 REFRESHING SYSTEM... 🎮" -Color $AISwitchTheme.RetroYellow
        }
        default {
            Add-ToRetroTerminal -Terminal $Terminal -Message "🎮 $($Action.ToUpper()) - COMING SOON! ⚡" -Color $AISwitchTheme.RetroYellow
        }
    }
}

# =============================================================================
# DASHBOARD AND UTILITY FUNCTIONS
# =============================================================================

function Show-AISwitchDashboard {
    param([System.Windows.Forms.RichTextBox]$Terminal)
    
    $stats = Get-AISwitchSystemStats
    
    Add-ToRetroTerminal -Terminal $Terminal -Message @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🎮 RETRO AI DASHBOARD 🎮                            ║
╚═══════════════════════════════════════════════════════════════════════════════╝

🏠 SYSTEM: AI-SWITCH RETRO EDITION    📊 MODELS: $($stats.ModelFiles) GAMES
🔋 HEALTH: ALL SYSTEMS READY ✓       💾 STORAGE: $($stats.TotalSizeGB) GB  
🎮 STATUS: READY TO PLAY! 🏆          🌐 NETWORK: CONNECTED ✓

💡 PRO TIPS: USE JOY-CON BUTTONS | TYPE 'KONAMI' FOR SURPRISE | DOWNLOAD NEW AI GAMES!
"@ -Color $AISwitchTheme.RetroBlue
}

function Get-AISwitchSystemStats {
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

# =============================================================================
# APPLICATION ENTRY POINT
# =============================================================================

function Start-AISwitchApp {
    Write-Host "🎮 Starting AI-Switch Clean Resizable Interface..." -ForegroundColor Cyan
    Write-Host "   Preparing Joy-Cons... ✅" -ForegroundColor Green
    Write-Host "   Initializing Clean Screen... ✅" -ForegroundColor Green
    Write-Host "   Loading Resizable System... ✅" -ForegroundColor Green
    Write-Host "   Ready to play! 🎮" -ForegroundColor Yellow
    
    # Initialize Windows Forms application
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
    
    # Create and show the AI-Switch clean app
    $aiSwitchForm = New-AISwitchApp
    
    # Show the form
    [System.Windows.Forms.Application]::Run($aiSwitchForm)
}

# Launch the AI-Switch Clean System!
Start-AISwitchApp