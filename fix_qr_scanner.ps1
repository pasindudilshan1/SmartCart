# Fix qr_code_scanner plugin namespace issue
$buildGradlePath = "C:\Users\USER\AppData\Local\Pub\Cache\hosted\pub.dev\qr_code_scanner-1.0.1\android\build.gradle"

if (Test-Path $buildGradlePath) {
    Write-Host "Reading build.gradle file..."
    $content = Get-Content $buildGradlePath -Raw
    
    # Check if namespace is already present
    if ($content -match 'namespace') {
        Write-Host "Namespace already exists in build.gradle"
    } else {
        Write-Host "Adding namespace to build.gradle..."
        
        # Add namespace after 'android {' line
        $content = $content -replace '(android\s*\{)', "`$1`n    namespace 'net.touchcapture.qr.flutterqr'"
        
        # Write back to file
        Set-Content -Path $buildGradlePath -Value $content
        Write-Host "Successfully added namespace to qr_code_scanner build.gradle"
    }
} else {
    Write-Host "Error: build.gradle file not found at $buildGradlePath"
    Write-Host "Please make sure the qr_code_scanner package is installed"
}
