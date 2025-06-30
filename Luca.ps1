# --- BOTTONE TOGGLE MODALITA' SCURA ---
$btnDarkMode = New-Object System.Windows.Forms.Button
$btnDarkMode.Text = "Modalità Scura"
$btnDarkMode.Size = New-Object System.Drawing.Size(160, 40)
$btnDarkMode.Location = New-Object System.Drawing.Point(10, 120)
$btnDarkMode.Tag = $true  # scura attiva
$btnDarkMode.BackColor = $colorButtonBack
$btnDarkMode.ForeColor = $colorFore
$btnDarkMode.FlatStyle = 'Flat'
$btnDarkMode.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100,100,100)
$btnDarkMode.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnDarkMode.Add_MouseEnter({ $btnDarkMode.BackColor = $colorButtonHover })
$btnDarkMode.Add_MouseLeave({ $btnDarkMode.BackColor = $colorButtonBack })
$btnDarkMode.Add_Click({
    if ($btnDarkMode.Tag) {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 1 -ErrorAction SilentlyContinue
        $btnDarkMode.Text = "Modalità Chiara"
        $btnDarkMode.Tag = $false
    } else {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -ErrorAction SilentlyContinue
        $btnDarkMode.Text = "Modalità Scura"
        $btnDarkMode.Tag = $true
    }
})
$sidebar.Controls.Add($btnDarkMode)

# --- BOTTONE PRESTAZIONI ELEVATE ---
$btnPowerPerf = New-Object System.Windows.Forms.Button
$btnPowerPerf.Text = "Prestazioni Elevate"
$btnPowerPerf.Size = New-Object System.Drawing.Size(160, 40)
$btnPowerPerf.Location = New-Object System.Drawing.Point(10, 170)
$btnPowerPerf.BackColor = $colorButtonBack
$btnPowerPerf.ForeColor = $colorFore
$btnPowerPerf.FlatStyle = 'Flat'
$btnPowerPerf.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100,100,100)
$btnPowerPerf.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnPowerPerf.Add_MouseEnter({ $btnPowerPerf.BackColor = $colorButtonHover })
$btnPowerPerf.Add_MouseLeave({ $btnPowerPerf.BackColor = $colorButtonBack })
$btnPowerPerf.Add_Click({
    $guid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    $exists = powercfg /list | Select-String $guid
    if (-not $exists) {
        powercfg -duplicatescheme $guid | Out-Null
    }
    powercfg -setactive $guid
    powercfg /change monitor-timeout-ac 0
    powercfg /change monitor-timeout-dc 0
    [System.Windows.Forms.MessageBox]::Show("✅ Prestazioni elevate attivate.","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
})
$sidebar.Controls.Add($btnPowerPerf)

# --- BOTTONE DISABILITA IBERNAZIONE ---
$btnDisableHibernate = New-Object System.Windows.Forms.Button
$btnDisableHibernate.Text = "Disabilita Ibernazione"
$btnDisableHibernate.Size = New-Object System.Drawing.Size(160, 40)
$btnDisableHibernate.Location = New-Object System.Drawing.Point(10, 220)
$btnDisableHibernate.BackColor = $colorButtonBack
$btnDisableHibernate.ForeColor = $colorFore
$btnDisableHibernate.FlatStyle = 'Flat'
$btnDisableHibernate.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100,100,100)
$btnDisableHibernate.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnDisableHibernate.Add_MouseEnter({ $btnDisableHibernate.BackColor = $colorButtonHover })
$btnDisableHibernate.Add_MouseLeave({ $btnDisableHibernate.BackColor = $colorButtonBack })
$btnDisableHibernate.Add_Click({
    powercfg /hibernate off
    [System.Windows.Forms.MessageBox]::Show("✅ Ibernazione disabilitata.","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
})
$sidebar.Controls.Add($btnDisableHibernate)

# --- BOTTONE DISATTIVA SERVIZI CONSIGLIATI ---
$btnDisableServices = New-Object System.Windows.Forms.Button
$btnDisableServices.Text = "Disattiva servizi consigliati"
$btnDisableServices.Size = New-Object System.Drawing.Size(160, 40)
$btnDisableServices.Location = New-Object System.Drawing.Point(10, 320)
$btnDisableServices.BackColor = $colorButtonBack
$btnDisableServices.ForeColor = $colorFore
$btnDisableServices.FlatStyle = 'Flat'
$btnDisableServices.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100,100,100)
$btnDisableServices.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnDisableServices.Add_MouseEnter({ $btnDisableServices.BackColor = $colorButtonHover })
$btnDisableServices.Add_MouseLeave({ $btnDisableServices.BackColor = $colorButtonBack })
$btnDisableServices.Add_Click({

    $batchCode = @"
@echo off

:: BatchGotAdmin
:-------------------------------------

REM  --> Verifica i permessi

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
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------

@echo off
mode con: cols=100 lines=55
cls
echo.
echo                SCRIPT DISATTIVATORE SERVIZI BY KRIS-ANDREA-MARS
color 09
echo --- IMPORTANTE: Fate un PUNTO DI RIPRISTINO prima di INIZIARE (non si sa MAI) ---
echo       Ricordati che devi avviarmi come AMMINISTARTORE
echo Vuoi disattivare i servizi consigliati (Impostazione generica "RAM Speedy Bost System")?
echo               ELENCO SERVIZI
echo  Auto Connection Manager di Accesso Remoto
echo  Cartelle di lavoro                    
echo  Connection Manager di Accesso remoto  
echo  Consumo dati                          
echo  Interfaccia servizio guest Hyper-V    
echo  Redirector porta UserMode di Serviz...
echo  Richiedente Copia Shadow del volume...
echo  Server                                
echo  Servizi Desktop remoto                
echo  Servizio Arresto guest Hyper-V        
echo  Servizio dati sensori                 
echo  Servizio Demo negozio                 	
echo  Servizio di enumerazione dispositiv...
echo  Servizio di gestione radio            
echo  Servizio Heartbeat Hyper-V            
echo  Servizio monitoraggio sensori         
echo  Servizio PowerShell Direct Hyper-V    
echo  Servizio Scambio di dati Hyper-V      
echo  Servizio Sincronizzazione ora Hyper-V 
echo  Servizio Telefono                     
echo  Servizio Virtualizzazione Desktop remoto Hyper-V
echo  Smart Card                            
echo  Telefonia                             
echo  Windows Search                        
echo  Workstation  
echo  Gestione mappe scaricate              
echo  Servizio sensori                      
echo  Servizio di georilevazione            
echo  Servizio Risoluzione problemi compa...
echo  Criterio rimozione smart card         
echo  Accesso secondario                    
echo  Servizio router SMS di Microsoft Wi...
echo  Servizio Windows Insider              
echo  Acquisizione di immagini di Windows
echo  File non linea                        
echo  Host sistema di diagnostica           
echo  Servizio host hypervisor              
echo  SysMain           
echo 1) Si
echo 2) No
set /p scelta="Vuoi disattivare i servizi?: "

if "%scelta%"=="1" (
sc config  vmicguestinterface	        start= disabled
sc config  vmicvss           	        start= disabled
sc config  vmicshutdown      	        start= disabled
sc config  vmicheartbeat     	        start= disabled
sc config  vmicvmsession     	        start= disabled
sc config  vmickvpexchange   	        start= disabled
sc config  vmictimesync      	        start= disabled
sc config  vmicrdv           	        start= disabled
sc config  RasAuto           	        start= disabled
sc config  workfolderssvc    	        start= disabled
sc config  RasMan            	        start= disabled
sc config  DusmSvc           	        start= disabled
sc config  UmRdpService      	        start= disabled
sc config  LanmanServer      	        start= disabled
sc config  TermService       	        start= disabled
sc config  SensorDataService 	        start= disabled
sc config  RetailDemo        	        start= disabled
sc config  ScDeviceEnum      	        start= disabled
sc config  RmSvc             	        start= disabled
sc config  SensrSvc          	        start= disabled
sc config  PhoneSvc          	        start= disabled
sc config  SCardSvr          	        start= disabled
sc config  TapiSrv           	        start= disabled
sc config  WSearch           	        start= disabled
sc config  LanmanWorkstation 	        start= disabled
sc config  MapsBroker                   start= disabled
sc config  SensorService                start= disabled
sc config  lfsvc             	        start= disabled
sc config  PcaSvc            	        start= disabled
sc config  SCPolicySvc       	        start= disabled
sc config  seclogon          	        start= disabled
sc config  SmsRouter         	        start= disabled
sc config  wisvc             	        start= disabled
sc config  StiSvc            	        start= disabled
sc config  CscService        	        start= disabled
sc config  WdiSystemHost     	        start= disabled
sc config  HvHost            	        start= disabled
sc config  SysMain            	        start= disabled
echo.
echo Servizi Richiesti disabilitati.
) else if "%scelta%"=="2" (
    echo Servizi non disabilitati.
) else (
    echo Scelta non valida.
)
pause

mode con: cols=120 lines=30
cls
color 0a
echo.
echo Vuoi disattivare i servizi Xbox?
echo          ELENCO SERVIZI                                        Note
echo	Gestione autenticazione Xbox Live     
echo	Giochi salvati su Xbox Live           da non disattivare se usate XBOX accoppiata al vostro PC
echo	Servizio di rete Xbox Live            
echo	Xbox Accessory Management Service     
echo.
echo 1) Si
echo 2) No
set /p scelta="Vuoi disattivare i servizi?: "

if "%scelta%"=="1" (
sc config  XblAuthManager    start= disabled
sc config  XblGameSave       start= disabled
sc config  XboxNetApiSvc     start= disabled
sc config  XboxGipSvc        start= disabled
echo.
echo Servizi Richiesti disabilitati.
) else if "%scelta%"=="2" (
    echo Servizi non disabilitati.
) else (
    echo Scelta non valida.
)
pause
cls
color 09
echo.
echo Vuoi disattivare i restanti servizi? (leggi le note e valuta bene)
echo      ELENCO SERVIZI                                               NOTE
echo Configurazione Desktop remoto         	disattivatelo anche se usate programmi per remotare il pc
echo 1) Si
echo 2) No
set /p scelta="Vuoi disattivare i servizi?: "

if "%scelta%"=="1" (
sc config	SessionEnv        	           start= disabled
echo Servizi Richiesti disabilitati.
) else if "%scelta%"=="2" (
    echo Servizi non disabilitati.
) else (
    echo Scelta non valida.
)
pause

cls
color 0a
echo.
echo Controllo genitori                    	non fatelo se minori usano il vostro pc
echo 1) Si
echo 2) No
set /p scelta="Vuoi disattivare i servizi?: "
if "%scelta%"=="1" (
sc config	WpcMonSvc         	           start= disabled
echo Servizi Richiesti disabilitati.

) else if "%scelta%"=="2" (
    echo Servizi non disabilitati.
) else (
    echo Scelta non valida.
)
pause
cls
color 09
echo.
echo Servizio Telemetria                  	Servizio di tracciamento utente
echo 1) Si
echo 2) No
set /p scelta="Vuoi disattivare i servizi?: "

if "%scelta%"=="1" (
sc config DiagTrack	         	           start= disabled
echo Servizi Richiesti disabilitati.

) else if "%scelta%"=="2" (
    echo Servizi non disabilitati.
) else (
    echo Scelta non valida.
)
pause
cls
color 0a
echo.
echo Gestione pagamenti e NFC/SE           	non disattivatelo se usate tool di lettura NFC
echo 1) Si
echo 2) No
set /p scelta="Vuoi disattivare i servizi?: "

if "%scelta%"=="1" (
sc config	SEMgrSvc          	           start= disabled
echo Servizi Richiesti disabilitati.

) else if "%scelta%"=="2" (
    echo Servizi non disabilitati.
) else (
    echo Scelta non valida.
)
pause
cls
color 09
echo.
echo Microsoft Edge 	     non disattivatelo se usate Edge come browser principale
echo 1) Si
echo 2) No
set /p scelta="Vuoi disattivare i servizi?: "

if "%scelta%"=="1" (
sc config	MicrosoftEdgeElevationService  start= disabled
sc config	edgeupdate        	           start= disabled
sc config	edgeupdatem       	           start= disabled
echo Servizi Richiesti disabilitati.

) else if "%scelta%"=="2" (
    echo Servizi non disabilitati.
) else (
    echo Scelta non valida.
)
pause
cls
color 0a
echo.
echo Servizi di crittografia                      non disattivatelo se usate token per impronte digitali  
echo Servizio di crittografia Unita BitLoker                riconoscimento facciale o retinico
echo Servizio di biometria Windows                non disattivatelo se usate token per impronte digitali
echo 1) Si
echo 2) No
set /p scelta="Vuoi disattivare i servizi?: "

if "%scelta%"=="1" (
sc config	CryptSvc      start= disabled
sc config	BDESVC        start= disabled
sc config	WbioSrvc      start= disabled
echo Servizi Richiesti disabilitati.

) else if "%scelta%"=="2" (
    echo Servizi non disabilitati.
) else (
    echo Scelta non valida.
)
pause
cls
color 09
echo.
echo Servizio di supporto Bluetooth        	non Disattivatelo se avete accessori Bluetooth accoppiato al vostro PC
echo Servizio gateway audio Bluetooth      	
echo 1) Si
echo 2) No
set /p scelta="Vuoi disattivare i servizi?: "

if "%scelta%"=="1" (
sc config	bthserv           	           start= disabled
sc config	BTAGService       	           start= disabled
echo Servizi Richiesti disabilitati.

) else if "%scelta%"=="2" (
    echo Servizi non disabilitati.
) else (
    echo Scelta non valida.
)
pause
cls
color 0a
echo.
echo Estensioni e notifiche stampante         	non Disattivatelo se avete una stampante o uno scanner
echo 1) Si
echo 2) No
set /p scelta="Vuoi disattivare i servizi?: "

if "%scelta%"=="1" (
sc config	PrintNotify       	           start= disabled
echo Servizi Richiesti disabilitati.

) else if "%scelta%"=="2" (
    echo Servizi non disabilitati.
) else (
    echo Scelta non valida.
)
pause
cls
color 09
echo.
echo Windows Insider        non Disattivatelo se siete windows insider o utilizzate programmi insider
echo 1) Si
echo 2) No
set /p scelta="Vuoi disattivare i servizi?: "

if "%scelta%"=="1" (
sc config	wisvc      start= disabled
echo Servizi Richiesti disabilitati.

) else if "%scelta%"=="2" (
    echo Servizi non disabilitati.
) else (
    echo Scelta non valida.
)
pause
cls
color 0a
echo.
echo Servizio di condivisione in rete Windows Media Player        
echo 1) Si
echo 2) No
set /p scelta="Vuoi disattivare i servizi?: "

if "%scelta%"=="1" (
sc config	WMPNetworkSvc     start= disabled
echo Servizi Richiesti disabilitati.

) else if "%scelta%"=="2" (
    echo Servizi non disabilitati.
) else (
    echo Scelta non valida.
)
pause
cls
color 09
echo.
echo Supporto del pannello di controllo segnalazione problemi        Segnalazione errori di Windows
echo 1) Si
echo 2) No
set /p scelta="Vuoi disattivare i servizi?: "

if "%scelta%"=="1" (
sc config	wercplsupport       start= disabled
echo Servizi Richiesti disabilitati.

) else if "%scelta%"=="2" (
    echo Servizi non disabilitati.
) else (
    echo Scelta non valida.
)
pause
cls
color 0a
echo.
echo Windows Connect Now - Registro conf       punti di accesso di rete e i dispositivi 
echo 1) Si
echo 2) No
set /p scelta="Vuoi disattivare i servizi?: "

if "%scelta%"=="1" (
sc config	wcncsvc       start= disabled
echo Servizi Richiesti disabilitati.

) else if "%scelta%"=="2" (
    echo Servizi non disabilitati.
) else (
    echo Scelta non valida.
)
pause

cls
color 1f
echo.
echo I Servizi scelti sono stati disattivati, ora devi riavviare il sistema per rendere effettive le modifiche.
echo                                    ------GENTILUOMO-DIGITALE--------

@echo off
echo Vuoi riavviare il computer?
echo 1) Si
echo 2) No
set /p scelta="Vuoi disattivare i servizi?: "

if "%scelta%"=="1" (
    echo Spegnimento in corso...
    shutdown /r /t 0
) else if "%scelta%"=="2" (
    echo Servizi non disabilitati.
) else (
    echo Scelta non valida.
)
pause
"@

    # Scrivi batch in file temporaneo
    $tempBatchPath = [System.IO.Path]::Combine($env:TEMP, "DisableServices.bat")
    Set-Content -Path $tempBatchPath -Value $batchCode -Encoding ASCII

    # Esegui con elevazione
    Start-Process -FilePath $tempBatchPath -Verb RunAs

    # Aspetta e prova a cancellare il file temporaneo
    Start-Sleep -Seconds 3
    Remove-Item -Path $tempBatchPath -ErrorAction SilentlyContinue
})
$sidebar.Controls.Add($btnDisableServices)


# Variabile di stato iniziale
$uacPromptDisabled = $false

# Crea bottone toggle
$btnToggleUAC = New-Object System.Windows.Forms.Button
$btnToggleUAC.Size = New-Object System.Drawing.Size(160, 40)
$btnToggleUAC.Location = New-Object System.Drawing.Point(10, 370)
$btnToggleUAC.BackColor = $colorButtonBack
$btnToggleUAC.ForeColor = $colorFore
$btnToggleUAC.FlatStyle = 'Flat'
$btnToggleUAC.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100,100,100)
$btnToggleUAC.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnToggleUAC.Text = "Disabilita prompt UAC"

$btnToggleUAC.Add_Click({
    # Inverti stato
    $uacPromptDisabled = -not $uacPromptDisabled
    Set-UACPromptForAdmins -DisablePrompt:$uacPromptDisabled

    if ($uacPromptDisabled) {
        $btnToggleUAC.Text = "Abilita prompt UAC"
        [System.Windows.Forms.MessageBox]::Show("Prompt UAC disabilitato per amministratori.`nRiavvia per applicare.", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    else {
        $btnToggleUAC.Text = "Disabilita prompt UAC"
        [System.Windows.Forms.MessageBox]::Show("Prompt UAC abilitato per amministratori.`nRiavvia per applicare.", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

$sidebar.Controls.Add($btnToggleUAC)

# --- BOTTONE DEBLOAT APPX ---
$btnDebloatAppx = New-Object System.Windows.Forms.Button
$btnDebloatAppx.Text = "Debloat AppX"
$btnDebloatAppx.Size = New-Object System.Drawing.Size(160, 40)
$btnDebloatAppx.Location = New-Object System.Drawing.Point(10, 420)
$btnDebloatAppx.BackColor = $colorButtonBack
$btnDebloatAppx.ForeColor = $colorFore
$btnDebloatAppx.FlatStyle = 'Flat'
$btnDebloatAppx.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100,100,100)
$btnDebloatAppx.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnDebloatAppx.Add_MouseEnter({ $btnDebloatAppx.BackColor = $colorButtonHover })
$btnDebloatAppx.Add_MouseLeave({ $btnDebloatAppx.BackColor = $colorButtonBack })
$btnDebloatAppx.Add_Click({
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
        "Microsoft.YourPhone",
        "Microsoft.ZuneMusic",
        "MicrosoftCorporationII.QuickAssist",
        "MSTeams"
    )
    $errors = 0
    foreach ($app in $apps) {
        try {
            Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*$app*" } | ForEach-Object {
                Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
            }
        } catch {
            $errors++
        }
    }
    if ($errors -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("✅ AppX rimossi con successo.","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        [System.Windows.Forms.MessageBox]::Show("⚠️ Alcuni AppX potrebbero non essere stati rimossi.","Attenzione",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})
$sidebar.Controls.Add($btnDebloatAppx)
