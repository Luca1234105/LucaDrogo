Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# === Funzione per scrivere nel registro con gestione errori ===
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
            New-Item -Path $fullPath -Force | Out-Null
        }
        Set-ItemProperty -Path $fullPath -Name $Name -Value $Value -Type $Type
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Errore: $($_.Exception.Message)", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
}

# === Funzione per creare pulsanti ===
function New-Button {
    param (
        [string]$Text,
        [int]$X,
        [int]$Y
    )
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Size = New-Object System.Drawing.Size(280, 40)
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    return $button
}

# === Crea il form ===
$form = New-Object System.Windows.Forms.Form
$form.Text = "Gestione Tweaks Registro"
$form.Size = New-Object System.Drawing.Size(640, 600)
$form.StartPosition = "CenterScreen"

# === Pannello scrollabile ===
$panel = New-Object System.Windows.Forms.Panel
$panel.Dock = "Fill"  # Fa sì che occupi tutto lo spazio *restante* dopo la sidebar
$panel.AutoScroll = $true
$form.Controls.Add($panel)

# === Elenco bottoni (X, Y alternati in 2 colonne) ===
$buttons = @(
    @{Text="Imposta SvcHostSplitThresholdInKB (0x4000000)";         X=20;  Y=10;  Path="SYSTEM\CurrentControlSet\Control"; Name="SvcHostSplitThresholdInKB"; Value=0x4000000; Type="DWord"},
    @{Text="Abilita LongPathsEnabled";                             X=320; Y=10;  Path="SYSTEM\CurrentControlSet\Control\FileSystem"; Name="LongPathsEnabled"; Value=1; Type="DWord"},
    @{Text="Nascondi pagina Impostazioni Home";                    X=20;  Y=60;  Path="SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name="SettingsPageVisibility"; Value="hide:home"; Type="String"},
    @{Text="Disabilita CEIP (SQMClient)";                          X=320; Y=60;  Path="SOFTWARE\Microsoft\SQMClient\Windows"; Name="CEIPEnable"; Value=0; Type="DWord"},
    @{Text="Blocca driver da Windows Update";                      X=20;  Y=110; Path="SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"; Name="ExcludeWUDriversInQualityUpdate"; Value=1; Type="DWord"},
    @{Text="Disattiva installazione automatica driver";            X=320; Y=110; Path="SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching"; Name="SearchOrderConfig"; Value=0; Type="DWord"},
    @{Text="Disabilita aggiornamento driver da PC";                X=20;  Y=160; Path="SOFTWARE\Policies\Microsoft\Windows\Device Metadata"; Name="PreventDeviceMetadataFromNetwork"; Value=1; Type="DWord"},
    @{Text="Disabilita GameDVR";                                   X=320; Y=160; Path="SOFTWARE\Policies\Microsoft\Windows\GameDVR"; Name="AllowGameDVR"; Value=0; Type="DWord"},
    @{Text="Nascondi Opzioni Famiglia";                            X=20;  Y=210; Path="SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Family options"; Name="UILockdown"; Value=1; Type="DWord"},
    @{Text="Nascondi Prestazioni e Integrità";                     X=320; Y=210; Path="SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Device performance and health"; Name="UILockdown"; Value=1; Type="DWord"},
    @{Text="Nascondi Protezione Account";                          X=20;  Y=260; Path="SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Account protection"; Name="UILockdown"; Value=1; Type="DWord"},
    @{Text="Disabilita WPBT Execution";                            X=320; Y=260; Path="SYSTEM\CurrentControlSet\Control\Session Manager"; Name="DisableWpbtExecution"; Value=1; Type="DWord"},
    @{Text="Imposta Max Cached Icons a 4096";                      X=20;  Y=310; Path="SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"; Name="Max Cached Icons"; Value="4096"; Type="String"},
    @{Text="Disabilita Multicast DNSClient";                       X=320; Y=310; Path="SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"; Name="EnableMulticast"; Value=0; Type="DWord"},
    @{Text="Blocca Internet OpenWith";                             X=20;  Y=360; Path="SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name="NoInternetOpenWith"; Value=1; Type="DWord"},
    @{Text="Disabilita Superfetch e Prefetcher";                   X=320; Y=360; Path="SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Name="EnableSuperfetch"; Value=0; Type="DWord"},
    @{Text="Imposta GPU Priority giochi";                          X=20;  Y=410; Path="SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Name="GPU Priority"; Value=8; Type="DWord"},
    @{Text="Blocca AAD Workplace Join";                            X=320; Y=410; Path="SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name="BlockAADWorkplaceJoin"; Value=0; Type="DWord"},
    @{Text="Disabilita Agent Activation SpeechOneCore";            X=20;  Y=460; Path="SOFTWARE\Microsoft\Windows\CurrentVersion\SpeechOneCore\Settings"; Name="AgentActivationLastUsed"; Value=0; Type="DWord"},
    @{Text="Imposta System Responsiveness";                        X=320; Y=460; Path="SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Name="SystemResponsiveness"; Value=0; Type="DWord"}
    @{Text="Disabilita feed Notizie e Widgets"; X=20; Y=510; Action={
    try {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Force | Out-Null
        New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -PropertyType DWord -Value 0 -Force | Out-Null
        Get-AppxPackage *WebExperience* | Remove-AppxPackage -ErrorAction SilentlyContinue
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned" -Force | Out-Null
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned" `
            -Name "MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy" -Value "" -PropertyType String -Force | Out-Null
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Process explorer.exe
        [System.Windows.Forms.MessageBox]::Show("Feed Notizie e Widgets disabilitati.","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Errore: $($_.Exception.Message)","Errore",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
}},

@{Text="Disattiva tracciamento Edge"; X=320; Y=510; Action={
    $edgeRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    $entries = @{
        EdgeEnhanceImagesEnabled                      = 0
        PersonalizationReportingEnabled               = 0
        ShowRecommendationsEnabled                    = 0
        HideFirstRunExperience                        = 1
        UserFeedbackAllowed                           = 0
        ConfigureDoNotTrack                           = 1
        AlternateErrorPagesEnabled                    = 0
        EdgeCollectionsEnabled                        = 0
        EdgeFollowEnabled                             = 0
        EdgeShoppingAssistantEnabled                  = 0
        MicrosoftEdgeInsiderPromotionEnabled          = 0
        RelatedMatchesCloudServiceEnabled             = 0
        ShowMicrosoftRewards                          = 0
        WebWidgetAllowed                              = 0
        MetricsReportingEnabled                       = 0
        StartupBoostEnabled                           = 0
        BingAdsSuppression                            = 0
        NewTabPageHideDefaultTopSites                 = 0
        PromotionalTabsEnabled                        = 0
        SendSiteInfoToImproveServices                 = 0
        SpotlightExperiencesAndRecommendationsEnabled = 0
        DiagnosticData                                = 0
        EdgeAssetDeliveryServiceEnabled               = 0
        CryptoWalletEnabled                           = 0
        WalletDonationEnabled                         = 0
    }

    if (-not (Test-Path $edgeRegPath)) {
        New-Item -Path $edgeRegPath -Force | Out-Null
    }

    foreach ($name in $entries.Keys) {
        New-ItemProperty -Path $edgeRegPath -Name $name -PropertyType DWord -Value $entries[$name] -Force | Out-Null
    }

    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe

    [System.Windows.Forms.MessageBox]::Show("Ottimizzazioni Edge applicate con successo.","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}}

)

# === Ciclo per creare e aggiungere i pulsanti al pannello ===
foreach ($btnInfo in $buttons) {
    $btn = New-Button -Text $btnInfo.Text -X $btnInfo.X -Y $btnInfo.Y

    if ($btnInfo.ContainsKey("Action")) {
        $btn.Add_Click($btnInfo.Action)
    } else {
        $btn.Add_Click({
            Set-RegistryValue -Path $btnInfo.Path -Name $btnInfo.Name -Value $btnInfo.Value -Type ([Microsoft.Win32.RegistryValueKind]::$($btnInfo.Type))

            if ($btnInfo.Text -like "*Superfetch*") {
                Set-RegistryValue -Path "SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" `
                                  -Name "EnablePrefetcher" -Value 0 -Type ([Microsoft.Win32.RegistryValueKind]::DWord)
            }

            if ($btnInfo.Text -like "*SpeechOneCore*") {
                Set-RegistryValue -Path "SOFTWARE\Microsoft\Windows\CurrentVersion\SpeechOneCore\Settings" `
                                  -Name "AgentActivationEnabled" -Value 0 -Type ([Microsoft.Win32.RegistryValueKind]::DWord)
            }
        })
    }

    $panel.Controls.Add($btn)
}


# === Pannello laterale ===
$sidebar = New-Object System.Windows.Forms.Panel
$sidebar.Size = New-Object System.Drawing.Size(150, $form.ClientSize.Height)
$sidebar.Dock = "Left"
$sidebar.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$sidebar.BorderStyle = "FixedSingle"
$form.Controls.Add($sidebar)

# === Bottoni barra laterale ===

# Num Lock Toggle
$btnNumLock = New-Object System.Windows.Forms.Button
$btnNumLock.Text = "Num Lock ON"
$btnNumLock.Size = New-Object System.Drawing.Size(130, 40)
$btnNumLock.Location = New-Object System.Drawing.Point(10, 20)
$btnNumLock.Tag = $true
$btnNumLock.Add_Click({
    if ($btnNumLock.Tag) {
        $wsh = New-Object -ComObject WScript.Shell
        $wsh.SendKeys('{NUMLOCK}')
        $btnNumLock.Text = "Num Lock OFF"
        $btnNumLock.Tag = $false
    } else {
        $wsh = New-Object -ComObject WScript.Shell
        $wsh.SendKeys('{NUMLOCK}')
        $btnNumLock.Text = "Num Lock ON"
        $btnNumLock.Tag = $true
    }
})
$sidebar.Controls.Add($btnNumLock)

# Modalità scura Toggle
$btnDarkMode = New-Object System.Windows.Forms.Button
$btnDarkMode.Text = "Modalità Scura"
$btnDarkMode.Size = New-Object System.Drawing.Size(130, 40)
$btnDarkMode.Location = New-Object System.Drawing.Point(10, 80)
$btnDarkMode.Tag = $false
$btnDarkMode.Add_Click({
    if ($btnDarkMode.Tag) {
        # Passa a chiara
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 1
        $btnDarkMode.Text = "Modalità Scura"
        $btnDarkMode.Tag = $false
    } else {
        # Passa a scura
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0
        $btnDarkMode.Text = "Modalità Chiara"
        $btnDarkMode.Tag = $true
    }
})
$sidebar.Controls.Add($btnDarkMode)

$btnPowerPerf = New-Object System.Windows.Forms.Button
$btnPowerPerf.Text = "Prestazioni Elevate"
$btnPowerPerf.Size = New-Object System.Drawing.Size(130, 40)
$btnPowerPerf.Location = New-Object System.Drawing.Point(10, 140)
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


$btnDisableHibernate = New-Object System.Windows.Forms.Button
$btnDisableHibernate.Text = "Disabilita Ibernazione"
$btnDisableHibernate.Size = New-Object System.Drawing.Size(130, 40)
$btnDisableHibernate.Location = New-Object System.Drawing.Point(10, 200)
$btnDisableHibernate.Add_Click({
    Start-Process -FilePath "powercfg.exe" -ArgumentList "-h off" -Wait -NoNewWindow
    [System.Windows.Forms.MessageBox]::Show("✅ Ibernazione disabilitata.","Successo",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
})
$sidebar.Controls.Add($btnDisableHibernate)



# === Avvia il form ===
$form.Topmost = $true
[void]$form.ShowDialog()
