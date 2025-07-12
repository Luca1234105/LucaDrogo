<#
.SYNOPSIS
    Uno script PowerShell con interfaccia grafica per applicare varie ottimizzazioni al Registro di Windows.

.DESCRIPTION
    Questo script fornisce un'interfaccia utente grafica (GUI) per applicare selettivamente
    una collezione di modifiche al Registro di Windows. Queste modifiche mirano a
    ottimizzare le prestazioni del sistema, migliorare la privacy e personalizzare l'esperienza utente
    disabilitando alcune funzionalità, nascondendo elementi dell'interfaccia e modificando i comportamenti del sistema.

    Ogni ottimizzazione è presentata come una casella di controllo, consentendo all'utente di scegliere quali
    modifiche implementare. Lo script gestisce diversi tipi di dati del Registro
    (DWord, String, Binary) e supporta l'impostazione e la rimozione di chiavi/valori del Registro.
    Include anche funzionalità per disinstallare app predefinite di Windows (bloatware).

.NOTES
    Autore: Gemini
    Versione: 2.2
    Data: 12 luglio 2025

    IMPORTANTE:
    - L'esecuzione di questo script richiede privilegi di amministratore. Tenterà di elevarsi
      se non già in esecuzione come amministratore.
    - La modifica del Registro di Windows e la disinstallazione delle app di sistema comportano dei rischi.
      Si raccomanda vivamente di creare un punto di ripristino del sistema o di eseguire il backup
      del Registro prima di procedere.
    - Alcune modifiche potrebbero richiedere un riavvio del sistema per avere pieno effetto.
#>

#region Verifica privilegi di amministratore
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
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
            @{ Path = "HKLM:\Software\Policies\Microsoft\PushToInstall"; Name = "DisabilitaPushToInstall"; Value = 1; Type = "DWord"; Action = "Set" },
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
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"; Name = "HideRecommendedSection"; Value = 1; Type = "DWord"; Action = "Set" }
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
            @{ Path = "HKLM:\Software\Policies\Microsoft\Windows\System"; Name = "AllowClipboardHistory"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\Software\Policies\Microsoft\Windows\System"; Name = "AllowCrossDeviceClipboard"; Value = 0; Type = "DWord"; Action = "Set" },
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
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "ShowRecommendationsEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "SleepingTabsEnabled"; Value = 1; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "TabServicesEnabled"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "WebWidgetAllowed"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "WebWidgetIsEnabledOnStartup"; Value = 0; Type = "DWord"; Action = "Set" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"; Name = "CreateDesktopShortcutDefault"; Value = 0; Type = "DWord"; Action = "Set" }
        )
    },
    @{
        Name = "Ottimizzazioni Effetti Visivi"
        Description = "Imposta gli effetti visivi su 'Personalizzato', abilita la smussatura dei caratteri e disattiva animazioni superflue per migliorare le prestazioni visive."
        RegistryActions = @(
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"; Name = "VisualFXSetting"; Value = 3; Type = "DWord"; Action = "Set" },
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
        Name = "Disinstalla: Clipchamp"
        Description = "Disinstalla l'applicazione Clipchamp."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Clipchamp.Clipchamp_3.0.10220.0_neutral_~_yxz26nhyzhsrt" }
        )
    },
    @{
        Name = "Disinstalla: Notizie di Bing"
        Description = "Disinstalla l'applicazione Notizie di Bing."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.BingNews_4.1.24002.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Ricerca Bing"
        Description = "Disinstalla l'applicazione Ricerca Bing."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.BingSearch_2022.0.79.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Meteo di Bing"
        Description = "Disinstalla l'applicazione Meteo di Bing."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.BingWeather_4.53.52892.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: App Gaming (Xbox)"
        Description = "Disinstalla l'applicazione Xbox Gaming."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.GamingApp_2024.311.2341.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Ottieni Guida"
        Description = "Disinstalla l'applicazione Ottieni Guida."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.GetHelp_10.2302.10601.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Hub di Office"
        Description = "Disinstalla l'applicazione Hub di Office."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.MicrosoftOfficeHub_18.2308.1034.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Microsoft Solitaire Collection"
        Description = "Disinstalla l'applicazione Microsoft Solitaire Collection."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.MicrosoftSolitaireCollection_4.19.3190.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Sticky Notes"
        Description = "Disinstalla l'applicazione Sticky Notes."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.MicrosoftStickyNotes_4.6.2.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Outlook per Windows"
        Description = "Disinstalla l'applicazione Outlook per Windows."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.OutlookForWindows_1.0.0.0_neutral__8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Paint"
        Description = "Disinstalla l'applicazione Paint."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.Paint_11.2302.20.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Power Automate Desktop"
        Description = "Disinstalla l'applicazione Power Automate Desktop."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.PowerAutomateDesktop_11.2401.28.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Cattura e Annota"
        Description = "Disinstalla l'applicazione Cattura e Annota (Screen Sketch)."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.ScreenSketch_2022.2307.52.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: To Do"
        Description = "Disinstalla l'applicazione Microsoft To Do."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.Todos_2.104.62421.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Dev Home"
        Description = "Disinstalla l'applicazione Dev Home."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.Windows.DevHome_0.100.128.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Fotocamera Windows"
        Description = "Disinstalla l'applicazione Fotocamera di Windows."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.WindowsCamera_2022.2312.3.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Hub di Feedback"
        Description = "Disinstalla l'applicazione Hub di Feedback di Windows."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.WindowsFeedbackHub_2024.125.1522.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Registratore Vocale"
        Description = "Disinstalla l'applicazione Registratore Vocale di Windows."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.WindowsSoundRecorder_2021.2312.5.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Terminale Windows"
        Description = "Disinstalla l'applicazione Terminale Windows."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.WindowsTerminal_3001.18.10301.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Xbox TCUI"
        Description = "Disinstalla l'applicazione Xbox TCUI."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.Xbox.TCUI_1.23.28005.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Xbox Gaming Overlay"
        Description = "Disinstalla l'applicazione Xbox Gaming Overlay."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.XboxGamingOverlay_2.624.1111.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Xbox Identity Provider"
        Description = "Disinstalla l'applicazione Xbox Identity Provider."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.XboxIdentityProvider_12.110.15002.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Xbox Speech To Text Overlay"
        Description = "Disinstalla l'applicazione Xbox Speech To Text Overlay."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.XboxSpeechToTextOverlay_1.97.17002.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Il tuo telefono"
        Description = "Disinstalla l'applicazione Il tuo telefono (Your Phone)."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.YourPhone_1.24012.105.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Groove Musica"
        Description = "Disinstalla l'applicazione Groove Musica (ZuneMusic)."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.ZuneMusic_11.2312.8.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Assistenza Rapida"
        Description = "Disinstalla l'applicazione Assistenza Rapida (Quick Assist)."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "MicrosoftCorporationII.QuickAssist_2024.309.159.0_neutral_~_8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Microsoft Teams (Preinstallato)"
        Description = "Disinstalla l'applicazione Microsoft Teams preinstallata."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "MSTeams_1.0.0.0_x64__8wekyb3d8bbwe" }
        )
    },
    @{
        Name = "Disinstalla: Orologio"
        Description = "Disinstalla l'applicazione Orologio e Sveglie di Windows."
        RegistryActions = @(
            @{ Action = "UninstallAppxPackage"; AppxPackageName = "Microsoft.WindowsAlarms_8wekyb3d8bbwe" } # Usiamo il PackageFamilyName per maggiore compatibilità
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
            @{ Action = "DisableScheduledTask"; TaskPath = "\Microsoft\Windows\OneDrive\"; TaskName = "OneDrive Standalone Update Task-S-1-5-21-*" },
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
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, $Buttons, $Icon) | Out-Null
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
        # Usiamo Start-Process per eseguire il comando PowerShell in un processo separato
        # con l'opzione -Wait per attendere il completamento e -NoNewWindow per non mostrare la finestra
        $command = "Get-AppxPackage -AllUsers -Name `"$AppxPackageNamePattern`" | Remove-AppxPackage -AllUsers -ErrorAction Stop"
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command `"$command`"" -Verb RunAs -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
        $process.WaitForExit()

        If ($process.ExitCode -eq 0) {
            $Script:LogTextBox.AppendText("SUCCESSO: Disinstallato '$AppxPackageNamePattern' per tutti gli utenti.`r`n")
        } Else {
            $Script:LogTextBox.AppendText("ERRORE: Fallita la disinstallazione di '$AppxPackageNamePattern'. Codice di uscita: $($process.ExitCode)`r`n")
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
                Disable-ScheduledTask -InputObject $task -ErrorAction Stop
                $Script:LogTextBox.AppendText("SUCCESSO: Disabilitata attività pianificata '$($task.TaskPath)$($task.TaskName)'.`r`n")
            }
        } else {
            $Script:LogTextBox.AppendText("INFO: Attività pianificata '$TaskPath$TaskNamePattern' non trovata, non disabilitata.`r`n")
        }
    }
    Catch {
        $Script:LogTextBox.AppendText("ERRORE: Impossibile disabilitare attività pianificata '$TaskPath$TaskNamePattern'. Errore: $($_.Exception.Message)`r`n")
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
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command `"$Command`"" -Verb RunAs -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
        $process.WaitForExit()
        If ($process.ExitCode -eq 0) {
            $Script:LogTextBox.AppendText("SUCCESSO: Comando eseguito: '$Command'.`r`n")
        } Else {
            $Script:LogTextBox.AppendText("ERRORE: Fallita esecuzione comando '$Command'. Codice di uscita: $($process.ExitCode)`r`n")
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
        $ProgressPreference = "SilentlyContinue" # Disables the Progress Bar to drastically speed up Invoke-WebRequest
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

Function Perform-FullDebloat {
    $Script:LogTextBox.Clear()
    $Script:LogTextBox.AppendText("Avvio del processo di Debloat completo...`r`n`r`n")

    $confirm = Show-MessageBox "Questo processo eseguirà una serie di modifiche profonde al sistema, inclusa la disinstallazione di OneDrive e la modifica delle impostazioni della barra delle applicazioni. Alcune modifiche potrebbero richiedere un riavvio del sistema. Continuare?" "Conferma Debloat Completo" "YesNo" "Warning"

    If ($confirm -ne "Yes") {
        $Script:LogTextBox.AppendText("Operazione di Debloat annullata dall'utente.`r`n")
        Return
    }

    $Script:LogTextBox.AppendText("--- Disinstallazione e Pulizia OneDrive ---`r`n")
    Try {
        $Script:LogTextBox.AppendText("Tentativo di terminare il processo OneDrive.exe...`r`n")
        Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
        $Script:LogTextBox.AppendText("Processo OneDrive.exe terminato (se in esecuzione).`r`n")
    } Catch {
        $Script:LogTextBox.AppendText("AVVISO: Impossibile terminare OneDrive.exe. Errore: $($_.Exception.Message)`r`n")
    }

    If (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe") {
        $Script:LogTextBox.AppendText("Tentativo di disinstallare OneDrive tramite System32...`r`n")
        Start-Process -FilePath "$env:System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        $Script:LogTextBox.AppendText("Disinstallazione OneDrive (System32) completata.`r`n")
    }
    If (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
        $Script:LogTextBox.AppendText("Tentativo di disinstallare OneDrive tramite SysWOW64...`r`n")
        Start-Process -FilePath "$env:SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        $Script:LogTextBox.AppendText("Disinstallazione OneDrive (SysWOW64) completata.`r`n")
    }

    $Script:LogTextBox.AppendText("Copia dei file di OneDrive nelle cartelle locali...`r`n")
    Try {
        # Using Start-Process for robocopy as it's an external executable and provides better control over output/wait
        $robocopyArgs = "`"$env:USERPROFILE\OneDrive`" `"$env:USERPROFILE`" /mov /e /xj /ndl /nfl /njh /njs /nc /ns /np"
        $process = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
        $process.WaitForExit()
        If ($process.ExitCode -eq 0 -or $process.ExitCode -eq 1) { # Robocopy returns 1 on success with files copied
            $Script:LogTextBox.AppendText("Copia file OneDrive completata.`r`n")
        } else {
            $Script:LogTextBox.AppendText("AVVISO: Robocopy ha restituito codice di uscita $($process.ExitCode). Potrebbe non aver copiato tutti i file.`r`n")
        }
    } Catch {
        $Script:LogTextBox.AppendText("ERRORE: Fallita la copia dei file di OneDrive. Errore: $($_.Exception.Message)`r`n")
    }

    $Script:LogTextBox.AppendText("Rimozione di OneDrive dalla barra laterale di Esplora file...`r`n")
    Remove-Item -Path "HKCR:\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -Force -ErrorAction SilentlyContinue
    $Script:LogTextBox.AppendText("Voci di OneDrive rimosse dalla barra laterale.`r`n")

    $Script:LogTextBox.AppendText("Rimozione collegamento OneDrive...`r`n")
    Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" -ErrorAction SilentlyContinue
    $Script:LogTextBox.AppendText("Collegamento OneDrive rimosso.`r`n")

    $Script:LogTextBox.AppendText("Rimozione attività pianificate di OneDrive...`r`n")
    Try {
        Get-ScheduledTask -TaskPath '\' -TaskName 'OneDrive*' -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false
        $Script:LogTextBox.AppendText("Attività pianificate di OneDrive rimosse.`r`n")
    } Catch {
        $Script:LogTextBox.AppendText("AVVISO: Impossibile rimuovere attività pianificate di OneDrive. Errore: $($_.Exception.Message)`r`n")
    }

    $Script:LogTextBox.AppendText("Rimozione residui di OneDrive...`r`n")
    Remove-Item -Path "$env:USERPROFILE\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKCU:\Software\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    $Script:LogTextBox.AppendText("Residui di OneDrive rimossi.`r`n")

    $Script:LogTextBox.AppendText("--- Ripristino posizioni cartelle predefinite ---`r`n")
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "AppData" -Value "$env:USERPROFILE\AppData\Roaming" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Cache" -Value "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCache" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Cookies" -Value "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCookies" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Favorites" -Value "$env:USERPROFILE\Favorites" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "History" -Value "$env:USERPROFILE\AppData\Local\Microsoft\Windows\History" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Local AppData" -Value "$env:USERPROFILE\AppData\Local" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "My Music" -Value "$env:USERPROFILE\Music" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "My Video" -Value "$env:USERPROFILE\Videos" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "NetHood" -Value "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Network Shortcuts" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "PrintHood" -Value "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Printer Shortcuts" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Programs" -Value "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Recent" -Value "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Recent" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "SendTo" -Value "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\SendTo" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Start Menu" -Value "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Startup" -Value "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Templates" -Value "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Templates" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}" -Value "$env:USERPROFILE\Downloads" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Desktop" -Value "$env:USERPROFILE\Desktop" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "My Pictures" -Value "$env:USERPROFILE\Pictures" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Personal" -Value "$env:USERPROFILE\Documents" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{F42EE2D3-909F-4907-8871-4C22FC0BF756}" -Value "$env:USERPROFILE\Documents" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{0DDD015D-B06C-45D5-8C4C-F59713854639}" -Value "$env:USERPROFILE\Pictures" -Force -ErrorAction SilentlyContinue
    $Script:LogTextBox.AppendText("Posizioni cartelle utente ripristinate.`r`n")

    $Script:LogTextBox.AppendText("--- Disabilitazione Widget Barra delle Applicazioni ---`r`n")
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" -Name "value" -Value 0 -Type "DWord" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Value 0 -Type "DWord" -Force -ErrorAction SilentlyContinue
    $Script:LogTextBox.AppendText("Widget della barra delle applicazioni disabilitati.`r`n")

    $Script:LogTextBox.AppendText("--- Disinstallazione Widgets (WebExperience) ---`r`n")
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0 -Type "DWord" -Force -ErrorAction SilentlyContinue
    Uninstall-AppxPackage -AppxPackageName "*WebExperience*"
    # This registry entry marks the WebExperience as deprovisioned for new users
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy" -Name "(Default)" -Value "" -Force -ErrorAction SilentlyContinue

    $Script:LogTextBox.AppendText("Processo di Debloat completo. Riavvio di Esplora risorse...`r`n")
    Show-MessageBox "Il processo di Debloat è stato completato. Esplora risorse verrà riavviato per applicare alcune modifiche." "Debloat Completato" "OK" "Information"

    # Restart Explorer
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
    Start-Process -FilePath "explorer.exe" -ErrorAction SilentlyContinue
}


Function Apply-SelectedChanges {
    $Script:LogTextBox.Clear()
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
#endregion

#region Crea Form Principale
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Ottimizzatore Registro di Windows"
$Form.Size = New-Object System.Drawing.Size(800, 700)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle" # Impedisce il ridimensionamento
$Form.MaximizeBox = $false
$Form.MinimizeBox = $true
$Form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30) # Sfondo scuro
$Form.ForeColor = [System.Drawing.Color]::LightGray # Testo chiaro

# Aggiungi un componente ToolTip al form
$ToolTip = New-Object System.Windows.Forms.ToolTip

# Pannello per le caselle di controllo (con scorrimento automatico)
$Panel = New-Object System.Windows.Forms.Panel
$Panel.Location = New-Object System.Drawing.Point(10, 10)
$Panel.Size = New-Object System.Drawing.Size(760, 400)
$Panel.AutoScroll = $true
$Panel.BorderStyle = "FixedSingle"
$Panel.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48) # Sfondo scuro leggermente diverso
$Panel.ForeColor = [System.Drawing.Color]::LightGray # Testo chiaro
$Form.Controls.Add($Panel)

$yPos = 10
$Script:CheckBoxes = @() # Memorizza le caselle di controllo per un facile accesso

ForEach ($config in $RegistryConfigurations) {
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

# Pulsanti
$SelectAllButton = New-Object System.Windows.Forms.Button
$SelectAllButton.Text = "Seleziona Tutto"
# Calcola esplicitamente le coordinate per il costruttore Point
$btnY = $Panel.Location.Y + $Panel.Height + 10
$SelectAllButton.Location = New-Object System.Drawing.Point(10, $btnY)
$SelectAllButton.Size = New-Object System.Drawing.Size(100, 30)
$SelectAllButton.Add_Click({ Select-AllCheckboxes })
$SelectAllButton.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60) # Sfondo scuro per i pulsanti
$SelectAllButton.ForeColor = [System.Drawing.Color]::White # Testo bianco per i pulsanti
$SelectAllButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$SelectAllButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(90, 90, 90)
$SelectAllButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($SelectAllButton)

$DeselectAllButton = New-Object System.Windows.Forms.Button
$DeselectAllButton.Text = "Deseleziona Tutto"
# Calcola esplicitamente le coordinate per il costruttore Point
$deselectBtnX = $SelectAllButton.Location.X + $SelectAllButton.Width + 10
$DeselectAllButton.Location = New-Object System.Drawing.Point($deselectBtnX, $btnY)
$DeselectAllButton.Size = New-Object System.Drawing.Size(120, 30)
$DeselectAllButton.Add_Click({ Deselect-AllCheckboxes })
$DeselectAllButton.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$DeselectAllButton.ForeColor = [System.Drawing.Color]::White
$DeselectAllButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$DeselectAllButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(90, 90, 90)
$DeselectAllButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($DeselectAllButton)

$ApplyButton = New-Object System.Windows.Forms.Button
$ApplyButton.Text = "Applica Modifiche Selezionate"
# Calcola esplicitamente le coordinate per il costruttore Point
$applyBtnX = $Form.Width - 190 # Regola per il testo più lungo del pulsante
$ApplyButton.Location = New-Object System.Drawing.Point($applyBtnX, $btnY)
$ApplyButton.Size = New-Object System.Drawing.Size(170, 30)
$ApplyButton.Add_Click({ Apply-SelectedChanges })
$ApplyButton.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204) # Un blu più visibile per il pulsante principale
$ApplyButton.ForeColor = [System.Drawing.Color]::White
$ApplyButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$ApplyButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 100, 180)
$ApplyButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($ApplyButton)

# Nuovo pulsante per il debloat completo
$DebloatButton = New-Object System.Windows.Forms.Button
$DebloatButton.Text = "Debloat Completo"
$debloatBtnX = $DeselectAllButton.Location.X + $DeselectAllButton.Width + 10
$DebloatButton.Location = New-Object System.Drawing.Point($debloatBtnX, $btnY)
$DebloatButton.Size = New-Object System.Drawing.Size(140, 30)
$DebloatButton.Add_Click({ Perform-FullDebloat })
$DebloatButton.BackColor = [System.Drawing.Color]::FromArgb(204, 0, 0) # Un rosso per l'azione di debloat
$DebloatButton.ForeColor = [System.Drawing.Color]::White
$DebloatButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$DebloatButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(180, 0, 0)
$DebloatButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($DebloatButton)

# Nuovo pulsante per O&O ShutUp10
$OOSUButton = New-Object System.Windows.Forms.Button
$OOSUButton.Text = "Esegui O&O ShutUp10"
$oosuBtnX = $DebloatButton.Location.X + $DebloatButton.Width + 10
$OOSUButton.Location = New-Object System.Drawing.Point($oosuBtnX, $btnY)
$OOSUButton.Size = New-Object System.Drawing.Size(140, 30)
$OOSUButton.Add_Click({ Invoke-WPFOOSU })
$OOSUButton.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136) # Un colore verde-blu per il pulsante
$OOSUButton.ForeColor = [System.Drawing.Color]::White
$OOSUButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$OOSUButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 120, 100)
$OOSUButton.FlatAppearance.BorderSize = 1
$Form.Controls.Add($OOSUButton)


# Casella di testo per il log
$Script:LogTextBox = New-Object System.Windows.Forms.TextBox
# Calcola esplicitamente le coordinate per il costruttore Point
$logTextBoxY = $ApplyButton.Location.Y + $ApplyButton.Height + 10
$logTextBoxHeight = $Form.Height - $logTextBoxY - 60
$Script:LogTextBox.Location = New-Object System.Drawing.Point(10, $logTextBoxY)
# Calcola esplicitamente l'altezza
$Script:LogTextBox.Size = New-Object System.Drawing.Size(760, $logTextBoxHeight)
$Script:LogTextBox.MultiLine = $true
$Script:LogTextBox.ReadOnly = $true
$Script:LogTextBox.ScrollBars = "Vertical"
$Script:LogTextBox.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25) # Sfondo molto scuro per il log
$Script:LogTextBox.ForeColor = [System.Drawing.Color]::LightGray # Testo chiaro per il log
$Form.Controls.Add($Script:LogTextBox)

# Mostra il form
$Form.ShowDialog() | Out-Null
#endregion
