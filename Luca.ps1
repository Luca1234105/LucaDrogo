Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# COLORI
$colorFormBack = [System.Drawing.Color]::FromArgb(30,30,30)
$colorText = [System.Drawing.Color]::White
$colorButton = [System.Drawing.Color]::FromArgb(60,63,65)
$colorButtonHover = [System.Drawing.Color]::FromArgb(75,110,175)

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

# FUNZIONI PREESISTENTI
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
        "MSTeams"
    )
    foreach ($app in $apps) {
        Remove-AppxPackageSafe -PackageName $app
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

# FUNZIONI PER I TOGGLE PICCOLI
function Invoke-WinUtilDarkMode {
    try {
        $Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        $current = Get-ItemPropertyValue -Path $Path -Name AppsUseLightTheme -ErrorAction SilentlyContinue
        if ($null -eq $current) { $current = 1 }
        $newValue = if ($current -eq 0) { 1 } else { 0 }
        Set-ItemProperty -Path $Path -Name AppsUseLightTheme -Value $newValue
        Set-ItemProperty -Path $Path -Name SystemUsesLightTheme -Value $newValue
        $msg = if ($newValue -eq 0) { "Dark Mode attivata." } else { "Dark Mode disattivata." }
        [System.Windows.Forms.MessageBox]::Show($msg, "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Errore nel toggle Dark Mode: $($_.Exception.Message)","Errore",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Invoke-WinUtilTaskbarSearch {
    try {
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
        $current = Get-ItemPropertyValue -Path $Path -Name SearchboxTaskbarMode -ErrorAction SilentlyContinue
        if ($null -eq $current) { $current = 1 }
        # Valori possibili: 0=nascondi, 1=mostra icona, 2=mostra barra di ricerca
        $newValue = if ($current -eq 0) { 1 } else { 0 }
        Set-ItemProperty -Path $Path -Name SearchboxTaskbarMode -Value $newValue
        $msg = if ($newValue -eq 0) { "Taskbar Search disattivata." } else { "Taskbar Search attivata." }
        [System.Windows.Forms.MessageBox]::Show($msg, "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Errore nel toggle Taskbar Search: $($_.Exception.Message)","Errore",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Toggle-CustomVisualEffects {
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0)) -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show("UserPreferencesMask impostato con successo.","Info",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Errore durante l'impostazione di UserPreferencesMask:`n$($_.Exception.Message)","Errore",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}



# CREAZIONE FORM
$form = New-Object System.Windows.Forms.Form
$form.Text = "Luca Tweaks"
$form.Size = New-Object System.Drawing.Size(650, 600)
$form.StartPosition = "CenterScreen"
$form.BackColor = $colorFormBack
$form.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Regular)

# POSIZIONE BOTTONI GRANDI
$startX = 30
$startY = 30
$spacingY = 55

# Pulsanti grandi con le funzioni preesistenti
$btnRemoveApps = New-Button "Rimuovi App Microsoft Inutili" ([System.Drawing.Point]::new($startX, $startY))
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

$btnRemoveEdge = New-Button "Rimuovi Microsoft Edge" ([System.Drawing.Point]::new($startX, $startY + $spacingY*4))
$btnRemoveEdge.Add_Click({ Remove-Edge })
$form.Controls.Add($btnRemoveEdge)

$btnDisableServices = New-Button "Disattiva Servizi" ([System.Drawing.Point]::new($startX, $startY + $spacingY*5))
$btnDisableServices.Add_Click({ Invoke-DisattivaServizi })
$form.Controls.Add($btnDisableServices)

# PICCOLI PULSANTI TOGGLE (separati) posizionati a destra, per esempio
$smallStartX = 460
$smallStartY = 40
$smallSpacingY = 50

$btnToggleDarkMode = New-SmallButton "Toggle Dark Mode" ([System.Drawing.Point]::new($smallStartX, $smallStartY))
$btnToggleDarkMode.Add_Click({ Invoke-WinUtilDarkMode })
$form.Controls.Add($btnToggleDarkMode)

$btnToggleTaskbarSearch = New-SmallButton "Toggle Taskbar Search" ([System.Drawing.Point]::new($smallStartX, $smallStartY + $smallSpacingY))
$btnToggleTaskbarSearch.Add_Click({ Invoke-WinUtilTaskbarSearch })
$form.Controls.Add($btnToggleTaskbarSearch)

$btnToggleCustomVisuals = New-SmallButton "Toggle Visual FX" ([System.Drawing.Point]::new($smallStartX, $smallStartY + $smallSpacingY*2))
$btnToggleCustomVisuals.Add_Click({ Toggle-CustomVisualEffects })
$form.Controls.Add($btnToggleCustomVisuals)


# MOSTRA FORM
[void]$form.ShowDialog()
