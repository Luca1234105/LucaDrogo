Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# REGIONE: COLORI E STILI
# Definizioni dei colori per l'interfaccia grafica con un tocco più raffinato.
$colorFormBack = [System.Drawing.Color]::FromArgb(35, 35, 35) # Grigio scuro leggermente più chiaro
$colorText = [System.Drawing.Color]::White
$colorButton = [System.Drawing.Color]::FromArgb(50, 50, 50) # Grigio scuro per i pulsanti
$colorButtonHover = [System.Drawing.Color]::FromArgb(75, 120, 190) # Blu più vibrante al passaggio del mouse
$colorSidebar = [System.Drawing.Color]::FromArgb(25, 25, 25) # Grigio molto scuro per la sidebar
$colorBorder = [System.Drawing.Color]::FromArgb(80, 80, 80) # Bordo sottile per i pulsanti
$colorLogBackground = [System.Drawing.Color]::FromArgb(45, 45, 45) # Sfondo per il log

$globalFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$buttonFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold) # Font leggermente più grande e grassetto per i pulsanti
$logFont = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Regular) # Font monospace per il log
# FINE REGIONE: COLORI E STILI

# Variabile per l'area di log, inizializzata dopo la creazione del form
$globalLogTextBox = $null
# Variabile per la ComboBox DNS
$globalDnsComboBox = $null


# Funzione per scrivere nell'area di log e nella console
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [string]$Level = "Info" # Info, Warning, Error
    )
    if ($globalLogTextBox) {
        $timestamp = (Get-Date -Format "HH:mm:ss")
        $formattedMessage = "[$timestamp] ${Level}: $Message" 
        
        $globalLogTextBox.AppendText("$formattedMessage`r`n")
        
        $globalLogTextBox.SelectionStart = $globalLogTextBox.Text.Length
        $globalLogTextBox.ScrollToCaret()
    }
    if ($Level -eq "Warning") {
        Write-Warning $Message
    } elseif ($Level -eq "Error") {
        Write-Error $Message
    } else {
        Write-Host $Message
    }
}

# REGIONE: FUNZIONI CREAZIONE PULSANTI E CHECKBOX
function New-Button($text, [System.Drawing.Point]$location, $width=220, $height=50) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Width = $width
    $btn.Height = $height
    $btn.Location = $location
    $btn.BackColor = $colorButton
    $btn.ForeColor = $colorText
    $btn.Font = $buttonFont
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderSize = 1
    $btn.FlatAppearance.BorderColor = $colorBorder
    $btn.Cursor = 'Hand'
    $btn.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

    $btn.Add_MouseEnter({ param($sender,$e) $sender.BackColor = $colorButtonHover })
    $btn.Add_MouseLeave({ param($sender,$e) $sender.BackColor = $colorButton })

    return $btn
}

function New-SmallButton($text, [System.Drawing.Point]$location, $width=120, $height=45) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Width = $width
    $btn.Height = $height
    $btn.Location = $location
    $btn.BackColor = $colorButton
    $btn.ForeColor = $colorText
    $btn.Font = $globalFont
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderSize = 1
    $btn.FlatAppearance.BorderColor = $colorBorder
    $btn.Cursor = 'Hand'
    $btn.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

    $btn.Add_MouseEnter({ param($sender,$e) $sender.BackColor = $colorButtonHover })
    $btn.Add_MouseLeave({ param($sender,$e) $sender.BackColor = $colorButton })

    return $btn
}

function New-TweakCheckbox($text, [System.Drawing.Point]$location) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $text
    $checkbox.Location = $location
    $checkbox.Width = 250
    $checkbox.Height = 30
    $checkbox.ForeColor = $colorText
    $checkbox.Font = $globalFont
    $checkbox.UseVisualStyleBackColor = $true

    return $checkbox
}
# FINE REGIONE: FUNZIONI CREAZIONE PULSANTI E CHECKBOX

# REGIONE: FUNZIONI PRINCIPALI (AGGIORNATE PER DNS E HARDCORE TWEAKS)

function Set-DnsServers {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$DnsServers
    )
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.LinkSpeed -ne $null}
    foreach ($adapter in $adapters) {
        Write-Log "Configurazione DNS per adattatore $($adapter.Name)..."
        try {
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $DnsServers -ErrorAction Stop
            Write-Log "DNS impostato per $($adapter.Name) su $($DnsServers -join ', ')"
        } catch {
            Write-Log "Errore durante la configurazione DNS per $($adapter.Name): $($_.Exception.Message)" "Error"
        }
    }
}

function Clear-DnsServers {
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.LinkSpeed -ne $null}
    foreach ($adapter in $adapters) {
        Write-Log "Rimozione DNS personalizzati per adattatore $($adapter.Name)..."
        try {
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ResetServerAddresses -ErrorAction Stop
            Write-Log "DNS resettati per $($adapter.Name)."
        } catch {
            Write-Log "Errore durante il reset DNS per $($adapter.Name): $($_.Exception.Message)" "Error"
        }
    }
}

function Handle-DNS {
    if (-not $globalDnsComboBox) {
        Write-Log "Errore: ComboBox DNS non trovata." "Error"
        [System.Windows.Forms.MessageBox]::Show("Errore interno: ComboBox DNS non disponibile.", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $selectedDnsOption = $globalDnsComboBox.SelectedItem
    Write-Log "Opzione DNS selezionata: $($selectedDnsOption)"

    switch ($selectedDnsOption) {
        "Google DNS" {
            Set-DnsServers -DnsServers @("8.8.8.8", "8.8.4.4")
            [System.Windows.Forms.MessageBox]::Show("DNS impostato su Google DNS.", "Successo", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
        "Cloudflare DNS" {
            Set-DnsServers -DnsServers @("1.1.1.1", "1.0.0.1")
            [System.Windows.Forms.MessageBox]::Show("DNS impostato su Cloudflare DNS.", "Successo", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
        "OpenDNS" {
            Set-DnsServers -DnsServers @("208.67.222.222", "208.67.220.220")
            [System.Windows.Forms.MessageBox]::Show("DNS impostato su OpenDNS.", "Successo", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
        "Rimuovi DNS Custom" {
            Clear-DnsServers
            [System.Windows.Forms.MessageBox]::Show("DNS personalizzati rimossi (impostato su automatico).", "Successo", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
        default {
            Write-Log "Nessuna opzione DNS valida selezionata." "Warning"
            [System.Windows.Forms.MessageBox]::Show("Seleziona un'opzione DNS valida dal menu a tendina.", "Attenzione", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    }
}

function Invoke-HardcoreTweaks {
    Write-Log "Avvio Tweaks Avanzati (Hardcore Tweaks)..."
    $successCount = 0
    $errorMessages = @()

    $tweaks = @(
        @{ Name = "Disabilito accesso alla posizione"; Cmd = { reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /d "Deny" /f } },
        @{ Name = "Disabilito Cloud Sync"; Cmd = {
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableSettingSync" /t REG_DWORD /d 2 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableSettingSyncUserOverride" /t REG_DWORD /d 1 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableSyncOnPaidNetwork" /t REG_DWORD /d 1 /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync" /v "SyncPolicy" /t REG_DWORD /d 5 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableApplicationSettingSync" /t REG_DWORD /d 2 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableApplicationSettingSyncUserOverride" /t REG_DWORD /d 1 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableAppSyncSettingSync" /t REG_DWORD /d 2 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableAppSyncSettingSyncUserOverride" /t REG_DWORD /d 1 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableCredentialsSettingSync" /t REG_DWORD /d 2 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableCredentialsSettingSyncUserOverride" /t REG_DWORD /d 1 /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Credentials" /v "Enabled" /t REG_DWORD /d 0 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableDesktopThemeSettingSync" /t REG_DWORD /d 2 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableDesktopThemeSettingSyncUserOverride" /t REG_DWORD /d 1 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisablePersonalizationSettingSync" /t REG_DWORD /d 2 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisablePersonalizationSettingSyncUserOverride" /t REG_DWORD /d 1 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableStartLayoutSettingSync" /t REG_DWORD /d 2 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableStartLayoutSettingSyncUserOverride" /t REG_DWORD /d 1 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableWebBrowserSettingSync" /t REG_DWORD /d 2 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableWebBrowserSettingSyncUserOverride" /t REG_DWORD /d 1 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableWebBrowserSettingSync" /t REG_DWORD /d 2 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableWebBrowserSettingSyncUserOverride" /t REG_DWORD /d 1 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableWindowsSettingSync" /t REG_DWORD /d 2 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableWindowsSettingSyncUserOverride" /t REG_DWORD /d 1 /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language" /t REG_DWORD /v "Enabled" /d 0 /f
        }},
        @{ Name = "Disabilito Activity Feed"; Cmd = { reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /d "0" /t REG_DWORD /f } },
        
        @{ Name = "Disabilito Registrazione Schermo Xbox"; Cmd = {
            reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f
        }},
        @{ Name = "Disabilito Download Mappe Automatico"; Cmd = {
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps" /v "AllowUntriggeredNetworkTrafficOnSettingsPage" /t REG_DWORD /d 0 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps" /v "AutoDownloadAndUpdateMapData" /t REG_DWORD /d 0 /f
        }},
        @{ Name = "Elimino utente Default0 (se presente)"; Cmd = { net user defaultuser0 /delete 2>$null } },
        @{ Name = "Disabilito Fotocamera Lock Screen"; Cmd = { reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v "NoLockScreenCamera" /t REG_DWORD /d 1 /f } },
        @{ Name = "Disabilito Biometria (ATTENZIONE: Rompe Windows Hello)"; Cmd = {
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Biometrics" /v "Enabled" /t REG_DWORD /d "0" /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Biometrics\Credential Provider" /v "Enabled" /t "REG_DWORD" /d "0" /f
        }},
        @{ Name = "Disabilito Telemetria Windows"; Cmd = {
            schtasks /change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Windows\Autochk\Proxy" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Windows\Feedback\Siuf\DmClient" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Windows\Windows Error Reporting\QueueReporting" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Windows\Maps\MapsUpdateTask" /DISABLE > $null 2>&1
            sc config diagnosticshub.standardcollector.service start=demand
            sc config diagsvc start=demand
            sc config WerSvc start=demand
            sc config wercplsupport start=demand
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowDesktopAnalyticsProcessing" /t REG_DWORD /d 0 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowDeviceNameInTelemetry" /t REG_DWORD /d 0 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "MicrosoftEdgeDataOptIn" /t REG_DWORD /d 0 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowWUfBCloudProcessing" /t REG_DWORD /d 0 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowUpdateComplianceProcessing" /t REG_DWORD /d 0 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowCommercialDataPipeline" /t REG_DWORD /d 0 /f
            reg add "HKLM\Software\Policies\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d "0" /f
            reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f
            reg add "HKLM\Software\Policies\Microsoft\Windows\DataCollection" /v "DisableOneSettingsDownloads" /t "REG_DWORD" /d "1" /f
            reg add "HKLM\Software\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" /v "NoGenTicket" /t "REG_DWORD" /d "1" /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d "1" /f
            reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t "REG_DWORD" /d "1" /f
            reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting\Consent" /v "DefaultConsent" /t REG_DWORD /d "0" /f
            reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting\Consent" /v "DefaultOverrideBehavior" /t REG_DWORD /d "1" /f
            reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting" /v "DontSendAdditionalData" /t REG_DWORD /d "1" /f
            reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting" /v "LoggingDisabled" /t REG_DWORD /d "1" /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /d "0" /t REG_DWORD /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /d "0" /t REG_DWORD /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /d "0" /t REG_DWORD /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEverEnabled" /d "0" /t REG_DWORD /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /d "0" /t REG_DWORD /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /d "0" /t REG_DWORD /f
            reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications" /v "EnableAccountNotifications" /t REG_DWORD /d "0" /f
            reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications" /v "EnableAccountNotifications" /t REG_DWORD /d "0" /f
            reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_TOASTS_ENABLED" /t REG_DWORD /d "0" /f
            reg add "HKCU\Software\Policies\Microsoft\Windows\EdgeUI" /v "DisableMFUTracking" /t REG_DWORD /d "1" /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\EdgeUI" /v "DisableMFUTracking" /t REG_DWORD /d "1" /f
            reg add "HKCU\Control Panel\International\User Profile" /v "HttpAcceptLanguageOptOut" /t REG_DWORD /d "1" /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d "0" /f
        }},
        @{ Name = "Disabilito Telemetria Windows Update"; Cmd = {
            reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 0 /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t "REG_DWORD" /d 0 /f
        }},
        @{ Name = "Disabilito Telemetria Windows Search"; Cmd = {
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchPrivacy" /t REG_DWORD /d "3" /f
            reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v "DisableSearchHistory" /t REG_DWORD /d "1" /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowSearchToUseLocation" /t "REG_DWORD" /d "0" /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "EnableDynamicContentInWSB" /t "REG_DWORD" /d "0" /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t "REG_DWORD" /d "0" /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch" /t "REG_DWORD" /d "1" /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t "REG_DWORD" /d "1" /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "PreventUnwantedAddIns" /t "REG_SZ" /d " " /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "PreventRemoteQueries" /t REG_DWORD /d "1" /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AlwaysUseAutoLangDetection" /t "REG_DWORD" /d "0" /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowIndexingEncryptedStoresOrItems" /t "REG_DWORD" /d "0" /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "DisableSearchBoxSuggestions" /t "REG_DWORD" /d "1" /f
            reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "CortanaInAmbientMode" /t "REG_DWORD" /d "0" /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t "REG_DWORD" /d "0" /f
            reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCortanaButton" /t "REG_DWORD" /d "0" /f
            reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "CanCortanaBeEnabled" /t "REG_DWORD" /d "0" /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWebOverMeteredConnections" /t "REG_DWORD" /d "0" /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortanaAboveLock" /t "REG_DWORD" /d "0" /f
            reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDynamicSearchBoxEnabled" /t "REG_DWORD" /d "1" /f
            reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\Experience\AllowCortana" /v "value" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "AllowSearchToUseLocation" /t "REG_DWORD" /d "1" /f
            reg add "HKCU\Software\Microsoft\Speech_OneCore\Preferences" /v "ModelDownloadAllowed" /t "REG_DWORD" /d "0" /f
            reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDeviceSearchHistoryEnabled" /t REG_DWORD /d "1" /f
            reg add "HKCU\Software\Microsoft\Speech_OneCore\Preferences" /v "VoiceActivationOn" /t REG_DWORD /d 0 /f
            reg add "HKCU\Software\Microsoft\Speech_OneCore\Preferences" /v "VoiceActivationEnableAboveLockscreen" /t "REG_DWORD" /d "0" /f
            reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v "DisableVoice" /t "REG_DWORD" /d "1" /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t "REG_DWORD" /d "0" /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "DeviceHistoryEnabled" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "HistoryViewEnabled" /t REG_DWORD /d 0 /f
            reg add "HKLM\Software\Microsoft\Speech_OneCore\Preferences" /v "VoiceActivationDefaultOn" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "CortanaEnabled" /t "REG_DWORD" /d "0" /f
            reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "CortanaEnabled" /t "REG_DWORD" /d "0" /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsMSACloudSearchEnabled" /t REG_DWORD /d "0" /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsAADCloudSearchEnabled" /t REG_DWORD /d "0" /f
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCloudSearch" /t "REG_DWORD" /d "0" /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "VoiceShortcut" /t "REG_DWORD" /d "0" /f
            reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "CortanaConsent" /t "REG_DWORD" /d "0" /f
        }},
        @{ Name = "Disabilito Telemetria Office"; Cmd = {
            reg add "HKCU\SOFTWARE\Microsoft\Office\15.0\Outlook\Options\Mail" /v "EnableLogging" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Outlook\Options\Mail" /v "EnableLogging" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\Office\15.0\Outlook\Options\Calendar" /v "EnableCalendarLogging" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Outlook\Options\Calendar" /v "EnableCalendarLogging" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\Office\15.0\Word\Options" /v "EnableLogging" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Word\Options" /v "EnableLogging" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Policies\Microsoft\Office\15.0\OSM" /v "EnableLogging" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Policies\Microsoft\Office\16.0\OSM" /v "EnableLogging" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Policies\Microsoft\Office\15.0\OSM" /v "EnableUpload" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Policies\Microsoft\Office\16.0\OSM" /v "EnableUpload" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\Office\Common\ClientTelemetry" /v "DisableTelemetry" /t REG_DWORD /d 1 /f
            reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Common\ClientTelemetry" /v "DisableTelemetry" /t REG_DWORD /d 1 /f
            reg add "HKCU\SOFTWARE\Microsoft\Office\Common\ClientTelemetry" /v "VerboseLogging" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Common\ClientTelemetry" /v "VerboseLogging" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\Office\15.0\Common" /v "QMEnable" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Common" /v "QMEnable" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\Office\15.0\Common\Feedback" /v "Enabled" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Common\Feedback" /v "Enabled" /t REG_DWORD /d 0 /f
            schtasks /change /TN "\Microsoft\Office\OfficeTelemetryAgentFallBack" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Office\OfficeTelemetryAgentLogOn" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Office\OfficeTelemetryAgentFallBack2016" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Office\OfficeTelemetryAgentLogOn2016" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Office\Office 15 Subscription Heartbeat" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Office\Office 16 Subscription Heartbeat" /DISABLE > $null 2>&1
        }},
        @{ Name = "Disabilito Telemetria Application Experience"; Cmd = {
            schtasks /change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Windows\Application Experience\StartupAppTask" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Windows\Application Experience\PcaPatchDbTask" /DISABLE > $null 2>&1
            schtasks /change /TN "\Microsoft\Windows\Application Experience\MareBackup" /DISABLE > $null 2>&1
        }},
        @{ Name = "Disabilito Telemetria NVIDIA"; Cmd = {
            reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d 0 /f
            reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v "EnableRID44231" /t REG_DWORD /d 0 /f
            reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v "EnableRID64640" /t REG_DWORD /d 0 /f
            reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v "EnableRID66610" /t REG_DWORD /d 0 /f
            reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\Startup" /v "SendTelemetryData" /t REG_DWORD /d 0 /f
            schtasks /change /TN NvTmMon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8} /DISABLE > $null 2>&1
            schtasks /change /TN NvTmRep_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8} /DISABLE > $null 2>&1
            schtasks /change /TN NvTmRepOnLogon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8} /DISABLE > $null 2>&1
        }},
        @{ Name = "Disabilito aggiornamenti Google"; Cmd = {
            sc config gupdate start=disabled
            sc config gupdatem start=disabled
        }},
        @{ Name = "Disabilito Game Bar"; Cmd = {
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f
            reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d 0 /f
        }},
        @{ Name = "Disabilito Game Mode"; Cmd = {
            reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AutoGameModeEnabled" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 0 /f
        }},
        @{ Name = "Imposto Piano Energetico Ultimate Performance"; Cmd = {
            $ultimatePerformance = powercfg -list | Select-String -Pattern 'Ultimate Performance'
            if (-not $ultimatePerformance) {
                Write-Log "-- - Abilito Ultimate Performance (potrebbe non essere disponibile su tutte le SKU)"
                $output = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
                if ($output -match 'Unable to create a new power scheme' -or $output -match 'The power scheme, subgroup or setting specified does not exist') {
                    Write-Log "Tentativo di ripristinare schemi predefiniti e riprovare per Ultimate Performance." "Warning"
                    powercfg -RestoreDefaultSchemes | Out-Null
                    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null # Riprova
                }
            } else {
                Write-Log "-- - Piano energetico Ultimate Performance già esistente."
            }
            $ultimatePlanGUID = (powercfg -list | Select-String -Pattern 'Ultimate Performance').Line.Split()[3]
            if ($ultimatePlanGUID) {
                Write-Log "-- - Attivo Ultimate Performance: $ultimatePlanGUID"
                powercfg -setactive $ultimatePlanGUID | Out-Null
            } else {
                Write-Log "Impossibile trovare il GUID di Ultimate Performance per attivarlo." "Error"
            }
        }},
        @{ Name = "Disabilito Core Isolation (Integrità Memoria)"; Cmd = { reg add "HKLM\System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 0 /f } },
        @{ Name = "Disabilito Prefetch (SysMain)"; Cmd = {
            try { sc stop sysmain } catch {};
            sc config sysmain start=disabled
        }},
        @{ Name = "Disabilito Storage Sense"; Cmd = { reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "01" /t REG_DWORD /d 0 /f } },
        @{ Name = "Disabilito Windows Search Service"; Cmd = {
            try { sc stop "wsearch" } catch {};
            sc config "wsearch" start=disabled
        }},
        @{ Name = "Disabilito Ibernazione"; Cmd = { powercfg.exe /hibernate off } },
        @{ Name = "Aggiungo 'Termina attività' al menu contestuale della Taskbar"; Cmd = { reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" /v "TaskbarEndTask" /t REG_DWORD /d "1" /f } },
        
      @{ Name = "Abilito Dark Mode"; Cmd = {
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f
        }},
        @{ Name = "Mostro Estensioni File"; Cmd = { reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 0 /f } },
        @{ Name = "Disabilito Sticky Keys (tasti permanenti)"; Cmd = { reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "58" /f } },
        @{ Name = "Disabilito Snap Assist Flyout"; Cmd = { reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "EnableSnapAssistFlyout" /t REG_DWORD /d 0 /f } }
    )

    foreach ($tweak in $tweaks) {
        Write-Log "Eseguo: $($tweak.Name)"
        try {
            # Blocca la scrittura sull'output per i comandi reg e schtasks, altrimenti PowerShell li visualizza.
            # Converti ogni riga del Cmd in un comando separato se è un blocco di script.
            if ($tweak.Cmd -is [scriptblock]) {
                & $tweak.Cmd *>&1 | Out-Null # Esegui lo scriptblock e manda l'output a Out-Null
            } else {
                Invoke-Expression "$($tweak.Cmd) *>&1 | Out-Null" # Esegui la stringa come comando e manda l'output a Out-Null
            }
            $successCount++
            Write-Log "   Completato: $($tweak.Name)"
        } catch {
            $errorMessage = $_.Exception.Message
            $errorMessages += "Errore in '$($tweak.Name)': $errorMessage"
            Write-Log "   Errore: $($errorMessage)" "Error"
        }
    }

    Write-Log "Riavvio explorer.exe per applicare alcune modifiche all'interfaccia utente..."
    try {
        Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
        Start-Process "explorer"
        Write-Log "explorer.exe riavviato."
    } catch {
        $errorMessage = $_.Exception.Message
        $errorMessages += "Errore durante il riavvio di explorer.exe: $errorMessage"
        Write-Log "Errore durante il riavvio di explorer.exe: $errorMessage" "Error"
    }

    if ($errorMessages.Count -gt 0) {
        $summary = "Tweaks avanzati completati con errori. Totalmente eseguiti: $($successCount)/$($tweaks.Count). Errori: $($errorMessages.Count)."
        [System.Windows.Forms.MessageBox]::Show("$summary`n`nConsulta il log per i dettagli sugli errori.`nAlcune modifiche potrebbero richiedere un riavvio del sistema o un logout per essere pienamente effettive.", "Tweaks Avanzati - Completo con Errori", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    } else {
        $summary = "Tweaks avanzati completati con successo. Tutte le operazioni eseguite."
        [System.Windows.Forms.MessageBox]::Show("$summary`n`nAlcune modifiche potrebbero richiedere un riavvio del sistema o un logout per essere pienamente effettive.", "Tweaks Avanzati - Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    Write-Log "Esecuzione Tweaks Avanzati completata."
}


function Remove-AppxPackageSafe {
    param([string]$PackageName)
    try {
        Write-Log "Rimuovo $($PackageName) ..."
        Get-AppxPackage -AllUsers -Name $PackageName | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like "$PackageName*" } | Remove-AppxProvisionedPackage -Online
        Write-Log "$($PackageName) rimosso."
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Log "Errore nella rimozione di $($PackageName): $errorMessage" "Error"
    }
}

function Remove-MicrosoftApps {
    Write-Log "Inizio rimozione app Microsoft..."
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
        Write-Log "Tentativo di rimozione: $($app)"
        try {
            Get-AppxPackage -AllUsers -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue
        } catch {
            $errorMessage = $_.Exception.Message
            Write-Log "Impossibile rimuovere $($app): $errorMessage" "Warning"
        }
    }

    $accessibilityPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Accessibility"

    if (Test-Path $accessibilityPath) {
        Write-Log "Tentativo di rimozione cartella Accessibility: $($accessibilityPath)"
        Get-ChildItem -LiteralPath $accessibilityPath -Recurse -Force | ForEach-Object {
            try { $_.Attributes = 'Normal' } catch {}
        }
        try {
            Remove-Item -LiteralPath $accessibilityPath -Recurse -Force -ErrorAction Stop
            Write-Log "Cartella Accessibility rimossa con Remove-Item."
        } catch {
            $errorMessage = $_.Exception.Message
            Write-Log "Remove-Item fallito per cartella Accessibility: $errorMessage" "Warning"
            $cmd = "rd /s /q `"$accessibilityPath`""
            Write-Log "Tentativo di rimozione cartella Accessibility con cmd: $cmd"
            Start-Process -FilePath cmd.exe -ArgumentList "/c $cmd" -Wait -NoNewWindow
            if (-not (Test-Path $accessibilityPath)) {
                Write-Log "Cartella Accessibility rimossa con cmd."
            } else {
                Write-Log "Impossibile rimuovere la cartella Accessibility." "Error"
            }
        }
    } else {
        Write-Log "Cartella Accessibility non trovata."
    }

    [System.Windows.Forms.MessageBox]::Show("Rimozione app Microsoft completata!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

function Remove-OneDrive {
    Write-Log "Rimuovo OneDrive..."
    try {
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
        powershell -Command "Get-ScheduledTask -TaskPath '\' -TaskName 'OneDrive*' -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:`$false" | Out-Null
        Remove-Item "$env:UserProfile\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:LocalAppData\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:LocalAppData\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue
        reg delete "HKEY_CURRENT_USER\Software\Microsoft\OneDrive" /f | Out-Null
        [System.Windows.Forms.MessageBox]::Show("OneDrive rimosso con successo!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Errore durante la rimozione di OneDrive: $errorMessage","Errore",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Disable-Copilot {
    Write-Log "Disabilito Copilot..."
    try {
        Get-AppxPackage Microsoft.CoPilot | Remove-AppxPackage -ErrorAction SilentlyContinue
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f | Out-Null
        reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f | Out-Null
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "AutoOpenCopilotLargeScreens" /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKCU\Software\Microsoft\Windows\Shell\Copilot\BingChat" /v "IsUserEligible" /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "HubsSidebarEnabled" /t REG_DWORD /d 0 /f | Out-Null
        [System.Windows.Forms.MessageBox]::Show("Copilot disabilitato!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Errore durante la disabilitazione di Copilot: $errorMessage","Errore",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Remove-Widgets {
    Write-Log "Rimuovo Widgets..."
    try {
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f | Out-Null
        Get-AppxPackage *WebExperience* | Remove-AppxPackage -ErrorAction SilentlyContinue
        reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy" /f | Out-Null
        [System.Windows.Forms.MessageBox]::Show("Widgets rimossi!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Errore durante la rimozione dei Widgets: $errorMessage","Errore",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Remove-Edge {
    Write-Log "Rimuovo Microsoft Edge Chromium..."
    try {
        $script = (New-Object Net.WebClient).DownloadString('https://cdn.jsdelivr.net/gh/he3als/EdgeRemover@main/get.ps1')
        $sb = [ScriptBlock]::Create($script)
        & $sb -UninstallEdge
        [System.Windows.Forms.MessageBox]::Show("Microsoft Edge rimosso!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Errore durante la rimozione di Microsoft Edge: $errorMessage","Errore",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Invoke-DisattivaServizi {
    Write-Log "Disattivo servizi..."
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
    try {
        [System.IO.File]::WriteAllText($tempBat, $batContent)
        Start-Process -FilePath $tempBat -Verb RunAs
    } catch {
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Errore durante la disattivazione dei servizi: $errorMessage","Errore",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Invoke-AppInstaller {
    Write-Log "Avvio installazione app da E:\App..."
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
    try {
        [System.IO.File]::WriteAllText($tempBat, $batContent)
        Start-Process -FilePath $tempBat -Verb RunAs
    } catch {
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Errore durante l'installazione delle app: $errorMessage","Errore",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Invoke-PowerOptimizations {
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing

    function Write-Log {
        param (
            [string]$Message,
            [ValidateSet("Info", "Warning", "Error")][string]$Level = "Info"
        )
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        switch ($Level) {
            "Info"    { Write-Host "$timestamp [INFO] $Message" -ForegroundColor White }
            "Warning" { Write-Host "$timestamp [WARNING] $Message" -ForegroundColor Yellow }
            "Error"   { Write-Host "$timestamp [ERROR] $Message" -ForegroundColor Red }
        }
    }

    Write-Log "🔧 Avvio ottimizzazioni energetiche..."

    try {
        # Controllo privilegi amministrativi
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Log "❌ Devi eseguire questo script come amministratore." "Error"
            [System.Windows.Forms.MessageBox]::Show("❌ Devi eseguire questo script come amministratore.", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }

        # GUID del piano Ultimate Performance
        $ultimateGUID = "e9a42b02-d5df-448d-aa00-03f14749eb61"

        # Verifica se il piano esiste già
        $exists = powercfg -list | Select-String $ultimateGUID
        if (-not $exists) {
            Write-Log "⚙️ Piano Ultimate Performance non trovato, lo creo..."
            powercfg -duplicatescheme $ultimateGUID | Out-Null
        } else {
            Write-Log "✔️ Piano Ultimate Performance già esistente."
        }

        # Attiva direttamente il GUID (senza cercare per nome)
        powercfg -setactive $ultimateGUID | Out-Null
        Write-Log "✅ Profilo 'Ultimate Performance' attivato (via GUID)."

        # Altri tweak energetici
        powercfg /change monitor-timeout-ac 0 | Out-Null
        powercfg /change monitor-timeout-dc 0 | Out-Null
        Write-Log "✅ Timeout monitor su 'mai' (AC/DC)."

        powercfg /change disk-timeout-ac 0 | Out-Null
        powercfg /change disk-timeout-dc 0 | Out-Null
        Write-Log "✅ Timeout disco su 'mai' (AC/DC)."

        powercfg /change standby-timeout-ac 0 | Out-Null
        powercfg /change standby-timeout-dc 0 | Out-Null
        Write-Log "✅ Sospensione disattivata (AC/DC)."

        powercfg /hibernate off | Out-Null
        Write-Log "✅ Ibernazione disattivata."

        [System.Windows.Forms.MessageBox]::Show("✅ Ottimizzazioni energetiche completate con successo.`nRiavvia il PC per applicare tutti i cambiamenti.", "Successo", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        Write-Log "🎉 Ottimizzazioni completate."
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Log "❌ Errore: $errorMessage" "Error"
        [System.Windows.Forms.MessageBox]::Show("❌ Errore durante le ottimizzazioni:`n$errorMessage", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Invoke-WinUtilDarkMode {
    Write-Log "Toggle Dark Mode..."
    try {
        $Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        $current = Get-ItemPropertyValue -Path $Path -Name AppsUseLightTheme -ErrorAction SilentlyContinue
        if ($null -eq $current) { $current = 1 } # Default to light if not set
        $newValue = if ($current -eq 0) { 1 } else { 0 }
        Set-ItemProperty -Path $Path -Name AppsUseLightTheme -Value $newValue
        Set-ItemProperty -Path $Path -Name SystemUsesLightTheme -Value $newValue
        $msg = if ($newValue -eq 0) { "Dark Mode attivata." } else { "Dark Mode disattivata." }
        [System.Windows.Forms.MessageBox]::Show($msg)
    } catch { 
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Errore: $errorMessage") 
    }
}

function Invoke-WinUtilTaskbarSearch {
    Write-Log "Toggle Taskbar Search..."
    try {
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
        $current = Get-ItemPropertyValue -Path $Path -Name SearchboxTaskbarMode -ErrorAction SilentlyContinue
        if ($null -eq $current) { $current = 1 } # Default to 1 if not set (search icon)
        $newValue = if ($current -eq 0) { 1 } else { 0 } # Toggle 0 (hidden) and 1 (icon)
        Set-ItemProperty -Path $Path -Name SearchboxTaskbarMode -Value $newValue
        $msg = if ($newValue -eq 0) { "Pulsante ricerca disattivato." } else { "Pulsante ricerca attivato." }
        [System.Windows.Forms.MessageBox]::Show($msg)
    } catch { 
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Errore: $errorMessage") 
    }
}

function Toggle-CustomVisualEffects {
    Write-Log "Applico effetti visivi personalizzati..."
    try {
        # Corresponds to "Adjust for best performance"
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0))
        [System.Windows.Forms.MessageBox]::Show("Effetti visivi personalizzati applicati. Potrebbe essere necessario riavviare o effettuare il logout per vedere tutte le modifiche.","Info",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Errore nell'applicazione degli effetti visivi: $errorMessage")
    }
}

function Toggle-ShowTaskViewButton {
    Write-Log "Toggle Pulsante Vista Attività..."
    try {
        $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        $current = Get-ItemPropertyValue -Path $key -Name ShowTaskViewButton -ErrorAction SilentlyContinue
        if ($null -eq $current) { $current = 1 } # Default to 1 (visible)
        $newValue = if ($current -eq 0) { 1 } else { 0 } # Toggle 0 (hidden) and 1 (visible)
        Set-ItemProperty -Path $key -Name ShowTaskViewButton -Value $newValue
        $msg = if ($newValue -eq 0) { "Pulsante Vista Attività disattivato." } else { "Pulsante Vista Attività attivato." }
        [System.Windows.Forms.MessageBox]::Show($msg)
    } catch { 
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Errore: $errorMessage") 
    }
}

function Invoke-RegImporter {
    Write-Log "Avvio importazione file .reg da E:\Script\Esegui..."
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
    try {
        [System.IO.File]::WriteAllText($tempBat, $batContent)
        Start-Process -FilePath $tempBat -Verb RunAs
    } catch {
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Errore durante l'importazione dei file .reg: $errorMessage","Errore",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Disable-Teredo {
    Write-Log "Disabilito Teredo..."
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 1 -Force -ErrorAction Stop
        netsh interface teredo set state disabled | Out-Null
        [System.Windows.Forms.MessageBox]::Show("Teredo disabilitato! Potrebbe essere necessario un riavvio per applicare completamente le modifiche.","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Errore durante la disabilitazione di Teredo: $errorMessage","Errore",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Kill-LMS {
    Write-Log "Kill LMS (Intel Management and Security Application Local Management Service)..."
    try {
        $serviceName = "LMS"
        Write-Log "Arresto e disabilitazione del servizio: $($serviceName)"
        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue;
        Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue;

        Write-Log "Rimozione del servizio: $($serviceName)";
        sc.exe delete $serviceName | Out-Null;

        Write-Log "Rimozione dei pacchetti driver LMS";
        $lmsDriverPackages = Get-ChildItem -Path "C:\Windows\System32\DriverStore\FileRepository" -Recurse -Filter "lms.inf*" -ErrorAction SilentlyContinue;
        foreach ($package in $lmsDriverPackages) {
            Write-Log "Rimozione pacchetto driver: $($package.Name)";
            pnputil /delete-driver "$($package.Name)" /uninstall /force | Out-Null;
        }
        if ($lmsDriverPackages.Count -eq 0) {
            Write-Log "Nessun pacchetto driver LMS trovato nel driver store."
        } else {
            Write-Log "Tutti i pacchetti driver LMS trovati sono stati rimossi."
        }

        Write-Log "Ricerca ed eliminazione dei file eseguibili LMS";
        $programFilesDirs = @("C:\Program Files", "C:\Program Files (x86)");
        $lmsFiles = @();
        foreach ($dir in $programFilesDirs) {
            $lmsFiles += Get-ChildItem -Path $dir -Recurse -Filter "LMS.exe" -ErrorAction SilentlyContinue;
        }
        foreach ($file in $lmsFiles) {
            Write-Log "Acquisizione proprietà del file: $($file.FullName)";
            & icacls "$($file.FullName)" /grant Administrators:F /T /C /Q | Out-Null;
            & takeown /F "$($file.FullName)" /A /R /D Y | Out-Null;
            Write-Log "Eliminazione del file: $($file.FullName)";
            Remove-Item "$($file.FullName)" -Force -ErrorAction SilentlyContinue;
        }
        if ($lmsFiles.Count -eq 0) {
            Write-Log "Nessun file LMS.exe trovato nelle directory Program Files."
        } else {
            Write-Log "Tutti i file LMS.exe trovati sono stati eliminati."
        }
        [System.Windows.Forms.MessageBox]::Show("Il servizio Intel LMS vPro è stato disabilitato, rimosso e bloccato.","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Errore durante la rimozione di LMS: $errorMessage","Errore",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Disable-WifiSense {
    Write-Log "Disabilito Wifi-Sense..."
    try {
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Type DWord -Value 0 -Force -ErrorAction Stop
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Type DWord -Value 0 -Force -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show("Wifi-Sense disabilitato!","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Errore durante la disabilitazione di Wifi-Sense: $errorMessage","Errore",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# FINE REGIONE: FUNZIONI PRINCIPALI

# REGIONE: CREAZIONE FORM PRINCIPALE E LAYOUT
$form = New-Object System.Windows.Forms.Form
$form.Text = "Luca Tweaks - Utility di Ottimizzazione Windows"
$form.Size = [System.Drawing.Size]::new(1000, 780)
$form.MinimumSize = $form.Size # Rende la finestra non ridimensionabile
$form.StartPosition = "CenterScreen"
$form.BackColor = $colorFormBack
$form.ForeColor = $colorText
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.Font = $globalFont # Applica il font globale al form e a tutti i controlli che lo ereditano

# CREAZIONE SIDEBAR
$sidebar = New-Object System.Windows.Forms.Panel
$sidebar.Width = 150
$sidebar.Height = $form.ClientSize.Height
$sidebar.Location = [System.Drawing.Point]::new(0,0)
$sidebar.BackColor = $colorSidebar
$sidebar.Anchor = "Top, Bottom, Left"

$form.Controls.Add($sidebar)

# Coordinate per i pulsanti piccoli nella sidebar
$smallStartX = 15
$smallStartY = 20
$smallSpacingY = 55

# PULSANTI PICCOLI (toggle) NELLA SIDEBAR
$locationBtnToggleDarkMode = [System.Drawing.Point]::new($smallStartX, $smallStartY)
$btnToggleDarkMode = New-SmallButton "Toggle Dark Mode" $locationBtnToggleDarkMode
$btnToggleDarkMode.Add_Click({ Invoke-WinUtilDarkMode })
$sidebar.Controls.Add($btnToggleDarkMode)

$locationBtnToggleTaskbarSearch = [System.Drawing.Point]::new($smallStartX, $smallStartY + $smallSpacingY)
$btnToggleTaskbarSearch = New-SmallButton "Taskbar Search" $locationBtnToggleTaskbarSearch
$btnToggleTaskbarSearch.Add_Click({ Invoke-WinUtilTaskbarSearch })
$sidebar.Controls.Add($btnToggleTaskbarSearch)

$locationBtnToggleVisualFX = [System.Drawing.Point]::new($smallStartX, $smallStartY + $smallSpacingY*2)
$btnToggleVisualFX = New-SmallButton "Effetti Visivi" $locationBtnToggleVisualFX
$btnToggleVisualFX.Add_Click({ Toggle-CustomVisualEffects })
$sidebar.Controls.Add($btnToggleVisualFX)

$locationBtnToggleShowTaskView = [System.Drawing.Point]::new($smallStartX, $smallStartY + $smallSpacingY*3)
$btnToggleShowTaskView = New-SmallButton "Vista Attività" $locationBtnToggleShowTaskView
$btnToggleShowTaskView.Add_Click({ Toggle-ShowTaskViewButton })
$sidebar.Controls.Add($btnToggleShowTaskView)

$locationBtnInstallAppsSidebar = [System.Drawing.Point]::new($smallStartX, $smallStartY + $smallSpacingY*4)
$btnInstallAppsSidebar = New-SmallButton "Installa App E:\App" $locationBtnInstallAppsSidebar
$btnInstallAppsSidebar.Add_Click({ Invoke-AppInstaller })
$sidebar.Controls.Add($btnInstallAppsSidebar)

$locationBtnRegImporter = [System.Drawing.Point]::new($smallStartX, $smallStartY + $smallSpacingY*5)
$btnRegImporter = New-SmallButton "Importa .REG" $locationBtnRegImporter
$btnRegImporter.Add_Click({ Invoke-RegImporter })
$sidebar.Controls.Add($btnRegImporter)

# Nuovo pulsante per i Tweaks Avanzati nella sidebar
$locationBtnHardcoreTweaks = [System.Drawing.Point]::new($smallStartX, $smallStartY + $smallSpacingY*6)
$btnHardcoreTweaks = New-SmallButton "Hardcore Tweaks" $locationBtnHardcoreTweaks
$btnHardcoreTweaks.Add_Click({ Invoke-HardcoreTweaks })
$sidebar.Controls.Add($btnHardcoreTweaks)

# Aggiunta del nuovo pulsante nella sidebar
$locationBtnPowerOptimizations = [System.Drawing.Point]::new($smallStartX, $smallStartY + $smallSpacingY*7)
$btnPowerOptimizations = New-SmallButton "Power Optimizations" $locationBtnPowerOptimizations
$btnPowerOptimizations.Add_Click({ Invoke-PowerOptimizations })
$sidebar.Controls.Add($btnPowerOptimizations)


# Area Principale per Checkbox e Log
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Location = [System.Drawing.Point]::new($sidebar.Width, 0) 
$mainPanelWidth = $form.ClientSize.Width - $sidebar.Width
$mainPanelHeight = $form.ClientSize.Height
$mainPanel.Size = [System.Drawing.Size]::new($mainPanelWidth, $mainPanelHeight)
$mainPanel.BackColor = $colorFormBack
$form.Controls.Add($mainPanel)

# Coordinate per le Checkbox (main area)
$checkboxStartX = 30
$checkboxStartY = 20
$checkboxSpacingY = 40

# CHECKBOX PER LE AZIONI
$locationChkRemoveMicrosoftApps = [System.Drawing.Point]::new($checkboxStartX, $checkboxStartY)
$chkRemoveMicrosoftApps = New-TweakCheckbox "Rimuovi App Microsoft" $locationChkRemoveMicrosoftApps
$mainPanel.Controls.Add($chkRemoveMicrosoftApps)

$locationChkRemoveOneDrive = [System.Drawing.Point]::new($checkboxStartX, $checkboxStartY + $checkboxSpacingY)
$chkRemoveOneDrive = New-TweakCheckbox "Rimuovi OneDrive" $locationChkRemoveOneDrive
$mainPanel.Controls.Add($chkRemoveOneDrive)

$locationChkDisableCopilot = [System.Drawing.Point]::new($checkboxStartX, $checkboxStartY + $checkboxSpacingY*2)
$chkDisableCopilot = New-TweakCheckbox "Disattiva Copilot" $locationChkDisableCopilot
$mainPanel.Controls.Add($chkDisableCopilot)

$locationChkRemoveWidgets = [System.Drawing.Point]::new($checkboxStartX, $checkboxStartY + $checkboxSpacingY*3)
$chkRemoveWidgets = New-TweakCheckbox "Rimuovi Widgets" $locationChkRemoveWidgets
$mainPanel.Controls.Add($chkRemoveWidgets)

$locationChkRemoveEdge = [System.Drawing.Point]::new($checkboxStartX, $checkboxStartY + $checkboxSpacingY*4)
$chkRemoveEdge = New-TweakCheckbox "Rimuovi Microsoft Edge" $locationChkRemoveEdge
$mainPanel.Controls.Add($chkRemoveEdge)

$locationChkDisableServices = [System.Drawing.Point]::new($checkboxStartX, $checkboxStartY + $checkboxSpacingY*5)
$chkDisableServices = New-TweakCheckbox "Disattiva Servizi Windows" $locationChkDisableServices
$mainPanel.Controls.Add($chkDisableServices)

$locationChkDisableTeredo = [System.Drawing.Point]::new($checkboxStartX, $checkboxStartY + $checkboxSpacingY*6)
$chkDisableTeredo = New-TweakCheckbox "Disabilita Teredo" $locationChkDisableTeredo
$mainPanel.Controls.Add($chkDisableTeredo)

$locationChkKillLMS = [System.Drawing.Point]::new($checkboxStartX, $checkboxStartY + $checkboxSpacingY*7)
$chkKillLMS = New-TweakCheckbox "Disabilita Intel LMS (vPro)" $locationChkKillLMS
$mainPanel.Controls.Add($chkKillLMS)

$locationChkDisableWifiSense = [System.Drawing.Point]::new($checkboxStartX, $checkboxStartY + $checkboxSpacingY*8)
$chkDisableWifiSense = New-TweakCheckbox "Disabilita Wifi-Sense" $locationChkDisableWifiSense
$mainPanel.Controls.Add($chkDisableWifiSense)


# DNS ComboBox - posizionata accanto alla checkbox per "Gestione DNS"
$locationDnsComboBox = [System.Drawing.Point]::new($checkboxStartX, $checkboxStartY + $checkboxSpacingY * 9)
$globalDnsComboBox = New-Object System.Windows.Forms.ComboBox
$globalDnsComboBox.Location = $locationDnsComboBox
$globalDnsComboBox.Width = 250
$globalDnsComboBox.Height = 30
$globalDnsComboBox.Font = $globalFont
$globalDnsComboBox.ForeColor = $colorText
$globalDnsComboBox.BackColor = $colorButton # O un colore adatto al tuo tema
$globalDnsComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList # Rende il campo non modificabile
$globalDnsComboBox.Items.AddRange(@("Seleziona opzione DNS", "Google DNS", "Cloudflare DNS", "OpenDNS", "Rimuovi DNS Custom"))
$globalDnsComboBox.SelectedIndex = 0 # Seleziona l'elemento di placeholder

$mainPanel.Controls.Add($globalDnsComboBox)

# Il pulsante Applica Selezionati dovrà ora gestire anche l'opzione DNS selezionata dalla ComboBox.
# Non c'è più una checkbox per Handle-DNS, si basa sulla selezione della ComboBox.

# Pulsante "Applica Selezionati"
$btnApplySelectedX = $checkboxStartX
$btnApplySelectedY = $checkboxStartY + $checkboxSpacingY * 10 + 20 # Sposta leggermente più in basso per fare spazio alla ComboBox
$locationBtnApplySelected = [System.Drawing.Point]::new($btnApplySelectedX, $btnApplySelectedY)
$btnApplySelected = New-Button "Applica Selezionati" $locationBtnApplySelected 250 60
$btnApplySelected.Add_Click({
    if ($globalLogTextBox) { $globalLogTextBox.Clear() }
    Write-Log "Inizio esecuzione delle operazioni selezionate..."
    
    if ($chkRemoveMicrosoftApps.Checked) { Remove-MicrosoftApps }
    if ($chkRemoveOneDrive.Checked) { Remove-OneDrive }
    if ($chkDisableCopilot.Checked) { Disable-Copilot }
    if ($chkRemoveWidgets.Checked) { Remove-Widgets }
    if ($chkRemoveEdge.Checked) { Remove-Edge }
    if ($chkDisableServices.Checked) { Invoke-DisattivaServizi }
    if ($chkDisableTeredo.Checked) { Disable-Teredo }
    if ($chkKillLMS.Checked) { Kill-LMS }
    if ($chkDisableWifiSense.Checked) { Disable-WifiSense }

    # CHIAMATA ALLA FUNZIONE DNS BASATA SULLA COMBOBOX
    if ($globalDnsComboBox.SelectedIndex -ne 0) { 
        Handle-DNS 
    } else {
        Write-Log "Nessuna azione DNS selezionata." "Info"
    }

    Write-Log "Esecuzione completata."
})
$mainPanel.Controls.Add($btnApplySelected)

# Area di Log
$logX = $checkboxStartX + 280
$logY = $checkboxStartY
$logWidth = $mainPanel.Width - $logX - 30 
$logHeight = $mainPanel.Height - $logY - 30 

$globalLogTextBox = New-Object System.Windows.Forms.TextBox
$globalLogTextBox.Multiline = $true
$globalLogTextBox.ReadOnly = $true
$globalLogTextBox.ScrollBars = "Vertical"
$globalLogTextBox.BackColor = $colorLogBackground
$globalLogTextBox.ForeColor = $colorText
$globalLogTextBox.Font = $logFont
$globalLogTextBox.Location = [System.Drawing.Point]::new($logX, $logY)
$globalLogTextBox.Size = [System.Drawing.Size]::new($logWidth, $logHeight)
$globalLogTextBox.Anchor = "Top, Bottom, Right, Left"

$mainPanel.Controls.Add($globalLogTextBox)

# FINE REGIONE: CREAZIONE FORM PRINCIPALE E LAYOUT

# MOSTRA FORM
[void]$form.ShowDialog()
