# WinScript Interattivo - PowerShell Edition
Add-Type -AssemblyName Microsoft.VisualBasic

function Show-Menu {
    Clear-Host
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "     WIN DEBLOAT TOOL" -ForegroundColor Green
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "1. Rimuovi Appx Inutili"
    Write-Host "2. Rimuovi Widgets"
    Write-Host "3. Rimuovi Copilot"
    Write-Host "4. Rimuovi Edge"
    Write-Host "5. Rimuovi OneDrive"
    Write-Host "6. Esegui Tutto"
    Write-Host "0. Esci"
    Write-Host "=============================="
}

function Wait {
    Write-Host ""
    Read-Host "Premi INVIO per tornare al menu"
}

function Rimuovi-Appx {
    Write-Host "[*] Rimozione App Inutili..." -ForegroundColor Yellow
    $packages = @(
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
    foreach ($pkg in $packages) {
        Write-Host "→ Rimuovo: $pkg"
        Get-AppxPackage -Name "*$pkg*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    }
    Wait
}

function Rimuovi-Widgets {
    Write-Host "[*] Rimozione Widgets..." -ForegroundColor Yellow
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f | Out-Null
    Get-AppxPackage -Name "*WebExperience*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy" /f | Out-Null
    Wait
}

function Rimuovi-Copilot {
    Write-Host "[*] Rimozione Copilot..." -ForegroundColor Yellow
    Get-AppxPackage -Name "Microsoft.CoPilot" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "AutoOpenCopilotLargeScreens" /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\Shell\Copilot\BingChat" /v "IsUserEligible" /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "HubsSidebarEnabled" /t REG_DWORD /d 0 /f | Out-Null
    Wait
}

function Rimuovi-Edge {
    Write-Host "[*] Disinstallazione Edge..." -ForegroundColor Yellow
    try {
        $script = (Invoke-WebRequest -Uri "https://cdn.jsdelivr.net/gh/he3als/EdgeRemover@main/get.ps1").Content
        Invoke-Command -ScriptBlock ([ScriptBlock]::Create($script)) -ArgumentList "-UninstallEdge"
    } catch {
        Write-Host "Errore durante la disinstallazione di Edge." -ForegroundColor Red
    }
    Wait
}

function Rimuovi-OneDrive {
    Write-Host "[*] Disinstallazione OneDrive..." -ForegroundColor Yellow
    taskkill /f /im OneDrive.exe > $null 2>&1
    $paths = @(
        "$env:SystemRoot\System32\OneDriveSetup.exe",
        "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) {
            & $p /uninstall
        }
    }

    Remove-Item "$env:UserProfile\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LocalAppData\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LocalAppData\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue
    reg delete "HKCU\Software\Microsoft\OneDrive" /f | Out-Null
    reg delete "HKCR\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f | Out-Null
    reg delete "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f | Out-Null
    Wait
}



function Esegui-BatchWinScript {
    $batchCode = @'
:: WinScript 
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
echo -- Disabling Taskbar Widgets
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d 0 /f
echo -- Disabling Location access
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /d "Deny" /f
echo -- Disabling System files access
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\documentsLibrary" /v "Value" /d "Deny" /t REG_SZ /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\picturesLibrary" /v "Value" /d "Deny" /t REG_SZ /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\videosLibrary" /v "Value" /d "Deny" /t REG_SZ /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\broadFileSystemAccess" /v "Value" /d "Deny" /t REG_SZ /f
echo -- Disabling Account Information access
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation" /v "Value" /d "Deny" /f
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
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableWebBrowserSettingSync" /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableWebBrowserSettingSyncUserOverride" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableWebBrowserSettingSync" /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableWebBrowserSettingSyncUserOverride" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableWindowsSettingSync" /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableWindowsSettingSyncUserOverride" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language" /t REG_DWORD /v "Enabled" /d 0 /f
echo -- Disabling Activity Feed
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /d "0" /t REG_DWORD /f
echo -- Disabling Notification Tray
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /d "1" /t REG_DWORD /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /d "0" /t REG_DWORD /f
echo -- Disabling Xbox Screen Recording
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f
echo -- Disabling Auto Map Downloads
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps" /v "AllowUntriggeredNetworkTrafficOnSettingsPage" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps" /v "AutoDownloadAndUpdateMapData" /t REG_DWORD /d 0 /f
echo -- Deleting Default0 User
net user defaultuser0 /delete 2>nul
echo -- Disabling Biometrics (Breaks Windows Hello)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Biometrics" /v "Enabled" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Biometrics\Credential Provider" /v "Enabled" /t "REG_DWORD" /d "0" /f
echo -- Disabling Lock Screen Camera
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v "NoLockScreenCamera" /t REG_DWORD /d 1 /f
echo -- Disabling Windows Telemetry
schtasks /change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /DISABLE > NUL 2>&1
schtasks /change /TN "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /DISABLE > NUL 2>&1
schtasks /change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /DISABLE > NUL 2>&1
schtasks /change /TN "\Microsoft\Windows\Autochk\Proxy" /DISABLE > NUL 2>&1
schtasks /change /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /DISABLE > NUL 2>&1
schtasks /change /TN "\Microsoft\Windows\Feedback\Siuf\DmClient" /DISABLE > NUL 2>&1
schtasks /change /TN "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /DISABLE > NUL 2>&1
schtasks /change /TN "\Microsoft\Windows\Windows Error Reporting\QueueReporting" /DISABLE > NUL 2>&1
schtasks /change /TN "\Microsoft\Windows\Maps\MapsUpdateTask" /DISABLE > NUL 2>&1
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
reg add "HKLM\Software\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d "1" /f
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
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /d "0" /t REG_DWORD /f
echo -- Disabling Web Search in Start Menu
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f
echo -- Disabling Windows Spotlight
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenOverlayEnabled" /t REG_DWORD /d 0 /f
echo -- Disabling Print 3D
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Print3D" /v "AllowPrint3d" /t REG_DWORD /d 0 /f
echo -- Disabling Xbox Services
sc config XblGameSave start=disabled
sc stop XblGameSave
sc config XblAuthManager start=disabled
sc stop XblAuthManager
sc config XboxGipSvc start=disabled
sc stop XboxGipSvc
sc config XboxNetApiSvc start=disabled
sc stop XboxNetApiSvc
sc config XblBroadcastService start=disabled
sc stop XblBroadcastService
echo -- Disabling Game Bar
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v "GameConfigStoreEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f
echo -- Disabling Notifications for Tips and Suggestions
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353698Enabled" /t REG_DWORD /d 0 /f
echo -- Disabling Windows Ink Workspace
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PenWorkspace" /v "PenWorkspaceMenu" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PenWorkspace" /v "PenWorkspaceButtonDesiredVisibility" /t REG_DWORD /d 0 /f
echo -- Disabling Cortana
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearchOverMeteredConnections" /t REG_DWORD /d 1 /f
echo -- Disabling Store Apps Sync
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount\$$windows.data.applicationsettings.$$windows.data.applicationsettings.ApplicationSettings" /v "Data" /t REG_BINARY /d 00000000 /f
echo -- Disabling Mixed Reality Portal
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Holographic" /v "AllowAutoLaunch" /t REG_DWORD /d 0 /f
echo -- Disabling Windows Spotlight on Start Menu
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "StartMenuExperienceHost" /t REG_DWORD /d 0 /f
echo -- Disabling Windows Store Auto Updates
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "AutoDownload" /t REG_DWORD /d 2 /f
echo -- Disabling Windows Update delivery optimization
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t REG_DWORD /d 0 /f
echo -- Disabling Tips in Start Menu
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_NotifyNewApps" /t REG_DWORD /d 0 /f
echo -- Disabling File Explorer Recent Items
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d 0 /f
echo -- Deleting Temporary files
del /s /q "%TEMP%\*.*"
del /s /q "%SYSTEMROOT%\Temp\*.*"
echo -- End of script
pause
'@

    # Salvo il batch in file temporaneo
    $tempBat = [IO.Path]::Combine([IO.Path]::GetTempPath(), "WinScript_temp.bat")
    Set-Content -Path $tempBat -Value $batchCode -Encoding ASCII

    # Eseguo con elevazione (amministratore)
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempBat`"" -Verb RunAs -Wait

    # Cancello il file temporaneo
    Remove-Item -Path $tempBat -Force
}

function Applica-Reg {
    Write-Log "[*] Applico tutti i tweak del registro..."

    $regItems = @(
        @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="RotatingLockScreenOverlayEnabled"; Type="DWord"; Value=0},
        @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="ShowSyncProviderNotifications"; Type="DWord"; Value=0},
        @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="ShowCastToDevice"; Type="DWord"; Value=0},
        @{Path="HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start"; Name="HideRecommendedSection"; Type="DWord"; Value=1},
        @{Path="HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Education"; Name="IsEducationEnvironment"; Type="DWord"; Value=1},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"; Name="HideRecommendedSection"; Type="DWord"; Value=1},
        @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name="NoLowDiskSpaceChecks"; Type="DWord"; Value=1},
        @{Path="HKCU:\Control Panel\Desktop"; Name="ShakeMinimizeWindows"; Type="String"; Value="0"},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"; Name="Disabled"; Type="DWord"; Value=1},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Name="LongPathsEnabled"; Type="DWord"; Value=1},
        @{Path="HKLM:\Software\Microsoft\PCHealth\ErrorReporting"; Name="DoReport"; Type="DWord"; Value=0},
        @{Path="HKCU:\Software\Microsoft\Windows\Windows Error Reporting"; Name="Disabled"; Type="DWord"; Value=1},
        @{Path="HKLM:\Software\Microsoft\Windows\Windows Error Reporting"; Name="Disabled"; Type="DWord"; Value=1},
        @{Path="HKLM:\Software\Policies\Microsoft\Windows\Windows Error Reporting"; Name="Disabled"; Type="DWord"; Value=1},
        @{Path="HKCU:\Control Panel\Desktop"; Name="MenuShowDelay"; Type="String"; Value="0"},
        @{Path="HKCU:\Control Panel\Mouse"; Name="MouseHoverTime"; Type="String"; Value="10"},
        @{Path="HKLM:\Software\Microsoft\Dfrg\BootOptimizeFunction"; Name="Enable"; Type="String"; Value="y"},
        @{Path="HKLM:\Software\Microsoft\Windows\ScheduledDiagnostics"; Name="EnabledExecution"; Type="DWord"; Value=0},
        @{Path="HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance"; Name="MaintenanceDisabled"; Type="DWord"; Value=1},
        @{Path="HKLM:\Software\Policies\Microsoft\Windows\ScheduledDiagnostics"; Name="EnabledExecution"; Type="DWord"; Value=0},
        @{Path="HKLM:\Software\Policies\Microsoft\Windows\AppCompat"; Name="DisableUAR"; Type="DWord"; Value=1},
        @{Path="HKLM:\Software\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Application-Experience/Steps-Recorder"; Name="Enabled"; Type="DWord"; Value=0},
        @{Path="HKCU:\System\GameConfigStore"; Name="GameDVR_Enabled"; Type="DWord"; Value=0},
        @{Path="HKLM:\Software\Policies\Microsoft\Windows\GameDVR"; Name="AllowgameDVR"; Type="DWord"; Value=0},
        @{Path="HKLM:\System\CurrentControlSet\Services\BcastDVRUserService"; Name="Start"; Type="DWord"; Value=4},
        @{Path="HKLM:\Software\Policies\Microsoft\Windows\System"; Name="AllowClipboardHistory"; Type="DWord"; Value=0},
        @{Path="HKLM:\Software\Policies\Microsoft\Windows\System"; Name="AllowCrossDeviceClipboard"; Type="DWord"; Value=0},
        @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\SmartActionPlatform\SmartClipboard"; Name="Disabled"; Type="DWord"; Value=1},
        @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="EnableSnapAssistFlyout"; Type="DWord"; Value=0},
        @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="EnableSnapBar"; Type="DWord"; Value=0},
        @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="EnableTaskGroups"; Type="DWord"; Value=0},
        @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="MultiTaskingAltTabFilter"; Type="DWord"; Value=3},
        @{Path="HKLM:\Software\Policies\Microsoft\PushToInstall"; Name="DisabilitaPushToInstall"; Type="DWord"; Value=1},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control"; Name="SvcHostSplitThresholdInKB"; Type="DWord"; Value=0x4000000},
        @{Path="HKCU:\Control Panel\Desktop"; Name="AutoEndTasks"; Type="String"; Value="1"},
        @{Path="HKLM:\SOFTWARE\Microsoft\SQMClient\Windows"; Name="CEIPEnable"; Type="DWord"; Value=0},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications"; Name="ConfigureChatAutoInstall"; Type="DWord"; Value=0},
        @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"; Name="link"; Type="Binary"; Value=0},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Family options"; Name="UILockdown"; Type="DWord"; Value=1},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Device performance and health"; Name="UILockdown"; Type="DWord"; Value=1},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Account protection"; Name="UILockdown"; Type="DWord"; Value=1}
    )

    foreach ($item in $regItems) {
        try {
            if (-not (Test-Path $item.Path)) {
                New-Item -Path $item.Path -Force | Out-Null
            }
            New-ItemProperty -Path $item.Path -Name $item.Name -Value $item.Value -PropertyType $item.Type -Force | Out-Null
            Write-Log "[+] $($item.Path) → $($item.Name) = $($item.Value)"
        } catch {
            Write-Log "[X] Errore su $($item.Path) → $($item.Name): $_"
        }
    }

    $deleteKeys = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps"
    )

    foreach ($key in $deleteKeys) {
        try {
            if (Test-Path $key) {
                Remove-Item -Path $key -Recurse -Force
                Write-Log "[-] Rimozione chiave: $key"
            }
        } catch {
            Write-Log "[X] Errore durante la rimozione di $key: $_"
        }
    }
}





function Show-Menu {
    Clear-Host
    Write-Host "=== Menu Principale ===" -ForegroundColor Yellow
    Write-Host "1 - Rimuovi Appx"
    Write-Host "2 - Rimuovi Widgets"
    Write-Host "3 - Rimuovi Copilot"
    Write-Host "4 - Rimuovi Edge"
    Write-Host "5 - Rimuovi OneDrive"
    Write-Host "6 - Esegui tutte le rimozioni + ottimizza sistema"
    Write-Host "7 - Ottimizza sistema (batch completo)"
    Write-Host "8 - Applica-Reg"
    Write-Host "0 - Esci"
    Write-Host ""
}

do {
    Show-Menu
    $choice = Read-Host "Seleziona un'opzione"

    switch ($choice) {
        '1' { Write-Host "Rimuovo Appx..." }
        '2' { Write-Host "Rimuovo Widgets..." }
        '3' { Write-Host "Rimuovo Copilot..." }
        '4' { Write-Host "Rimuovo Edge..." }
        '5' { Write-Host "Rimuovo OneDrive..." }
        '6' { Write-Host "Eseguo tutte le rimozioni + ottimizzazione..." }
        '7' { Write-Host "Ottimizzo sistema (batch completo)..." }
        '8' { Applica-Reg }
        '0' {
            Write-Host "Programma terminato."
            break
        }
        default { Write-Host "Scelta non valida. Riprova." -ForegroundColor Red }
    }

    Write-Host ""
    Write-Host "Premi un tasto per continuare..."
    [void][System.Console]::ReadKey($true)
} while ($true)


Write-Host "Programma terminato. Premere un tasto per chiudere."
[void][System.Console]::ReadKey($true)
