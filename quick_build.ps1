# Quick Build Script - Uninstall old version and install new one
# Use this for faster rebuilds during development

param(
    [switch]$Clean = $false
)

$PackageName = "com.SmartCart"
$ApkPath = "build\app\outputs\flutter-apk\app-release.apk"

Write-Host "SmartCart Quick Build & Install" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

if ($Clean) {
    Write-Host "Cleaning..." -ForegroundColor Yellow
    flutter clean
    flutter pub get
    Write-Host ""
}

Write-Host "Building APK..." -ForegroundColor Yellow
flutter build apk --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Build complete!" -ForegroundColor Green
Write-Host ""

# Check for connected devices
Write-Host "Checking devices..." -ForegroundColor Yellow
$devices = adb devices
Write-Host $devices
Write-Host ""

if ($devices -match "device$") {
    Write-Host "Uninstalling old version..." -ForegroundColor Yellow
    adb uninstall $PackageName 2>$null
    
    Write-Host "Installing new APK..." -ForegroundColor Yellow
    adb install $ApkPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Installation complete!" -ForegroundColor Green
        Write-Host "Launch SmartCart on your device" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "Installation failed!" -ForegroundColor Red
    }
} else {
    Write-Host "No device connected" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "APK built at: $ApkPath" -ForegroundColor Cyan
    Write-Host "Connect device and run: adb install $ApkPath" -ForegroundColor Gray
}

Write-Host ""
