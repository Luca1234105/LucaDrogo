Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function New-StylishButton {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width = 200,
        [int]$Height = 40,
        [ScriptBlock]$OnClick
    )
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Location = New-Object System.Drawing.Point($X, $Y)
    $btn.Size = New-Object System.Drawing.Size($Width, $Height)
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderSize = 0
    $btn.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 11)
    $btn.BackColor = [System.Drawing.Color]::FromArgb(46,46,46)
    $btn.ForeColor = [System.Drawing.Color]::FromArgb(0,191,255)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand

    $btn.add_MouseEnter({
        param($sender, $eventArgs)
        $sender.BackColor = [System.Drawing.Color]::FromArgb(74,74,74)
    })
    $btn.add_MouseLeave({
        param($sender, $eventArgs)
        $sender.BackColor = [System.Drawing.Color]::FromArgb(46,46,46)
    })

    if ($OnClick) { $btn.Add_Click($OnClick) }
    return $btn
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Luca Debloat Tool"
$form.Size = New-Object System.Drawing.Size(700, 700)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(28, 28, 28)
$form.ForeColor = [System.Drawing.Color]::White

# Log box scrollabile (RichTextBox)
$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Size = New-Object System.Drawing.Size(660, 420)
$logBox.Location = New-Object System.Drawing.Point(10, 10)
$logBox.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$logBox.ForeColor = [System.Drawing.Color]::White
$logBox.ReadOnly = $true
$logBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$form.Controls.Add($logBox)

function Write-Log($text) {
    $logBox.AppendText("$text`r`n")
    $logBox.ScrollToCaret()
}



# Bottone 1: Esegui Debloat (OneDrive + altro)
$btnDebloat = New-StylishButton -Text "Esegui Debloat" -X 10 -Y 440 -OnClick {
    Write-Log "-- Arresto OneDrive..."
    Start-Process taskkill -ArgumentList "/f /im OneDrive.exe" -WindowStyle Hidden -Wait

    if (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe") {
        Write-Log "-- Disinstallazione OneDrive (System32)"
        Start-Process "$env:SystemRoot\System32\OneDriveSetup.exe" "/uninstall" -Wait
    }
    if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
        Write-Log "-- Disinstallazione OneDrive (SysWOW64)"
        Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" "/uninstall" -Wait
    }

    Write-Log "-- Pulizia cartelle OneDrive..."
    robocopy "$env:USERPROFILE\OneDrive" "$env:USERPROFILE" /mov /e /xj /ndl /nfl /njh /njs /nc /ns /np | Out-Null

    Remove-Item "$env:UserProfile\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LocalAppData\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LocalAppData\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Log "-- Pulizia registro OneDrive..."
    reg delete "HKCU\Software\Microsoft\OneDrive" /f | Out-Null
    reg delete "HKCR\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f | Out-Null
    reg delete "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f | Out-Null
    Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" -ErrorAction SilentlyContinue

    Write-Log "-- Riavvio Explorer..."
    Stop-Process -Name explorer -Force
    Start-Process explorer
    Write-Log "-- Completato!"
}
$form.Controls.Add($btnDebloat)

# Bottone 2: Applica Registry Tweaks completi
$btnApplyRegs = New-StylishButton -Text "Applica Registry Tweaks" -X 230 -Y 440 -Width 200 -OnClick {
    Write-Log "-- Applicazione modifiche registro in corso..."

    $tweaks = @(
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'RotatingLockScreenOverlayEnabled'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowSyncProviderNotifications'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowCastToDevice'; Type='DWORD'; Data=0 },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start'; Name = 'HideRecommendedSection'; Type='DWORD'; Data=1 },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Education'; Name = 'IsEducationEnvironment'; Type='DWORD'; Data=1 },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecommendedSection'; Type='DWORD'; Data=1 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoLowDiskSpaceChecks'; Type='DWORD'; Data=1 },
        @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'ShakeMinimizeWindows'; Type='SZ'; Data='0' },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting'; Name = 'Disabled'; Type='DWORD'; Data=1 },
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'; Name = 'LongPathsEnabled'; Type='DWORD'; Data=1 },
        @{ Path = 'HKLM:\Software\Microsoft\PCHealth\ErrorReporting'; Name = 'DoReport'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\Windows Error Reporting'; Name = 'Disabled'; Type='DWORD'; Data=1 },
        @{ Path = 'HKLM:\Software\Microsoft\Windows\Windows Error Reporting'; Name = 'Disabled'; Type='DWORD'; Data=1 },
        @{ Path = 'HKLM:\Software\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'Disabled'; Type='DWORD'; Data=1 },
        @{ Path = 'HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}'; Name = 'System.IsPinnedToNameSpaceTree'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'MenuShowDelay'; Type='SZ'; Data='0' },
        @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseHoverTime'; Type='SZ'; Data='10' },
        @{ Path = 'HKLM:\Software\Microsoft\Dfrg\BootOptimizeFunction'; Name = 'Enable'; Type='SZ'; Data='y' },
        @{ Path = 'HKLM:\Software\Microsoft\Windows\ScheduledDiagnostics'; Name = 'EnabledExecution'; Type='DWORD'; Data=0 },
        @{ Path = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance'; Name = 'MaintenanceDisabled'; Type='DWORD'; Data=1 },
        @{ Path = 'HKLM:\Software\Policies\Microsoft\Windows\ScheduledDiagnostics'; Name = 'EnabledExecution'; Type='DWORD'; Data=0 },
        @{ Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoLowDiskSpaceChecks'; Type='DWORD'; Data=1 },
        @{ Path = 'HKLM:\Software\Policies\Microsoft\Windows\AppCompat'; Name = 'DisableUAR'; Type='DWORD'; Data=1 },
        @{ Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Application-Experience/Steps-Recorder'; Name = 'Enabled'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_Enabled'; Type='DWORD'; Data=0 },
        @{ Path = 'HKLM:\Software\Policies\Microsoft\Windows\GameDVR'; Name = 'AllowgameDVR'; Type='DWORD'; Data=0 },
        @{ Path = 'HKLM:\System\CurrentControlSet\Services\BcastDVRUserService'; Name = 'Start'; Type='DWORD'; Data=4 },
        @{ Path = 'HKLM:\Software\Policies\Microsoft\Windows\System'; Name = 'AllowClipboardHistory'; Type='DWORD'; Data=0 },
        @{ Path = 'HKLM:\Software\Policies\Microsoft\Windows\System'; Name = 'AllowCrossDeviceClipboard'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SmartActionPlatform\SmartClipboard'; Name = 'Disabled'; Type='DWORD'; Data=1 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'DITest'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'EnableSnapAssistFlyout'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'EnableSnapBar'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'EnableTaskGroups'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'MultiTaskingAltTabFilter'; Type='DWORD'; Data=3 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'ContentDeliveryAllowed'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'FeatureManagementEnabled'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'OemPreInstalledAppsEnabled'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'PreInstalledAppsEnabled'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'PreInstalledAppsEverEnabled'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'RotatingLockScreenEnabled'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'RotatingLockScreenOverlayEnabled'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SilentInstalledAppsEnabled'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SlideshowEnabled'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SoftLandingEnabled'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-338388Enabled'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-88000326Enabled'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContentEnabled'; Type='DWORD'; Data=0 },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SystemPaneSuggestionsEnabled'; Type='DWORD'; Data=0 },
        @{ Path = 'HKLM:\Software\Policies\Microsoft\PushToInstall'; Name = 'DisabilitaPushToInstall'; Type='DWORD'; Data=1 },
        # Qui i valori che si vogliono eliminare
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions'; Name = ''; Type='DeleteKey'; Data=$null },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps'; Name = ''; Type='DeleteKey'; Data=$null },
        # Impostazioni per SvcHostSplitThresholdInKB
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control'; Name = 'SvcHostSplitThresholdInKB'; Type='DWORD'; Data=67108864 },
        # Eliminazione namespace
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}'; Name = ''; Type='DeleteKey'; Data=$null },
        @{ Path = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}'; Name = ''; Type='DeleteKey'; Data=$null },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}'; Name = ''; Type='DeleteKey'; Data=$null },
        @{ Path = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}'; Name = ''; Type='DeleteKey'; Data=$null },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}'; Name = ''; Type='DeleteKey'; Data=$null },
        @{ Path = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}'; Name = ''; Type='DeleteKey'; Data=$null },
        # Disabilita prompt UAC agli amministratori
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'ConsentPromptBehaviorAdmin'; Type='DWORD'; Data=0 },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'PromptOnSecureDesktop'; Type='DWORD'; Data=0 }
    )

    foreach ($tweak in $tweaks) {
        try {
            if ($tweak.Type -eq 'DeleteKey') {
                if (Test-Path $tweak.Path) {
                    Remove-Item -Path $tweak.Path -Recurse -Force
                    Write-Log "Chiave eliminata: $($tweak.Path)"
                } else {
                    Write-Log "Chiave da eliminare non trovata: $($tweak.Path)"
                }
            }
            else {
                if (-not (Test-Path $tweak.Path)) {
                    New-Item -Path $tweak.Path -Force | Out-Null
                    Write-Log "Chiave creata: $($tweak.Path)"
                }
                Set-ItemProperty -Path $tweak.Path -Name $tweak.Name -Value $tweak.Data -Type $tweak.Type -Force
                Write-Log "Impostato $($tweak.Name) in $($tweak.Path) a $($tweak.Data)"
            }
        }
        catch {
            Write-Log "Errore su chiave $($tweak.Path): $($_)"
        }
    }
    Write-Log "-- Tweaks applicati. Riavvia per sicurezza."
}
$form.Controls.Add($btnApplyRegs)

# Bottone 3: Prestazioni Elevate
$btnPower = New-StylishButton -Text "Prestazioni Elevate" -X 450 -Y 440 -Width 200 -OnClick {
    Write-Log "-- Attivazione profilo Prestazioni elevate..."

    $script = @"
if (-not (powercfg /list | Select-String 'e9a42b02-d5df-448d-aa00-03f14749eb61')) {
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
}
powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0
"@

    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))

    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -EncodedCommand $encodedCommand" -Verb RunAs -Wait
        Write-Log "-- Profilo Prestazioni elevate attivato."
    }
    catch {
        Write-Log "-- Errore durante l'attivazione del profilo: $_"
    }
}
$form.Controls.Add($btnPower)



# Bottone 4: Rimuovi AppX Inutili
$btnRemoveAppx = New-StylishButton -Text "Rimuovi AppX Inutili" -X 10 -Y 490 -Width 200 -OnClick {
    Write-Log "-- Rimozione AppX in corso..."
    $apps = @(
        'Clipchamp.Clipchamp',
        'Microsoft.BingNews',
        'Microsoft.BingSearch',
        'Microsoft.BingWeather',
        'Microsoft.GamingApp',
        'Microsoft.GetHelp',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.MicrosoftStickyNotes',
        'Microsoft.OutlookForWindows',
        'Microsoft.Paint',
        'Microsoft.PowerAutomateDesktop',
        'Microsoft.ScreenSketch',
        'Microsoft.Todos',
        'Microsoft.Windows.DevHome',
        'Microsoft.WindowsCamera',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.WindowsSoundRecorder',
        'Microsoft.WindowsTerminal',
        'Microsoft.Xbox.TCUI',
        'Microsoft.XboxGamingOverlay',
        'Microsoft.XboxIdentityProvider',
        'Microsoft.XboxSpeechToTextOverlay',
        'Microsoft.YourPhone',
        'Microsoft.ZuneMusic',
        'MicrosoftCorporationII.QuickAssist',
        'MSTeams'
    )
    foreach ($app in $apps) {
        Write-Log "  Disinstallo $app..."
        Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
    Write-Log "-- AppX rimosse."
}
$form.Controls.Add($btnRemoveAppx)

# Bottone 5: WinScript (esegue batch script complesso)
$btnWinScript = New-StylishButton -Text "Esegui WinScript" -X 230 -Y 490 -Width 200 -OnClick {
    Write-Log "-- Avvio WinScript..."

    $batScript = @"
@echo off
:: Check if the script is running as admin
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    color 4
    echo This script requires administrator privileges.
    echo Please run WinScript as an administrator.
    pause
    exit
)
:: Admin privileges confirmed, continue execution
setlocal EnableExtensions DisableDelayedExpansion
echo -- Debloating Edge
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "EdgeEnhanceImagesEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "PersonalizationReportingEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "ShowRecommendationsEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "HideFirstRunExperience" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "UserFeedbackAllowed" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "ConfigureDoNotTrack" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "AlternateErrorPagesEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "EdgeCollectionsEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "EdgeFollowEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "EdgeShoppingAssistantEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "MicrosoftEdgeInsiderPromotionEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "RelatedMatchesCloudServiceEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "ShowMicrosoftRewards" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "WebWidgetAllowed" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "MetricsReportingEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "StartupBoostEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "BingAdsSuppression" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "NewTabPageHideDefaultTopSites" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "PromotionalTabsEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "SendSiteInfoToImproveServices" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "SpotlightExperiencesAndRecommendationsEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "DiagnosticData" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "EdgeAssetDeliveryServiceEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "CryptoWalletEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "WalletDonationEnabled" /t REG_DWORD /d 0 /f
echo -- Uninstalling Widgets
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t "REG_DWORD" /d "0" /f
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage *WebExperience* | Remove-AppxPackage"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy" /f
echo -- Disabling Taskbar Widgets
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d 0 /f
echo -- Disabling Location access
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /d "Deny" /f
echo -- Disabling Cloud Sync
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
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableThemeSettingSync" /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableThemeSettingSyncUserOverride" /t REG_DWORD /d 1 /f
echo -- Fine WinScript
pause
"@

    $tempFile = [System.IO.Path]::GetTempFileName() + ".bat"
    Set-Content -Path $tempFile -Value $batScript -Encoding ASCII
    Start-Process -FilePath $tempFile -Verb RunAs
    Write-Log "-- WinScript eseguito."
}
$form.Controls.Add($btnWinScript)

# Scegli DNS
$btnVuoto1 = New-StylishButton -Text "Menu DNS" -X 450 -Y 490 -Width 200 -OnClick {
    $dnsBatch = @"
:MENU_DNS
cls
echo Scegli il DNS da impostare:
echo.
echo 1) Google (8.8.8.8 8.8.4.4)
echo 2) Cloudflare (1.1.1.1 1.0.0.1)
echo 3) Cloudflare_Malware (1.1.1.2 1.0.0.2)
echo 4) Cloudflare_Malware_Adult (1.1.1.3 1.0.0.3)
echo 5) Open_DNS (208.67.222.222 208.67.220.220)
echo 6) Quad9 (9.9.9.9 149.112.112.112)
echo 7) AdGuard_Ads_Trackers (94.140.14.14 94.140.15.15)
echo 8) AdGuard_Ads_Trackers_Malware_Adult (94.140.14.15 94.140.15.16)
echo 9) dns0.eu_Open (193.110.81.254 185.253.5.254)
echo 10) dns0.eu_ZERO (193.110.81.9 185.253.5.9)
echo 11) dns0.eu_KIDS (193.110.81.1 185.253.5.1)
echo 12) Ripristina DNS automatici
echo 13) Esci
echo.

set /p choice_dns="Inserisci il numero della scelta: "
set choice_dns=%choice_dns: =%

if "%choice_dns%"=="1" goto SETDNS1
if "%choice_dns%"=="2" goto SETDNS2
if "%choice_dns%"=="3" goto SETDNS3
if "%choice_dns%"=="4" goto SETDNS4
if "%choice_dns%"=="5" goto SETDNS5
if "%choice_dns%"=="6" goto SETDNS6
if "%choice_dns%"=="7" goto SETDNS7
if "%choice_dns%"=="8" goto SETDNS8
if "%choice_dns%"=="9" goto SETDNS9
if "%choice_dns%"=="10" goto SETDNS10
if "%choice_dns%"=="11" goto SETDNS11
if "%choice_dns%"=="12" goto RESETDNS
if "%choice_dns%"=="13" goto END

echo Scelta non valida!
pause
goto MENU_DNS

:SetDns
setlocal enabledelayedexpansion
set primary=%1
set secondary=%2

echo Impostazione DNS %primary% e %secondary% su tutte le interfacce attive...

for /f "tokens=2 delims=:" %%i in ('netsh interface show interface ^| findstr /i "Connesso" ^| findstr /i "Ethernet Wi-Fi"') do (
    set "intf=%%i"
    setlocal enabledelayedexpansion
    set "intf=!intf:~1!"
    echo Impostando su interfaccia: !intf!
    netsh interface ip set dns name="!intf!" static %primary% primary
    netsh interface ip add dns name="!intf!" %secondary% index=2
    endlocal
)

echo Fatto.
pause
endlocal
goto MENU_DNS

:SETDNS1
call :SetDns 8.8.8.8 8.8.4.4
goto MENU_DNS

:SETDNS2
call :SetDns 1.1.1.1 1.0.0.1
goto MENU_DNS

:SETDNS3
call :SetDns 1.1.1.2 1.0.0.2
goto MENU_DNS

:SETDNS4
call :SetDns 1.1.1.3 1.0.0.3
goto MENU_DNS

:SETDNS5
call :SetDns 208.67.222.222 208.67.220.220
goto MENU_DNS

:SETDNS6
call :SetDns 9.9.9.9 149.112.112.112
goto MENU_DNS

:SETDNS7
call :SetDns 94.140.14.14 94.140.15.15
goto MENU_DNS

:SETDNS8
call :SetDns 94.140.14.15 94.140.15.16
goto MENU_DNS

:SETDNS9
call :SetDns 193.110.81.254 185.253.5.254
goto MENU_DNS

:SETDNS10
call :SetDns 193.110.81.9 185.253.5.9
goto MENU_DNS

:SETDNS11
call :SetDns 193.110.81.1 185.253.5.1
goto MENU_DNS

:RESETDNS
echo Ripristino DNS automatici su tutte le interfacce attive...

for /f "tokens=2 delims=:" %%i in ('netsh interface show interface ^| findstr /i "Connesso" ^| findstr /i "Ethernet Wi-Fi"') do (
    set "intf=%%i"
    setlocal enabledelayedexpansion
    set "intf=!intf:~1!"
    echo Ripristino su !intf!
    netsh interface ip set dns name="!intf!" dhcp
    endlocal
)

echo Fatto.
pause
goto MENU_DNS

:END
exit
"@

    $tempFile = [IO.Path]::Combine($env:TEMP, "MenuDNS.bat")
    $dnsBatch | Out-File -FilePath $tempFile -Encoding ASCII
    Start-Process -FilePath $tempFile -Verb RunAs
}
$form.Controls.Add($btnVuoto1)



# Bottone Vuoto 2
$btnVuoto2 = New-StylishButton -Text "Disattiva Attività Pianificate" -X 10 -Y 540 -Width 200 -OnClick {
    $batchScript = @"
@echo off
title Disattivazione attività pianificate inutili
echo Disattivazione attività in corso...

:: === Customer Experience / Telemetria ===
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /disable >nul 2>nul
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /disable >nul 2>nul
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /disable >nul 2>nul

:: === Application Experience / Autochk / DiskDiagnostic ===
schtasks /change /tn "\Microsoft\Windows\Application Experience\ProgramDataUpdater" /disable >nul 2>nul
schtasks /change /tn "\Microsoft\Windows\Autochk\Proxy" /disable >nul 2>nul
schtasks /change /tn "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /disable >nul 2>nul

:: === Feedback e suggerimenti ===
schtasks /change /tn "\Microsoft\Windows\Feedback\Siuf\DmClient" /disable >nul 2>nul
schtasks /change /tn "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /disable >nul 2>nul
schtasks /change /tn "\Microsoft\Windows\PushToInstall\LoginCheck" /disable >nul 2>nul

:: === Family Safety ===
schtasks /change /tn "\Microsoft\Windows\Shell\FamilySafetyMonitor" /disable >nul 2>nul
schtasks /change /tn "\Microsoft\Windows\Shell\FamilySafetyRefresh" /disable >nul 2>nul

:: === Update Orchestrator ===
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScanAfterUpdate" /disable >nul 2>nul
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\Start Oobe Expedite Work" /disable >nul 2>nul
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" /disable >nul 2>nul

:: === Windows Update programmato ===
schtasks /change /tn "\Microsoft\Windows\WindowsUpdate\Scheduled Start" /disable >nul 2>nul

:: === OneDrive ===
schtasks /change /tn "\Microsoft\Windows\OneDrive\OneDrive Standalone Update Task-S-1-5-21-*" /disable >nul 2>nul

:: === Windows Store background ===
schtasks /change /tn "\Microsoft\Windows\WS\WSTask" /disable >nul 2>nul

echo Tutte le attività inutili sono state disattivate.
pause
"@

    $tempFile = [IO.Path]::Combine($env:TEMP, "disattiva_attivita_pianificate.bat")
    $batchScript | Out-File -FilePath $tempFile -Encoding ASCII

    # Esegui il batch come amministratore e aspetta la fine
    Start-Process -FilePath $tempFile -Verb RunAs -Wait
}
$form.Controls.Add($btnVuoto2)


$form.Topmost = $true
$form.ShowDialog() | Out-Null
