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


function Apply-RegistryTweaks {
    # === DWORD Settings ===
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Type DWord -Value 0x4000000
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "HubMode" -Type DWord -Value 1

    # === Transparency Off
    $themePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    if (-not (Test-Path $themePath)) { New-Item -Path $themePath -Force | Out-Null }
    Set-ItemProperty -Path $themePath -Name "EnableTransparency" -Type DWord -Value 0

    # === Sticky/Toggle Keys
    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type String -Value "2"
    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\ToggleKeys" -Name "Flags" -Type String -Value "34"

    # === No Low Disk Space Notification
    $lowDiskPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    if (-not (Test-Path $lowDiskPath)) { New-Item -Path $lowDiskPath -Force | Out-Null }
    Set-ItemProperty -Path $lowDiskPath -Name "NoLowDiskSpaceChecks" -Type DWord -Value 1

    # === ShakeMinimize
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ShakeMinimizeWindows" -Type String -Value "0"

    # === Content Delivery e SyncProvider
    $cdm = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    if (-not (Test-Path $cdm)) { New-Item -Path $cdm -Force | Out-Null }
    Set-ItemProperty -Path $cdm -Name "RotatingLockScreenOverlayEnabled" -Type DWord -Value 0

    $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (-not (Test-Path $adv)) { New-Item -Path $adv -Force | Out-Null }
    Set-ItemProperty -Path $adv -Name "ShowSyncProviderNotifications" -Type DWord -Value 0
    Set-ItemProperty -Path $adv -Name "ShowCastToDevice" -Type DWord -Value 0

    # === Nascondi Consigliati menu Start
    $policyPaths = @(
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start",
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Education",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
    )
    foreach ($path in $policyPaths) {
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    }
    Set-ItemProperty -Path $policyPaths[0] -Name "HideRecommendedSection" -Type DWord -Value 1
    Set-ItemProperty -Path $policyPaths[1] -Name "IsEducationEnvironment" -Type DWord -Value 1
    Set-ItemProperty -Path $policyPaths[2] -Name "HideRecommendedSection" -Type DWord -Value 1

    # === Error Reporting
    $wer = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
    if (-not (Test-Path $wer)) { New-Item -Path $wer -Force | Out-Null }
    Set-ItemProperty -Path $wer -Name "Disabled" -Type DWord -Value 1

    # === Gallery (Nav Panel)
    $galleryKey = "HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
    if (-not (Test-Path $galleryKey)) { New-Item -Path $galleryKey -Force | Out-Null }
    Set-ItemProperty -Path $galleryKey -Name "System.IsPinnedToNameSpaceTree" -Type DWord -Value 0

    # === UILockdown - Sicurezza di Windows
    $defenderBase = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center"
    $sections = @("Family options", "Device performance and health", "Account protection")
    foreach ($section in $sections) {
        $path = Join-Path $defenderBase $section
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        New-ItemProperty -Path $path -Name "UILockdown" -Type DWord -Value 1 -Force | Out-Null
    }

    # === Rimuovi chiavi Explorer (NameSpace e DelegateFolders)
    $toRemove = @(
        # Desktop / Videos / Music
        "{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}",
        "{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}",
        "{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}"
    )
    foreach ($guid in $toRemove) {
        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\$guid" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\$guid" -Force -ErrorAction SilentlyContinue
    }

    # OneDrive Namespace e pin
    try {
        Remove-Item -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Force -Recurse -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    } catch {}

    # Removable Drives
    $rem = "{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}"
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\$rem" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\$rem" -Force -ErrorAction SilentlyContinue

    # Home Explorer
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" -Force -ErrorAction SilentlyContinue

    # Network in Esplora
    $net = "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}"
    Remove-Item -Path "HKCR:\CLSID\$net\ShellFolder" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKCR:\Wow6432Node\CLSID\$net\ShellFolder" -Force -ErrorAction SilentlyContinue

    # Done
    [System.Windows.Forms.MessageBox]::Show("Tutti i tweak sono stati applicati.","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

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
