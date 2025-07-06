Certainly\! It looks like you're aiming to gather all your scripts into one comprehensive PowerShell GUI application. That's a great approach for simplifying your system maintenance tasks.

You've already provided a solid base, including:

  * **GUI Framework:** Using `System.Windows.Forms` for the graphical interface.
  * **Styling:** Defined colors for a dark theme.
  * **Button Functions:** `New-Button` and `New-SmallButton` for consistent styling and hover effects.
  * **Core Functions:** Scripts to remove Microsoft apps, OneDrive, disable Copilot, remove Widgets, remove Edge, disable various services, and install apps from a specific folder (`E:\App`).
  * **Utility Functions:** Toggling Dark Mode, Taskbar Search, Visual Effects, and the Task View Button.
  * **New `Invoke-RegImporter` Function:** To import `.reg` files from `E:\Script\Esegui`.

To ensure everything is included and organized, I'll provide the complete PowerShell script below. This script consolidates all the functions and integrates the new `.reg` importer into your sidebar.

-----

## **Luca Tweaks GUI Script**

Here's the full script. You can copy and paste this into an elevated PowerShell window.

```powershell
Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# REGIONE: COLORI
# Definizioni dei colori per l'interfaccia grafica.
$colorFormBack = [System.Drawing.Color]::FromArgb(30,30,30)
$colorText = [System.Drawing.Color]::White
$colorButton = [System.Drawing.Color]::FromArgb(60,63,65)
$colorButtonHover = [System.Drawing.Color]::FromArgb(75,110,175)
$colorSidebar = [System.Drawing.Color]::FromArgb(40,40,40)
# FINE REGIONE: COLORI

# REGIONE: FUNZIONI CREAZIONE PULSANTI
# Funzione per creare pulsanti grandi con effetto hover.
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

# Funzione per creare pulsanti piccoli con effetto hover (toggle).
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
# FINE REGIONE: FUNZIONI CREAZIONE PULSANTI

# REGIONE: FUNZIONI PRINCIPALI
# Rimuove un pacchetto AppX per tutti gli utenti e disabilita il provisioning.
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

# Rimuove diverse app Microsoft predefinite.
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
        "Microsoft.WindowsAlarms"
    )
    foreach ($app in $apps) {
        try {
            Get-AppxPackage -AllUsers -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue
        } catch {}
    }

    # Percorso cartella Accessibility
    $accessibilityPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Accessibility"

    if (Test-Path $accessibilityPath) {

        # Rimuove attributi sola lettura e sistema a tutti i file e cartelle
        Get-ChildItem -LiteralPath $accessibilityPath -Recurse -Force | ForEach-Object {
            try { $_.Attributes = 'Normal' } catch {}
        }

        # Prova a rimuovere con Remove-Item
        try {
            Remove-Item -LiteralPath $accessibilityPath -Recurse -Force -ErrorAction Stop
            Write-Host "Cartella Accessibility rimossa con Remove-Item."
        } catch {
            Write-Warning "Remove-Item fallito: $_"
            # Ultima risorsa: prova a rimuovere con cmd
            $cmd = "rd /s /q `"$accessibilityPath`""
            Start-Process -FilePath cmd.exe -ArgumentList "/c $cmd" -Wait -NoNewWindow # Added -NoNewWindow to run cmd silently
            if (-not (Test-Path $accessibilityPath)) {
                Write-Host "Cartella Accessibility rimossa con cmd."
            } else {
                Write-Warning "Impossibile rimuovere la cartella Accessibility."
            }
        }
    } else {
        Write-Host "Cartella Accessibility non trovata."
    }

    [System.Windows.Forms.MessageBox]::Show("Rimozione app Microsoft completata!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

# Rimuove OneDrive dal sistema.
function Remove-OneDrive {
    Write-Host "Rimuovo OneDrive..."
    taskkill /f /im OneDrive.exe > $null 2>&1
    if (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe") {
        & "$env:SystemRoot\System32\OneDriveSetup.exe" /uninstall
    }
    if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
        & "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" /uninstall
    }
    # Using robocopy for moving content before full removal
    robocopy "$env:USERPROFILE\OneDrive" "$env:USERPROFILE" /mov /e /xj /ndl /nfl /njh /njs /nc /ns /np | Out-Null
    reg delete "HKEY_CLASSES_ROOT\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f | Out-Null
    reg delete "HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f | Out-Null
    Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" -Force -ErrorAction SilentlyContinue
    powershell -Command "Get-ScheduledTask -TaskPath '\' -TaskName 'OneDrive*' -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:`$false" | Out-Null
    Remove-Item "$env:UserProfile\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LocalAppData\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LocalAppData\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\OneDrive" /f | Out-Null
    [System.Windows.Forms.MessageBox]::Show("OneDrive rimosso con successo!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

# Disabilita Microsoft Copilot.
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

# Rimuove i Widgets di Windows.
function Remove-Widgets {
    Write-Host "Rimuovo Widgets..."
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f | Out-Null
    Get-AppxPackage *WebExperience* | Remove-AppxPackage -ErrorAction SilentlyContinue
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy" /f | Out-Null
    [System.Windows.Forms.MessageBox]::Show("Widgets rimossi!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

# Rimuove Microsoft Edge Chromium.
function Remove-Edge {
    Write-Host "Rimuovo Microsoft Edge Chromium..."
    try {
        # Downloads and executes a community script to uninstall Edge
        $script = (New-Object Net.WebClient).DownloadString('https://cdn.jsdelivr.net/gh/he3als/EdgeRemover@main/get.ps1')
        $sb = [ScriptBlock]::Create($script)
        & $sb -UninstallEdge
        [System.Windows.Forms.MessageBox]::Show("Microsoft Edge rimosso!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Errore durante la rimozione di Microsoft Edge: $($_.Exception.Message)","Errore",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# Disattiva una lista predefinita di servizi di Windows tramite uno script batch.
function Invoke-DisattivaServizi {
    $batContent = @"
@echo off
:: Elevazione automatica se non è già admin
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
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
exit
"@

    $tempBat = [System.IO.Path]::Combine($env:TEMP, "DisattivaServizi.bat")
    [System.IO.File]::WriteAllText($tempBat, $batContent)
    Start-Process -FilePath $tempBat -Verb RunAs
}

# Installa app eseguibili, MSI, batch o PowerShell da una cartella specificata (E:\App).
function Invoke-AppInstaller {
    $batContent = @"
@echo off
setlocal enabledelayedexpansion

set "APP_DIR=E:\App"
title Selezione e installazione app

:: Array delle app trovate
set count=0
echo.
echo Scansione della cartella "%APP_DIR%"...

:: Cerca i file supportati
for %%F in ("%APP_DIR%\*.exe" "%APP_DIR%\*.msi" "%APP_DIR%\*.bat" "%APP_DIR%\*.cmd" "%APP_DIR%\*.ps1") do (
    set /a count+=1
    set "app!count!=%%~fF"
    echo    !count!^) %%~nxF
)

if %count%==0 (
    echo Nessuna app trovata nella cartella.
    pause
    exit /b
)

echo.
echo 0^) Installa TUTTE le app
echo.

set /p scelta=Inserisci i numeri delle app da installare (es. 1,3,5 o 0 per tutte): 

:: Se 0, installa tutte
if "%scelta%"=="0" (
    set "scelta="
    for /L %%I in (1,1,%count%) do (
        call :installaApp %%I
    )
    goto fine
)

:: Selezione personalizzata
for %%N in (%scelta%) do (
    call :installaApp %%N
)

goto fine

:installaApp
set "num=%1"
set "file=!app%num%!"
if not defined file (
    echo ERRORE: selezione %num% non valida.
    goto :eof
)

echo.
echo ------------------------------------------
echo Installazione: !file!
echo ------------------------------------------

:: Determina estensione
set "ext=!file:~-4!"
if /i "!ext!"==".exe" (
    start /wait "" "!file!" /quiet /norestart
) else if /i "!ext!"==".msi" (
    start /wait msiexec /i "!file!" /quiet /norestart
) else if /i "!ext!"==".bat" (
    call "!file!"
) else if /i "!ext!"==".cmd" (
    call "!file!"
) else if /i "!ext!"==".ps1" (
    powershell -ExecutionPolicy Bypass -File "!file!"
)

if !errorlevel! EQU 0 (
    echo ✅ Installazione completata per: !file!
) else (
    echo ❌ Errore durante l'installazione di: !file!
)

goto :eof

:fine
echo.
echo -----------------------
echo TUTTE LE INSTALLAZIONI CONCLUSE
echo -----------------------
pause
exit /b
"@

    $tempBat = [System.IO.Path]::Combine($env:TEMP, "InstallerAppScript.bat")
    [System.IO.File]::WriteAllText($tempBat, $batContent)
    Start-Process -FilePath $tempBat -Verb RunAs
}

# Attiva/Disattiva la modalità scura di Windows.
function Invoke-WinUtilDarkMode {
    try {
        $Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        $current = Get-ItemPropertyValue -Path $Path -Name AppsUseLightTheme -ErrorAction SilentlyContinue
        if ($null -eq $current) { $current = 1 } # Default to light if not set
        $newValue = if ($current -eq 0) { 1 } else { 0 }
        Set-ItemProperty -Path $Path -Name AppsUseLightTheme -Value $newValue
        Set-ItemProperty -Path $Path -Name SystemUsesLightTheme -Value $newValue
        $msg = if ($newValue -eq 0) { "Dark Mode attivata." } else { "Dark Mode disattivata." }
        [System.Windows.Forms.MessageBox]::Show($msg)
    } catch { [System.Windows.Forms.MessageBox]::Show("Errore: $($_.Exception.Message)") }
}

# Attiva/Disattiva la barra di ricerca sulla Taskbar.
function Invoke-WinUtilTaskbarSearch {
    try {
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
        $current = Get-ItemPropertyValue -Path $Path -Name SearchboxTaskbarMode -ErrorAction SilentlyContinue
        if ($null -eq $current) { $current = 1 } # Default to 1 if not set (search icon)
        $newValue = if ($current -eq 0) { 1 } else { 0 } # Toggle 0 (hidden) and 1 (icon)
        Set-ItemProperty -Path $Path -Name SearchboxTaskbarMode -Value $newValue
        $msg = if ($newValue -eq 0) { "Taskbar Search disattivata." } else { "Taskbar Search attivata." }
        [System.Windows.Forms.MessageBox]::Show($msg)
    } catch { [System.Windows.Forms.MessageBox]::Show("Errore: $($_.Exception.Message)") }
}

# Applica effetti visivi personalizzati per le prestazioni.
function Toggle-CustomVisualEffects {
    try {
        # Corresponds to "Adjust for best performance"
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0))
        [System.Windows.Forms.MessageBox]::Show("Effetti visivi personalizzati applicati. Potrebbe essere necessario riavviare o effettuare il logout per vedere tutte le modifiche.","Info",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Errore nell'applicazione degli effetti visivi: $($_.Exception.Message)")
    }
}

# Attiva/Disattiva il pulsante Vista Attività sulla Taskbar.
function Toggle-ShowTaskViewButton {
    try {
        $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        $current = Get-ItemPropertyValue -Path $key -Name ShowTaskViewButton -ErrorAction SilentlyContinue
        if ($null -eq $current) { $current = 1 } # Default to 1 (visible)
        $newValue = if ($current -eq 0) { 1 } else { 0 } # Toggle 0 (hidden) and 1 (visible)
        Set-ItemProperty -Path $key -Name ShowTaskViewButton -Value $newValue
        $msg = if ($newValue -eq 0) { "Pulsante Vista Attività disattivato." } else { "Pulsante Vista Attività attivato." }
        [System.Windows.Forms.MessageBox]::Show($msg)
    } catch { [System.Windows.Forms.MessageBox]::Show("Errore: $($_.Exception.Message)") }
}

# Importa file .reg da una cartella specificata (E:\Script\Esegui).
function Invoke-RegImporter {
    $batContent = @"
@echo off
setlocal enabledelayedexpansion

set "folder=E:\Script\Esegui"
title Importazione File .reg

rem Verifica se la cartella esiste
if not exist "%folder%" (
    echo La cartella %folder% non esiste!
    pause
    exit /b
)

rem Crea una lista temporanea dei file .reg
set "filelist="
set /a count=0

for %%F in ("%folder%\*.reg") do (
    set /a count+=1
    set "file!count!=%%~nxF"
)

if %count%==0 (
    echo Nessun file .reg trovato nella cartella %folder%
    pause
    exit /b
)

:menu
cls
echo Seleziona i file .reg da importare:
echo.

for /L %%i in (1,1,%count%) do (
    echo %%i. !file%%i!
)

echo.
echo 0. Importa TUTTI i file
echo Q. Esci senza importare
echo.
set /p scelta=Inserisci numeri separati da spazi (es: 1 3 5) oppure 0 per tutti: 

if /i "%scelta%"=="q" (
    echo Uscita...
    exit /b
)

if "%scelta%"=="0" (
    echo Importazione di tutti i file .reg...
    for /L %%i in (1,1,%count%) do (
        echo Importando !file%%i!...
        reg import "%folder%\!file%%i!"
    )
    echo Fatto.
    pause
    exit /b
)

rem Importa i file scelti dall'utente
rem Suddivide la stringa scelta in token separati da spazi

for %%a in (%scelta%) do (
    set "num=%%a"
    rem Controlla che num sia tra 1 e count
    if !num! GEQ 1 if !num! LEQ %count% (
        echo Importando !file%num%!...
        reg import "%folder%\!file%num%!"
    ) else (
        echo Numero non valido: !num!
    )
)

echo Operazione completata.
pause
exit /b
"@

    $tempBat = [System.IO.Path]::Combine($env:TEMP, "RegImporterScript.bat")
    [System.IO.File]::WriteAllText($tempBat, $batContent)
    # Use -Wait to keep the PowerShell GUI responsive until the batch finishes, if desired.
    # Start-Process -FilePath $tempBat -Verb RunAs -Wait
    Start-Process -FilePath $tempBat -Verb RunAs
}
# FINE REGIONE: FUNZIONI PRINCIPALI

# REGIONE: CREAZIONE FORM PRINCIPALE E LAYOUT
$form = New-Object System.Windows.Forms.Form
$form.Text = "Luca Tweaks"
$form.Size = New-Object System.Drawing.Size(1100, 720)
$form.StartPosition = "CenterScreen"
$form.BackColor = $colorFormBack
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false # Impedisce la massimizzazione

# CREAZIONE SIDEBAR
$sidebar = New-Object System.Windows.Forms.Panel
$sidebar.Width = 140
$sidebar.Height = $form.ClientSize.Height
$sidebar.BackColor = $colorSidebar
$sidebar.Location = [System.Drawing.Point]::new(0,0)
$sidebar.Anchor = "Top, Bottom, Left" # Ancoraggio per mantenere la posizione

$form.Controls.Add($sidebar)

# Coordinate per i pulsanti piccoli nella sidebar
$smallStartX = 10
$smallStartY = 20
$smallSpacingY = 50

# PULSANTI PICCOLI (toggle) NELLA SIDEBAR
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

$btnInstallAppsSidebar = New-SmallButton "Installa App E:\App" ([System.Drawing.Point]::new($smallStartX, $smallStartY + $smallSpacingY*4))
$btnInstallAppsSidebar.Add_Click({ Invoke-AppInstaller })
$sidebar.Controls.Add($btnInstallAppsSidebar)

$btnRegImporter = New-SmallButton "Importa .REG" ([System.Drawing.Point]::new($smallStartX, $smallStartY + $smallSpacingY*5))
$btnRegImporter.Add_Click({ Invoke-RegImporter })
$sidebar.Controls.Add($btnRegImporter)

# Coordinate per pulsanti grandi
$bigStartX = 160
$bigStartY = 20
$bigSpacingY = 60

# PULSANTI GRANDI (Azioni)
$btnRemoveApps = New-Button "Rimuovi App Microsoft" ([System.Drawing.Point]::new($bigStartX, $bigStartY))
$btnRemoveApps.Add_Click({ Remove-MicrosoftApps })
$form.Controls.Add($btnRemoveApps)

$btnRemoveOneDrive = New-Button "Rimuovi OneDrive" ([System.Drawing.Point]::new($bigStartX, $bigStartY + $bigSpacingY))
$btnRemoveOneDrive.Add_Click({ Remove-OneDrive })
$form.Controls.Add($btnRemoveOneDrive)

$btnDisableCopilot = New-Button "Disattiva Copilot" ([System.Drawing.Point]::new($bigStartX, $bigStartY + $bigSpacingY*2))
$btnDisableCopilot.Add_Click({ Disable-Copilot })
$form.Controls.Add($btnDisableCopilot)

$btnRemoveWidgets = New-Button "Rimuovi Widgets" ([System.Drawing.Point]::new($bigStartX, $bigStartY + $bigSpacingY*3))
$btnRemoveWidgets.Add_Click({ Remove-Widgets })
$form.Controls.Add($btnRemoveWidgets)

$btnRemoveEdge = New-Button "Rimuovi Microsoft Edge" ([System.Drawing.Point]::new($bigStartX, $bigStartY + $bigSpacingY*4))
$btnRemoveEdge.Add_Click({ Remove-Edge })
$form.Controls.Add($btnRemoveEdge)

$btnDisableServices = New-Button "Disattiva Servizi" ([System.Drawing.Point]::new($bigStartX, $bigStartY + $bigSpacingY*5))
$btnDisableServices.Add_Click({ Invoke-DisattivaServizi })
$form.Controls.Add($btnDisableServices)
# FINE REGIONE: CREAZIONE FORM PRINCIPALE E LAYOUT

# MOSTRA FORM
[void]$form.ShowDialog()
```
