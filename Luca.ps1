<#
.SYNOPSIS
    Uno script PowerShell con interfaccia grafica per applicare varie ottimizzazioni al Registro di Windows.

.DESCRIPTION
    Questo script fornisce un'interfaccia utente grafica (GUI) per applicare selettivamente
    una collezione di modifiche al Registro di Windows. Queste modifiche mirano a
    ottimizzare le prestazioni del sistema, migliorare la privacy e personalizzare l'esperienza utente
    disabilitando alcune funzionalità, nascondendo elementi dell'interfaccia e modificando i comportamenti del sistema.
   
   
   IMPORTANTE:
    - L'esecuzione di questo script richiede privilegi di amministratore. Tenterà di elevarsi
      se non già in esecuzione come amministratore.
    - La modifica del Registro di Windows e la disinstallazione delle app di sistema comportano dei rischi.
      Si raccomanda vivamente di creare un punto di ripristino del sistema o di eseguire il backup
      del Registro prima di procedere.
    - Alcune modifiche potrebbero richiedere un riavvio del sistema per avere pieno effetto.
#>

#region Verifica privilegi di amministratore
# Ottieni l'identità dell'utente corrente
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)

# Controlla se l'utente corrente è un amministratore
If (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Questo script deve essere eseguito con privilegi di amministratore. Tentativo di riavvio..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`""
    Exit
}
#endregion

#region Carica gli assembly per la GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
#endregion

#region Configurazioni del Registro
# Definisce tutte le modifiche del Registro come un elenco di tabelle hash.
# Ogni tabella hash rappresenta un gruppo logico di impostazioni che possono essere abilitate/disabilitate insieme.
# 'Name': Nome visualizzato per la casella di controllo.
# 'Description': Testo del tooltip per la casella di controllo.
# 'RegistryActions': Un array di azioni da eseguire.
#   'Path': Il percorso completo del Registro (es. "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager").
#   'Name': Il nome del valore del Registro (o $null per il valore predefinito).
#   'Value': I dati da impostare (può essere DWord, String o Byte[] per Binary).
#   'Type': Il tipo di valore del Registro ("DWord", "String", "Binary", "ExpandString", "MultiString", "QWord", "Unknown").
#   'Action': "Set" per impostare un valore, "RemoveValue" per eliminare un valore, "RemoveKey" per eliminare un'intera chiave.
# 'AppxPackageName': Per le azioni di disinstallazione delle app, il nome completo del pacchetto AppX.
# 'TaskPath', 'TaskName': Per le azioni di disabilitazione delle attività pianificate.
# 'ServiceName': Per le azioni di disabilitazione dei servizi.
# 'Command': Per le azioni di esecuzione di comandi arbitrari.
# 'FunctionName': Per le azioni che chiamano una funzione PowerShell specifica.
$RegistryConfigurations = @(
    @{
        Name = "Disabilita Schermata di Blocco Dinamica e Consegna Contenuti"
        Description = "Disabilita funzionalità come la schermata di blocco dinamica, le app suggerite e altri meccanismi di consegna dei contenuti."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "RotatingLockScreenOverlayEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "ContentDeliveryAllowed"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "FeatureManagementEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "OemPreInstalledAppsEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "PreInstalledAppsEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "PreInstalledAppsEverEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "RotatingLockScreenEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SilentInstalledAppsEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SlideshowEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SoftLandingEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338388Enabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-88000326Enabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContentEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SystemPaneSuggestionsEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\Software\Policies\Microsoft\PushToInstall"; Name = "DisablePushToInstall"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions"; Action = "RemoveKey" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps"; Action = "RemoveKey" }
        )
    },
    @{
        Name = "Disabilita Notifiche Provider Sincronizzazione e Trasmetti a Dispositivo"
        Description = "Impedisce le notifiche dai provider di sincronizzazione e l'opzione 'Trasmetti a dispositivo'."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowSyncProviderNotifications"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowCastToDevice"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Nascondi Sezione 'Consigliati' nel Menu Start"
        Description = "Rimuove la sezione 'Consigliati' dal Menu Start di Windows."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start"; Name = "HideRecommendedSection"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Education"; Name = "IsEducationEnvironment"; Value = 1; Type = "DWord"; Action = "Set" }, # Spesso correlato al nascondere i consigliati
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"; Name = "HideRecommendedSection"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_ShowRecommendedToggle"; Value = 0; Type = "DWord"; Action = "Set" } # Aggiunta per una maggiore copertura
        )
    },
    @{
        Name = "Disabilita Notifiche Spazio su Disco Insufficiente"
        Description = "Impedisce a Windows di visualizzare notifiche quando lo spazio su disco è insufficiente."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name = "NoLowDiskSpaceChecks"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name = "NoLowDiskSpaceChecks"; Value = 1; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Scuotimento per Ridurre a Icona"
        Description = "Disabilita la funzionalità 'Scuoti' che riduce a icona le altre finestre quando si scuote una finestra."
        RegistryActions = @(
            @{ Path = "HKCU:\Control Panel\Desktop"; Name = "ShakeMinimizeWindows"; Value = "0"; Type = "String"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Segnalazione Errori di Windows (WER)"
        Description = "Disabilita completamente la Segnalazione Errori di Windows."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"; Name = "Disabled"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\Software\Microsoft\PCHealth\ErrorReporting"; Name = "DoReport"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\Windows Error Reporting"; Name = "Disabled"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting"; Name = "Disabled"; Value = 1; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Abilita Percorsi Lunghi"
        Description = "Consente alle applicazioni di accedere a percorsi di file più lunghi di 260 caratteri."
        RegistryActions = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Name = "LongPathsEnabled"; Value = 1; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Rimuovi Galleria dal Riquadro di Navigazione"
        Description = "Rimuove la voce 'Galleria' dal riquadro di navigazione di Esplora file."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"; Name = "System.IsPinnedToNameSpaceTree"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Velocizza Apertura Menu"
        Description = "Riduce il ritardo prima che i menu si aprano, rendendo l'interfaccia utente più reattiva."
        RegistryActions = @(
            @{ Path = "HKCU:\Control Panel\Desktop"; Name = "MenuShowDelay"; Value = "0"; Type = "String"; Action = "Set" }
        )
    },
    @{
        Name = "Riduci Tempo Attesa Popup"
        Description = "Diminuisce il tempo di ritardo prima che appaiano i tooltip e i popup al passaggio del mouse."
        RegistryActions = @(
            @{ Path = "HKCU:\Control Panel\Mouse"; Name = "MouseHoverTime"; Value = "10"; Type = "String"; Action = "Set" }
        )
    },
    @{
        Name = "Abilita Ottimizzazione Avvio (Disabilita Defrag Disco)"
        Description = "Ottimizza le prestazioni di avvio disabilitando la deframmentazione del disco all'avvio."
        RegistryActions = @(
            @{ Path = "HKLM:\Software\Microsoft\Dfrg\BootOptimizeFunction"; Name = "Enable"; Value = "y"; Type = "String"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Manutenzione Automatica"
        Description = "Impedisce a Windows di eseguire attività di manutenzione automatica."
        RegistryActions = @(
            @{ Path = "HKLM:\Software\Microsoft\Windows\ScheduledDiagnostics"; Name = "EnabledExecution"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance"; Name = "MaintenanceDisabled"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\Software\Policies\Microsoft\Windows\ScheduledDiagnostics"; Name = "EnabledExecution"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Registratore Passi"
        Description = "Disabilita l'utility Registratore Passi (Problem Steps Recorder)."
        RegistryActions = @(
            @{ Path = "HKLM:\Software\Policies\Microsoft\Windows\AppCompat"; Name = "DisableUAR"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Application-Experience/Steps-Recorder"; Name = "Enabled"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Cronologia Appunti"
        Description = "Disattiva la cronologia multi-elemento degli appunti e la sincronizzazione degli appunti tra dispositivi."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "AllowClipboardHistory"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "AllowCrossDeviceClipboard"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SmartActionPlatform\SmartClipboard"; Name = "Disabled"; Value = 1; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Snap Assist e Layout"
        Description = "Disabilita le funzionalità relative all'aggancio delle finestre e ai suggerimenti di layout."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "DITest"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "EnableSnapAssistFlyout"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "EnableSnapBar"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "EnableTaskGroups"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "MultiTaskingAltTabFilter"; Value = 3; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Imposta Soglia Suddivisione SvcHost in KB"
        Description = "Regola la soglia di suddivisione del servizio host per una migliore gestione delle risorse."
        RegistryActions = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control"; Name = "SvcHostSplitThresholdInKB"; Value = 0x4000000; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Rimuovi Desktop, Video, Musica, OneDrive, Rete, Accesso Rapido da Esplora File"
        Description = "Rimuove varie cartelle e categorie predefinite dal riquadro di navigazione di Esplora file."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}"; Action = "RemoveKey" }, # Desktop
            @{ Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}"; Action = "RemoveKey" },
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}"; Action = "RemoveKey" }, # Video
            @{ Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}"; Action = "RemoveKey" },
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}"; Action = "RemoveKey" }, # Musica
            @{ Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}"; Action = "RemoveKey" },
            @{ Path = "HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"; Name = "System.IsPinnedToNameSpaceTree"; Value = 0; Type = "DWord"; Action = "Set" }, # OneDrive
            @{ Path = "HKCU:\Software\Classes\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"; Name = "System.IsPinnedToNameSpaceTree"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}"; Action = "RemoveKey" }, # Unità rimovibili
            @{ Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}"; Action = "RemoveKey" },
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"; Action = "RemoveKey" }, # Sblocca Home
            @{ Path = "HKCU:\Software\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}\ShellFolder"; Name = "Attributes"; Value = 0xB0940064; Type = "DWord"; Action = "Set" }, # Rete
            @{ Path = "HKCU:\Software\Classes\Wow6432Node\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}\ShellFolder"; Name = "Attributes"; Value = 0xB0940064; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"; Name = "HubMode"; Value = 1; Type = "DWord"; Action = "Set" } # Rimuovi Accesso Rapido
        )
    },
    @{
        Name = "Disabilita Trasparenza dopo il Primo Riavvio"
        Description = "Disattiva gli effetti di trasparenza in Windows dopo il primo riavvio."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "EnableTransparency"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Illuminazione Ambientale"
        Description = "Disattiva le funzionalità di illuminazione ambientale."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Lighting"; Name = "AmbientLightingEnabled"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Rimuovi Suffisso '- Collegamento'"
        Description = "Rimuove il suffisso '- Collegamento' dai collegamenti appena creati."
        RegistryActions = @(
            @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"; Name = "link"; Value = ([byte[]](0x00,0x00,0x00,0x00)); Type = "Binary"; Action = "Set" }
        )
    },
    @{
        Name = "Nascondi Sezioni Centro Sicurezza Windows"
        Description = "Nasconde 'Opzioni famiglia', 'Prestazioni e integrità del dispositivo' e 'Protezione account' nel Centro Sicurezza Windows."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Family options"; Name = "UILockdown"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Device performance and health"; Name = "UILockdown"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Account protection"; Name = "UILockdown"; Value = 1; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Segnalazione Hotspot WiFi e Connessione Automatica"
        Description = "Disabilita la segnalazione degli hotspot WiFi e la connessione automatica agli hotspot WiFi Sense."
        RegistryActions = @(
            @{ Path = "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"; Name = "Value"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots"; Name = "Value"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Esecuzione WPBT"
        Description = "Disabilita l'esecuzione della Windows Platform Binary Table (WPBT)."
        RegistryActions = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"; Name = "DisableWpbtExecution"; Value = 1; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Aggiornamento Ultimo Accesso su NTFS"
        Description = "Impedisce a NTFS di aggiornare il timestamp 'Ultimo Accesso' su file e cartelle, migliorando potenzialmente le prestazioni."
        RegistryActions = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Name = "NtfsDisableLastAccessUpdate"; Value = 1; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Rilevamento Automatico Tipo Cartella"
        Description = "Impedisce a Esplora file di rilevare e modificare automaticamente i modelli di cartella."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell"; Name = "FolderType"; Value = "NotSpecified"; Type = "String"; Action = "Set" }
        )
    },
    @{
        Name = "Aumenta Icone Cache Massime"
        Description = "Aumenta il numero massimo di icone memorizzate nella cache da Windows, riducendo potenzialmente i problemi di ridisegno delle icone."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"; Name = "Max Cached Icons"; Value = 4096; Type = "String"; Action = "Set" } # Nota: Questo è solitamente un valore String nel Registro
        )
    },
    @{
        Name = "Ottimizza Priorità GPU per Giochi"
        Description = "Imposta una priorità GPU e CPU più alta per le applicazioni categorizzate come giochi."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Name = "GPU Priority"; Value = 8; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Name = "Priority"; Value = 6; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita DNS Multicast"
        Description = "Disabilita la funzionalità client DNS Multicast (mDNS)."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"; Name = "EnableMulticast"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Ricerca Internet 'Apri con'"
        Description = "Impedisce a Windows di cercare su Internet programmi per aprire tipi di file sconosciuti."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name = "NoInternetOpenWith"; Value = 1; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Abilita Num Lock all'Accesso"
        Description = "Assicura che il Num Lock sia abilitato automaticamente nella schermata di accesso e per l'utente corrente."
        RegistryActions = @(
            @{ Path = "HKU:\.DEFAULT\Control Panel\Keyboard"; Name = "InitialKeyboardIndicators"; Value = 2; Type = "String"; Action = "Set" }, # Nota: Questo è solitamente un valore String nel Registro
            @{ Path = "HKCU:\Control Panel\Keyboard"; Name = "InitialKeyboardIndicators"; Value = 2; Type = "String"; Action = "Set" } # Nota: Questo è solitamente un valore String nel Registro
        )
    },
    @{
        Name = "Nascondi 'Home' dalla Pagina Impostazioni"
        Description = "Nasconde la sezione 'Home' all'interno dell'applicazione Impostazioni di Windows."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name = "SettingsPageVisibility"; Value = "hide:home"; Type = "String"; Action = "Set" }
        )
    },
    @{
        Name = "Rimuovi 'Gruppo Home' dal Riquadro di Navigazione"
        Description = "Rimuove la voce 'Gruppo Home' dal riquadro di navigazione di Esplora file."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Classes\CLSID\{B4FB3F98-C1EA-428d-A78A-D1F5659CBA93}"; Name = "System.IsPinnedToNameSpaceTree"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Rimuovi 'Versioni Precedenti' dalla Scheda Proprietà"
        Description = "Rimuove la scheda 'Versioni Precedenti' dalle proprietà di file e cartelle."
        RegistryActions = @(
            @{ Path = "HKCR:\AllFilesystemObjects\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}"; Action = "RemoveKey" },
            @{ Path = "HKCR:\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}"; Action = "RemoveKey" },
            @{ Path = "HKCR:\Directory\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}"; Action = "RemoveKey" },
            @{ Path = "HKCR:\Drive\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}"; Action = "RemoveKey" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"; Name = "NoPreviousVersionsPage"; Action = "RemoveValue" }, # Cancella le policy
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"; Name = "NoPreviousVersionsPage"; Action = "RemoveValue" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\PreviousVersions"; Name = "DisableLocalPage"; Action = "RemoveValue" },
            @{ Path = "HKCU:\Software\Policies\Microsoft\PreviousVersions"; Name = "DisableLocalPage"; Action = "RemoveValue" }
        )
    },
    @{
        Name = "Rimuovi 'Quota' dalla Scheda Proprietà"
        Description = "Rimuove la scheda 'Quota' dalle proprietà dell'unità."
        RegistryActions = @(
            @{ Path = "HKCR:\Drive\shellex\PropertySheetHandlers\{7988B573-EC89-11cf-9C00-00AA00A14F56}"; Action = "RemoveKey" },
            @{ Path = "HKCR:\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\PropertySheetHandlers\{7988B573-EC89-11cf-9C00-00AA00A14F56}"; Action = "RemoveKey" },
            @{ Path = "HKCR:\Directory\shellex\PropertySheetHandlers\{7988B573-EC89-11cf-9C00-00AA00A14F56}"; Action = "RemoveKey" },
            @{ Path = "HKCR:\Drive\shellex\PropertySheetHandlers\{7988B573-EC89-11cf-9C00-00AA00A14F56}"; Action = "RemoveKey" }
            # Nota: Il file .reg originale includeva nuovamente la cancellazione delle policy per "NoPreviousVersionsPage" qui.
            # Supponendo che si trattasse di un errore di copia-incolla e non fosse inteso per Quota.
        )
    },
    @{
        Name = "Disabilita Prompt UAC per Amministratori"
        Description = "Impedisce i prompt del Controllo Account Utente (UAC) per gli amministratori (non raccomandato per la sicurezza)."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "ConsentPromptBehaviorAdmin"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "PromptOnSecureDesktop"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Suono Avvio"
        Description = "Disattiva il suono di avvio di Windows."
        RegistryActions = @(
            @{ Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\EditionOverrides"; Name = "UserSetting_DisableStartupSound"; Value = 1; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Riduzione Volume Audio (Ducking)"
        Description = "Impedisce a Windows di ridurre automaticamente il volume di altri suoni durante la comunicazione."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Multimedia\Audio"; Name = "UserDuckingPreference"; Value = 3; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Attivazione Vocale per App"
        Description = "Disattiva le funzionalità di attivazione vocale per le applicazioni."
        RegistryActions = @(
            @{ Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\SpeechOneCore\Settings"; Name = "AgentActivationEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\SpeechOneCore\Settings"; Name = "AgentActivationLastUsed"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Miglioramenti Audio"
        Description = "Disattiva i miglioramenti audio (es. bass boost, surround virtuale) per i dispositivi audio."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Multimedia\Audio\DeviceFx"; Name = "EnableDeviceEffects"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Audio Spaziale / Windows Sonic"
        Description = "Disattiva l'Audio Spaziale di Windows e Windows Sonic per Cuffie."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Audio"; Name = "EnableSpatialSound"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Ritardo Avvio Applicazioni"
        Description = "Disabilita il ritardo di avvio per le applicazioni all'avvio di Windows."
        RegistryActions = @(
            @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize"; Name = "StartupDelayInMSec"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Abilita Sfocatura Schermata di Blocco"
        Description = "Abilita l'effetto di sfocatura sullo sfondo della schermata di blocco."
        RegistryActions = @(
            @{ Path = "HKCU:\Control Panel\Desktop"; Name = "Background"; Value = "1"; Type = "String"; Action = "Set" }
        )
    },
    @{
        Name = "Sblocca Impostazioni Core Parking"
        Description = "Sblocca le impostazioni di Core Parking nella gestione dell'alimentazione di Windows."
        RegistryActions = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"; Name = "Attributes"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disattiva High Precision Event Timer (HPET)"
        Description = "Disattiva il High Precision Event Timer (HPET) per potenziali miglioramenti di latenza e prestazioni."
        RegistryActions = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel"; Name = "GlobalTimerResolutionRequestsDisabled"; Value = 1; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Riduci Input Lag (MaxPreRenderedFrames)"
        Description = "Riduce il lag di input impostando il numero massimo di frame pre-renderizzati a 1 per i driver grafici."
        RegistryActions = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Name = "MaxPreRenderedFrames"; Value = 1; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Aumenta Priorità Thread in Primo Piano"
        Description = "Aumenta la priorità dei thread in primo piano per migliorare la reattività del sistema."
        RegistryActions = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name = "Win32PrioritySeparation"; Value = 0x26; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Riduci Riserva CPU per Processi in Background"
        Description = "Riduce la quantità di CPU riservata per i processi in background, liberando risorse per le applicazioni in primo piano."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Name = "SystemResponsiveness"; Value = 0x0A; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Ottimizzazioni Microsoft Edge"
        Description = "Applica varie ottimizzazioni per Microsoft Edge, inclusa la disabilitazione di funzionalità non necessarie e la personalizzazione del comportamento."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "AddressBarMicrosoftSearchInBingProviderEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "AdsSettingForIntrusiveAdsSites"; Value = 2; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "AllowGamesMenu"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "BingAdsSuppression"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "BlockExternalExtensions"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "CryptoWalletEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "DiagnosticData"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "DnsOverHttpsMode"; Value = "secure"; Type = "String"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "DnsOverHttpsTemplates"; Value = "https://chrome.cloudflare-dns.com/dns-query"; Type = "String"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "EdgeCollectionsEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "EdgeDiscoverEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "EdgeFollowEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "EdgeShoppingAssistantEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "HideFirstRunExperience"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "HubsSidebarEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "MathSolverEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "MicrosoftEdgeInsiderPromotionEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "NewTabPageAllowedBackgroundTypes"; Value = 3; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "NewTabPageContentEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "NewTabPageHideDefaultTopSites"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "NewTabPageQuickLinksEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "NewTabPageSearchBox"; Value = "redirect"; Type = "String"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "PersonalizationReportingEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "PromotionalTabsEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "QuickSearchShowMiniMenu"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "ShowMicrosoftRewards"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "SleepingTabsEnabled"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "TabServicesEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "WebWidgetAllowed"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "WebWidgetIsEnabledOnStartup"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"; Name = "CreateDesktopShortcutDefault"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "EdgeEnhanceImagesEnabled"; Value = 0; Type = "DWord"; Action = "Set" }, # Aggiunto da input utente
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "UserFeedbackAllowed"; Value = 0; Type = "DWord"; Action = "Set" }, # Aggiunto da input utente
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "ConfigureDoNotTrack"; Value = 1; Type = "DWord"; Action = "Set" }, # Aggiornato da input utente
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "AlternateErrorPagesEnabled"; Value = 0; Type = "DWord"; Action = "Set" }, # Aggiunto da input utente
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "EdgeAssetDeliveryServiceEnabled"; Value = 0; Type = "DWord"; Action = "Set" }, # Aggiunto da input utente
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "WalletDonationEnabled"; Value = 0; Type = "DWord"; Action = "Set" } # Aggiunto da input utente
        )
    },
    @{
        Name = "Ottimizzazioni Effetti Visivi (Avanzato)"
        Description = "Imposta gli effetti visivi su 'Personalizzato', abilita la smussatura dei caratteri e disattiva animazioni superflue per migliorare le prestazioni visive."
        RegistryActions = @(
            @{ Path = "HKCU:\Control Panel\Desktop"; Name = "FontSmoothing"; Value = "2"; Type = "String"; Action = "Set" },
            @{ Path = "HKCU:\Control Panel\Desktop"; Name = "DragFullWindows"; Value = "1"; Type = "String"; Action = "Set" },
            @{ Path = "HKCU:\Control Panel\Desktop\WindowMetrics"; Name = "FontSmoothingType"; Value = 2; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\DWM"; Name = "EnableAeroPeek"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarAnimations"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ListviewAlphaSelect"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ListviewShadow"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ListviewWatermark"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ListviewHoverSelect"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "DisablePreviewDesktop"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\DWM"; Name = "ColorPrevalence"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\DWM"; Name = "EnableWindowColorization"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Feed Attività"
        Description = "Disabilita la funzionalità del Feed Attività di Windows."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "EnableActivityFeed"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Xbox Game Bar e Registrazione Schermo"
        Description = "Disattiva tutte le funzionalità relative a Xbox Game Bar, inclusa la registrazione dello schermo e la modalità gioco automatica."
        RegistryActions = @(
            @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_Enabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"; Name = "AllowGameDVR"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\System\CurrentControlSet\Services\BcastDVRUserService"; Name = "Start"; Value = 4; Type = "DWord"; Action = "Set" }, # Dal gruppo Game DVR precedente
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"; Name = "AppCaptureEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"; Name = "AutoGameModeEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\SOFTWARE\Microsoft\GameBar"; Name = "UseNexusForGameBarEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\SOFTWARE\Microsoft\GameBar"; Name = "ShowStartupPanel"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\SOFTWARE\Microsoft\GameBar"; Name = "AutoGameModeEnabled"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Abilita/Disabilita Modalità Gioco"
        Description = "Controlla l'attivazione della Modalità Gioco di Windows per ottimizzare le prestazioni durante il gaming. (Abilita: 1, Disabilita: 0)"
        RegistryActions = @(
            @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameMode_Enabled"; Value = 1; Type = "DWord"; Action = "Set" } # Impostato su 1 per abilitare, può essere cambiato a 0 per disabilitare
        )
    },
    @{
        Name = "Disabilita Download Automatico Mappe"
        Description = "Disabilita il download e l'aggiornamento automatico dei dati delle mappe di Windows."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps"; Name = "AllowUntriggeredNetworkTrafficOnSettingsPage"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps"; Name = "AutoDownloadAndUpdateMapData"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Fotocamera Schermata di Blocco"
        Description = "Disabilita l'accesso alla fotocamera direttamente dalla schermata di blocco di Windows."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"; Name = "NoLockScreenCamera"; Value = 1; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Biometria (Potrebbe Comprometter Windows Hello)"
        Description = "Disabilita le funzionalità biometriche di Windows. Attenzione: questo potrebbe impedire il funzionamento di Windows Hello."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Biometrics"; Name = "Enabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Biometrics\Credential Provider"; Name = "Enabled"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Tasti Permanenti"
        Description = "Disabilita la funzionalità di accessibilità Tasti Permanenti (Sticky Keys)."
        RegistryActions = @(
            @{ Path = "HKCU:\Control Panel\Accessibility\StickyKeys"; Name = "Flags"; Value = "58"; Type = "String"; Action = "Set" }
        )
    },
    @{
        Name = "Abilita Schermata Blu Dettagliata (BSOD)"
        Description = "Abilita la visualizzazione dei parametri dettagliati sulla schermata blu (BSOD) in caso di crash del sistema."
        RegistryActions = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl"; Name = "DisplayParameters"; Value = 1; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Abilita Accesso Dettagliato (Verbose Logon)"
        Description = "Abilita messaggi di stato dettagliati durante l'accesso e la disconnessione di Windows."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "VerboseStatus"; Value = 1; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Aggiungi 'Termina Attività' alla Barra delle Applicazioni"
        Description = "Aggiunge l'opzione 'Termina attività' al menu contestuale delle applicazioni nella barra delle applicazioni per chiuderle rapidamente."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"; Name = "TaskbarEndTask"; Value = 1; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Abilita Tema Scuro per App e Sistema"
        Description = "Imposta il tema scuro per le applicazioni e l'interfaccia di sistema, riducendo l'affaticamento degli occhi e migliorando l'estetica."
        RegistryActions = @(
            @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "AppsUseLightTheme"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "SystemUsesLightTheme"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Imposta Dimensione File di Paging (4096-8192 MB)"
        Description = "Imposta la dimensione iniziale e massima del file di paging (memoria virtuale) a 4096 MB e 8192 MB rispettivamente. Abilita anche la pulizia del file di paging allo spegnimento."
        RegistryActions = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name = "PagingFiles"; Value = "C:\\pagefile.sys 4096 8192"; Type = "MultiString"; Action = "Set" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name = "ClearPageFileAtShutdown"; Value = 1; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Teredo"
        Description = "Disabilita il tunneling Teredo per IPv6."
        RegistryActions = @(
            @{ Action = "RunCommand"; Command = "netsh interface teredo set state disabled" }
        )
    },
    @{
        Name = "Kill Intel LMS Service (Avanzato)"
        Description = "Arresta, disabilita e rimuove il servizio Intel Management and Security Application Local Management Service (LMS), inclusi driver e file."
        RegistryActions = @(
            @{ Action = "RunFunction"; FunctionName = "Perform-KillLMS" }
        )
    },
    @{
        Name = "Duplica Schema Alimentazione (Massime Prestazioni)"
        Description = "Duplica lo schema di alimentazione 'Massime Prestazioni' per creare un nuovo schema personalizzato."
        RegistryActions = @(
            @{ Action = "RunCommand"; Command = "powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61" }
        )
    },
    @{
        Name = "Disabilita Ibernazione"
        Description = "Disabilita la funzionalità di ibernazione di Windows."
        RegistryActions = @(
            @{ Action = "RunCommand"; Command = "powercfg.exe /hibernate off" }
        )
    },
    @{
        Name = "Ottimizzazioni Avanzate di Sistema"
        Description = "Applica una serie di ottimizzazioni avanzate, inclusi BCDedit, Task Manager, pulizia policy Edge, raggruppamento Svchost, pulizia AutoLogger e disabilitazione invio campioni Defender."
        RegistryActions = @(
            @{ Action = "RunFunction"; FunctionName = "Perform-AdvancedSystemTweaks" }
        )
    },
    @{
        Name = "Disabilita Tracciamento Posizione"
        Description = "Disabilita il tracciamento della posizione a livello di sistema."
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"; Name = "Value"; Value = "Deny"; Type = "String"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"; Name = "SensorPermissionState"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration"; Name = "Status"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SYSTEM\Maps"; Name = "AutoUpdateEnabled"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Icona/Casella di Ricerca nella Barra delle Applicazioni"
        Description = "Nasconde l'icona o la casella di ricerca dalla barra delle applicazioni di Windows."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "SearchboxTaskbarMode"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Widget Barra delle Applicazioni"
        Description = "Rimuove il pulsante Widget dalla barra delle applicazioni di Windows."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarDa"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"; Name = "ShellFeedsTaskbarViewMode"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Animazioni Finestre e Menu"
        Description = "Disattiva animazioni di finestre, menu, tooltip e altri effetti di dissolvenza/scorrimento per migliorare la reattività dell'interfaccia utente."
        RegistryActions = @(
            @{ Path = "HKCU:\Control Panel\Desktop"; Name = "UserPreferencesMask"; Value = ([byte[]](144,18,3,128,16,0,0,0)); Type = "Binary"; Action = "Set" }
        )
    },
    @{
        Name = "Disabilita Attività Pianificate Inutili"
        Description = "Disabilita varie attività pianificate di sistema relative a telemetria, esperienza utente, feedback, sicurezza familiare, aggiornamenti e OneDrive, per migliorare privacy e prestazioni."
        RegistryActions = @(
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\Customer Experience Improvement Program\"; TaskName = "UsbCeip" },
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\Customer Experience Improvement Program\"; TaskName = "KernelCeipTask" },
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\Customer Experience Improvement Program\"; TaskName = "Consolidator" },
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\Application Experience\"; TaskName = "ProgramDataUpdater" },
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\Autochk\"; TaskName = "Proxy" },
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\DiskDiagnostic\"; TaskName = "Microsoft-Windows-DiskDiagnosticDataCollector" },
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\Feedback\Siuf\"; TaskName = "DmClient" },
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\Feedback\Siuf\"; TaskName = "DmClientOnScenarioDownload" },
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\PushToInstall\"; TaskName = "LoginCheck" },
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\Shell\"; TaskName = "FamilySafetyMonitor" },
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\Shell\"; TaskName = "FamilySafetyRefresh" },
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\UpdateOrchestrator\"; TaskName = "StartOobeAppsScanAfterUpdate" },
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\UpdateOrchestrator\"; TaskName = "Start Oobe Expedite Work" },
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\UpdateOrchestrator\"; TaskName = "Schedule Scan" },
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\WindowsUpdate\"; TaskName = "Scheduled Start" },
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\OneDrive\"; TaskName = "OneDrive*" }, # Modificato per usare il wildcard
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\WS\"; TaskName = "WSTask" }
        )
    },
    @{
        Name = "Disabilita Servizi Inutili"
        Description = "Disabilita una serie di servizi Windows non essenziali per migliorare le prestazioni e ridurre l'utilizzo delle risorse."
        RegistryActions = @(
            @{ Action = "DisableService"; ServiceName = "vmicguestinterface" },
            @{ Action = "DisableService"; ServiceName = "vmicvss" },
            @{ Action = "DisableService"; ServiceName = "vmicshutdown" },
            @{ Action = "DisableService"; ServiceName = "vmicheartbeat" },
            @{ Action = "DisableService"; ServiceName = "vmicvmsession" },
            @{ Action = "DisableService"; ServiceName = "vmickvpexchange" },
            @{ Action = "DisableService"; ServiceName = "vmictimesync" },
            @{ Action = "DisableService"; ServiceName = "vmicrdv" },
            @{ Action = "DisableService"; ServiceName = "RasAuto" },
            @{ Action = "DisableService"; ServiceName = "workfolderssvc" },
            @{ Action = "DisableService"; ServiceName = "RasMan" },
            @{ Action = "DisableService"; ServiceName = "DusmSvc" },
            @{ Action = "DisableService"; ServiceName = "UmRdpService" },
            @{ Action = "DisableService"; ServiceName = "LanmanServer" },
            @{ Action = "DisableService"; ServiceName = "TermService" },
            @{ Action = "DisableService"; ServiceName = "SensorDataService" },
            @{ Action = "DisableService"; ServiceName = "RetailDemo" },
            @{ Action = "DisableService"; ServiceName = "ScDeviceEnum" },
            @{ Action = "DisableService"; ServiceName = "RmSvc" },
            @{ Action = "DisableService"; ServiceName = "SensrSvc" },
            @{ Action = "DisableService"; ServiceName = "PhoneSvc" },
            @{ Action = "DisableService"; ServiceName = "SCardSvr" },
            @{ Action = "DisableService"; ServiceName = "TapiSrv" },
            @{ Action = "DisableService"; ServiceName = "WSearch" },
            @{ Action = "DisableService"; ServiceName = "LanmanWorkstation" },
            @{ Action = "DisableService"; ServiceName = "MapsBroker" },
            @{ Action = "DisableService"; ServiceName = "SensorService" },
            @{ Action = "DisableService"; ServiceName = "lfsvc" },
            @{ Action = "DisableService"; ServiceName = "PcaSvc" },
            @{ Action = "DisableService"; ServiceName = "SCPolicySvc" },
            @{ Action = "DisableService"; ServiceName = "seclogon" },
            @{ Action = "DisableService"; ServiceName = "SmsRouter" },
            @{ Action = "DisableService"; ServiceName = "wisvc" },
            @{ Action = "DisableService"; ServiceName = "StiSvc" },
            @{ Action = "DisableService"; ServiceName = "CscService" },
            @{ Action = "DisableService"; ServiceName = "WdiSystemHost" },
            @{ Action = "DisableService"; ServiceName = "HvHost" },
            @{ Action = "DisableService"; ServiceName = "SysMain" },
            @{ Action = "DisableService"; ServiceName = "XblAuthManager" },
            @{ Action = "DisableService"; ServiceName = "XblGameSave" },
            @{ Action = "DisableService"; ServiceName = "XboxNetApiSvc" },
            @{ Action = "DisableService"; ServiceName = "XboxGipSvc" },
            @{ Action = "DisableService"; ServiceName = "SessionEnv" },
            @{ Action = "DisableService"; ServiceName = "WpcMonSvc" },
            @{ Action = "DisableService"; ServiceName = "DiagTrack" },
            @{ Action = "DisableService"; ServiceName = "SEMgrSvc" },
            @{ Action = "DisableService"; ServiceName = "MicrosoftEdgeElevationService" },
            @{ Action = "DisableService"; ServiceName = "edgeupdate" },
            @{ Action = "DisableService"; ServiceName = "edgeupdatem" },
            @{ Action = "DisableService"; ServiceName = "CryptSvc" },
            @{ Action = "DisableService"; ServiceName = "BDESVC" },
            @{ Action = "DisableService"; ServiceName = "WbioSrvc" },
            @{ Action = "DisableService"; ServiceName = "bthserv" },
            @{ Action = "DisableService"; ServiceName = "BTAGService" },
            @{ Action = "DisableService"; ServiceName = "PrintNotify" },
            @{ Action = "DisableService"; ServiceName = "WMPNetworkSvc" },
            @{ Action = "DisableService"; ServiceName = "wercplsupport" },
            @{ Action = "DisableService"; ServiceName = "wcncsvc" }
        )
    },
    @{
        Name = "Disabilita Sensore di Archiviazione"
        Description = "Disabilita la funzionalità di Sensore di Archiviazione di Windows, che pulisce automaticamente i file temporanei e il contenuto del cestino."
        RegistryActions = @(
            @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"; Name = "01"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Disinstalla App Predefinite (Bloatware)"
        Description = "Disinstalla una selezione di applicazioni predefinite di Windows che sono spesso considerate bloatware, inclusa la disabilitazione di Copilot."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*Clipchamp*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*BingNews*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*BingSearch*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*BingWeather*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*GamingApp*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*GetHelp*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*MicrosoftOfficeHub*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*MicrosoftSolitaireCollection*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*MicrosoftStickyNotes*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*OutlookForWindows*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*Paint*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*PowerAutomateDesktop*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*ScreenSketch*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*Todos*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*DevHome*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*WindowsCamera*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*WindowsFeedbackHub*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*WindowsSoundRecorder*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*WindowsTerminal*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*Xbox.TCUI*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*XboxGamingOverlay*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*XboxIdentityProvider*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*XboxSpeechToTextOverlay*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*YourPhone*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*ZuneMusic*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*QuickAssist*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*MSTeams*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*WindowsAlarms*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*MicrosoftWindows.Client.AI.Copilot*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*Microsoft.Windows.Copilot*" },
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "*Microsoft.CoPilot*" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"; Name = "TurnOffWindowsCopilot"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"; Name = "TurnOffWindowsCopilot"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"; Name = "AutoOpenCopilotLargeScreens"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowCopilotButton"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\Shell\Copilot\BingChat"; Name = "IsUserEligible"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "HubsSidebarEnabled"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Rimuovi OneDrive (Completo)"
        Description = "Disinstalla completamente OneDrive dal sistema, inclusi i file, le voci di registro e le attività pianificate, e ripristina le posizioni predefinite delle cartelle utente."
        RegistryActions = @(
            @{ Action = "RunFunction"; FunctionName = "Perform-UninstallOneDrive" }
        )
    },
    @{
        Name = "Abilita/Disabilita Protezione in tempo reale di Windows Defender"
        Description = "Controlla lo stato della protezione in tempo reale di Windows Defender. (Abilita: 0, Disabilita: 1)"
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection"; Name = "DisableRealtimeMonitoring"; Value = 0; Type = "DWord"; Action = "Set" } # 0 per abilitare, 1 per disabilitare
        )
    },
    @{
        Name = "Abilita/Disabilita Aggiornamenti Automatici di Windows"
        Description = "Controlla il comportamento degli aggiornamenti automatici di Windows. (Abilita: 0, Disabilita: 1)"
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"; Name = "NoAutoUpdate"; Value = 0; Type = "DWord"; Action = "Set" } # 0 per abilitare, 1 per disabilitare
        )
    },
    @{
        Name = "Mostra/Nascondi Estensioni File"
        Description = "Mostra o nasconde le estensioni dei file in Esplora risorse. (Mostra: 0, Nascondi: 1)"
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "HideFileExt"; Value = 0; Type = "DWord"; Action = "Set" } # 0 per mostrare, 1 per nascondere
        )
    },
    @{
        Name = "Abilita/Disabilita Ripristino Configurazione di Sistema"
        Description = "Abilita o disabilita la creazione di punti di ripristino del sistema. (Abilita: 0, Disabilita: 1)"
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"; Name = "DisableSR"; Value = 0; Type = "DWord"; Action = "Set" } # 0 per abilitare, 1 per disabilitare
        )
    },
    @{
        Name = "Abilita/Disabilita Accelerazione Hardware GPU"
        Description = "Controlla l'accelerazione hardware GPU (Hardware-accelerated GPU scheduling). (Abilita: 2, Disabilita: 0)"
        RegistryActions = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Name = "HwSchMode"; Value = 2; Type = "DWord"; Action = "Set" } # 2 per abilitare, 0 per disabilitare
        )
    },
    @{
        Name = "Imposta Effetti Visivi su Prestazioni/Qualità"
        Description = "Imposta gli effetti visivi di Windows per privilegiare le prestazioni (3) o la qualità visiva (0). (Prestazioni: 3, Qualità: 0)"
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"; Name = "VisualFXSetting"; Value = 3; Type = "DWord"; Action = "Set" } # 3 per prestazioni, 0 per qualità
        )
    },
    @{
        Name = "Abilita/Disabilita Ottimizzazione Recapito"
        Description = "Controlla l'Ottimizzazione Recapito di Windows, che consente il download di aggiornamenti da altri PC sulla rete locale o su Internet. (Abilita: 0, Disabilita: 99)"
        RegistryActions = @(
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"; Name = "DODownloadMode"; Value = 0; Type = "DWord"; Action = "Set" } # 0 per abilitare (modalità HTTP), 99 per disabilitare
        )
    },
    @{
        Name = "Ottimizzazione Processore Scheda di Rete Integrata"
        Description = "Applica ottimizzazioni per la scheda di rete, inclusa la disabilitazione del risparmio energetico e l'abilitazione di Receive Side Scaling (RSS)."
        RegistryActions = @(
            @{ Action = "RunFunction"; FunctionName = "Optimize-NetworkAdapter" }
        )
    },
    @{
        Name = "Disabilita Pulsante Visualizzazione Attività e Funzioni Barra delle Applicazioni"
        Description = "Disabilita il pulsante Visualizzazione Attività e altre funzioni specifiche della barra delle applicazioni."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowTaskViewButton"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Ripristina Interfaccia Utente (UI) e Sfondo Desktop"
        Description = "Ripristina le impostazioni predefinite dell'interfaccia utente e riavvia Explorer.exe per risolvere problemi visivi e del menu Start, preservando il tuo sfondo desktop esistente."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"; Name = "VisualFXSetting"; Value = 1; Type = "DWord"; Action = "Set" }, # Imposta su Personalizzato (per un reset stabile)
            @{ Path = "HKCU:\Control Panel\Desktop"; Name = "FontSmoothing"; Value = "2"; Type = "String"; Action = "Set" }, # ClearType
            @{ Path = "HKCU:\Control Panel\Desktop"; Name = "DragFullWindows"; Value = "1"; Type = "String"; Action = "Set" }, # Mostra il contenuto della finestra durante il trascinamento
            @{ Action = "RunCommand"; Command = "taskkill /f /im explorer.exe & start explorer" } # Riavvia Explorer
        )
    }
)
#endregion

#region Funzioni GUI
Function Show-MessageBox {
    Param (
        [string]$Message,
        [string]$Title = "Informazioni",
        [System.Windows.Forms.MessageBoxButtons]$Buttons = "OK",
        [System.Windows.Forms.MessageBoxIcon]$Icon = "Information"
    )
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, $Buttons, $Icon)
}

Function Set-RegistryValue {
    Param (
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type
    )
    Try {
        # Assicurati che il percorso padre esista prima di impostare la proprietà
        $ParentPath = Split-Path -Path $Path -Parent
        If (-not (Test-Path $ParentPath)) {
            New-Item -Path $ParentPath -Force | Out-Null
        }
        
        # Converte il tipo stringa in enum RegistryValueKind
        $RegistryValueKind = [Microsoft.Win32.RegistryValueKind]::$Type

        Set-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -Force -ErrorAction Stop -Type $RegistryValueKind
        $Script:LogTextBox.AppendText("SUCCESSO: Impostato '$Name' su '$Value' in '$Path'`r`n")
    }
    Catch {
        $Script:LogTextBox.AppendText("ERRORE: Impossibile impostare '$Name' in '$Path'. Errore: $($_.Exception.Message)`r`n")
    }
}

Function Remove-RegistryValue {
    Param (
        [string]$Path,
        [string]$Name
    )
    Try {
        If (Test-Path -LiteralPath $Path) {
            Remove-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop -Force
            $Script:LogTextBox.AppendText("SUCCESSO: Rimosso valore '$Name' da '$Path'`r`n")
        } else {
            $Script:LogTextBox.AppendText("INFO: Il percorso '$Path' non esiste, il valore '$Name' non è stato rimosso.`r`n")
        }
    }
    Catch {
        $Script:LogTextBox.AppendText("ERRORE: Impossibile rimuovere il valore '$Name' da '$Path'. Errore: $($_.Exception.Message)`r`n")
    }
}

Function Remove-RegistryKey {
    Param (
        [string]$Path
    )
    Try {
        If (Test-Path -LiteralPath $Path) {
            Remove-Item -LiteralPath $Path -Recurse -ErrorAction Stop -Force
            $Script:LogTextBox.AppendText("SUCCESSO: Rimosso chiave '$Path'`r`n")
        } else {
            $Script:LogTextBox.AppendText("INFO: La chiave '$Path' non esiste, non è stata rimossa.`r`n")
        }
    }
    Catch {
        $Script:LogTextBox.AppendText("ERRORE: Impossibile rimuovere la chiave '$Path'. Errore: $($_.Exception.Message)`r`n")
    }
}

Function Uninstall-AppxPackage {
    Param (
        [string]$AppxPackageNamePattern # Changed name to reflect it can be a pattern
    )
    Try {
        # Trova i pacchetti che corrispondono al pattern per PackageFullName o Name
        $packagesToUninstall = Get-AppxPackage -AllUsers | Where-Object {
            $_.PackageFullName -like $AppxPackageNamePattern -or $_.Name -like $AppxPackageNamePattern
        }

        if ($packagesToUninstall) {
            foreach ($package in $packagesToUninstall) {
                $Script:LogTextBox.AppendText("Tentativo di disinstallare: $($package.PackageFullName)`r`n")
                Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop
                $Script:LogTextBox.AppendText("SUCCESSO: Disinstallato '$($package.PackageFullName)' per tutti gli utenti.`r`n")
            }
        } else {
            $Script:LogTextBox.AppendText("INFO: Nessun pacchetto corrispondente a '$AppxPackageNamePattern' trovato per la disinstallazione.`r`n")
        }
    }
    Catch {
        $Script:LogTextBox.AppendText("ERRORE: Eccezione durante la disinstallazione di '$AppxPackageNamePattern'. Errore: $($_.Exception.Message)`r`n")
    }
}

Function Disable-ScheduledTaskAction {
    Param (
        [string]$TaskPath,
        [string]$TaskNamePattern # Use pattern for flexibility
    )
    Try {
        $tasks = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskNamePattern -ErrorAction SilentlyContinue

        If ($tasks) {
            ForEach ($task in $tasks) {
                Try {
                    Disable-ScheduledTask -InputObject $task -ErrorAction Stop
                    $Script:LogTextBox.AppendText("SUCCESSO: Disabilitata attività pianificata '$($task.TaskPath)$($task.TaskName)'.`r`n")
                }
                Catch {
                    $Script:LogTextBox.AppendText("ERRORE: Impossibile disabilitare attività pianificata '$($task.TaskPath)$($task.TaskName)'. Causa: $($_.Exception.Message). Potrebbe essere protetta dal sistema.`r`n")
                }
            }
        } else {
            $Script:LogTextBox.AppendText("INFO: Attività pianificata '$TaskPath$TaskNamePattern' non trovata, non disabilitata.`r`n")
        }
    }
    Catch {
        # This outer catch would only trigger if Get-ScheduledTask itself fails, which is less common.
        $Script:LogTextBox.AppendText("ERRORE GENERALE: Impossibile cercare attività pianificate per '$TaskPath$TaskNamePattern'. Errore: $($_.Exception.Message)`r`n")
    }
}

Function Disable-ServiceAction {
    Param (
        [string]$ServiceName
    )
    Try {
        # Check if the service exists before attempting to disable
        If (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
            Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction Stop
            $Script:LogTextBox.AppendText("SUCCESSO: Servizio '$ServiceName' disabilitato.`r`n")
        } else {
            $Script:LogTextBox.AppendText("INFO: Servizio '$ServiceName' non trovato, non disabilitato.`r`n")
        }
    }
    Catch {
        $Script:LogTextBox.AppendText("ERRORE: Impossibile disabilitare il servizio '$ServiceName'. Errore: $($_.Exception.Message)`r`n")
    }
}

Function Run-CommandAction {
    Param (
        [string]$Command
    )
    Try {
        $Script:LogTextBox.AppendText("Esecuzione comando: $Command`r`n")
        # Using Start-Process for commands that might require elevation or run external executables
        # -NoNewWindow hides the console window that might briefly appear for some commands
        # Removed -ErrorAction SilentlyContinue from Start-Process as it's a PowerShell parameter
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command `"$Command`"" -Verb RunAs -PassThru -WindowStyle Hidden
        $process.WaitForExit()
        If ($process.ExitCode -eq 0) {
            $Script:LogTextBox.AppendText("SUCCESSO: Comando eseguito: '$Command'.`r`n")
        } Else {
            $Script:LogTextBox.AppendText("ERRORE: Fallita esecuzione comando '$Command'. Codice di uscita: $($process.ExitCode).`r`n")
            $Script:LogTextBox.AppendText("Potrebbe essere necessario eseguire lo script come amministratore o il pacchetto Winget potrebbe non esistere/essere valido.`r`n") # Added this line
        }
    }
    Catch {
        $Script:LogTextBox.AppendText("ERRORE: Eccezione durante l'esecuzione del comando '$Command'. Errore: $($_.Exception.Message)`r`n")
    }
}

Function Perform-KillLMS {
    $Script:LogTextBox.AppendText("--- Avvio 'Kill LMS' (Intel Management and Security Application Local Management Service) ---`r`n")
    $serviceName = "LMS"

    Try {
        $Script:LogTextBox.AppendText("Tentativo di arrestare e disabilitare il servizio: $serviceName`r`n")
        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
        Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue
        $Script:LogTextBox.AppendText("Servizio '$serviceName' arrestato e disabilitato (se esistente).`r`n")
    } Catch {
        $Script:LogTextBox.AppendText("AVVISO: Impossibile arrestare/disabilitare il servizio '$serviceName'. Errore: $($_.Exception.Message)`r`n")
    }

    Try {
        $Script:LogTextBox.AppendText("Tentativo di rimuovere il servizio: $serviceName`r`n")
        # Use sc.exe directly as Remove-Service cmdlet might not be available or reliable for all services
        $process = Start-Process -FilePath "sc.exe" -ArgumentList "delete", "$serviceName" -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
        $process.WaitForExit()
        If ($process.ExitCode -eq 0) {
            $Script:LogTextBox.AppendText("SUCCESSO: Servizio '$serviceName' rimosso.`r`n")
        } Else {
            $Script:LogTextBox.AppendText("AVVISO: Impossibile rimuovere il servizio '$serviceName'. Codice di uscita: $($process.ExitCode). Potrebbe non esistere già.`r`n")
        }
    } Catch {
        $Script:LogTextBox.AppendText("ERRORE: Eccezione durante la rimozione del servizio '$serviceName'. Errore: $($_.Exception.Message)`r`n")
    }

    $Script:LogTextBox.AppendText("Rimozione pacchetti driver LMS...`r`n")
    Try {
        $lmsDriverPackages = Get-ChildItem -Path "C:\Windows\System32\DriverStore\FileRepository" -Recurse -Filter "lms.inf*" -ErrorAction SilentlyContinue
        if ($lmsDriverPackages) {
            foreach ($package in $lmsDriverPackages) {
                $Script:LogTextBox.AppendText("Rimozione pacchetto driver: $($package.Name)`r`n")
                $process = Start-Process -FilePath "pnputil.exe" -ArgumentList "/delete-driver", "$($package.Name)", "/uninstall", "/force" -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
                $process.WaitForExit()
                If ($process.ExitCode -eq 0) {
                    $Script:LogTextBox.AppendText("SUCCESSO: Pacchetto driver '$($package.Name)' rimosso.`r`n")
                } Else {
                    $Script:LogTextBox.AppendText("AVVISO: Impossibile rimuovere il pacchetto driver '$($package.Name)'. Codice di uscita: $($process.ExitCode).`r`n")
                }
            }
            $Script:LogTextBox.AppendText("Tutti i pacchetti driver LMS trovati sono stati rimossi.`r`n")
        } else {
            $Script:LogTextBox.AppendText("Nessun pacchetto driver LMS trovato nel driver store.`r`n")
        }
    } Catch {
        $Script:LogTextBox.AppendText("ERRORE: Eccezione durante la rimozione dei pacchetti driver LMS. Errore: $($_.Exception.Message)`r`n")
    }

    $Script:LogTextBox.AppendText("Ricerca ed eliminazione file eseguibili LMS...`r`n")
    Try {
        $programFilesDirs = @("C:\Program Files", "C:\Program Files (x86)")
        $lmsFiles = @()
        foreach ($dir in $programFilesDirs) {
            $lmsFiles += Get-ChildItem -Path $dir -Recurse -Filter "LMS.exe" -ErrorAction SilentlyContinue
        }

        if ($lmsFiles.Count -gt 0) {
            foreach ($file in $lmsFiles) {
                $Script:LogTextBox.AppendText("Tentativo di prendere possesso del file: $($file.FullName)`r`n")
                # Take ownership and grant full control to Administrators
                & icacls "$($file.FullName)" /grant Administrators:F /T /C /Q | Out-Null
                & takeown /F "$($file.FullName)" /A /R /D Y | Out-Null
                $Script:LogTextBox.AppendText("Eliminazione file: $($file.FullName)`r`n")
                Remove-Item -LiteralPath $($file.FullName) -Recurse -Force -ErrorAction SilentlyContinue
                If (-not (Test-Path -LiteralPath $($file.FullName))) {
                    $Script:LogTextBox.AppendText("SUCCESSO: File '$($file.FullName)' eliminato.`r`n")
                } else {
                    $Script:LogTextBox.AppendText("AVVISO: Impossibile eliminare il file '$($file.FullName)'.`r`n")
                }
            }
            $Script:LogTextBox.AppendText("Tutti i file LMS.exe trovati sono stati eliminati.`r`n")
        } else {
            $Script:LogTextBox.AppendText("Nessun file LMS.exe trovato nelle directory Program Files.`r`n")
        }
    } Catch {
        $Script:LogTextBox.AppendText("ERRORE: Eccezione durante la gestione dei file LMS. Errore: $($_.Exception.Message)`r`n")
    }

    $Script:LogTextBox.AppendText("Servizio Intel LMS vPro disabilitato, rimosso e bloccato.`r`n")
    $Script:LogTextBox.AppendText("--- Fine 'Kill LMS' ---`r`n")
}

Function Perform-AdvancedSystemTweaks {
    $Script:LogTextBox.AppendText("--- Avvio Ottimizzazioni Avanzate di Sistema ---`r`n")

    Try {
        $Script:LogTextBox.AppendText("Impostazione Boot Menu Policy su Legacy...`r`n")
        Run-CommandAction "bcdedit /set `{current`} bootmenupolicy Legacy"
    } Catch {
        $Script:LogTextBox.AppendText("ERRORE: Impossibile impostare Boot Menu Policy. Errore: $($_.Exception.Message)`r`n")
    }

    Try {
        $Script:LogTextBox.AppendText("Tentativo di risolvere il problema delle preferenze di Task Manager (solo per build < 22557)...`r`n")
        If ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild).CurrentBuild -lt 22557) {
            $taskmgr = Start-Process -WindowStyle Hidden -FilePath taskmgr.exe -PassThru -ErrorAction SilentlyContinue
            If ($taskmgr) {
                Do {
                    Start-Sleep -Milliseconds 100
                    $preferences = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -ErrorAction SilentlyContinue
                } Until ($preferences)
                Stop-Process $taskmgr -Force -ErrorAction SilentlyContinue
                If ($preferences) {
                    $preferences.Preferences[28] = 0
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -Type Binary -Value $preferences.Preferences -Force -ErrorAction SilentlyContinue
                    $Script:LogTextBox.AppendText("SUCCESSO: Preferenze Task Manager aggiornate.`r`n")
                } else {
                    $Script:LogTextBox.AppendText("AVVISO: Impossibile recuperare le preferenze di Task Manager.`r`n")
                }
            } else {
                $Script:LogTextBox.AppendText("AVVISO: Impossibile avviare Task Manager per modificare le preferenze.`r`n")
            }
        } else {
            $Script:LogTextBox.AppendText("INFO: Build di Windows >= 22557, salto la modifica delle preferenze di Task Manager.`r`n")
        }
    } Catch {
        $Script:LogTextBox.AppendText("ERRORE: Eccezione durante la modifica delle preferenze di Task Manager. Errore: $($_.Exception.Message)`r`n")
    }

    Try {
        $Script:LogTextBox.AppendText("Rimozione della voce 'Oggetti 3D' da Esplora File...`r`n")
        Remove-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
        Remove-RegistryKey -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
    } Catch {
        $Script:LogTextBox.AppendText("ERRORE: Impossibile rimuovere la voce 'Oggetti 3D'. Errore: $($_.Exception.Message)`r`n")
    }

    Try {
        $Script:LogTextBox.AppendText("Pulizia delle policy di Microsoft Edge (se gestite dall'organizzazione)...`r`n")
        If (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge") {
            Remove-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
        } else {
            $Script:LogTextBox.AppendText("INFO: Percorso del Registro 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' non trovato, nessuna policy Edge da rimuovere.`r`n")
        }
    } Catch {
        $Script:LogTextBox.AppendText("ERRORE: Impossibile rimuovere le policy di Microsoft Edge. Errore: $($_.Exception.Message)`r`n")
    }

    Try {
        $Script:LogTextBox.AppendText("Raggruppamento dei processi svchost.exe in base alla RAM disponibile...`r`n")
        $ram = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1MB # Converti in MB
        Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Type "DWord" -Value ($ram * 1024) # Converti in KB
    } Catch {
        $Script:LogTextBox.AppendText("ERRORE: Impossibile raggruppare i processi svchost.exe. Errore: $($_.Exception.Message)`r`n")
    }

    Try {
        $Script:LogTextBox.AppendText("Disabilitazione del listener AutoLogger-Diagtrack-Listener.etl...`r`n")
        $autoLoggerDir = "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger"
        If (Test-Path "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl") {
            Remove-Item "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl" -Force -ErrorAction SilentlyContinue
            $Script:LogTextBox.AppendText("SUCCESSO: File 'AutoLogger-Diagtrack-Listener.etl' rimosso.`r`n")
        } else {
            $Script:LogTextBox.AppendText("INFO: File 'AutoLogger-Diagtrack-Listener.etl' non trovato, nessuna azione necessaria.`r`n")
        }
        $process = Start-Process -FilePath "icacls.exe" -ArgumentList "$autoLoggerDir", "/deny", "SYSTEM:(OI)(CI)F" -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
        $process.WaitForExit()
        If ($process.ExitCode -eq 0) {
            $Script:LogTextBox.AppendText("SUCCESSO: Permessi su '$autoLoggerDir' modificati per negare l'accesso a SYSTEM.`r`n")
        } Else {
            $Script:LogTextBox.AppendText("AVVISO: Impossibile modificare i permessi su '$autoLoggerDir'. Codice di uscita: $($process.ExitCode).`r`n")
        }
    } Catch {
        $Script:LogTextBox.AppendText("ERRORE: Eccezione durante la disabilitazione di AutoLogger. Errore: $($_.Exception.Message)`r`n")
    }

    Try {
        $Script:LogTextBox.AppendText("Disabilitazione dell'invio automatico di campioni a Windows Defender...`r`n")
        Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue | Out-Null
        $Script:LogTextBox.AppendText("SUCCESSO: Invio automatico di campioni a Windows Defender disabilitato.`r`n")
    } Catch {
        $Script:LogTextBox.AppendText("ERRORE: Impossibile disabilitare l'invio automatico di campioni a Windows Defender. Errore: $($_.Exception.Message)`r`n")
    }

    $Script:LogTextBox.AppendText("--- Fine Ottimizzazioni Avanzate di Sistema ---`r`n")
}

Function Invoke-WPFOOSU {
    <#
    .SYNOPSIS
        Downloads and runs OO Shutup 10
    #>
    Try {
        $Script:LogTextBox.AppendText("Avvio del download di OOSU10.exe...`r`n")
        $OOSU_filepath = "$ENV:temp\OOSU10.exe"
        $Initial_ProgressPreference = $ProgressPreference
        $ProgressPreference = "Continue" # Show native PowerShell progress bar
        Invoke-WebRequest -Uri "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile $OOSU_filepath -ErrorAction Stop
        $ProgressPreference = $Initial_ProgressPreference
        $Script:LogTextBox.AppendText("Download completato. Avvio OO ShutUp 10...`r`n")
        Start-Process $OOSU_filepath -ErrorAction Stop
        $Script:LogTextBox.AppendText("OO ShutUp 10 avviato con successo.`r`n")
    } Catch {
        $Script:LogTextBox.AppendText("ERRORE: Impossibile scaricare o avviare OO ShutUp 10. Errore: $($_.Exception.Message)`r`n")
    }
    finally {
        $ProgressPreference = $Initial_ProgressPreference
    }
}

Function Perform-SystemRepair {
    $Script:LogTextBox.Clear()
    $Script:LogTextBox.AppendText("Avvio della riparazione del sistema (DISM e SFC)...`r`n`r`n")

    $confirm = Show-MessageBox "Questo processo eseguirà gli strumenti DISM e SFC per riparare l'immagine di sistema e i file di sistema. Potrebbe richiedere del tempo. Continuare?" "Conferma Riparazione Sistema" "YesNo" "Information"

    If ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
        $Script:LogTextBox.AppendText("Operazione di riparazione del sistema annullata dall'utente.`r`n")
        Return
    }

    $Script:LogTextBox.AppendText("--- Esecuzione DISM /Online /Cleanup-Image /RestoreHealth ---`r`n")
    Try {
        $process = Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
        If ($process.ExitCode -eq 0) {
            $Script:LogTextBox.AppendText("SUCCESSO: DISM completato senza errori.`r`n")
        } Else {
            $Script:LogTextBox.AppendText("AVVISO: DISM completato con codice di uscita: $($process.ExitCode). Controllare il log per i dettagli.`r`n")
        }
    } Catch {
        $Script:LogTextBox.AppendText("ERRORE: Errore durante l'esecuzione di DISM. Errore: $($_.Exception.Message)`r`n")
    }
    $Script:LogTextBox.AppendText("`r`n")

    $Script:LogTextBox.AppendText("--- Esecuzione sfc /scannow ---`r`n")
    Try {
        $process = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
        If ($process.ExitCode -eq 0) {
            $Script:LogTextBox.AppendText("SUCCESSO: SFC completato senza errori. Nessuna violazione dell'integrità trovata o riparata.`r`n")
        } Else {
            $Script:LogTextBox.AppendText("AVVISO: SFC completato con codice di uscita: $($process.ExitCode). Controllare il log per i dettagli.`r`n")
        }
    } Catch {
        $Script:LogTextBox.AppendText("ERRORE: Errore durante l'esecuzione di SFC. Errore: $($_.Exception.Message)`r`n")
    }
    $Script:LogTextBox.AppendText("`r`n")

    $Script:LogTextBox.AppendText("Riparazione del sistema completata. Si prega di rivedere il log sopra.`r`n")
    Show-MessageBox "La riparazione del sistema è stata completata. Si prega di controllare il log per i dettagli. Potrebbe essere necessario un riavvio del sistema." "Riparazione Completata"
}

Function Invoke-WPFControlPanel {
    <#
    .SYNOPSIS
        Opens the requested legacy panel
    .PARAMETER Panel
        The panel to open
    #>
    param($Panel)

    switch ($Panel) {
        "WPFPanelcontrol" {
            $Script:LogTextBox.AppendText("Apertura Pannello di Controllo...`r`n")
            cmd /c control
        }
        "WPFPanelnetwork" {
            $Script:LogTextBox.AppendText("Apertura Connessioni di Rete...`r`n")
            cmd /c ncpa.cpl
        }
        "WPFPanelpower" {
            $Script:LogTextBox.AppendText("Apertura Opzioni Alimentazione...`r`n")
            cmd /c powercfg.cpl
        }
        "WPFPanelregion" {
            $Script:LogTextBox.AppendText("Apertura Impostazioni Area Geografica...`r`n")
            cmd /c intl.cpl
        }
        "WPFPanelsound" {
            $Script:LogTextBox.AppendText("Apertura Impostazioni Audio...`r`n")
            cmd /c mmsys.cpl
        }
        "WPFPanelsystem" {
            $Script:LogTextBox.AppendText("Apertura Proprietà di Sistema...`r`n")
            cmd /c sysdm.cpl
        }
        "WPFPaneluser" {
            $Script:LogTextBox.AppendText("Apertura Account Utente...`r`n")
            cmd /c "control userpasswords2"
        }
        Default {
            $Script:LogTextBox.AppendText("AVVISO: Pannello di Controllo sconosciuto: $Panel`r`n")
        }
    }
}

Function Set-DNSConfiguration {
    Param (
        [string]$DnsProfile
    )
    $Script:LogTextBox.AppendText("Tentativo di impostare la configurazione DNS su: $DnsProfile`r`n")

    $DnsServers = @{
        "Default DHCP" = @() # Empty array means DHCP
        "Google" = @("8.8.8.8", "8.8.4.4")
        "Cloudflare" = @("1.1.1.1", "1.0.0.1")
        "Cloudflare_Malware" = @("1.1.1.2", "1.0.0.2")
        "Cloudflare_Malware_Adult" = @("1.1.1.3", "1.0.0.3")
        "Open_DNS" = @("208.67.222.222", "208.67.220.220")
        "Quad9" = @("9.9.9.9", "149.112.112.112")
        "AdGuard_Ads_Trackers" = @("94.140.14.14", "94.140.15.15")
        "AdGuard_Ads_Trackers_Malware_Adult" = @("94.140.14.15", "94.140.15.16")
    }

    $serversToSet = $DnsServers[$DnsProfile]
    if (-not $serversToSet -and $DnsProfile -ne "Default DHCP") {
        $Script:LogTextBox.AppendText("ERRORE: Profilo DNS sconosciuto: $DnsProfile`r`n")
        return
    }

    Try {
        $networkAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.LinkSpeed -ne $null -and $_.Name -notlike "*Bluetooth*" -and $_.Name -notlike "*VPN*" }

        if (-not $networkAdapters) {
            $Script:LogTextBox.AppendText("AVVISO: Nessun adattatore di rete attivo trovato per configurare il DNS.`r`n")
            return
        }

        foreach ($adapter in $networkAdapters) {
            $Script:LogTextBox.AppendText("Configurazione DNS per adattatore: $($adapter.Name)`r`n")
            if ($DnsProfile -eq "Default DHCP") {
                Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ResetServerAddresses -ErrorAction Stop
                $Script:LogTextBox.AppendText("SUCCESSO: DNS per '$($adapter.Name)' ripristinato su DHCP.`r`n")
            } else {
                Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $serversToSet -ErrorAction Stop
                $Script:LogTextBox.AppendText("SUCCESSO: DNS per '$($adapter.Name)' impostato su $($serversToSet -join ', ').`r`n")
            }
        }
    }
    Catch {
        $Script:LogTextBox.AppendText("ERRORE: Impossibile impostare la configurazione DNS. Errore: $($_.Exception.Message)`r`n")
    }
}

Function Optimize-NetworkAdapter {
    $Script:LogTextBox.AppendText("--- Avvio Ottimizzazione Processore Scheda di Rete Integrata ---`r`n")
    Try {
        $networkAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.LinkSpeed -ne $null -and $_.Name -notlike "*Bluetooth*" -and $_.Name -notlike "*VPN*" }

        if (-not $networkAdapters) {
            $Script:LogTextBox.AppendText("AVVISO: Nessun adattatore di rete attivo trovato per l'ottimizzazione.`r`n")
            return
        }

        foreach ($adapter in $networkAdapters) {
            $Script:LogTextBox.AppendText("Ottimizzazione adattatore: $($adapter.Name)`r`n")

            # Disabilita il risparmio energetico
            Try {
                Set-NetAdapterPowerManagement -Name $adapter.Name -DeviceSleepOnDisconnect Disabled -ErrorAction Stop
                Set-NetAdapterPowerManagement -Name $adapter.Name -WakeOnMagicPacket Disabled -ErrorAction Stop
                Set-NetAdapterPowerManagement -Name $adapter.Name -WakeOnPattern Disabled -ErrorAction Stop
                Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Energy Efficient Ethernet" -DisplayValue "Disabled" -ErrorAction Stop
                Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Green Ethernet" -DisplayValue "Disabled" -ErrorAction Stop
                Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Power Saving Mode" -DisplayValue "Disabled" -ErrorAction Stop
                $Script:LogTextBox.AppendText("SUCCESSO: Risparmio energetico disabilitato per '$($adapter.Name)'.`r`n")
            } Catch {
                $Script:LogTextBox.AppendText("AVVISO: Impossibile disabilitare il risparmio energetico per '$($adapter.Name)'. Errore: $($_.Exception.Message)`r`n")
            }

            # Abilita Receive Side Scaling (RSS)
            Try {
                Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Receive Side Scaling" -DisplayValue "Enabled" -ErrorAction Stop
                $Script:LogTextBox.AppendText("SUCCESSO: Receive Side Scaling (RSS) abilitato per '$($adapter.Name)'.`r`n")
            } Catch {
                $Script:LogTextBox.AppendText("AVVISO: Impossibile abilitare Receive Side Scaling (RSS) per '$($adapter.Name)'. Errore: $($_.Exception.Message)`r`n")
            }
        }
        $Script:LogTextBox.AppendText("--- Fine Ottimizzazione Processore Scheda di Rete Integrata ---`r`n")
    } Catch {
        $Script:LogTextBox.AppendText("ERRORE: Eccezione generale durante l'ottimizzazione della scheda di rete. Errore: $($_.Exception.Message)`r`n")
    }
}

Function Show-StartupAppsManager {
    $StartupForm = New-Object System.Windows.Forms.Form
    $StartupForm.Text = "Gestore App in Avvio Automatico"
    $StartupForm.Size = New-Object System.Drawing.Size(800, 600)
    $StartupForm.StartPosition = "CenterScreen"
    $StartupForm.FormBorderStyle = "FixedSingle"
    $StartupForm.MaximizeBox = $false
    $StartupForm.MinimizeBox = $true
    $StartupForm.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $StartupForm.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $StartupForm.ForeColor = [System.Drawing.Color]::LightGray

    $StartupDataGridView = New-Object System.Windows.Forms.DataGridView
    $StartupDataGridView.Location = New-Object System.Drawing.Point(10, 10)
    $StartupDataGridView.Size = New-Object System.Drawing.Size(760, 480)
    $StartupDataGridView.AllowUserToAddRows = $false
    $StartupDataGridView.AllowUserToDeleteRows = $false
    $StartupDataGridView.ReadOnly = $true
    $StartupDataGridView.MultiSelect = $true
    $StartupDataGridView.SelectionMode = "FullRowSelect"
    $StartupDataGridView.AutoGenerateColumns = $false
    $StartupDataGridView.BackgroundColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
    $StartupDataGridView.ForeColor = [System.Drawing.Color]::Black # Per il testo delle celle
    $StartupDataGridView.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60) # Colore di sfondo delle celle
    $StartupDataGridView.DefaultCellStyle.ForeColor = [System.Drawing.Color]::LightGray # Colore del testo delle celle
    $StartupDataGridView.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(75, 75, 75)
    $StartupDataGridView.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::White
    $StartupDataGridView.EnableHeadersVisualStyles = $false # Necessario per applicare stili personalizzati all'intestazione
    
    # Aggiungi colonne
    $colName = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colName.Name = "Name"
    $colName.HeaderText = "Nome"
    $colName.DataPropertyName = "Name"
    $colName.AutoSizeMode = "AllCells"
    $StartupDataGridView.Columns.Add($colName)

    $colPath = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colPath.Name = "Path"
    $colPath.HeaderText = "Percorso/Comando"
    $colPath.DataPropertyName = "Path"
    $colPath.AutoSizeMode = "Fill"
    $StartupDataGridView.Columns.Add($colPath)

    $colStatus = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colStatus.Name = "Status"
    $colStatus.HeaderText = "Stato"
    $colStatus.DataPropertyName = "Status"
    $colStatus.AutoSizeMode = "AllCells"
    $StartupDataGridView.Columns.Add($colStatus)
    
    $colSource = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colSource.Name = "Source"
    $colSource.HeaderText = "Origine"
    $colSource.DataPropertyName = "Source"
    $colSource.AutoSizeMode = "AllCells"
    $StartupDataGridView.Columns.Add($colSource)

    $StartupForm.Controls.Add($StartupDataGridView)

    $RefreshButton = New-Object System.Windows.Forms.Button
    $RefreshButton.Text = "Aggiorna Lista"
    $RefreshButton.Location = New-Object System.Drawing.Point(10, 500)
    $RefreshButton.Size = New-Object System.Drawing.Size(120, 30)
    $RefreshButton.Add_Click({ Load-StartupApps })
    $RefreshButton.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
    $RefreshButton.ForeColor = [System.Drawing.Color]::White
    $RefreshButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $RefreshButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(90, 90, 90)
    $RefreshButton.FlatAppearance.BorderSize = 1
    $StartupForm.Controls.Add($RefreshButton)

    $DisableButton = New-Object System.Windows.Forms.Button
    $DisableButton.Text = "Disabilita Selezionati"
    $DisableButton.Location = New-Object System.Drawing.Point(140, 500)
    $DisableButton.Size = New-Object System.Drawing.Size(140, 30)
    $DisableButton.Add_Click({
        If ($StartupDataGridView.SelectedRows.Count -eq 0) {
            Show-MessageBox "Nessuna applicazione selezionata per la disabilitazione." "Nessuna Selezione" "OK" "Warning"
            Return
        }
        $confirm = Show-MessageBox "Sei sicuro di voler disabilitare le applicazioni selezionate? Alcune potrebbero essere essenziali per il sistema." "Conferma Disabilitazione" "YesNo" "Warning"
        If ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { Return }

        ForEach ($row in $StartupDataGridView.SelectedRows) {
            $item = $row.DataBoundItem
            Try {
                Switch ($item.Type) {
                    "Registry" {
                        # Per disabilitare, impostiamo il valore su una stringa vuota o lo rimuoviamo se è un valore non essenziale.
                        # Impostare su stringa vuota è più sicuro per le chiavi "Run"
                        Set-ItemProperty -Path $item.RegistryPath -Name $item.RegistryName -Value "" -Force -ErrorAction Stop
                        $Script:LogTextBox.AppendText("SUCCESSO: Disabilitato (Registro) '${item.Name}'.`r`n")
                    }
                    "Folder" {
                        $disabledFolder = Join-Path (Split-Path $item.FilePath) ".disabled"
                        If (-not (Test-Path $disabledFolder)) { New-Item -Path $disabledFolder -ItemType Directory | Out-Null }
                        Move-Item -LiteralPath $item.FilePath -Destination (Join-Path $disabledFolder "${item.Name}.lnk") -Force -ErrorAction Stop
                        $Script:LogTextBox.AppendText("SUCCESSO: Disabilitato (Cartella) '${item.Name}'.`r`n")
                    }
                    "ScheduledTask" {
                        Disable-ScheduledTask -TaskPath $item.TaskPath -TaskName $item.TaskName -ErrorAction Stop
                        $Script:LogTextBox.AppendText("SUCCESSO: Disabilitato (Attività Pianificata) '${item.Name}'.`r`n")
                    }
                }
            } Catch {
                $Script:LogTextBox.AppendText("ERRORE: Impossibile disabilitare '${item.Name}'. Errore: $($_.Exception.Message)`r`n")
            }
        }
        Load-StartupApps # Ricarica la lista dopo le modifiche
        Show-MessageBox "Le applicazioni selezionate sono state disabilitate. Potrebbe essere necessario un riavvio per avere pieno effetto." "Operazione Completata"
    })
    $DisableButton.BackColor = [System.Drawing.Color]::FromArgb(200, 50, 50) # Rosso per disabilitare
    $DisableButton.ForeColor = [System.Drawing.Color]::White
    $DisableButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $DisableButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(150, 30, 30)
    $DisableButton.FlatAppearance.BorderSize = 1
    $StartupForm.Controls.Add($DisableButton)

    $EnableButton = New-Object System.Windows.Forms.Button
    $EnableButton.Text = "Abilita Selezionati"
    $EnableButton.Location = New-Object System.Drawing.Point(290, 500)
    $EnableButton.Size = New-Object System.Drawing.Size(140, 30)
    $EnableButton.Add_Click({
        If ($StartupDataGridView.SelectedRows.Count -eq 0) {
            Show-MessageBox "Nessuna applicazione selezionata per l'abilitazione." "Nessuna Selezione" "OK" "Warning"
            Return
        }
        $confirm = Show-MessageBox "Sei sicuro di voler abilitare le applicazioni selezionate?" "Conferma Abilitazione" "YesNo" "Information"
        If ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { Return }

        ForEach ($row in $StartupDataGridView.SelectedRows) {
            $item = $row.DataBoundItem
            Try {
                Switch ($item.Type) {
                    "Registry" {
                        # Per riabilitare, dobbiamo recuperare il valore originale.
                        # Per le chiavi "Run", ripristiniamo il percorso originale memorizzato in $item.Path
                        If ($item.Path -ne "") {
                             Set-ItemProperty -Path $item.RegistryPath -Name $item.RegistryName -Value $item.Path -Force -ErrorAction Stop
                             $Script:LogTextBox.AppendText("SUCCESSO: Abilitato (Registro) '${item.Name}'.`r`n")
                        } else {
                            $Script:LogTextBox.AppendText("AVVISO: Impossibile riabilitare (Registro) '${item.Name}' - Percorso originale sconosciuto.`r`n")
                        }
                    }
                    "Folder" {
                        $disabledFolder = Join-Path (Split-Path $item.FilePath) ".disabled"
                        $disabledPath = Join-Path $disabledFolder "${item.Name}.lnk"
                        If (Test-Path $disabledPath) {
                            Move-Item -LiteralPath $disabledPath -Destination $item.FilePath -Force -ErrorAction Stop
                            $Script:LogTextBox.AppendText("SUCCESSO: Abilitato (Cartella) '${item.Name}'.`r`n")
                        } else {
                            $Script:LogTextBox.AppendText("AVVISO: Impossibile riabilitare (Cartella) '${item.Name}' - File disabilitato non trovato.`r`n")
                        }
                    }
                    "ScheduledTask" {
                        Enable-ScheduledTask -TaskPath $item.TaskPath -TaskName $item.TaskName -ErrorAction Stop
                        $Script:LogTextBox.AppendText("SUCCESSO: Abilitato (Attività Pianificata) '${item.Name}'.`r`n")
                    }
                }
            } Catch {
                $Script:LogTextBox.AppendText("ERRORE: Impossibile abilitare '${item.Name}'. Errore: $($_.Exception.Message)`r`n")
            }
        }
        Load-StartupApps # Ricarica la lista dopo le modifiche
        Show-MessageBox "Le applicazioni selezionate sono state abilitate. Potrebbe essere necessario un riavvio per avere pieno effetto." "Operazione Completata"
    })
    $EnableButton.BackColor = [System.Drawing.Color]::FromArgb(50, 200, 50) # Verde per abilitare
    $EnableButton.ForeColor = [System.Drawing.Color]::White
    $EnableButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $EnableButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(30, 150, 30)
    $EnableButton.FlatAppearance.BorderSize = 1
    $StartupForm.Controls.Add($EnableButton)

    $CloseButton = New-Object System.Windows.Forms.Button
    $CloseButton.Text = "Chiudi"
    $CloseButton.Location = New-Object System.Drawing.Point(([int]$StartupForm.Width - 100 - 30), 500)
    $CloseButton.Size = New-Object System.Drawing.Size(100, 30)
    $CloseButton.Add_Click({ $StartupForm.Close() })
    $CloseButton.BackColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
    $CloseButton.ForeColor = [System.Drawing.Color]::White
    $CloseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $CloseButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
    $CloseButton.FlatAppearance.BorderSize = 1
    $StartupForm.Controls.Add($CloseButton)

    Function Load-StartupApps {
        $apps = New-Object System.Collections.ArrayList
        
        # Registry Run keys
        $runKeys = @(
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
        )
        foreach ($keyPath in $runKeys) {
            If (Test-Path $keyPath) {
                # Ottieni l'oggetto della chiave di registro
                $regKey = Get-Item -Path $keyPath -ErrorAction SilentlyContinue
                If ($regKey) {
                    # Itera sui nomi delle proprietà (valori) nella chiave di registro
                    foreach ($name in $regKey.Property) {
                        # Recupera il valore specifico per ogni nome di proprietà
                        $value = (Get-ItemProperty -Path $keyPath -Name $name -ErrorAction SilentlyContinue).$name
                        $status = If ($value -eq "") {"Disabilitato (Valore Vuoto)"} Else {"Abilitato"}
                        $apps.Add([PSCustomObject]@{
                            Name = $name
                            Path = $value
                            Status = $status
                            Source = "Registro: $keyPath"
                            Type = "Registry"
                            RegistryPath = $keyPath
                            RegistryName = $name
                        })
                    }
                }
            }
        }

        # Startup folders
        $startupFolders = @(
            "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
            "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\Startup"
        )
        foreach ($folder in $startupFolders) {
            If (Test-Path $folder) {
                Get-ChildItem -Path $folder -Filter "*.lnk" -ErrorAction SilentlyContinue | ForEach-Object {
                    $apps.Add([PSCustomObject]@{
                        Name = $_.BaseName
                        Path = $_.FullName
                        Status = "Abilitato"
                        Source = "Cartella Avvio: $folder"
                        Type = "Folder"
                        FilePath = $_.FullName
                    })
                }
            }
        }

        # Scheduled Tasks (running at logon)
        Try {
            Get-ScheduledTask | Where-Object { $_.Triggers -ne $null } | ForEach-Object {
                $task = $_
                # Controlla se esiste almeno un trigger di accesso abilitato
                $atLogonTrigger = $task.Triggers | Where-Object { $_.TriggerType -eq "Logon" -and $_.Enabled -eq $true }
                if ($atLogonTrigger) {
                    $apps.Add([PSCustomObject]@{
                        Name = $task.TaskName
                        Path = $task.Actions.Execute # Questo potrebbe essere un array o un oggetto complesso, potrebbe essere necessario stringificarlo
                        Status = If ($task.State -eq "Ready" -or $task.State -eq "Running") {"Abilitato"} Else {"Disabilitato"}
                        Source = "Attività Pianificata: $($task.TaskPath)"
                        Type = "ScheduledTask"
                        TaskPath = $task.TaskPath
                        TaskName = $task.TaskName
                    })
                }
            }
        } Catch {
            $Script:LogTextBox.AppendText("AVVISO: Impossibile recuperare le attività pianificate. Errore: $($_.Exception.Message)`r`n")
        }
        
        $StartupDataGridView.DataSource = $apps
        $StartupDataGridView.AutoResizeColumns()
    }

    $RefreshButton.Add_Click({ Load-StartupApps })

    Load-StartupApps # Carica le app all'apertura del form
    $StartupForm.ShowDialog() | Out-Null
}

Function Create-SystemRestorePoint {
    Param (
        [string]$Description = "Punto di ripristino creato da Luca - Ottimizzatore Registro di Windows"
    )
    $Script:LogTextBox.AppendText("--- Tentativo di creare un punto di ripristino del sistema ---`r`n")
    Try {
        # Controlla se il ripristino del sistema è abilitato sull'unità di sistema
        $systemDrive = "$($env:SystemDrive)\"
        $srStatus = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        $isSrEnabled = $false
        if ($srStatus) {
            $srConfig = Get-ComputerRestorePoint -Drive $systemDrive -ErrorAction SilentlyContinue
            if ($srConfig -and $srConfig.Enable -eq $true) {
                $isSrEnabled = $true
            }
        }

        if (-not $isSrEnabled) {
            $Script:LogTextBox.AppendText("AVVISO: Il ripristino del sistema non è abilitato sull'unità di sistema ($systemDrive).`r`n")
            $Script:LogTextBox.AppendText("Impossibile creare un punto di ripristino. Abilitalo in 'Protezione sistema' per usare questa funzione.`r`n")
            Show-MessageBox "Il ripristino del sistema non è abilitato sull'unità di sistema ($systemDrive). Impossibile creare un punto di ripristino. Abilitalo in 'Protezione sistema' per usare questa funzione." "Ripristino Sistema Disabilitato" "OK" "Warning"
            return $false
        }

        $Script:LogTextBox.AppendText("Creazione del punto di ripristino: '$Description'...`r`n")
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        $Script:LogTextBox.AppendText("SUCCESSO: Punto di ripristino creato con successo.`r`n")
        Show-MessageBox "Punto di ripristino del sistema creato con successo!" "Punto di Ripristino Creato" "OK" "Information"
        return $true
    } Catch {
        $Script:LogTextBox.AppendText("ERRORE: Impossibile creare il punto di ripristino del sistema. Errore: $($_.Exception.Message)`r`n")
        Show-MessageBox "Si è verificato un errore durante la creazione del punto di ripristino del sistema. Controlla il log per i dettagli." "Errore Punto di Ripristino" "OK" "Error"
        return $false
    }
    $Script:LogTextBox.AppendText("--- Fine creazione punto di ripristino ---`r`n`r`n")
}

Function Apply-SelectedChanges {
    $Script:LogTextBox.Clear()
    $Script:LogTextBox.AppendText("Preparazione per l'applicazione delle modifiche...`r`n`r`n")

    $createRestorePoint = Show-MessageBox "Vuoi creare un punto di ripristino del sistema prima di applicare le modifiche? Questo è fortemente raccomandato." "Crea Punto di Ripristino?" "YesNo" "Question"

    If ($createRestorePoint -eq [System.Windows.Forms.DialogResult]::Yes) {
        $restorePointCreated = Create-SystemRestorePoint
        If (-not $restorePointCreated) {
            $continueWithoutRestore = Show-MessageBox "La creazione del punto di ripristino è fallita o il ripristino del sistema non è abilitato. Vuoi continuare comunque ad applicare le modifiche?" "Continua Senza Ripristino?" "YesNo" "Warning"
            If ($continueWithoutRestore -ne [System.Windows.Forms.DialogResult]::Yes) {
                $Script:LogTextBox.AppendText("Operazione annullata dall'utente a causa del fallimento della creazione del punto di ripristino.`r`n")
                Show-MessageBox "Operazione annullata." "Annullato"
                Return
            }
        }
    }
    
    $Script:LogTextBox.AppendText("Applicazione delle modifiche al Registro selezionate...`r`n`r`n")

    ForEach ($config in $RegistryConfigurations) {
        $checkbox = $Script:CheckBoxes | Where-Object { $_.Tag -eq $config.Name }
        If ($checkbox.Checked) {
            $Script:LogTextBox.AppendText("--- Applicazione: $($config.Name) ---`r`n")
            ForEach ($action in $config.RegistryActions) {
                Switch ($action.Action) {
                    "Set" { Set-RegistryValue -Path $action.Path -Name $action.Name -Value $action.Value -Type $action.Type }
                    "RemoveValue" { Remove-RegistryValue -Path $action.Path -Name $action.Name }
                    "RemoveKey" { Remove-RegistryKey -Path $action.Path }
                    "UninstallAppxPackage" { Uninstall-AppxPackage -AppxPackageName $action.AppxPackageName }
                    "DisableScheduledTask" { Disable-ScheduledTaskAction -TaskPath $action.TaskPath -TaskNamePattern $action.TaskName }
                    "DisableService" { Disable-ServiceAction -ServiceName $action.ServiceName }
                    "RunCommand" { Run-CommandAction -Command $action.Command }
                    "RunFunction" { Invoke-Expression "$($action.FunctionName)" }
                    Default { $Script:LogTextBox.AppendText("AVVISO: Tipo di azione sconosciuto '$($action.Action)' per $($config.Name).`r`n") }
                }
            }
            $Script:LogTextBox.AppendText("`r`n")
        }
    }
    $Script:LogTextBox.AppendText("Tutte le modifiche selezionate sono state tentate. Si prega di rivedere il log sopra.`r`n")
    Show-MessageBox "Le modifiche al Registro sono state applicate. Si prega di controllare il log per i dettagli. Alcune modifiche potrebbero richiedere un riavvio del sistema per avere pieno effetto." "Operazione Completata"
}

Function Select-AllCheckboxes {
    ForEach ($checkbox in $Script:CheckBoxes) {
        $checkbox.Checked = $true
    }
}

Function Deselect-AllCheckboxes {
    ForEach ($checkbox in $Script:CheckBoxes) {
        $checkbox.Checked = false
    }
}

Function Update-Winget {
    $Script:LogTextBox.Clear()
    $Script:LogTextBox.AppendText("Controllo e aggiornamento di Winget...`r`n`r`n")

    Try {
        # Check if winget.exe is available
        $wingetPath = Get-Command winget.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source

        If (-not $wingetPath) {
            $Script:LogTextBox.AppendText("Winget (Gestione Pacchetti di Windows) non è stato trovato sul tuo sistema.`r`n")
            $Script:LogTextBox.AppendText("Per installarlo, apri il Microsoft Store e cerca 'App Installer'.`r`n")
            $Script:LogTextBox.AppendText("Oppure, scaricalo manualmente da: https://github.com/microsoft/winget-cli/releases`r`n")
            Show-MessageBox "Winget (Gestione Pacchetti di Windows) non è stato trovato. Per installarlo, apri il Microsoft Store e cerca 'App Installer', oppure scaricalo da GitHub." "Winget non Trovato" "OK" "Error"
            Return
        }

        $Script:LogTextBox.AppendText("Winget trovato: $wingetPath.`r`n")
        $Script:LogTextBox.AppendText("Tentativo di aggiornare tutte le app e Winget stesso...`r`n")

        # Create temporary files for output redirection
        $tempOutputFile = [System.IO.Path]::GetTempFileName()
        $tempErrorFile = [System.IO.Path]::GetTempFileName()

        # Execute winget upgrade --all and redirect output
        # -NoNewWindow hides the console window that might briefly appear for some commands
        $process = Start-Process -FilePath $wingetPath -ArgumentList "upgrade --all --source winget --accept-package-agreements --accept-source-agreements" -Wait -PassThru -NoNewWindow -RedirectStandardOutput $tempOutputFile -RedirectStandardError $tempErrorFile -ErrorAction Stop
        
        # Read output from temporary files after process exits
        $wingetOutput = Get-Content $tempOutputFile -Raw -ErrorAction SilentlyContinue
        $wingetError = Get-Content $tempErrorFile -Raw -ErrorAction SilentlyContinue

        If ($wingetOutput) {
            $Script:LogTextBox.AppendText("Output Winget:`r`n$wingetOutput`r`n")
        }
        If ($wingetError) {
            $Script:LogTextBox.AppendText("Errore Winget:`r`n$wingetError`r`n")
        }

        If ($process.ExitCode -eq 0) {
            $Script:LogTextBox.AppendText("SUCCESSO: Tutte le app (e Winget) sono state aggiornate con successo tramite Winget.`r`n")
            Show-MessageBox "Winget e tutte le app installate sono state aggiornate con successo!" "Aggiornamento Winget Completato" "OK" "Information"
        } Else {
            $Script:LogTextBox.AppendText("AVVISO: L'aggiornamento di Winget/app è terminato con codice di uscita: $($process.ExitCode). Potrebbero esserci stati errori o nessuna app da aggiornare.`r`n")
            Show-MessageBox "L'aggiornamento di Winget/app è terminato. Controlla il log per i dettagli. Potrebbero esserci stati errori o nessuna app da aggiornare." "Aggiornamento Winget Completato (con avvisi)" "OK" "Warning"
        }
    }
    Catch {
        $Script:LogTextBox.AppendText("ERRORE: Eccezione durante l'aggiornamento di Winget. Errore: $($_.Exception.Message)`r`n")
        Show-MessageBox "Si è verificato un errore durante l'aggiornamento di Winget. Controlla il log per i dettagli." "Errore Aggiornamento Winget" "OK" "Error"
    }
    Finally {
        # Clean up temporary files
        If (Test-Path $tempOutputFile) { Remove-Item $tempOutputFile -ErrorAction SilentlyContinue }
        If (Test-Path $tempErrorFile) { Remove-Item $tempErrorFile -ErrorAction SilentlyContinue }
        $Script:LogTextBox.AppendText("--- Fine aggiornamento Winget ---`r`n")
    }
}

#region Funzioni di Download App
Function Install-WingetApp {
    Param (
        [string]$WingetId
    )
    $Script:LogTextBox.AppendText("--- Avvio installazione di '$WingetId' tramite Winget ---`r`n")

    Try {
        # Check if winget is available
        $wingetPath = Get-Command winget.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source

        If (-not $wingetPath) {
            $Script:LogTextBox.AppendText("ERRORE: Winget non trovato. Assicurati che 'App Installer' sia installato dal Microsoft Store.`r`n")
            Show-MessageBox "Winget (Gestione Pacchetti di Windows) non è stato trovato sul tuo sistema. Per utilizzare questa funzionalità, installa 'App Installer' dal Microsoft Store o aggiornalo." "Winget non Trovato" "OK" "Error"
            Return $false # Indica fallimento
        }

        $Script:LogTextBox.AppendText("Winget trovato: $wingetPath. Avvio installazione...`r`n")

        # Create temporary files for output redirection
        $tempOutputFile = [System.IO.Path]::GetTempFileName()
        $tempErrorFile = [System.IO.Path]::GetTempFileName()

        # Execute winget install command and redirect output
        # -NoNewWindow hides the console window that might briefly appear for some commands
        $process = Start-Process -FilePath $wingetPath -ArgumentList "install -e --id $($WingetId)" -Wait -PassThru -NoNewWindow -RedirectStandardOutput $tempOutputFile -RedirectStandardError $tempErrorFile -ErrorAction Stop
        
        # Read output from temporary files after process exits
        $wingetOutput = Get-Content $tempOutputFile -Raw -ErrorAction SilentlyContinue
        $wingetError = Get-Content $tempErrorFile -Raw -ErrorAction SilentlyContinue

        If ($wingetOutput) {
            $Script:LogTextBox.AppendText("Output Winget:`r`n$wingetOutput`r`n")
        }
        If ($wingetError) {
            $Script:LogTextBox.AppendText("Errore Winget:`r`n$wingetError`r`n")
        }

        If ($process.ExitCode -eq 0) {
            $Script:LogTextBox.AppendText("SUCCESSO: '$WingetId' installato con successo.`r`n")
            Return $true # Indica successo
        } Else {
            $Script:LogTextBox.AppendText("ERRORE: Installazione di '$WingetId' fallita. Codice di uscita: $($process.ExitCode).`r`n")
            $Script:LogTextBox.AppendText("Potrebbe essere necessario eseguire lo script come amministratore o il pacchetto Winget potrebbe non esistere/essere valido.`r`n")
            Return $false # Indica fallimento
        }
    }
    Catch {
        $Script:LogTextBox.AppendText("ERRORE: Eccezione durante l'installazione di '$WingetId'. Errore: $($_.Exception.Message)`r`n")
        Return $false # Indica fallimento
    }
    Finally {
        # Clean up temporary files
        If (Test-Path $tempOutputFile) { Remove-Item $tempOutputFile -ErrorAction SilentlyContinue }
        If (Test-Path $tempErrorFile) { Remove-Item $tempErrorFile -ErrorAction SilentlyContinue }
        $Script:LogTextBox.AppendText("--- Fine installazione di '$WingetId' ---`r`n`r`n")
    }
}

Function Install-SelectedDownloadApps {
    $Script:LogTextBox.Clear()
    $Script:LogTextBox.AppendText("Avvio installazione delle app selezionate...`r`n`r`n")

    $selectedApps = $Script:DownloadAppsCheckedListBox.CheckedItems
    $selectedAppsCount = $selectedApps.Count

    If ($selectedAppsCount -eq 0) {
        $Script:LogTextBox.AppendText("Nessuna app selezionata per l'installazione.`r`n")
        Show-MessageBox "Nessuna app selezionata per l'installazione." "Nessuna Selezione" "OK" "Information"
        Return
    }

    # Initialize progress bar
    $Script:DownloadProgressBar.Maximum = $selectedAppsCount
    $Script:DownloadProgressBar.Value = 0
    $Script:DownloadProgressBar.Visible = $true # Make sure it's visible

    $currentAppIndex = 0
    ForEach ($item in $selectedApps) {
        $currentAppIndex++
        $Script:DownloadProgressBar.Value = $currentAppIndex
        $Script:DownloadProgressBar.Update() # Force GUI refresh
        
        # FIX: Explicitly extract and concatenate to avoid any parsing issues
        $appName = $item.DisplayName
        $Script:DownloadProgressLabel.Text = "Installazione app " + $currentAppIndex + " di " + $selectedAppsCount + ": " + $appName + "..."
        $Script:DownloadProgressLabel.Update()

        $wingetId = $item.WingetId 
        Install-WingetApp $wingetId
    }

    $Script:LogTextBox.AppendText("`r`nInstallazione delle app selezionate completata. Si prega di rivedere il log sopra.`r`n")
    Show-MessageBox "Installazione delle app selezionate completata. Si prega di controllare il log per i dettagli." "Installazione Completata"

    # Reset progress bar and label
    $Script:DownloadProgressBar.Value = 0
    $Script:DownloadProgressBar.Visible = $false
    $Script:DownloadProgressLabel.Text = ""
}

Function Select-AllDownloadApps {
    For ($i = 0; $i -lt $Script:DownloadAppsCheckedListBox.Items.Count; $i++) {
        $Script:DownloadAppsCheckedListBox.SetItemChecked($i, $true)
    }
}

Function Deselect-AllDownloadApps {
    For ($i = 0; $i -lt $Script:DownloadAppsCheckedListBox.Items.Count; $i++) {
        $Script:DownloadAppsCheckedListBox.SetItemChecked($i, $false)
    }
}

# Configurazioni per le app scaricabili
$DownloadConfigurations = @(
    @{ Name = "Nlitesoft NTLite"; WingetId = "Nlitesoft.NTLite" },
    @{ Name = "Google Chrome"; WingetId = "Google.Chrome" },
    @{ Name = "7-Zip"; WingetId = "7zip.7zip" },
    @{ Name = "Glary Utilities"; WingetId = "Glarysoft.GlaryUtilities" },
    @{ Name = "UniGetUI"; WingetId = "MartiCliment.UniGetUI" },
    @{ Name = "LibreOffice"; WingetId = "TheDocumentFoundation.LibreOffice" },
    @{ Name = "VLC Media Player"; WingetId = "VideoLAN.VLC" },
    @{ Name = "Nilesoft Shell"; WingetId = "Nilesoft.Shell" },
    @{ Name = "Foxit PhantomPDF"; WingetId = "Foxit.PhantomPDF.Subscription" },
    @{ Name = "HiBit Uninstaller"; WingetId = "HiBitSoftware.HiBitUninstaller" },
    @{ Name = "Unigram (Telegram)"; WingetId = "Telegram.Unigram" },
    @{ Name = "AnyBurn"; WingetId = "PowerSoftware.AnyBurn" },
    @{ Name = "Notepad++"; WingetId = "Notepad++.Notepad++" },
    @{ Name = "Oracle VirtualBox"; WingetId = "Oracle.VirtualBox" },
    @{ Name = "Stremio Beta"; WingetId = "Stremio.Stremio.Beta" },
    @{ Name = "LocalSend"; WingetId = "LocalSend.LocalSend" },
    @{ Name = ".NET Desktop Runtime 3.1"; WingetId = "Microsoft.DotNet.DesktopRuntime.3_1" },
    @{ Name = ".NET Runtime 5"; WingetId = "Microsoft.DotNet.Runtime.5" },
    @{ Name = ".NET Runtime 6"; WingetId = "Microsoft.DotNet.Runtime.6" },
    @{ Name = ".NET Runtime 7"; WingetId = "Microsoft.DotNet.Runtime.7" },
    @{ Name = ".NET Runtime 8"; WingetId = "Microsoft.DotNet.Runtime.8" },
    @{ Name = ".NET Runtime 9"; WingetId = "Microsoft.DotNet.Runtime.9" },
    @{ Name = "Microsoft Visual C++ Redistributable 2015+ x64"; WingetId = "Microsoft.VCRedist.2015+.x64" }
)
#endregion

#region Funzione di Disinstallazione OneDrive (Logica Utente)
Function Perform-UninstallOneDrive {
    $Script:LogTextBox.AppendText("--- Avvio disinstallazione completa di OneDrive ---`r`n")
    $OneDrivePath = "$($env:OneDrive)"

    Try {
        $Script:LogTextBox.AppendText("Terminazione del processo OneDrive.exe...`r`n")
        # Removed /ErrorAction as it's a PowerShell parameter, not for taskkill.exe
        taskkill /f /im OneDrive.exe | Out-Null
    } Catch {
        $Script:LogTextBox.AppendText("AVVISO: Impossibile terminare OneDrive.exe. Errore: $($_.Exception.Message)`r`n")
    }

    $regPathUninstall = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe"
    If (Test-Path $regPathUninstall) {
        Try {
            $Script:LogTextBox.AppendText("Tentativo di disinstallare OneDrive tramite la stringa di disinstallazione del Registro...`r`n")
            $OneDriveUninstallString = Get-ItemPropertyValue "$regPathUninstall" -Name "UninstallString" -ErrorAction Stop
            $OneDriveExe = $OneDriveUninstallString.Split(" ")[0]
            $OneDriveArgs = $OneDriveUninstallString.Substring($OneDriveExe.Length).Trim() + " /silent"
            
            $Script:LogTextBox.AppendText("Esecuzione: '$OneDriveExe $OneDriveArgs'`r`n")
            $process = Start-Process -FilePath $OneDriveExe -ArgumentList $OneDriveArgs -NoNewWindow -Wait -PassThru -ErrorAction Stop
            If ($process.ExitCode -eq 0) {
                $Script:LogTextBox.AppendText("SUCCESSO: OneDrive disinstallato tramite il programma di installazione.`r`n")
            } Else {
                $Script:LogTextBox.AppendText("AVVISO: La disinstallazione di OneDrive tramite il programma di installazione è terminata con codice di uscita: $($process.ExitCode).`r`n")
            }
        } Catch {
            $Script:LogTextBox.AppendText("ERRORE: Impossibile disinstallare OneDrive tramite la stringa di disinstallazione. Errore: $($_.Exception.Message)`r`n")
        }
    } Else {
        $Script:LogTextBox.AppendText("INFO: OneDrive non sembra essere installato tramite la voce del Registro. Proseguo con la pulizia dei file.`r`n")
    }

    # Verifica se OneDrive è stato disinstallato (controllando la voce del Registro)
    If (-not (Test-Path $regPathUninstall)) {
        $Script:LogTextBox.AppendText("Copia dei file scaricati dalla cartella OneDrive alla cartella utente principale...`r`n")
        # Check if the OneDrive folder exists before attempting to robocopy
        If (Test-Path $OneDrivePath) {
            Try {
                # Use an array for -ArgumentList to ensure correct parsing of robocopy arguments
                $robocopyArgs = @(
                    "$OneDrivePath",
                    "$($env:USERPROFILE.TrimEnd())\",
                    "/mov", "/e", "/xj", # /mov to move, /e for empty dirs, /xj for junction points
                    "/ndl", "/nfl", "/njh", "/njs", "/nc", "/ns", "/np" # Logging options
                )
                $Script:LogTextBox.AppendText("Esecuzione robocopy con argomenti: $($robocopyArgs -join ' ')`r`n")
                $process = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
                If ($process.ExitCode -le 8) { # Robocopy exit codes: 0-7 are success with info, 8+ are errors
                    $Script:LogTextBox.AppendText("SUCCESSO: File OneDrive copiati nella cartella utente principale.`r`n")
                } Else {
                    $Script:LogTextBox.AppendText("AVVISO: Robocopy terminato con codice di uscita: $($process.ExitCode). Potrebbero esserci stati errori durante la copia dei file.`r`n")
                }
            } Catch {
                $Script:LogTextBox.AppendText("ERRORE: Errore durante la copia dei file OneDrive. Errore: $($_.Exception.Message)`r`n")
            }
        } Else {
            $Script:LogTextBox.AppendText("INFO: La cartella OneDrive '$OneDrivePath' non esiste, salto la copia dei file.`r`n")
        }

        $Script:LogTextBox.AppendText("Rimozione dei file residui di OneDrive...`r`n")
        Try {
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:localappdata\Microsoft\OneDrive"
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:localappdata\OneDrive"
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:programdata\Microsoft OneDrive"
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:systemdrive\OneDriveTemp" # Aggiunto come da tua richiesta
            $Script:LogTextBox.AppendText("SUCCESSO: File residui di OneDrive rimossi.`r`n")
        } Catch {
            $Script:LogTextBox.AppendText("AVVISO: Errore durante la rimozione dei file residui di OneDrive. Errore: $($_.Exception.Message)`r`n")
        }

        $Script:LogTextBox.AppendText("Rimozione della voce di registro di OneDrive...`r`n")
        Try {
            Remove-Item -Path "HKEY_CURRENT_USER\Software\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
            $Script:LogTextBox.AppendText("SUCCESSO: Voce di registro di OneDrive rimossa.`r`n")
        } Catch {
            $Script:LogTextBox.AppendText("AVVISO: Errore durante la rimozione della voce di registro di OneDrive. Errore: $($_.Exception.Message)`r`n")
        }

        # Verifica se la directory OneDrive è vuota prima di rimuoverla
        If (Test-Path "$OneDrivePath") {
            Try {
                $itemsInOneDrivePath = Get-ChildItem "$OneDrivePath" -Recurse -ErrorAction SilentlyContinue
                If ($itemsInOneDrivePath.Count -eq 0) {
                    $Script:LogTextBox.AppendText("La cartella OneDrive è vuota, la rimuovo...`r`n")
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$OneDrivePath"
                    $Script:LogTextBox.AppendText("SUCCESSO: Cartella OneDrive rimossa.`r`n")
                } Else {
                    $Script:LogTextBox.AppendText("AVVISO: La cartella OneDrive '$OneDrivePath' contiene ancora elementi. Non verrà rimossa automaticamente.`r`n")
                    $Script:LogTextBox.AppendText("Si prega di notare - La cartella OneDrive in '$OneDrivePath' potrebbe contenere ancora elementi. È necessario eliminarla manualmente, ma tutti i file dovrebbero essere già stati copiati nella cartella utente di base.`r`n")
                }
            } Catch {
                $Script:LogTextBox.AppendText("AVVISO: Errore durante la verifica/rimozione della cartella OneDrive. Errore: $($_.Exception.Message)`r`n")
            }
        }

        $Script:LogTextBox.AppendText("Rimozione di OneDrive dalla barra laterale di Esplora file...`r`n")
        Try {
            Set-ItemProperty -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -ErrorAction SilentlyContinue
            $Script:LogTextBox.AppendText("SUCCESSO: OneDrive rimosso dalla barra laterale di Esplora file.`r`n")
        } Catch {
            $Script:LogTextBox.AppendText("AVVISO: Errore durante la rimozione di OneDrive dalla barra laterale di Esplora file. Errore: $($_.Exception.Message)`r`n")
        }

        $Script:LogTextBox.AppendText("Rimozione dell'hook di esecuzione per i nuovi utenti...`r`n")
        Try {
            # Carica l'hive del Registro di sistema dell'utente predefinito
            # Controlla se l'hive è già caricato per evitare errori
            if (-not (Test-Path "HKU:\Default")) {
                reg load "hku\Default" "C:\Users\Default\NTUSER.DAT" | Out-Null
                Start-Sleep -Milliseconds 500 # Breve pausa per assicurarsi che sia caricato
            }
            
            # Rimuovi la voce "OneDriveSetup" dalla chiave Run
            reg delete "HKEY_USERS\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f | Out-Null
            
            # Scarica l'hive del Registro di sistema dell'utente predefinito
            reg unload "hku\Default" | Out-Null
            $Script:LogTextBox.AppendText("SUCCESSO: Hook di esecuzione per i nuovi utenti rimosso.`r`n")
        } Catch {
            $Script:LogTextBox.AppendText("AVVISO: Errore durante la rimozione dell'hook di esecuzione per i nuovi utenti. Errore: $($_.Exception.Message)`r`n")
        }


        $Script:LogTextBox.AppendText("Rimozione della voce del menu Start...`r`n")
        Try {
            Remove-Item -Force -ErrorAction SilentlyContinue "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"
            $Script:LogTextBox.AppendText("SUCCESSO: Voce del menu Start rimossa.`r`n")
        } Catch {
            $Script:LogTextBox.AppendText("AVVISO: Errore durante la rimozione della voce del menu Start. Errore: $($_.Exception.Message)`r`n")
        }

        $Script:LogTextBox.AppendText("Rimozione dell'attività pianificata di OneDrive...`r`n")
        Try {
            Get-ScheduledTask -TaskPath '\' -TaskName 'OneDrive*' -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false
            $Script:LogTextBox.AppendText("SUCCESSO: Attività pianificata di OneDrive rimossa.`r`n")
        } Catch {
            $Script:LogTextBox.AppendText("AVVISO: Errore durante la rimozione dell'attività pianificata di OneDrive. Errore: $($_.Exception.Message)`r`n")
        }

        $Script:LogTextBox.AppendText("Ripristino delle posizioni predefinite delle cartelle shell...`r`n")
        Try {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "AppData" -Value "$env:userprofile\AppData\Roaming" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Cache" -Value "$env:userprofile\AppData\Local\Microsoft\Windows\INetCache" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Cookies" -Value "$env:userprofile\AppData\Local\Microsoft\Windows\INetCookies" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Favorites" -Value "$env:userprofile\Favorites" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "History" -Value "$env:userprofile\AppData\Local\Microsoft\Windows\History" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Local AppData" -Value "$env:userprofile\AppData\Local" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "My Music" -Value "$env:userprofile\Music" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "My Video" -Value "$env:userprofile\Videos" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "NetHood" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Network Shortcuts" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "PrintHood" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Printer Shortcuts" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Programs" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Recent" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Recent" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "SendTo" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\SendTo" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Start Menu" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Startup" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Templates" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Templates" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}" -Value "$env:userprofile\Downloads" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Desktop" -Value "$env:userprofile\Desktop" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "My Pictures" -Value "$env:userprofile\Pictures" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Personal" -Value "$env:userprofile\Documents" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{F42EE2D3-909F-4907-8871-4C22FC0BF756}" -Value "$env:userprofile\Documents" -Type ExpandString -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{0DDD015D-B06C-45D5-8C4C-F59713854639}" -Value "$env:userprofile\Pictures" -Type ExpandString -ErrorAction SilentlyContinue
            $Script:LogTextBox.AppendText("SUCCESSO: Posizioni delle cartelle shell ripristinate.`r`n")
        } Catch {
            $Script:LogTextBox.AppendText("AVVISO: Errore durante il ripristino delle posizioni delle cartelle shell. Errore: $($_.Exception.Message)`r`n")
        }

        $Script:LogTextBox.AppendText("Riavvio di Explorer.exe...`r`n")
        taskkill.exe /F /IM "explorer.exe" | Out-Null # Removed /ErrorAction
        Start-Process "explorer.exe" | Out-Null # Removed /ErrorAction
        $Script:LogTextBox.AppendText("SUCCESSO: Explorer.exe riavviato.`r`n")
        $Script:LogTextBox.AppendText("Si prega di notare - La cartella OneDrive in '$OneDrivePath' potrebbe contenere ancora elementi. È necessario eliminarla manualmente, ma tutti i file dovrebbero essere già stati copiati nella cartella utente di base.`r`n")
        $Script:LogTextBox.AppendText("Se in seguito mancano dei file, accedi a Onedrive.com e scaricali manualmente.`r`n")
    } Else {
        $Script:LogTextBox.AppendText("ERRORE: Qualcosa è andato storto durante la disinstallazione di OneDrive. La voce del Registro di sistema è ancora presente.`r`n")
    }
    $Script:LogTextBox.AppendText("--- Fine disinstallazione completa di OneDrive ---`r`n`r`n")
}
#endregion

#region Crea Form Principale
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Luca - Ottimizzatore Registro di Windows"
$Form.Size = New-Object System.Drawing.Size(1200, 1180) # Altezza aumentata
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle" # Impedisce il ridimensionamento
$Form.MaximizeBox = $false
$Form.MinimizeBox = $true
$Form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30) # Sfondo scuro
$Form.ForeColor = [System.Drawing.Color]::LightGray # Testo chiaro

# Aggiungi un componente ToolTip al form
$ToolTip = New-Object System.Windows.Forms.ToolTip

# Larghezza del pannello principale (ottimizzazioni)
$padding = 10
$logPanelWidth = 400 # Circa 1/3 della larghezza del form
$mainPanelWidth = [int]($Form.Width - $logPanelWidth - (3 * $padding)) # Calcola dinamicamente la larghezza del pannello principale

# Pannello per le caselle di controllo (con scorrimento automatico)
$Panel = New-Object System.Windows.Forms.Panel
$Panel.Location = New-Object System.Drawing.Point($padding, $padding)
$Panel.Size = New-Object System.Drawing.Size($mainPanelWidth, 350) # Altezza delle checkbox di ottimizzazione
$Panel.AutoScroll = $true
$Panel.BorderStyle = "FixedSingle"
$Panel.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48) # Sfondo scuro leggermente diverso
$Panel.ForeColor = [System.Drawing.Color]::LightGray # Testo chiaro
$Form.Controls.Add($Panel)

$yPos = 10
$Script:CheckBoxes = @() # Memorizza le caselle di controllo per un facile accesso

ForEach ($config in $RegistryConfigurations) {
    # Salta "Abilita/Disabilita App in Background" dalla lista delle caselle di controllo
    # Questa è ora gestita da un pulsante separato per una migliore UX
    If ($config.Name -eq "Abilita/Disabilita App in Background") {
        Continue
    }
    $CheckBox = New-Object System.Windows.Forms.CheckBox
    $CheckBox.Text = $config.Name
    $CheckBox.Location = New-Object System.Drawing.Point(10, $yPos)
    $CheckBox.AutoSize = $true
    $CheckBox.Width = $Panel.Width - 30 # Assicurati che rientri nel pannello
    $CheckBox.Tag = $config.Name # Usa Tag per collegare alla configurazione
    $CheckBox.ForeColor = [System.Drawing.Color]::LightGray # Testo chiaro per le checkbox
    $CheckBox.BackColor = $Panel.BackColor # Sfondo della checkbox come il pannello

    # Imposta il tooltip usando il componente ToolTip
    $ToolTip.SetToolTip($CheckBox, $config.Description)
    
    $Panel.Controls.Add($CheckBox)
    $Script:CheckBoxes += $CheckBox
    $yPos += $CheckBox.Height + 5 # Aggiungi un po' di spaziatura
}

# Regola la dimensione virtuale del pannello per ospitare tutte le caselle di controllo
$Panel.AutoScrollMinSize = New-Object System.Drawing.Size(0, $yPos)

# Pulsanti Azione Principali
$currentButtonY = [int]($Panel.Location.Y + $Panel.Height + 10) # Cast esplicito a int
$currentButtonX = $padding

$SelectAllButton = New-Object System.Windows.Forms.Button
$SelectAllButton.Text = "Seleziona Tutto"
$SelectAllButton.Location = New-Object System.Drawing.Point($currentButtonX, $currentButtonY)
$SelectAllButton.Size = New-Object System.Drawing.Size(100, 30)
$SelectAllButton.Add_Click({ Select-AllCheckboxes })
$SelectAllButton.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$SelectAllButton.ForeColor = [System.Drawing.Color]::White
$SelectAllButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$SelectAllButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(90, 90, 90)
$SelectAllButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($SelectAllButton)

$DeselectAllButton = New-Object System.Windows.Forms.Button
$DeselectAllButton.Text = "Deseleziona Tutto"
$DeselectAllButton.Location = New-Object System.Drawing.Point(([int]$SelectAllButton.Location.X + [int]$SelectAllButton.Width + 10), $currentButtonY)
$DeselectAllButton.Size = New-Object System.Drawing.Size(120, 30)
$DeselectAllButton.Add_Click({ Deselect-AllCheckboxes })
$DeselectAllButton.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$DeselectAllButton.ForeColor = [System.Drawing.Color]::White
$DeselectAllButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$DeselectAllButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(90, 90, 90)
$DeselectAllButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($DeselectAllButton)

$OOSUButton = New-Object System.Windows.Forms.Button
$OOSUButton.Text = "Esegui O&O ShutUp10"
$OOSUButton.Location = New-Object System.Drawing.Point(([int]$DeselectAllButton.Location.X + [int]$DeselectAllButton.Width + 10), $currentButtonY)
$OOSUButton.Size = New-Object System.Drawing.Size(140, 30)
$OOSUButton.Add_Click({ Invoke-WPFOOSU })
$OOSUButton.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
$OOSUButton.ForeColor = [System.Drawing.Color]::White
$OOSUButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$OOSUButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 120, 100)
$OOSUButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($OOSUButton)

$ApplyButton = New-Object System.Windows.Forms.Button
$ApplyButton.Text = "Applica Modifiche Selezionate"
$ApplyButton.Location = New-Object System.Drawing.Point(([int]$Panel.Location.X + [int]$Panel.Width - 170), $currentButtonY) # Allineato a destra del pannello
$ApplyButton.Size = New-Object System.Drawing.Size(170, 30)
$ApplyButton.Add_Click({ Apply-SelectedChanges })
$ApplyButton.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$ApplyButton.ForeColor = [System.Drawing.Color]::White
$ApplyButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$ApplyButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 100, 180)
$ApplyButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($ApplyButton)


$currentButtonY += [int]($SelectAllButton.Height + 10) # Spazio ridotto

# Etichetta per i pulsanti del Pannello di Controllo
$ControlPanelLabel = New-Object System.Windows.Forms.Label
$ControlPanelLabel.Text = "Pannelli di Controllo Rapidi:"
$ControlPanelLabel.Location = New-Object System.Drawing.Point($currentButtonX, $currentButtonY)
$ControlPanelLabel.AutoSize = $true
$ControlPanelLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$Form.Controls.Add($ControlPanelLabel)

$currentButtonY += [int]($ControlPanelLabel.Height + 5)

# Pulsanti per i pannelli di controllo
$ControlPanelButton = New-Object System.Windows.Forms.Button
$ControlPanelButton.Text = "Pannello di Controllo"
$ControlPanelButton.Location = New-Object System.Drawing.Point($currentButtonX, $currentButtonY)
$ControlPanelButton.Size = New-Object System.Drawing.Size(140, 30)
$ControlPanelButton.Add_Click({ Invoke-WPFControlPanel "WPFPanelcontrol" })
$ControlPanelButton.BackColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
$ControlPanelButton.ForeColor = [System.Drawing.Color]::White
$ControlPanelButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$ControlPanelButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$ControlPanelButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($ControlPanelButton)

$NetworkButton = New-Object System.Windows.Forms.Button
$NetworkButton.Text = "Connessioni di Rete"
$NetworkButton.Location = New-Object System.Drawing.Point(([int]$ControlPanelButton.Location.X + [int]$ControlPanelButton.Width + 10), $currentButtonY)
$NetworkButton.Size = New-Object System.Drawing.Size(140, 30)
$NetworkButton.Add_Click({ Invoke-WPFControlPanel "WPFPanelnetwork" })
$NetworkButton.BackColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
$NetworkButton.ForeColor = [System.Drawing.Color]::White
$NetworkButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$NetworkButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$NetworkButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($NetworkButton)

$PowerButton = New-Object System.Windows.Forms.Button
$PowerButton.Text = "Opzioni Alimentazione"
$PowerButton.Location = New-Object System.Drawing.Point(([int]$NetworkButton.Location.X + [int]$NetworkButton.Width + 10), $currentButtonY)
$PowerButton.Size = New-Object System.Drawing.Size(140, 30)
$PowerButton.Add_Click({ Invoke-WPFControlPanel "WPFPanelpower" })
$PowerButton.BackColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
$PowerButton.ForeColor = [System.Drawing.Color]::White
$PowerButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$PowerButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$PowerButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($PowerButton)

$RegionButton = New-Object System.Windows.Forms.Button
$RegionButton.Text = "Area Geografica"
$RegionButton.Location = New-Object System.Drawing.Point(([int]$PowerButton.Location.X + [int]$PowerButton.Width + 10), $currentButtonY)
$RegionButton.Size = New-Object System.Drawing.Size(140, 30)
$RegionButton.Add_Click({ Invoke-WPFControlPanel "WPFPanelregion" })
$RegionButton.BackColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
$RegionButton.ForeColor = [System.Drawing.Color]::White
$RegionButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$RegionButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$RegionButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($RegionButton)

$currentButtonY += [int]($ControlPanelButton.Height + 5) # Spazio ridotto

$SoundButton = New-Object System.Windows.Forms.Button
$SoundButton.Text = "Audio"
$SoundButton.Location = New-Object System.Drawing.Point($currentButtonX, $currentButtonY)
$SoundButton.Size = New-Object System.Drawing.Size(140, 30)
$SoundButton.Add_Click({ Invoke-WPFControlPanel "WPFPanelsound" })
$SoundButton.BackColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
$SoundButton.ForeColor = [System.Drawing.Color]::White
$SoundButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$SoundButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$SoundButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($SoundButton)

$SystemButton = New-Object System.Windows.Forms.Button
$SystemButton.Text = "Sistema"
$SystemButton.Location = New-Object System.Drawing.Point(([int]$SoundButton.Location.X + [int]$SoundButton.Width + 10), $currentButtonY)
$SystemButton.Size = New-Object System.Drawing.Size(140, 30)
$SystemButton.Add_Click({ Invoke-WPFControlPanel "WPFPanelsystem" })
$SystemButton.BackColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
$SystemButton.ForeColor = [System.Drawing.Color]::White
$SystemButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$SystemButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$SystemButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($SystemButton)

$UserButton = New-Object System.Windows.Forms.Button
$UserButton.Text = "Account Utente"
$UserButton.Location = New-Object System.Drawing.Point(([int]$SystemButton.Location.X + [int]$SystemButton.Width + 10), $currentButtonY)
$UserButton.Size = New-Object System.Drawing.Size(140, 30)
$UserButton.Add_Click({ Invoke-WPFControlPanel "WPFPaneluser" })
$UserButton.BackColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
$UserButton.ForeColor = [System.Drawing.Color]::White
$UserButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$UserButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$UserButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($UserButton)

$currentButtonY += [int]($SoundButton.Height + 10) # Spazio ridotto

# Etichetta per gli strumenti di riparazione
$RepairToolsLabel = New-Object System.Windows.Forms.Label
$RepairToolsLabel.Text = "Strumenti di Riparazione Sistema:"
$RepairToolsLabel.Location = New-Object System.Drawing.Point($currentButtonX, $currentButtonY)
$RepairToolsLabel.AutoSize = $true
$RepairToolsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$Form.Controls.Add($RepairToolsLabel)

$currentButtonY += [int]($RepairToolsLabel.Height + 5)

# Pulsante per DISM e SFC
$SystemRepairButton = New-Object System.Windows.Forms.Button
$SystemRepairButton.Text = "Esegui Riparazione Sistema (DISM & SFC)"
$SystemRepairButton.Location = New-Object System.Drawing.Point($currentButtonX, $currentButtonY)
$SystemRepairButton.Size = New-Object System.Drawing.Size(280, 30)
$SystemRepairButton.Add_Click({ Perform-SystemRepair })
$SystemRepairButton.BackColor = [System.Drawing.Color]::FromArgb(100, 100, 0) # Un colore giallo-verde per l'azione di riparazione
$SystemRepairButton.ForeColor = [System.Drawing.Color]::White
$SystemRepairButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$SystemRepairButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 0)
$SystemRepairButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($SystemRepairButton)

# Nuovo Pulsante per Winget
$WingetUpdateButton = New-Object System.Windows.Forms.Button
$WingetUpdateButton.Text = "Installa/Aggiorna Winget"
$WingetUpdateButton.Location = New-Object System.Drawing.Point(([int]$SystemRepairButton.Location.X + [int]$SystemRepairButton.Width + 10), $currentButtonY)
$WingetUpdateButton.Size = New-Object System.Drawing.Size(180, 30)
$WingetUpdateButton.Add_Click({ Update-Winget })
$WingetUpdateButton.BackColor = [System.Drawing.Color]::FromArgb(0, 100, 180) # Un colore blu
$WingetUpdateButton.ForeColor = [System.Drawing.Color]::White
$WingetUpdateButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$WingetUpdateButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 80, 150)
$WingetUpdateButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($WingetUpdateButton)

$currentButtonY += [int]($SystemRepairButton.Height + 10) # Spazio ridotto

# Etichetta per la configurazione DNS
$DnsLabel = New-Object System.Windows.Forms.Label
$DnsLabel.Text = "Configurazione DNS Personalizzata:"
$DnsLabel.Location = New-Object System.Drawing.Point($currentButtonX, $currentButtonY)
$DnsLabel.AutoSize = $true
$DnsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$Form.Controls.Add($DnsLabel)

$currentButtonY += [int]($DnsLabel.Height + 5)

# ComboBox per la selezione DNS
$DnsComboBox = New-Object System.Windows.Forms.ComboBox
$DnsComboBox.Location = New-Object System.Drawing.Point($currentButtonX, $currentButtonY)
$DnsComboBox.Size = New-Object System.Drawing.Size(200, 25)
$DnsComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList # Rende il ComboBox non modificabile
$DnsComboBox.Items.AddRange(@("Default DHCP", "Google", "Cloudflare", "Cloudflare_Malware", "Cloudflare_Malware_Adult", "Open_DNS", "Quad9", "AdGuard_Ads_Trackers", "AdGuard_Ads_Trackers_Malware_Adult"))
$DnsComboBox.SelectedIndex = 0 # Seleziona di default "Default DHCP"
$DnsComboBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$DnsComboBox.ForeColor = [System.Drawing.Color]::White
$Form.Controls.Add($DnsComboBox)

# Pulsante per applicare il DNS selezionato
$ApplyDnsButton = New-Object System.Windows.Forms.Button
$ApplyDnsButton.Text = "Applica DNS Selezionato"
$ApplyDnsButton.Location = New-Object System.Drawing.Point(([int]$DnsComboBox.Location.X + [int]$DnsComboBox.Width + 10), $currentButtonY)
$ApplyDnsButton.Size = New-Object System.Drawing.Size(180, 25)
$ApplyDnsButton.Add_Click({ Set-DNSConfiguration $DnsComboBox.SelectedItem })
$ApplyDnsButton.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$ApplyDnsButton.ForeColor = [System.Drawing.Color]::White
$ApplyDnsButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$ApplyDnsButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 100, 180)
$ApplyDnsButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($ApplyDnsButton)

$currentButtonY += [int]($DnsComboBox.Height + 10) # Spazio ridotto

# Etichetta per le App in Background
$BackgroundAppsLabel = New-Object System.Windows.Forms.Label
$BackgroundAppsLabel.Text = "Gestione App in Background:"
$BackgroundAppsLabel.Location = New-Object System.Drawing.Point($currentButtonX, $currentButtonY)
$BackgroundAppsLabel.AutoSize = $true
$BackgroundAppsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$Form.Controls.Add($BackgroundAppsLabel)

$currentButtonY += [int]($BackgroundAppsLabel.Height + 5)

# Pulsante per abilitare/disabilitare App in Background
$BackgroundAppsToggleButton = New-Object System.Windows.Forms.Button
$BackgroundAppsToggleButton.Location = New-Object System.Drawing.Point($currentButtonX, $currentButtonY)
$BackgroundAppsToggleButton.Size = New-Object System.Drawing.Size(250, 30)
$BackgroundAppsToggleButton.BackColor = [System.Drawing.Color]::FromArgb(50, 150, 200) # Un colore blu-verde
$BackgroundAppsToggleButton.ForeColor = [System.Drawing.Color]::White
$BackgroundAppsToggleButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$BackgroundAppsToggleButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(30, 120, 180)
$BackgroundAppsToggleButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($BackgroundAppsToggleButton)

# Funzione per aggiornare il testo e lo stato del pulsante App in Background
Function Update-BackgroundAppsButtonState {
    $currentValue = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -ErrorAction SilentlyContinue
    If ($currentValue -and $currentValue.GlobalUserDisabled -eq 1) {
        $BackgroundAppsToggleButton.Text = "Abilita App in Background"
        $BackgroundAppsToggleButton.Tag = "Disabled" # Usa Tag per memorizzare lo stato logico
        $BackgroundAppsToggleButton.BackColor = [System.Drawing.Color]::FromArgb(200, 50, 50) # Rosso per indicare che sono disabilitate
        $BackgroundAppsToggleButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(150, 30, 30)
    } Else {
        $BackgroundAppsToggleButton.Text = "Disabilita App in Background"
        $BackgroundAppsToggleButton.Tag = "Enabled" # Usa Tag per memorizzare lo stato logico
        $BackgroundAppsToggleButton.BackColor = [System.Drawing.Color]::FromArgb(50, 200, 50) # Verde per indicare che sono abilitate
        $BackgroundAppsToggleButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(30, 150, 30)
    }
}

# Aggiungi l'handler di click per il pulsante App in Background
$BackgroundAppsToggleButton.Add_Click({
    If ($BackgroundAppsToggleButton.Tag -eq "Enabled") {
        # Disabilita
        Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type "DWord"
        Show-MessageBox "Le app in background sono state disabilitate. Potrebbe essere necessario un riavvio per avere pieno effetto." "App in Background Disabilitate"
    } Else {
        # Abilita
        Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 0 -Type "DWord"
        Show-MessageBox "Le app in background sono state abilitate. Potrebbe essere necessario un riavvio per avere pieno effetto." "App in Background Abilitate"
    }
    Update-BackgroundAppsButtonState # Aggiorna lo stato del pulsante dopo la modifica
})

# Inizializza lo stato del pulsante all'avvio del form
$Form.Add_Load({ Update-BackgroundAppsButtonState })

$currentButtonY += [int]($BackgroundAppsToggleButton.Height + 5) # Spazio ridotto dopo il pulsante background apps

# Sposta il pulsante Gestisci App in Avvio Automatico qui
$StartupAppsButton = New-Object System.Windows.Forms.Button
$StartupAppsButton.Text = "Gestisci App in Avvio Automatico"
$StartupAppsButton.Location = New-Object System.Drawing.Point($currentButtonX, $currentButtonY) # Nuova posizione
$StartupAppsButton.Size = New-Object System.Drawing.Size(250, 30)
$StartupAppsButton.Add_Click({ Show-StartupAppsManager })
$StartupAppsButton.BackColor = [System.Drawing.Color]::FromArgb(100, 50, 150) # Un colore viola
$StartupAppsButton.ForeColor = [System.Drawing.Color]::White
$StartupAppsButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$StartupAppsButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 30, 120)
$StartupAppsButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($StartupAppsButton)

$currentButtonY += [int]($StartupAppsButton.Height + 2) # Spazio ulteriormente ridotto dopo il pulsante gestisci app avvio automatico

# Etichetta per la barra di avanzamento del download
$Script:DownloadProgressLabel = New-Object System.Windows.Forms.Label
$Script:DownloadProgressLabel.Location = New-Object System.Drawing.Point($currentButtonX, $currentButtonY)
$Script:DownloadProgressLabel.AutoSize = $true
$Script:DownloadProgressLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$Script:DownloadProgressLabel.Text = "" # Inizialmente vuoto
$Form.Controls.Add($Script:DownloadProgressLabel)

$currentButtonY += [int]($Script:DownloadProgressLabel.Height + 2) # Aggiungi altezza etichetta a Y, spazio ridotto

# Barra di avanzamento per i download delle app
$Script:DownloadProgressBar = New-Object System.Windows.Forms.ProgressBar
$Script:DownloadProgressBar.Location = New-Object System.Drawing.Point($currentButtonX, $currentButtonY)
$Script:DownloadProgressBar.Size = New-Object System.Drawing.Size($mainPanelWidth, 20)
$Script:DownloadProgressBar.Minimum = 0
$Script:DownloadProgressBar.Value = 0
$Script:DownloadProgressBar.Visible = $false # Inizialmente nascosta
$Form.Controls.Add($Script:DownloadProgressBar)

$currentButtonY += [int]($Script:DownloadProgressBar.Height + 5) # Aggiungi altezza barra di avanzamento a Y, spazio ridotto

# Nuovo GroupBox per le App da Scaricare
$DownloadAppsGroupBox = New-Object System.Windows.Forms.GroupBox
$DownloadAppsGroupBox.Text = "Download App con Winget"
$DownloadAppsGroupBox.Location = New-Object System.Drawing.Point($currentButtonX, $currentButtonY)
$DownloadAppsGroupBox.Size = New-Object System.Drawing.Size($mainPanelWidth, 330) # Altezza aumentata per la CheckedListBox e i suoi pulsanti
$DownloadAppsGroupBox.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$DownloadAppsGroupBox.ForeColor = [System.Drawing.Color]::LightGray
$Form.Controls.Add($DownloadAppsGroupBox)

# CheckedListBox per le app scaricabili
$Script:DownloadAppsCheckedListBox = New-Object System.Windows.Forms.CheckedListBox
$Script:DownloadAppsCheckedListBox.Location = New-Object System.Drawing.Point(10, 25)
$Script:DownloadAppsCheckedListBox.Size = New-Object System.Drawing.Size(([int]$DownloadAppsGroupBox.Width - 20), 250) # Altezza aumentata per la lista
$Script:DownloadAppsCheckedListBox.CheckOnClick = $true
$Script:DownloadAppsCheckedListBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$Script:DownloadAppsCheckedListBox.ForeColor = [System.Drawing.Color]::LightGray
$Script:DownloadAppsCheckedListBox.BorderStyle = "FixedSingle"
$DownloadAppsGroupBox.Controls.Add($Script:DownloadAppsCheckedListBox)

# Popola la CheckedListBox con oggetti personalizzati
ForEach ($config in $DownloadConfigurations) {
    # Crea un oggetto personalizzato che CheckedListBox può visualizzare e da cui può estrarre l'ID
    $listItem = [PSCustomObject]@{
        DisplayName = $config.Name
        WingetId = $config.WingetId
    }
    $Script:DownloadAppsCheckedListBox.Items.Add($listItem)
}
# Imposta quale proprietà dell'oggetto deve essere visualizzata
$Script:DownloadAppsCheckedListBox.DisplayMember = "DisplayName"


# Pulsanti per la CheckedListBox delle app
$DownloadSelectAllButton = New-Object System.Windows.Forms.Button
$DownloadSelectAllButton.Text = "Seleziona Tutto"
$DownloadSelectAllButton.Location = New-Object System.Drawing.Point(10, ([int]$Script:DownloadAppsCheckedListBox.Location.Y + [int]$Script:DownloadAppsCheckedListBox.Height + 10))
$DownloadSelectAllButton.Size = New-Object System.Drawing.Size(120, 30)
$DownloadSelectAllButton.Add_Click({ Select-AllDownloadApps })
$DownloadSelectAllButton.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$DownloadSelectAllButton.ForeColor = [System.Drawing.Color]::White
$DownloadSelectAllButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$DownloadSelectAllButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(90, 90, 90)
$DownloadSelectAllButton.FlatAppearance.BorderSize = 1
$DownloadAppsGroupBox.Controls.Add($DownloadSelectAllButton)

$DownloadDeselectAllButton = New-Object System.Windows.Forms.Button
$DownloadDeselectAllButton.Text = "Deseleziona Tutto"
$DownloadDeselectAllButton.Location = New-Object System.Drawing.Point(([int]$DownloadSelectAllButton.Location.X + [int]$DownloadSelectAllButton.Width + 10), ([int]$Script:DownloadAppsCheckedListBox.Location.Y + [int]$Script:DownloadAppsCheckedListBox.Height + 10))
$DownloadDeselectAllButton.Size = New-Object System.Drawing.Size(120, 30)
$DownloadDeselectAllButton.Add_Click({ Deselect-AllDownloadApps })
$DownloadDeselectAllButton.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$DownloadDeselectAllButton.ForeColor = [System.Drawing.Color]::White
$DownloadDeselectAllButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$DownloadDeselectAllButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(90, 90, 90)
$DownloadDeselectAllButton.FlatAppearance.BorderSize = 1
$DownloadAppsGroupBox.Controls.Add($DownloadDeselectAllButton)

$InstallSelectedAppsButton = New-Object System.Windows.Forms.Button
$InstallSelectedAppsButton.Text = "Installa App Selezionate"
$InstallSelectedAppsButton.Location = New-Object System.Drawing.Point(([int]$DownloadDeselectAllButton.Location.X + [int]$DownloadDeselectAllButton.Width + 10), ([int]$Script:DownloadAppsCheckedListBox.Location.Y + [int]$Script:DownloadAppsCheckedListBox.Height + 10))
$InstallSelectedAppsButton.Size = New-Object System.Drawing.Size(180, 30)
$InstallSelectedAppsButton.Add_Click({ Install-SelectedDownloadApps })
$InstallSelectedAppsButton.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$InstallSelectedAppsButton.ForeColor = [System.Drawing.Color]::White
$InstallSelectedAppsButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$InstallSelectedAppsButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 100, 180)
$InstallSelectedAppsButton.FlatAppearance.BorderSize = 1
$DownloadAppsGroupBox.Controls.Add($InstallSelectedAppsButton)


# Casella di testo per il log (spostata a destra)
$Script:LogTextBox = New-Object System.Windows.Forms.TextBox
$Script:LogTextBox.Location = New-Object System.Drawing.Point(([int]$Panel.Location.X + [int]$Panel.Width + $padding), $padding)
$Script:LogTextBox.Size = New-Object System.Drawing.Size($logPanelWidth, ([int]$Form.Height - (2 * $padding) - 30)) # Altezza quasi totale del form
$Script:LogTextBox.MultiLine = $true
$Script:LogTextBox.ReadOnly = $true
$Script:LogTextBox.ScrollBars = "Vertical"
$Script:LogTextBox.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25) # Sfondo molto scuro per il log
$Script:LogTextBox.ForeColor = [System.Drawing.Color]::LightGray # Testo chiaro per il log
$Form.Controls.Add($Script:LogTextBox)

# Mostra il form
$Form.ShowDialog() | Out-Null
#endregion
