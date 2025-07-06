Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# COLORI
$colorFormBack = [System.Drawing.Color]::FromArgb(30,30,30)
$colorSidebar = [System.Drawing.Color]::FromArgb(40,40,40)
$colorText = [System.Drawing.Color]::White
$colorButton = [System.Drawing.Color]::FromArgb(60,63,65)
$colorButtonHover = [System.Drawing.Color]::FromArgb(75,110,175)

# CREAZIONE FORM
$form = New-Object System.Windows.Forms.Form
$form.Text = "Luca Tweaks"
$form.Size = New-Object System.Drawing.Size(700, 580)
$form.StartPosition = "CenterScreen"
$form.BackColor = $colorFormBack
$form.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Regular)

# FUNZIONE CREAZIONE PULSANTI GRANDI CON HOVER
function New-Button($text, $location) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Size = New-Object System.Drawing.Size(240, 45)
    $btn.Location = $location
    $btn.BackColor = $colorButton
    $btn.ForeColor = $colorText
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderSize = 0
    $btn.Cursor = 'Hand'
    $btn.Add_MouseEnter({ param($s,$e) $s.BackColor = $colorButtonHover })
    $btn.Add_MouseLeave({ param($s,$e) $s.BackColor = $colorButton })
    return $btn
}

# FUNZIONE CREAZIONE PULSANTI PICCOLI TOGGLE
function New-SmallButton($text, $location) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Size = New-Object System.Drawing.Size(120, 40)
    $btn.Location = $location
    $btn.BackColor = $colorButton
    $btn.ForeColor = $colorText
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderSize = 0
    $btn.Cursor = 'Hand'
    $btn.Add_MouseEnter({ param($s,$e) $s.BackColor = $colorButtonHover })
    $btn.Add_MouseLeave({ param($s,$e) $s.BackColor = $colorButton })
    return $btn
}

# SIDEBAR
$sidebar = New-Object System.Windows.Forms.Panel
$sidebar.Size = New-Object System.Drawing.Size(160, $form.ClientSize.Height)
$sidebar.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - 160), 0)
$sidebar.BackColor = $colorSidebar
$form.Controls.Add($sidebar)

# ETICHETTA TOGGLE
$labelToggles = New-Object System.Windows.Forms.Label
$labelToggles.Text = "Toggles"
$labelToggles.ForeColor = $colorText
$labelToggles.BackColor = $colorSidebar
$labelToggles.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$labelToggles.AutoSize = $true
$labelToggles.Location = New-Object System.Drawing.Point(20, 15)
$sidebar.Controls.Add($labelToggles)

# POSIZIONI
$startX = 30; $startY = 30; $spacingY = 55
$smallStartX = 20; $smallStartY = 50; $smallSpacingY = 50

# FUNZIONI DI SISTEMA
function Remove-MicrosoftApps {
    $apps = @(
        "Clipchamp.Clipchamp","Microsoft.BingNews","Microsoft.BingSearch","Microsoft.BingWeather",
        "Microsoft.GamingApp","Microsoft.GetHelp","Microsoft.MicrosoftOfficeHub","Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MicrosoftStickyNotes","Microsoft.OutlookForWindows","Microsoft.Paint","Microsoft.PowerAutomateDesktop",
        "Microsoft.ScreenSketch","Microsoft.Todos","Microsoft.Windows.DevHome","Microsoft.WindowsCamera",
        "Microsoft.WindowsFeedbackHub","Microsoft.WindowsSoundRecorder","Microsoft.WindowsTerminal",
        "Microsoft.Xbox.TCUI","Microsoft.XboxGamingOverlay","Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay","Microsoft.YourPhone","Microsoft.ZuneMusic",
        "MicrosoftCorporationII.QuickAssist","MSTeams"
    )
    foreach ($app in $apps) {
        Get-AppxPackage -AllUsers -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like "$app*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
    [System.Windows.Forms.MessageBox]::Show("App Microsoft rimosse!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

function Remove-OneDrive {
    taskkill /f /im OneDrive.exe > $null 2>&1
    $setupPaths = @("$env:SystemRoot\System32\OneDriveSetup.exe", "$env:SystemRoot\SysWOW64\OneDriveSetup.exe")
    foreach ($path in $setupPaths) {
        if (Test-Path $path) { & $path /uninstall }
    }
    Remove-Item "$env:UserProfile\OneDrive","$env:LocalAppData\OneDrive","$env:LocalAppData\Microsoft\OneDrive","$env:ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    reg delete "HKCU\Software\Microsoft\OneDrive" /f | Out-Null
    [System.Windows.Forms.MessageBox]::Show("OneDrive rimosso!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

function Disable-Copilot {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "HubsSidebarEnabled" /t REG_DWORD /d 0 /f | Out-Null
    [System.Windows.Forms.MessageBox]::Show("Copilot disabilitato!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

function Remove-Widgets {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f | Out-Null
    Get-AppxPackage *WebExperience* | Remove-AppxPackage -ErrorAction SilentlyContinue
    [System.Windows.Forms.MessageBox]::Show("Widgets rimossi!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

function Remove-Edge {
    $url = 'https://cdn.jsdelivr.net/gh/he3als/EdgeRemover@main/get.ps1'
    try {
        $script = (New-Object Net.WebClient).DownloadString($url)
        $sb = [ScriptBlock]::Create($script)
        & $sb -UninstallEdge
        [System.Windows.Forms.MessageBox]::Show("Edge rimosso!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Errore rimozione Edge: $_")
    }
}

function Invoke-DisattivaServizi {
    $servizi = @"
@echo off
for %%S in (
vmicguestinterface vmicvss vmicshutdown vmicheartbeat vmicvmsession vmickvpexchange vmictimesync vmicrdv RasAuto RasMan
workfolderssvc DusmSvc UmRdpService LanmanServer TermService SensorDataService RetailDemo ScDeviceEnum RmSvc
SensrSvc PhoneSvc SCardSvr TapiSrv WSearch LanmanWorkstation MapsBroker SensorService lfsvc PcaSvc SCPolicySvc
seclogon SmsRouter wisvc StiSvc CscService WdiSystemHost HvHost SysMain XblAuthManager XblGameSave XboxNetApiSvc
XboxGipSvc SessionEnv WpcMonSvc DiagTrack SEMgrSvc MicrosoftEdgeElevationService edgeupdate edgeupdatem CryptSvc
BDESVC WbioSrvc bthserv BTAGService PrintNotify WMPNetworkSvc wercplsupport wcncsvc
) do sc config %%S start= disabled
"@
    $path = "$env:TEMP\disable_services.bat"
    $servizi | Set-Content -Encoding ASCII -Path $path
    Start-Process -FilePath $path -Verb RunAs
}

# TOGGLE: DARK MODE
function Invoke-WinUtilDarkMode {
    $key = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $current = Get-ItemPropertyValue -Path $key -Name AppsUseLightTheme -ErrorAction SilentlyContinue
    if ($null -eq $current) { $current = 1 }
    $newValue = if ($current -eq 0) { 1 } else { 0 }
    Set-ItemProperty -Path $key -Name AppsUseLightTheme -Value $newValue
    Set-ItemProperty -Path $key -Name SystemUsesLightTheme -Value $newValue
    $msg = if ($newValue -eq 0) { "Dark Mode attivata." } else { "Dark Mode disattivata." }
    [System.Windows.Forms.MessageBox]::Show($msg)
}

# TOGGLE: TASKBAR SEARCH
function Invoke-WinUtilTaskbarSearch {
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    $value = Get-ItemPropertyValue -Path $path -Name SearchboxTaskbarMode -ErrorAction SilentlyContinue
    if ($null -eq $value) { $value = 1 }
    $newValue = if ($value -eq 0) { 1 } else { 0 }
    Set-ItemProperty -Path $path -Name SearchboxTaskbarMode -Value $newValue
    $msg = if ($newValue -eq 0) { "Taskbar Search disattivata." } else { "Taskbar Search attivata." }
    [System.Windows.Forms.MessageBox]::Show($msg)
}

# TOGGLE: VISUAL FX
function Toggle-CustomVisualEffects {
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0))
    [System.Windows.Forms.MessageBox]::Show("Visual FX impostato.")
}

# AGGIUNGI PULSANTI GRANDI
$form.Controls.Add((New-Button "Rimuovi App Microsoft" ([System.Drawing.Point]::new($startX, $startY)))                  ); $form.Controls[$form.Controls.Count-1].Add_Click({ Remove-MicrosoftApps })
$form.Controls.Add((New-Button "Rimuovi OneDrive" ([System.Drawing.Point]::new($startX, $startY + $spacingY)))           ); $form.Controls[$form.Controls.Count-1].Add_Click({ Remove-OneDrive })
$form.Controls.Add((New-Button "Disabilita Copilot" ([System.Drawing.Point]::new($startX, $startY + $spacingY*2)))       ); $form.Controls[$form.Controls.Count-1].Add_Click({ Disable-Copilot })
$form.Controls.Add((New-Button "Rimuovi Widgets" ([System.Drawing.Point]::new($startX, $startY + $spacingY*3)))          ); $form.Controls[$form.Controls.Count-1].Add_Click({ Remove-Widgets })
$form.Controls.Add((New-Button "Rimuovi Edge" ([System.Drawing.Point]::new($startX, $startY + $spacingY*4)))             ); $form.Controls[$form.Controls.Count-1].Add_Click({ Remove-Edge })
$form.Controls.Add((New-Button "Disattiva Servizi" ([System.Drawing.Point]::new($startX, $startY + $spacingY*5)))        ); $form.Controls[$form.Controls.Count-1].Add_Click({ Invoke-DisattivaServizi })

# AGGIUNGI TOGGLE NELLA SIDEBAR
$sidebar.Controls.Add((New-SmallButton "Dark Mode" ([System.Drawing.Point]::new($smallStartX, $smallStartY)))             ); $sidebar.Controls[$sidebar.Controls.Count-1].Add_Click({ Invoke-WinUtilDarkMode })
$sidebar.Controls.Add((New-SmallButton "Search Taskbar" ([System.Drawing.Point]::new($smallStartX, $smallStartY + $smallSpacingY))) ); $sidebar.Controls[$sidebar.Controls.Count-1].Add_Click({ Invoke-WinUtilTaskbarSearch })
$sidebar.Controls.Add((New-SmallButton "Visual FX" ([System.Drawing.Point]::new($smallStartX, $smallStartY + $smallSpacingY*2)))     ); $sidebar.Controls[$sidebar.Controls.Count-1].Add_Click({ Toggle-CustomVisualEffects })

# MOSTRA FORM
[void]$form.ShowDialog()
