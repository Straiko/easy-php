# Автоматическая установка PHP для Windows
# Этот скрипт скачивает и устанавливает PHP автоматически

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PHP Automatic Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$phpDir = "C:\php"
$phpExe = "$phpDir\php.exe"

# Check if already installed
if (Test-Path $phpExe) {
    Write-Host "[OK] PHP already installed" -ForegroundColor Green
    & $phpExe -v
    exit 0
}

Write-Host "[*] PHP not found. Starting installation..." -ForegroundColor Yellow
Write-Host ""

# Create folder
Write-Host "[*] Creating folder C:\php..." -ForegroundColor Yellow
try {
    if (-not (Test-Path $phpDir)) {
        New-Item -ItemType Directory -Path $phpDir -Force | Out-Null
    }
    Write-Host "[OK] Folder created" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Cannot create folder: $_" -ForegroundColor Red
    Write-Host "[INFO] Run PowerShell as Administrator" -ForegroundColor Yellow
    exit 1
}

# Download PHP - using working archive URLs
Write-Host "[*] Downloading PHP..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Gray

$urls = @(
    # Archive URLs that are known to work
    "https://windows.php.net/downloads/releases/archives/php-8.3.12-Win32-vs16-x64.zip",
    "https://windows.php.net/downloads/releases/archives/php-8.3.11-Win32-vs16-x64.zip",
    "https://windows.php.net/downloads/releases/archives/php-8.3.10-Win32-vs16-x64.zip",
    "https://windows.php.net/downloads/releases/archives/php-8.2.20-Win32-vs16-x64.zip",
    "https://windows.php.net/downloads/releases/archives/php-8.2.19-Win32-vs16-x64.zip",
    "https://windows.php.net/downloads/releases/archives/php-8.1.30-Win32-vs16-x64.zip",
    "https://windows.php.net/downloads/releases/archives/php-8.1.29-Win32-vs16-x64.zip"
)

$zip = "$env:TEMP\php.zip"
$downloaded = $false

foreach ($url in $urls) {
    try {
        Write-Host "  Trying: $url" -ForegroundColor Gray
        $ProgressPreference = 'SilentlyContinue'
        $response = Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing -ErrorAction Stop -TimeoutSec 60
        
        # Check if file was downloaded (size > 0)
        if (Test-Path $zip) {
            $fileInfo = Get-Item $zip
            if ($fileInfo.Length -gt 1000000) { # At least 1MB
                $downloaded = $true
                Write-Host "[OK] Download complete ($([math]::Round($fileInfo.Length/1MB, 2)) MB)" -ForegroundColor Green
                break
            } else {
                Write-Host "  File too small, trying next..." -ForegroundColor Yellow
                Remove-Item $zip -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {
        Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Yellow
        if (Test-Path $zip) {
            Remove-Item $zip -Force -ErrorAction SilentlyContinue
        }
        continue
    }
}

if (-not $downloaded) {
    Write-Host ""
    Write-Host "[ERROR] Failed to download PHP from all URLs" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please try one of these options:" -ForegroundColor Yellow
    Write-Host "1. Download manually from: https://windows.php.net/download/" -ForegroundColor White
    Write-Host "   - Choose PHP 8.3 Thread Safe x64 ZIP" -ForegroundColor White
    Write-Host "   - Extract to C:\php" -ForegroundColor White
    Write-Host "   - Run this script again to configure" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Or use Chocolatey (if installed):" -ForegroundColor White
    Write-Host "   choco install php" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Or use winget (Windows 10/11):" -ForegroundColor White
    Write-Host "   winget install PHP.PHP" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Extract
Write-Host "[*] Extracting PHP..." -ForegroundColor Yellow
try {
    Expand-Archive -Path $zip -DestinationPath $phpDir -Force
    Remove-Item $zip -Force
    Write-Host "[OK] Extraction complete" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Extraction failed: $_" -ForegroundColor Red
    exit 1
}

# Configure php.ini
Write-Host "[*] Configuring php.ini..." -ForegroundColor Yellow
$iniDev = "$phpDir\php.ini-development"
$ini = "$phpDir\php.ini"

if (Test-Path $iniDev) {
    if (-not (Test-Path $ini)) {
        Copy-Item $iniDev $ini
    }
    
    $content = Get-Content $ini -Raw -Encoding UTF8
    
    # Enable extensions
    $content = $content -replace ";extension=curl", "extension=curl"
    $content = $content -replace ";extension=mbstring", "extension=mbstring"
    $content = $content -replace ";extension=openssl", "extension=openssl"
    $content = $content -replace ";extension=mysqli", "extension=mysqli"
    $content = $content -replace ";extension=pdo_mysql", "extension=pdo_mysql"
    
    # Development settings
    $content = $content -replace "display_errors\s*=\s*Off", "display_errors = On"
    $content = $content -replace "display_startup_errors\s*=\s*Off", "display_startup_errors = On"
    $content = $content -replace "error_reporting\s*=\s*.*", "error_reporting = E_ALL"
    
    [System.IO.File]::WriteAllText($ini, $content, [System.Text.Encoding]::UTF8)
    Write-Host "[OK] php.ini configured" -ForegroundColor Green
}

# Configure PATH
Write-Host "[*] Configuring PATH..." -ForegroundColor Yellow
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$phpDir*") {
    try {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$phpDir", "User")
        Write-Host "[OK] PATH updated" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Cannot update PATH (admin rights needed)" -ForegroundColor Yellow
    }
}
$env:Path += ";$phpDir"

# Create folders
New-Item -ItemType Directory -Path "$phpDir\logs" -Force | Out-Null
New-Item -ItemType Directory -Path "$phpDir\tmp" -Force | Out-Null

# Verify
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (Test-Path $phpExe) {
    & $phpExe -v
    Write-Host ""
    Write-Host "[SUCCESS] PHP installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANT: Restart terminal" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To run project:" -ForegroundColor Cyan
    Write-Host "  cd C:\Users\starikov\php-project" -ForegroundColor White
    Write-Host "  php -S localhost:8000" -ForegroundColor White
} else {
    Write-Host "[ERROR] PHP not found after installation" -ForegroundColor Red
    exit 1
}

