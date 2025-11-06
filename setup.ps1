# SmartCart Flutter Setup Script for PowerShell
# This script adds Flutter to PATH and runs common commands

param(
    [string]$Command = "menu"
)

# Add Flutter to PATH for this session
$env:Path += ";C:\develop\flutter\flutter\bin"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SmartCart Flutter Helper Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

switch ($Command) {
    "run" {
        Write-Host "Running SmartCart..." -ForegroundColor Green
        flutter run
    }
    "get" {
        Write-Host "Getting dependencies..." -ForegroundColor Green
        flutter pub get
    }
    "build" {
        Write-Host "Generating Hive adapters..." -ForegroundColor Green
        flutter pub run build_runner build --delete-conflicting-outputs
    }
    "clean" {
        Write-Host "Cleaning project..." -ForegroundColor Green
        flutter clean
        flutter pub get
    }
    "doctor" {
        Write-Host "Checking Flutter installation..." -ForegroundColor Green
        flutter doctor -v
    }
    "analyze" {
        Write-Host "Analyzing code..." -ForegroundColor Green
        flutter analyze
    }
    "release" {
        Write-Host "Building release APK..." -ForegroundColor Green
        flutter build apk --release
        Write-Host ""
        Write-Host "APK location: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Yellow
    }
    "devices" {
        Write-Host "Checking connected devices..." -ForegroundColor Green
        flutter devices
    }
    default {
        Write-Host "Available commands:" -ForegroundColor Yellow
        Write-Host "  .\setup.ps1 run        - Run the app" -ForegroundColor White
        Write-Host "  .\setup.ps1 get        - Get dependencies" -ForegroundColor White
        Write-Host "  .\setup.ps1 build      - Generate Hive adapters" -ForegroundColor White
        Write-Host "  .\setup.ps1 clean      - Clean project" -ForegroundColor White
        Write-Host "  .\setup.ps1 doctor     - Check Flutter setup" -ForegroundColor White
        Write-Host "  .\setup.ps1 analyze    - Analyze code" -ForegroundColor White
        Write-Host "  .\setup.ps1 release    - Build release APK" -ForegroundColor White
        Write-Host "  .\setup.ps1 devices    - Check connected devices" -ForegroundColor White
        Write-Host ""
        Write-Host "Example: .\setup.ps1 run" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Done!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
