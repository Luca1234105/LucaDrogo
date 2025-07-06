Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# COLORI
$colorFormBack = [System.Drawing.Color]::FromArgb(30,30,30)
$colorText = [System.Drawing.Color]::White
$colorButton = [System.Drawing.Color]::FromArgb(60,63,65)
$colorButtonHover = [System.Drawing.Color]::FromArgb(75,110,175)

# FUNZIONE CREAZIONE PULSANTI CON HOVER
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

    $btn.Add_MouseEnter({
        param($sender, $e)
        $sender.BackColor = $colorButtonHover
    })
    $btn.Add_MouseLeave({
        param($sender, $e)
        $sender.BackColor = $colorButton
    })

    return $btn
}

# FUNZIONE PER RIMUOVERE APPX
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

# FUNZIONI AZIONI

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


Add-Type -AssemblyName System.Windows.Forms




# CREAZIONE FORM

$form = New-Object System.Windows.Forms.Form
$form.Text = "Luca Tweaks - Debloat Windows"
$form.Size = New-Object System.Drawing.Size(450,700)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.BackColor = $colorFormBack

# Titolo
$labelTitle = New-Object System.Windows.Forms.Label
$labelTitle.Text = "Scegli cosa rimuovere o disabilitare:"
$labelTitle.ForeColor = $colorText
$labelTitle.Font = New-Object System.Drawing.Font("Segoe UI",14,[System.Drawing.FontStyle]::Bold)
$labelTitle.AutoSize = $true
$labelTitle.Location = New-Object System.Drawing.Point(10,10)
$form.Controls.Add($labelTitle)

# Pulsanti

$btnRemoveApps = New-Button "Rimuovi app Microsoft preinstallate" (New-Object System.Drawing.Point(120,60))
$form.Controls.Add($btnRemoveApps)
$btnRemoveApps.Add_Click({ Remove-MicrosoftApps })

$btnRemoveOneDrive = New-Button "Disinstalla OneDrive" (New-Object System.Drawing.Point(120,120))
$form.Controls.Add($btnRemoveOneDrive)
$btnRemoveOneDrive.Add_Click({ Remove-OneDrive })

$btnDisableCopilot = New-Button "Disabilita Copilot" (New-Object System.Drawing.Point(120,180))
$form.Controls.Add($btnDisableCopilot)
$btnDisableCopilot.Add_Click({ Disable-Copilot })

$btnRemoveWidgets = New-Button "Rimuovi Widgets" (New-Object System.Drawing.Point(120,240))
$form.Controls.Add($btnRemoveWidgets)
$btnRemoveWidgets.Add_Click({ Remove-Widgets })

$btnRemoveEdge = New-Button "Disinstalla Microsoft Edge" (New-Object System.Drawing.Point(120,300))
$form.Controls.Add($btnRemoveEdge)
$btnRemoveEdge.Add_Click({ Remove-Edge })

$btnDisableServices = New-Button "Disattiva Servizi" (New-Object System.Drawing.Point(120,360))
$form.Controls.Add($btnDisableServices)
$btnDisableServices.Add_Click({ Invoke-DisattivaServizi })

$btnApplyRegTweaks = New-Button "Applica Modifiche Registro Sicurezza" (New-Object System.Drawing.Point(120, 420))
$form.Controls.Add($btnApplyRegTweaks)
$btnApplyRegTweaks.Add_Click({ Apply-RegistryTweaks })


# Mostra finestra
[void]$form.ShowDialog()
