# PowerShell script for building SmartCart for Play Store
# This script reads Azure credentials from a secure location (not in git)

Write-Host "🔨 Building SmartCart for Google Play Store..." -ForegroundColor Green
Write-Host ""

# Check if Azure key file exists
$KeyFile = "$env:USERPROFILE\.smartcart\azure_key.txt"

if (-not (Test-Path $KeyFile)) {
    Write-Host "❌ Error: Azure key file not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please create it first:"
    Write-Host "  New-Item -ItemType Directory -Force -Path $env:USERPROFILE\.smartcart"
    Write-Host "  Set-Content -Path $env:USERPROFILE\.smartcart\azure_key.txt -Value 'YOUR_AZURE_KEY'"
    Write-Host ""
    exit 1
}

# Read Azure credentials from secure file
$AzureAccountName = "documentstoragepasindu"
$AzureKey = Get-Content $KeyFile -Raw
$AzureKey = $AzureKey.Trim()  # Remove whitespace

Write-Host "✅ Azure credentials loaded" -ForegroundColor Green
Write-Host "📦 Account: $AzureAccountName"
Write-Host ""

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
flutter pub get

Write-Host ""
Write-Host "🏗️  Building release AAB..." -ForegroundColor Cyan
Write-Host ""

# Build release AAB with environment variables
flutter build appbundle `
  --release `
  --dart-define=AZURE_ACCOUNT_NAME="$AzureAccountName" `
  --dart-define=AZURE_ACCOUNT_KEY="$AzureKey"

Write-Host ""
Write-Host "✅ Build complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📦 Your app bundle is ready:" -ForegroundColor Cyan
Write-Host "   build\app\outputs\bundle\release\app-release.aab"
Write-Host ""
Write-Host "🚀 Upload this file to Google Play Console" -ForegroundColor Yellow
Write-Host ""
