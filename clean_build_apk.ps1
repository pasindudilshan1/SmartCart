# PowerShell script for clean build of SmartCart APK
# This ensures you always get the latest version without cache issues

Write-Host "CLEAN BUILD - Removing ALL cached files..." -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Flutter Clean
Write-Host "Step 1: Running flutter clean..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter clean failed!" -ForegroundColor Red
    exit 1
}
Write-Host "   Flutter clean complete" -ForegroundColor Green
Write-Host ""

# Step 2: Delete build folders manually
Write-Host "Step 2: Deleting build directories..." -ForegroundColor Yellow
$foldersToDelete = @(
    "build",
    ".dart_tool",
    "android\.gradle",
    "android\app\build",
    "android\build"
)

foreach ($folder in $foldersToDelete) {
    if (Test-Path $folder) {
        Write-Host "   Removing $folder..." -ForegroundColor Gray
        Remove-Item -Recurse -Force $folder -ErrorAction SilentlyContinue
    }
}
Write-Host "   Build directories deleted" -ForegroundColor Green
Write-Host ""

# Step 3: Get dependencies
Write-Host "Step 3: Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Pub get failed!" -ForegroundColor Red
    exit 1
}
Write-Host "   Dependencies installed" -ForegroundColor Green
Write-Host ""

# Step 4: Generate Hive adapters
Write-Host "Step 4: Generating Hive adapters..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Build runner had warnings (this is usually OK)" -ForegroundColor Yellow
}
Write-Host "   Code generation complete" -ForegroundColor Green
Write-Host ""

# Step 5: Increment version (optional)
Write-Host "Step 5: Version info..." -ForegroundColor Yellow
$pubspecContent = Get-Content "pubspec.yaml" -Raw
if ($pubspecContent -match 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
    $version = $matches[1]
    $buildNumber = [int]$matches[2]
    Write-Host "   Current version: $version+$buildNumber" -ForegroundColor Cyan
    
    # Ask if user wants to increment build number
    $response = Read-Host "   Increment build number? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        $newBuildNumber = $buildNumber + 1
        $pubspecContent = $pubspecContent -replace "version:\s*\d+\.\d+\.\d+\+\d+", "version: $version+$newBuildNumber"
        Set-Content -Path "pubspec.yaml" -Value $pubspecContent
        Write-Host "   Version updated to: $version+$newBuildNumber" -ForegroundColor Green
    }
}
Write-Host ""

# Step 6: Build APK
Write-Host "Step 6: Building release APK..." -ForegroundColor Yellow
Write-Host "   This may take a few minutes..." -ForegroundColor Gray
Write-Host ""

flutter build apk --release

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "CLEAN BUILD SUCCESSFUL!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

# Get APK file info
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    $apkSize = (Get-Item $apkPath).Length / 1MB
    Write-Host "APK Location:" -ForegroundColor Cyan
    Write-Host "   $apkPath" -ForegroundColor White
    Write-Host ""
    Write-Host "APK Size: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Installation Commands:" -ForegroundColor Yellow
    Write-Host "   Install to connected device:" -ForegroundColor Gray
    Write-Host "   adb install -r $apkPath" -ForegroundColor White
    Write-Host ""
    Write-Host "   Uninstall old version first (recommended):" -ForegroundColor Gray
    Write-Host "   adb uninstall com.SmartCart" -ForegroundColor White
    Write-Host "   adb install $apkPath" -ForegroundColor White
    Write-Host ""
}

# Ask if user wants to install
$response = Read-Host "Install APK to connected device now? (y/n)"
if ($response -eq 'y' -or $response -eq 'Y') {
    Write-Host ""
    Write-Host "Checking for connected devices..." -ForegroundColor Yellow
    adb devices
    Write-Host ""
    
    $uninstall = Read-Host "Uninstall old version first? (recommended - y/n)"
    if ($uninstall -eq 'y' -or $uninstall -eq 'Y') {
        Write-Host "   Uninstalling old version..." -ForegroundColor Yellow
        adb uninstall com.SmartCart
    }
    
    Write-Host "   Installing new APK..." -ForegroundColor Yellow
    adb install -r $apkPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Installation successful!" -ForegroundColor Green
        Write-Host "You can now launch the app on your device" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "Installation failed. Make sure USB debugging is enabled." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
