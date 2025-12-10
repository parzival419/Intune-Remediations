# --------------------------- Config ---------------------------
$OrgName              = "NR TECHteam"
$HeroImageUri         = "https://stnormreevespublic001.blob.core.windows.net/intune/NR Tech Team PFP - 1.png"
$LocalImageRoot       = Join-Path $env:LOCALAPPDATA "NRTechTeam\images"
$LocalHeroImagePath   = Join-Path $LocalImageRoot  "NR Tech Team PFP - 1.png"

# Deferrals (per-user)
$RegistryBase         = "HKCU:\Software\NRTechTeam\RebootPrompt"
$MaxDeferrals         = 2
$DeferralSleepSeconds = 2.5 * 60 * 60   # 2.5 hours
$ForcedRebootSeconds  = 900             # 15 minutes

# ---------------------- Ensure STA (WinForms needs it) ----------------------
if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    Write-Output "Re-launching remediation in STA…"
    $exe = (Get-Command powershell.exe).Source
    $args = "-NoProfile -ExecutionPolicy Bypass -STA -File `"$PSCommandPath`""
    Start-Process -FilePath $exe -ArgumentList $args
    exit
}

# ---------------------- Uptime helper ----------------------
function Get-UptimeSpan {
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $raw = $os.LastBootUpTime
        if ($raw -is [DateTime]) { $lastBoot = $raw }
        elseif ($raw -is [string] -and $raw.Length -ge 8) {
            $lastBoot = [Management.ManagementDateTimeConverter]::ToDateTime($raw)
        } else { throw "Unexpected LastBootUpTime type: $($raw.GetType().FullName)" }
        return (Get-Date) - $lastBoot
    } catch {
        try {
            $perf = Get-CimInstance -Class Win32_PerfFormattedData_PerfOS_System -ErrorAction Stop
            $seconds = [double]$perf.SystemUpTime
            if ($seconds -gt 0) { return (New-TimeSpan -Seconds $seconds) }
            throw "Perf SystemUpTime invalid: $seconds"
        } catch { return $null }
    }
}

# -------------------- Deferral state (HKCU) -------------------
function Get-DeferralState {
    if (-not (Test-Path $RegistryBase)) {
        New-Item -Path $RegistryBase -Force | Out-Null
        New-ItemProperty -Path $RegistryBase -Name "DeferralCount"   -Value 0 -PropertyType DWord  -Force | Out-Null
        New-ItemProperty -Path $RegistryBase -Name "FirstPromptTime" -Value (Get-Date).ToString("o") -PropertyType String -Force | Out-Null
    }
    @{
        Count           = (Get-ItemProperty -Path $RegistryBase -Name DeferralCount   -ErrorAction SilentlyContinue).DeferralCount
        FirstPromptTime = (Get-ItemProperty -Path $RegistryBase -Name FirstPromptTime -ErrorAction SilentlyContinue).FirstPromptTime
    }
}

function Set-DeferralCount([int]$count) {
    New-Item -Path $RegistryBase -Force | Out-Null
    New-ItemProperty -Path $RegistryBase -Name "DeferralCount" -Value $count -PropertyType DWord -Force | Out-Null
    if ($count -eq 0) {
        New-ItemProperty -Path $RegistryBase -Name "FirstPromptTime" -Value (Get-Date).ToString("o") -PropertyType String -Force | Out-Null
    }
}

# ---------------------- Assets (user-writable) ----------------
function Ensure-HeroImage {
    try {
        if (-not (Test-Path $LocalImageRoot)) { New-Item -ItemType Directory -Path $LocalImageRoot -Force | Out-Null }
        if (-not (Test-Path $LocalHeroImagePath -PathType Leaf)) {
            Invoke-WebRequest -Uri $HeroImageUri -OutFile $LocalHeroImagePath -UseBasicParsing -ErrorAction Stop
        }
    } catch { }
}

# ---------------------- Popup (WinForms) ----------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-RebootPopup {
    param(
        [string]$Title,
        [string]$Message,
        [string]$ImagePath,
        [switch]$Final
    )

    $form = New-Object Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object Drawing.Size(400, 450)
    $form.StartPosition = 'CenterScreen'
    $form.TopMost = $true
    $form.BackColor = [System.Drawing.Color]::White
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    # Image banner (hero)
    if ($ImagePath -and (Test-Path $ImagePath -PathType Leaf)) {
        $pic = New-Object Windows.Forms.PictureBox
        $pic.Image = [System.Drawing.Image]::FromFile($ImagePath)
        $pic.SizeMode = 'StretchImage'
        $pic.Dock = 'Top'
        $pic.Height = 200
        $form.Controls.Add($pic)
    }

    # Buttons panel (bottom)
    $panel = New-Object Windows.Forms.FlowLayoutPanel
    $panel.Dock = 'Bottom'
    $panel.Height = 100
    $panel.FlowDirection = 'RightToLeft'
    $panel.Padding = New-Object System.Windows.Forms.Padding(10,10,10,10)
    $panel.BackColor = [System.Drawing.Color]::White
    $form.Controls.Add($panel)

    $btnReboot = New-Object Windows.Forms.Button
    $btnReboot.Text = 'Reboot Now'
    $btnReboot.Width = 100
    $btnReboot.Add_Click({
        Start-Process -FilePath "$env:SystemRoot\System32\shutdown.exe" -ArgumentList '/r /t 5 /c "NR TECHteam: Restarting to complete critical updates…"' -WindowStyle Hidden
        $form.Close()
    })
    $panel.Controls.Add($btnReboot)

    if (-not $Final) {
        $btnDismiss = New-Object Windows.Forms.Button
        $btnDismiss.Text = 'Dismiss'
        $btnDismiss.Width = 120
        $btnDismiss.Add_Click({ $form.Close() })
        $panel.Controls.Add($btnDismiss)
    }

    # Message (middle) — Option 1: Label with reliable wrapping/rendering
    $lbl = New-Object Windows.Forms.Label
    $lbl.Dock = 'Fill'
    $lbl.AutoSize = $false                    # allow it to fill the middle space
    $lbl.Padding = New-Object System.Windows.Forms.Padding(20, 10, 20, 10)
    $lbl.TextAlign = 'MiddleCenter'
    $lbl.Font = New-Object Drawing.Font('Segoe UI', 11)
    $lbl.UseCompatibleTextRendering = $true   # better GDI+ text rendering and wrapping
    $lbl.BackColor = [System.Drawing.Color]::White
    $lbl.ForeColor = [System.Drawing.Color]::Black
    $lbl.AutoEllipsis = $true
    $lbl.Text = $Message
    $form.Controls.Add($lbl)

    # Keyboard defaults
    $form.AcceptButton = $btnReboot
    if (-not $Final) { $form.CancelButton = $btnDismiss }

    # Show modal
    $form.ShowDialog() | Out-Null
}

# ------------------------------ Main ---------------------------
# Only proceed if uptime >= 10 hours (keeps behavior aligned with detection)
$uptime = Get-UptimeSpan
if ($uptime -and $uptime.TotalHours -lt 10) {
    Write-Output ("Remediation (user): Uptime {0:dd\.hh\:mm} < 10 hours—no action." -f $uptime)
    exit 0
}

Ensure-HeroImage

# Deferrals
$state         = Get-DeferralState
$deferralCount = [int]$state.Count
$deferralsLeft = $MaxDeferrals - $deferralCount
Write-Output    "Remediation (user): DeferralCount=$deferralCount, DeferralsLeft=$deferralsLeft"

# Progressive popups with deferrals
if ($deferralCount -lt $MaxDeferrals) {
    $msg = "A reboot is required! You have $deferralsLeft deferral(s) left.`r`n`r`nSelect 'Dismiss' to delay or 'Reboot Now' to restart."
    Show-RebootPopup -Title $OrgName -Message $msg -ImagePath $LocalHeroImagePath
    Start-Sleep -Seconds $DeferralSleepSeconds
    $deferralCount++
    Set-DeferralCount -count $deferralCount
    Write-Output "Remediation (user): Incremented deferral count to $deferralCount."
    exit 0
}

# Final popup, then forced reboot countdown
Write-Output "Remediation (user): Max deferrals reached—final popup and restart countdown."
$finalMsg = "You must reboot now. No more deferrals remain.`r`n`r`nA restart will begin in $([math]::Round($ForcedRebootSeconds/60))s—please save your work."
Show-RebootPopup -Title $OrgName -Message $finalMsg -ImagePath $LocalHeroImagePath -Final
Start-Process -FilePath "$env:SystemRoot\System32\shutdown.exe" -ArgumentList "/r /t $ForcedRebootSeconds /c `"NR TECHteam: Restarting to complete critical updates. Please save your work.`"" -WindowStyle Hidden
exit 0
