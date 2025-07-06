Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# COLORI
$colorFormBack = [System.Drawing.Color]::FromArgb(30,30,30)
$colorText = [System.Drawing.Color]::White
$colorButton = [System.Drawing.Color]::FromArgb(60,63,65)
$colorButtonHover = [System.Drawing.Color]::FromArgb(75,110,175)
$colorSidebar = [System.Drawing.Color]::FromArgb(40,40,40)

# FUNZIONE CREAZIONE PULSANTI GRANDI CON HOVER
function New-Button($text, $location) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Width = 200
    $btn.Height = 45
    $btn.Location = $location
    $btn.BackColor = $colorButton
    $btn.ForeColor = $colorText
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderSize = 0
    $btn.Cursor = 'Hand'

    $btn.Add_MouseEnter({ param($sender,$e) $sender.BackColor = $colorButtonHover })
    $btn.Add_MouseLeave({ param($sender,$e) $sender.BackColor = $colorButton })

    return $btn
}

# FUNZIONE CREAZIONE PULSANTI PICCOLI CON HOVER (toggle)
function New-SmallButton($text, $location) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Width = 120
    $btn.Height = 40
    $btn.Location = $location
    $btn.BackColor = $colorButton
    $btn.ForeColor = $colorText
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderSize = 0
    $btn.Cursor = 'Hand'

    $btn.Add_MouseEnter({ param($sender,$e) $sender.BackColor = $colorButtonHover })
    $btn.Add_MouseLeave({ param($sender,$e) $sender.BackColor = $colorButton })

    return $btn
}

# FUNZIONI PRINCIPALI

function Remove-AppxPackageSafe {
    param([string]$PackageName)
    try {
        Write-Host "Rimuovo $PackageName ..."
        Get-AppxPackage -AllUsers -Name $PackageName | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like "$PackageName*" } | Remove-AppxProvisionedPackage -Online
        Write-Host "$PackageName rimosso."
    } catch {
        Write-Host "Errore nella rimozione di $PackageName"
    }
}

function Remove-MicrosoftApps {
    $apps = @(
        "Clipchamp.Clipchamp",
        "Microsoft.BingNews",
        "Microsoft.BingSearch",
        "Microsoft.BingWeather",
        "Microsoft.GamingApp",
        "Microsoft.GetHelp",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MicrosoftStickyNotes",
        "Microsoft.OutlookForWindows",
        "Microsoft.Paint",
        "Microsoft.PowerAutomateDesktop",
        "Microsoft.ScreenSketch",
        "Microsoft.Todos",
        "Microsoft.Windows.DevHome",
        "Microsoft.WindowsCamera",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsSoundRecorder",
        "Microsoft.WindowsTerminal",
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.YourPhone",
        "Microsoft.ZuneMusic",
        "MicrosoftCorporationII.QuickAssist",
        "MSTeams",
        "Microsoft.WindowsAlarms"    # <-- Aggiunto Orologio
    )
    foreach ($app in $apps) {
        try {
            Get-AppxPackage -AllUsers -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue
        } catch {}
    }
    [System.Windows.Forms.MessageBox]::Show("Rimozione app Microsoft completata!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

function Remove-OneDrive {
    Write-Host "Rimuovo OneDrive..."
    taskkill /f /im OneDrive.exe > $null 2>&1
    if (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe") {
        & "$env:SystemRoot\System32\OneDriveSetup.exe" /uninstall
    }
    if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
        & "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" /uninstall
    }
    robocopy "$env:USERPROFILE\OneDrive" "$env:USERPROFILE" /mov /e /xj /ndl /nfl /njh /njs /nc /ns /np | Out-Null
    reg delete "HKEY_CLASSES_ROOT\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f | Out-Null
    reg delete "HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f | Out-Null
    Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" -Force -ErrorAction SilentlyContinue
    powershell -Command "Get-ScheduledTask -TaskPath '\' -TaskName 'OneDrive*' -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:\$false" | Out-Null
    Remove-Item "$env:UserProfile\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LocalAppData\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LocalAppData\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\OneDrive" /f | Out-Null
    [System.Windows.Forms.MessageBox]::Show("OneDrive rimosso con successo!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

function Disable-Copilot {
    Write-Host "Disabilito Copilot..."
    Get-AppxPackage Microsoft.CoPilot | Remove-AppxPackage -ErrorAction SilentlyContinue
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "AutoOpenCopilotLargeScreens" /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\Shell\Copilot\BingChat" /v "IsUserEligible" /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "HubsSidebarEnabled" /t REG_DWORD /d 0 /f | Out-Null
    [System.Windows.Forms.MessageBox]::Show("Copilot disabilitato!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

function Remove-Widgets {
    Write-Host "Rimuovo Widgets..."
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f | Out-Null
    Get-AppxPackage *WebExperience* | Remove-AppxPackage -ErrorAction SilentlyContinue
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy" /f | Out-Null
    [System.Windows.Forms.MessageBox]::Show("Widgets rimossi!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

function Remove-Edge {
    Write-Host "Rimuovo Microsoft Edge Chromium..."
    $script = (New-Object Net.WebClient).DownloadString('https://cdn.jsdelivr.net/gh/he3als/EdgeRemover@main/get.ps1')
    $sb = [ScriptBlock]::Create($script)
    & $sb -UninstallEdge
    [System.Windows.Forms.MessageBox]::Show("Microsoft Edge rimosso!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

function Invoke-DisattivaServizi {
    $batContent = '@echo off
:: Elevazione automatica se non è già admin
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if ''%errorlevel%'' NEQ ''0'' (
    echo Richiesta dei privilegi amministrativi...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
cls
color 1f
echo Disattivazione di tutti i servizi in corso...

for %%S in (
    vmicguestinterface
    vmicvss
    vmicshutdown
    vmicheartbeat
    vmicvmsession
    vmickvpexchange
    vmictimesync
    vmicrdv
    RasAuto
    workfolderssvc
    RasMan
    DusmSvc
    UmRdpService
    LanmanServer
    TermService
    SensorDataService
    RetailDemo
    ScDeviceEnum
    RmSvc
    SensrSvc
    PhoneSvc
    SCardSvr
    TapiSrv
    WSearch
    LanmanWorkstation
    MapsBroker
    SensorService
    lfsvc
    PcaSvc
    SCPolicySvc
    seclogon
    SmsRouter
    wisvc
    StiSvc
    CscService
    WdiSystemHost
    HvHost
    SysMain
    XblAuthManager
    XblGameSave
    XboxNetApiSvc
    XboxGipSvc
    SessionEnv
    WpcMonSvc
    DiagTrack
    SEMgrSvc
    MicrosoftEdgeElevationService
    edgeupdate
    edgeupdatem
    CryptSvc
    BDESVC
    WbioSrvc
    bthserv
    BTAGService
    PrintNotify
    WMPNetworkSvc
    wercplsupport
    wcncsvc
) do (
    sc config %%S start= disabled
)

echo.
echo Tutti i servizi selezionati sono stati disattivati.
echo Riavvia il sistema per applicare le modifiche.
pause
exit'

    $tempBat = [System.IO.Path]::Combine($env:TEMP, "DisattivaServizi.bat")
    [System.IO.File]::WriteAllText($tempBat, $batContent)
    Start-Process -FilePath $tempBat -Verb RunAs
}

function Invoke-WinUtilDarkMode {
    try {
        $Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        $current = Get-ItemPropertyValue -Path $Path -Name AppsUseLightTheme -ErrorAction SilentlyContinue
        if ($null -eq $current) { $current = 1 }
        $newValue = if ($current -eq 0) { 1 } else { 0 }
        Set-ItemProperty -Path $Path -Name AppsUseLightTheme -Value $newValue
        Set-ItemProperty -Path $Path -Name SystemUsesLightTheme -Value $newValue
        $msg = if ($newValue -eq 0) { "Dark Mode attivata." } else { "Dark Mode disattivata." }
        [System.Windows.Forms.MessageBox]::Show($msg)
    } catch { [System.Windows.Forms.MessageBox]::Show("Errore: $($_.Exception.Message)") }
}

function Invoke-WinUtilTaskbarSearch {
    try {
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
        $current = Get-ItemPropertyValue -Path $Path -Name SearchboxTaskbarMode -ErrorAction SilentlyContinue
        if ($null -eq $current) { $current = 1 }
        $newValue = if ($current -eq 0) { 1 } else { 0 }
        Set-ItemProperty -Path $Path -Name SearchboxTaskbarMode -Value $newValue
        $msg = if ($newValue -eq 0) { "Taskbar Search disattivata." } else { "Taskbar Search attivata." }
        [System.Windows.Forms.MessageBox]::Show($msg)
    } catch { [System.Windows.Forms.MessageBox]::Show("Errore: $($_.Exception.Message)") }
}

function Toggle-CustomVisualEffects {
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0))
        [System.Windows.Forms.MessageBox]::Show("Visual FX impostato.")
    } catch { [System.Windows.Forms.MessageBox]::Show("Errore: $($_.Exception.Message)") }
}

function Invoke-DisableCEIPAndBlockDrivers {
    $script = @"
@echo off
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo Esegui questo script COME AMMINISTRATORE!
    pause
    exit /b
)

reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v CEIPEnable /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v ExcludeWUDriversInQualityUpdate /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v SearchOrderConfig /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" /v PreventDeviceMetadataFromNetwork /t REG_DWORD /d 1 /f

echo Modifiche al registro applicate correttamente.
pause
"@

    $tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "tempDisableCEIPDrivers.bat")
    $script | Out-File -FilePath $tempFile -Encoding ASCII
    Start-Process -FilePath $tempFile -Verb RunAs
}

function Toggle-ShowTaskViewButton {
    try {
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $path -Name "ShowTaskViewButton" -Value 0 -Force
        [System.Windows.Forms.MessageBox]::Show("Pulsante Vista attività disabilitato!")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Errore: $_")
    }
}

# CREA FORM PRINCIPALE
$form = New-Object System.Windows.Forms.Form
$form.Text = "Luca Tweaks"
$form.Size = New-Object System.Drawing.Size(760,480)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'Sizable'
$form.MaximizeBox = $true
$form.MinimizeBox = $true
$form.BackColor = $colorFormBack

# SIDEBAR
$sidebar = New-Object System.Windows.Forms.Panel
$sidebar.Size = New-Object System.Drawing.Size(160, $form.ClientSize.Height)
$sidebar.Location = New-Object System.Drawing.Point(0,0)
$sidebar.BackColor = $colorSidebar
$form.Controls.Add($sidebar)

# ETICHETTA SIDEBAR
$labelSidebar = New-Object System.Windows.Forms.Label
$labelSidebar.Text = "Toggles"
$labelSidebar.ForeColor = $colorText
$labelSidebar.BackColor = $sidebar.BackColor
$labelSidebar.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$labelSidebar.AutoSize = $true
$labelSidebar.Location = New-Object System.Drawing.Point(20,15)
$sidebar.Controls.Add($labelSidebar)

# POSIZIONI PULSANTI
$startX = 180
$startY = 30
$spacingY = 55

$smallStartX = 20
$smallStartY = 50
$smallSpacingY = 50

# PULSANTI GRANDI
$btnRemoveApps = New-Button "Rimuovi App Microsoft" ([System.Drawing.Point]::new($startX, $startY))
$btnRemoveApps.Add_Click({ Remove-MicrosoftApps })
$form.Controls.Add($btnRemoveApps)

$btnRemoveOneDrive = New-Button "Rimuovi OneDrive" ([System.Drawing.Point]::new($startX, $startY + $spacingY))
$btnRemoveOneDrive.Add_Click({ Remove-OneDrive })
$form.Controls.Add($btnRemoveOneDrive)

$btnDisableCopilot = New-Button "Disabilita Copilot" ([System.Drawing.Point]::new($startX, $startY + $spacingY*2))
$btnDisableCopilot.Add_Click({ Disable-Copilot })
$form.Controls.Add($btnDisableCopilot)

$btnRemoveWidgets = New-Button "Rimuovi Widgets" ([System.Drawing.Point]::new($startX, $startY + $spacingY*3))
$btnRemoveWidgets.Add_Click({ Remove-Widgets })
$form.Controls.Add($btnRemoveWidgets)

$btnRemoveEdge = New-Button "Rimuovi Edge" ([System.Drawing.Point]::new($startX, $startY + $spacingY*4))
$btnRemoveEdge.Add_Click({ Remove-Edge })
$form.Controls.Add($btnRemoveEdge)

$btnDisableServices = New-Button "Disattiva Servizi" ([System.Drawing.Point]::new($startX, $startY + $spacingY*5))
$btnDisableServices.Add_Click({ Invoke-DisattivaServizi })
$form.Controls.Add($btnDisableServices)

$btnBlockCEIPDrivers = New-Button "Blocca CEIP & Driver" ([System.Drawing.Point]::new($startX, $startY + $spacingY*6))
$btnBlockCEIPDrivers.Add_Click({ Invoke-DisableCEIPAndBlockDrivers })
$form.Controls.Add($btnBlockCEIPDrivers)

# TOGGLE NELLA SIDEBAR
$btnToggleDarkMode = New-SmallButton "Toggle Dark Mode" ([System.Drawing.Point]::new($smallStartX, $smallStartY))
$btnToggleDarkMode.Add_Click({ Invoke-WinUtilDarkMode })
$sidebar.Controls.Add($btnToggleDarkMode)

$btnToggleTaskbarSearch = New-SmallButton "Taskbar Search" ([System.Drawing.Point]::new($smallStartX, $smallStartY + $smallSpacingY))
$btnToggleTaskbarSearch.Add_Click({ Invoke-WinUtilTaskbarSearch })
$sidebar.Controls.Add($btnToggleTaskbarSearch)

$btnToggleVisualFX = New-SmallButton "Toggle Visual FX" ([System.Drawing.Point]::new($smallStartX, $smallStartY + $smallSpacingY*2))
$btnToggleVisualFX.Add_Click({ Toggle-CustomVisualEffects })
$sidebar.Controls.Add($btnToggleVisualFX)

$btnToggleShowTaskView = New-SmallButton "Disabilita Vista attività" ([System.Drawing.Point]::new($smallStartX, $smallStartY + $smallSpacingY*3))
$btnToggleShowTaskView.Add_Click({ Toggle-ShowTaskViewButton })
$sidebar.Controls.Add($btnToggleShowTaskView)

# MOSTRA FORM
[void]$form.ShowDialog()
