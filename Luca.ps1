# Elevazione amministrativa
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $psi.Verb = "runas"
    try {
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        Write-Warning "Elevazione annullata. Serve esecuzione come amministratore."
    }
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# COLORI TEMA SCURO
$colorBackground = [System.Drawing.Color]::FromArgb(30,30,30)
$colorPanel = [System.Drawing.Color]::FromArgb(45,45,48)
$colorFore = [System.Drawing.Color]::FromArgb(220,220,220)
$colorButtonBack = [System.Drawing.Color]::FromArgb(70,70,70)
$colorButtonHover = [System.Drawing.Color]::FromArgb(100,100,100)
$colorChecked = [System.Drawing.Color]::FromArgb(70,130,180)
$colorCategoryLabel = [System.Drawing.Color]::FromArgb(150,200,255)

# Funzione per checkbox dark
function New-DarkCheckBox {
    param([string]$Text, [int]$X, [int]$Y, [hashtable]$TagData)
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $Text
    $cb.Size = New-Object System.Drawing.Size(580, 30)
    $cb.Location = New-Object System.Drawing.Point($X, $Y)
    $cb.ForeColor = $colorFore
    $cb.BackColor = $colorPanel
    $cb.FlatStyle = 'Flat'
    $cb.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100,100,100)
    $cb.FlatAppearance.CheckedBackColor = $colorChecked
    $cb.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $cb.Tag = $TagData
    return $cb
}

# Funzione per label categoria
function New-CategoryLabel {
    param([string]$Text, [int]$X, [int]$Y)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Text
    $lbl.ForeColor = $colorCategoryLabel
    $lbl.BackColor = $colorPanel
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $lbl.AutoSize = $true
    $lbl.Location = New-Object System.Drawing.Point($X, $Y)
    return $lbl
}

# Funzione per impostare valori registro
function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [Microsoft.Win32.RegistryValueKind]$Type = [Microsoft.Win32.RegistryValueKind]::String
    )
    try {
        $fullPath = "HKLM:\$Path"
        if (-not (Test-Path $fullPath)) {
            $pathParts = $Path -split '\\'
            $currentPath = "HKLM:\"
            foreach ($part in $pathParts) {
                $currentPath = Join-Path $currentPath $part
                if (-not (Test-Path $currentPath)) {
                    New-Item -Path $currentPath -Force | Out-Null
                }
            }
        }
        Set-ItemProperty -Path $fullPath -Name $Name -Value $Value -Type $Type
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Errore: $($_.Exception.Message)", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
}

# Tweaks completi divisi per categoria (come da tuo elenco)
$categories = @{
    "Sistema" = @(
        @{Text="Imposta SvcHostSplitThresholdInKB (0x4000000)"; Path="SYSTEM\CurrentControlSet\Control"; Name="SvcHostSplitThresholdInKB"; Value=0x4000000; Type="DWord"},
        @{Text="Abilita LongPathsEnabled"; Path="SYSTEM\CurrentControlSet\Control\FileSystem"; Name="LongPathsEnabled"; Value=1; Type="DWord"},
        @{Text="Disabilita WPBT Execution"; Path="SYSTEM\CurrentControlSet\Control\Session Manager"; Name="DisableWpbtExecution"; Value=1; Type="DWord"},
        @{Text="Abilita BSOD Dettagliato"; Path="SYSTEM\CurrentControlSet\Control\CrashControl"; Name="DisplayParameters"; Value=1; Type="DWord"},
        @{Text="Disabilita Superfetch e Prefetcher"; Path="SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Name="EnableSuperfetch"; Value=0; Type="DWord"},
        @{Text="Disabilita Windows Search (wsearch)"; Path="SYSTEM\CurrentControlSet\Services\WSearch"; Name="Start"; Value=4; Type="DWord"}
    )
    "Explorer e UI" = @(
        @{Text="Nascondi pagina Impostazioni Home"; Path="SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name="SettingsPageVisibility"; Value="hide:home"; Type="String"},
        @{Text="Imposta Max Cached Icons a 4096"; Path="SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"; Name="Max Cached Icons"; Value="4096"; Type="String"},
        @{Text="Disattiva Snap Assist Flyout"; Path="SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="EnableSnapAssistFlyout"; Value=0; Type="DWord"},
        @{Text="Disattiva Sticky Keys"; Path="Control Panel\Accessibility\StickyKeys"; Name="Flags"; Value="58"; Type="String"}
    )
    "Aggiornamenti e Driver" = @(
        @{Text="Blocca driver da Windows Update"; Path="SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"; Name="ExcludeWUDriversInQualityUpdate"; Value=1; Type="DWord"},
        @{Text="Disattiva installazione automatica driver"; Path="SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching"; Name="SearchOrderConfig"; Value=0; Type="DWord"},
        @{Text="Disabilita aggiornamento driver da PC"; Path="SOFTWARE\Policies\Microsoft\Windows\Device Metadata"; Name="PreventDeviceMetadataFromNetwork"; Value=1; Type="DWord"}
    )
    "Telemetria e Sicurezza" = @(
        @{Text="Disabilita CEIP (SQMClient)"; Path="SOFTWARE\Microsoft\SQMClient\Windows"; Name="CEIPEnable"; Value=0; Type="DWord"},
        @{Text="Nascondi Opzioni Famiglia"; Path="SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Family options"; Name="UILockdown"; Value=1; Type="DWord"},
        @{Text="Nascondi Prestazioni e Integrità"; Path="SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Device performance and health"; Name="UILockdown"; Value=1; Type="DWord"},
        @{Text="Nascondi Protezione Account"; Path="SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Account protection"; Name="UILockdown"; Value=1; Type="DWord"},
        @{Text="Disabilita Agent Activation SpeechOneCore"; Path="SOFTWARE\Microsoft\Windows\CurrentVersion\SpeechOneCore\Settings"; Name="AgentActivationLastUsed"; Value=0; Type="DWord"},
        @{Text="Disabilita Multicast DNSClient"; Path="SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"; Name="EnableMulticast"; Value=0; Type="DWord"},
        @{Text="Blocca Internet OpenWith"; Path="SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name="NoInternetOpenWith"; Value=1; Type="DWord"}
    )
    "Mappe e Feed" = @(
        @{Text="Disattiva Download automatico mappe"; Path="SOFTWARE\Policies\Microsoft\Windows\Maps"; Name="AutoDownloadAndUpdateMapData"; Value=0; Type="DWord"},
        @{Text="Disattiva traffico rete mappe"; Path="SOFTWARE\Policies\Microsoft\Windows\Maps"; Name="AllowUntriggeredNetworkTrafficOnSettingsPage"; Value=0; Type="DWord"},
        @{Text="Disattiva Feed Attività"; Path="SOFTWARE\Policies\Microsoft\Windows\System"; Name="EnableActivityFeed"; Value=0; Type="DWord"}
    )
    "Vari" = @(
        @{Text="Imposta GPU Priority giochi"; Path="SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Name="GPU Priority"; Value=8; Type="DWord"},
        @{Text="Blocca AAD Workplace Join"; Path="SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name="BlockAADWorkplaceJoin"; Value=0; Type="DWord"},
        @{Text="Imposta System Responsiveness"; Path="SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Name="SystemResponsiveness"; Value=0; Type="DWord"},
        @{Text="Disabilita Storage Sense"; Path="SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"; Name="01"; Value=0; Type="DWord"},
        @{Text="Abilita Logon Verboso"; Path="SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name="VerboseStatus"; Value=1; Type="DWord"}
    )
}

# Creo form e splitcontainer
$form = New-Object System.Windows.Forms.Form
$form.Text = "Luca Tweaks - Tema Scuro"
$form.Size = New-Object System.Drawing.Size(820, 620)
$form.StartPosition = "CenterScreen"
$form.BackColor = $colorBackground
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$splitContainer = New-Object System.Windows.Forms.SplitContainer
$splitContainer.Dock = "Fill"
$splitContainer.Panel1MinSize = 180
$splitContainer.Panel2MinSize = 600
$splitContainer.SplitterDistance = 180
$form.Controls.Add($splitContainer)

# Sidebar (Panel1)
$sidebar = $splitContainer.Panel1
$sidebar.BackColor = $colorPanel

# Titolo sidebar
$labelSidebarTitle = New-Object System.Windows.Forms.Label
$labelSidebarTitle.Text = "Luca Tweaks"
$labelSidebarTitle.ForeColor = $colorChecked
$labelSidebarTitle.Font = New-Object System.Drawing.Font("Segoe Script", 16, [System.Drawing.FontStyle]::Bold)
$labelSidebarTitle.AutoSize = $true
$labelSidebarTitle.Top = 15
$labelSidebarTitle.Left = [Math]::Max(10, ($sidebar.Width - $labelSidebarTitle.PreferredWidth) / 2)
$sidebar.Controls.Add($labelSidebarTitle)

# Pulsante toggle Num Lock (esempio sidebar)
$btnNumLock = New-Object System.Windows.Forms.Button
$btnNumLock.Text = "Num Lock ON"
$btnNumLock.Size = New-Object System.Drawing.Size(160, 40)
$btnNumLock.Location = New-Object System.Drawing.Point(10, 70)
$btnNumLock.Tag = $true
$btnNumLock.BackColor = $colorButtonBack
$btnNumLock.ForeColor = $colorFore
$btnNumLock.FlatStyle = 'Flat'
$btnNumLock.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100,100,100)
$btnNumLock.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnNumLock.Add_MouseEnter({ $btnNumLock.BackColor = $colorButtonHover })
$btnNumLock.Add_MouseLeave({ $btnNumLock.BackColor = $colorButtonBack })
$btnNumLock.Add_Click({
    $wsh = New-Object -ComObject WScript.Shell
    $wsh.SendKeys('{NUMLOCK}')
    if ($btnNumLock.Tag) {
        $btnNumLock.Text = "Num Lock OFF"
        $btnNumLock.Tag = $false
    } else {
        $btnNumLock.Text = "Num Lock ON"
        $btnNumLock.Tag = $true
    }
})
$sidebar.Controls.Add($btnNumLock)

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

# Area principale (Panel2)
$panel = $splitContainer.Panel2
$panel.BackColor = $colorPanel

# Pannello bottoni in alto (Seleziona/Deseleziona tutto)
$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$buttonPanel.Height = 40
$buttonPanel.BackColor = $colorPanel
$panel.Controls.Add($buttonPanel)

# Bottone Seleziona Tutto
$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Seleziona tutto"
$btnSelectAll.Size = New-Object System.Drawing.Size(120, 30)
$btnSelectAll.Location = New-Object System.Drawing.Point(10, 5)
$btnSelectAll.BackColor = $colorButtonBack
$btnSelectAll.ForeColor = $colorFore
$btnSelectAll.FlatStyle = 'Flat'
$btnSelectAll.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnSelectAll.Add_MouseEnter({ $btnSelectAll.BackColor = $colorButtonHover })
$btnSelectAll.Add_MouseLeave({ $btnSelectAll.BackColor = $colorButtonBack })
$buttonPanel.Controls.Add($btnSelectAll)

# Bottone Deseleziona Tutto
$btnDeselectAll = New-Object System.Windows.Forms.Button
$btnDeselectAll.Text = "Deseleziona tutto"
$btnDeselectAll.Size = New-Object System.Drawing.Size(120, 30)
$btnDeselectAll.Location = New-Object System.Drawing.Point(140, 5)
$btnDeselectAll.BackColor = $colorButtonBack
$btnDeselectAll.ForeColor = $colorFore
$btnDeselectAll.FlatStyle = 'Flat'
$btnDeselectAll.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnDeselectAll.Add_MouseEnter({ $btnDeselectAll.BackColor = $colorButtonHover })
$btnDeselectAll.Add_MouseLeave({ $btnDeselectAll.BackColor = $colorButtonBack })
$buttonPanel.Controls.Add($btnDeselectAll)

# Pannello scrollabile sotto bottoni per checkbox
$scrollCheckboxPanel = New-Object System.Windows.Forms.Panel
$scrollCheckboxPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$scrollCheckboxPanel.AutoScroll = $true
$scrollCheckboxPanel.BackColor = $colorPanel
$panel.Controls.Add($scrollCheckboxPanel)

# Lista checkbox per tenere riferimento
$checkboxes = @()

# Posizione verticale iniziale per checkbox
$posY = 10

# Aggiungo categorie e tweaks
foreach ($category in $categories.GetEnumerator()) {
    # Label categoria
    $lblCat = New-CategoryLabel -Text $category.Key -X 10 -Y $posY
    $scrollCheckboxPanel.Controls.Add($lblCat)
    $posY += 30

    foreach ($tweak in $category.Value) {
        $cb = New-DarkCheckBox -Text $tweak.Text -X 20 -Y $posY -TagData $tweak
        $scrollCheckboxPanel.Controls.Add($cb)
        $checkboxes += $cb
        $posY += 35
    }
}

# Eventi Seleziona tutto
$btnSelectAll.Add_Click({
    foreach ($cb in $checkboxes) { $cb.Checked = $true }
})

# Eventi Deseleziona tutto
$btnDeselectAll.Add_Click({
    foreach ($cb in $checkboxes) { $cb.Checked = $false }
})

# Bottone Applica Tweaks in basso (sotto pannello scrollabile)
$btnApply = New-Object System.Windows.Forms.Button
$btnApply.Text = "Applica Tweaks"
$btnApply.Size = New-Object System.Drawing.Size(320, 50)
$btnApply.BackColor = [System.Drawing.Color]::FromArgb(70,130,180)
$btnApply.ForeColor = [System.Drawing.Color]::White
$btnApply.FlatStyle = 'Flat'
$btnApply.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(40,90,140)
$btnApply.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnApply.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)

# Per posizionare il bottone nella parte bassa del panel principale, useremo un secondo panel sotto scrollCheckboxPanel
$bottomPanel = New-Object System.Windows.Forms.Panel
$bottomPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
$bottomPanel.Height = 70
$bottomPanel.BackColor = $colorPanel
$panel.Controls.Add($bottomPanel)
$btnApply.Location = New-Object System.Drawing.Point(10, 10)
$bottomPanel.Controls.Add($btnApply)

# Evento click bottone Applica
$btnApply.Add_Click({
    $countApplied = 0
    foreach ($cb in $checkboxes) {
        if ($cb.Checked) {
            $t = $cb.Tag
            if ($t -and $t.Path -and $t.Name) {
                try {
                    $typeKind = [Microsoft.Win32.RegistryValueKind]::$($t.Type)
                    Set-RegistryValue -Path $t.Path -Name $t.Name -Value $t.Value -Type $typeKind
                    $countApplied++
                } catch {
                    [System.Windows.Forms.MessageBox]::Show("Errore nel tweak: $($t.Text)`n$($_.Exception.Message)", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
                }
            }
        }
    }
    [System.Windows.Forms.MessageBox]::Show("$countApplied tweak(s) applicati.", "Fatto", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
})

# Mostro form
[void]$form.ShowDialog()
