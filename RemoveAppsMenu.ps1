# ============================================
# RemoveAppsMenu.ps1 - Menu de Debloat Windows
# ============================================

# Lista de apps
$apps = @{
    1  = @{ Name = "3D Viewer"; Package = "Microsoft.Microsoft3DViewer" };
    2  = @{ Name = "Copilot"; Package = "Microsoft.Copilot" };
    3  = @{ Name = "Cortana"; Package = "Microsoft.549981C3F5F10" };
    4  = @{ Name = "InternetExplorer"; Package = "Browser.InternetExplorer" };
    5  = @{ Name = "Microsoft Family"; Package = "Microsoft.WindowsFamily" };
    6  = @{ Name = "Get Help (Obter Ajuda)"; Package = "Microsoft.GetHelp" };
    7  = @{ Name = "Bing News"; Package = "Microsoft.BingNews" };
    8  = @{ Name = "OneDrive"; Package = "OneDrive" };
    9  = @{ Name = "Paint 3D"; Package = "Microsoft.MSPaint" };
    10 = @{ Name = "Quick Assist"; Package = "Microsoft.QuickAssist" };
    11 = @{ Name = "Mixed Reality Portal"; Package = "Microsoft.MixedReality.Portal" };
    12 = @{ Name = "Power Automate Desktop"; Package = "Microsoft.PowerAutomateDesktop" };
    13 = @{ Name = "Windows Fax and Scan"; Package = "Print.Fax.Scan" };
    14 = @{ Name = "Clipchamp"; Package = "Microsoft.Clipchamp" };
    15 = @{ Name = "OneNote (UWP)"; Package = "Microsoft.Office.OneNote" };
    16 = @{ Name = "Outlook for Windows"; Package = "Microsoft.OutlookForWindows" };
    17 = @{ Name = "People"; Package = "Microsoft.People" };
    18 = @{ Name = "Bing Weather (Clima)"; Package = "Microsoft.BingWeather" };
    19 = @{ Name = "OpenSSH Client"; Package = "OpenSSH.Client" };
    20 = @{ Name = "Office 365"; Package = "Microsoft.MicrosoftOfficeHub" };
    21 = @{ Name = "OneSync"; Package = "OneCoreUAP.OneSync" };
    22 = @{ Name = "Solitarie Collection"; Package = "Microsoft.MicrosoftSolitarieCollection" };
    23 = @{ Name = "Notas Auto-Adesivas"; Package = "Microsoft.MicrosoftStickyNotes" };
    24 = @{ Name = "Bing Search"; Package = "Microsoft.BingSearch" };
    25 = @{ Name = "Skype"; Package = "Microsoft.SkypeApp" };
    26 = @{ Name = "Your Phone"; Package = "Microsoft.YourPhone" };
    27 = @{ Name = "Dev Home"; Package = "Microsoft.Windows.DevHome" };
    28 = @{ Name = "Mapas"; Package = "Microsoft.WindowsMaps" };
    29 = @{ Name = "Recall"; Package = "Recall" };
    30 = @{ Name = "Tips"; Package = "Microsoft.Getstarted" };
    31 = @{ Name = "Wallet"; Package = "Microsoft.Wallet" };

    99 = @{ Name = "Sair"; Package = "" }
}

# Função para verificar se um app está instalado
function Get-AppStatus {
    param([string]$packageName)

    # Caso especial: OneDrive
    if ($packageName -eq "OneDrive") {
        $paths = @(
            "$env:SystemRoot\System32\OneDriveSetup.exe",
            "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
        )
        foreach ($p in $paths) {
            if (Test-Path $p) { return "INSTALADO" }
        }
        return "NAO INSTALADO"
    }

    # Caso especial: Fax and Scan (Feature Windows)
    if ($packageName -eq "FaxScan") {
        $feature = (dism /online /Get-Features /Format:Table | Select-String "FaxServicesClientPackage").ToString()
        if ($feature -like "*Enabled*") { return "INSTALADO" }
        else { return "NAO INSTALADO" }
    }

    # Appx normal
    $installed = Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq $packageName }
    $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $packageName }

    if ($installed -or $prov) { return "INSTALADO" }
    else { return "NAO INSTALADO" }
}

# Função para remover o app
function Remove-CustomApp {
    param([string]$packageName)

    Write-Host "`nRemovendo: $packageName ..." -ForegroundColor Yellow

    if ($packageName -eq "OneDrive") {
        Write-Host "Removendo OneDrive..." -ForegroundColor Cyan
        Start-Process "C:\Windows\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue
        Start-Process "C:\Windows\SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue
        return
    }

    if ($packageName -eq "FaxScan") {
        Write-Host "Removendo Windows Fax and Scan via DISM..." -ForegroundColor Cyan
        dism /online /Disable-Feature /FeatureName:FaxServicesClientPackage /NoRestart
        return
    }

    Get-AppxProvisionedPackage -Online |
        Where-Object { $_.DisplayName -eq $packageName } |
        Remove-AppxProvisionedPackage -Online -AllUsers -ErrorAction SilentlyContinue

    Get-AppxPackage -AllUsers |
        Where-Object { $_.Name -eq $packageName } |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

    Write-Host "Debloat Concluido!" -ForegroundColor Green
}

# ============================
# MENU
# ============================
while ($true) {
    Clear-Host
    Write-Host "=== Debloat Windows Apps ===`n" -ForegroundColor Cyan

    foreach ($key in $apps.Keys) {

        # Não mostrar status no item 99
        if ($key -eq 99) {
            Write-Host ("{0} - {1}" -f $key, $apps[$key].Name) -ForegroundColor Yellow
            continue
        }

        $pkg = $apps[$key].Package
        $status = Get-AppStatus -packageName $pkg

        if ($status -eq "INSTALADO") {
            $statusText = "[INSTALADO]"
            $color = "Green"
        }
        else {
            $statusText = "[NAO INSTALADO]"
            $color = "Red"
        }

        Write-Host ("{0} - {1} " -f $key, $apps[$key].Name) -NoNewline
        Write-Host $statusText -ForegroundColor $color
    }

    $choice = Read-Host "`nDigite o numero do app que deseja remover"

    if ($apps.ContainsKey([int]$choice)) {

        if ($choice -eq 99) {
            Write-Host "`nSaindo..." -ForegroundColor Cyan
            break
        }

        $pkg = $apps[[int]$choice].Package
        Remove-CustomApp -packageName $pkg
        Pause
    }
    else {
        Write-Host "`nOpcao invalida!" -ForegroundColor Red
        Pause
    }
}

Write-Host "`nPressione qualquer tecla para finalizar o programa..."
[void][System.Console]::ReadKey($true)
