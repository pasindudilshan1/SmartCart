@echo off
REM SmartCart Flutter Setup Script for Windows
REM This script adds Flutter to PATH and runs common commands

echo ========================================
echo SmartCart Flutter Helper Script
echo ========================================
echo.

REM Add Flutter to PATH for this session
set PATH=%PATH%;C:\develop\flutter\flutter\bin

REM Check what command to run
if "%1"=="" goto menu
if "%1"=="run" goto run
if "%1"=="get" goto get
if "%1"=="build" goto build_adapters
if "%1"=="clean" goto clean
if "%1"=="doctor" goto doctor
if "%1"=="analyze" goto analyze
if "%1"=="release" goto release
goto menu

:menu
echo Available commands:
echo   setup.bat run        - Run the app
echo   setup.bat get        - Get dependencies
echo   setup.bat build      - Generate Hive adapters
echo   setup.bat clean      - Clean project
echo   setup.bat doctor     - Check Flutter setup
echo   setup.bat analyze    - Analyze code
echo   setup.bat release    - Build release APK
echo.
echo Or just run: setup.bat
echo to add Flutter to PATH for this session
echo.
goto end

:run
echo Running SmartCart...
flutter run
goto end

:get
echo Getting dependencies...
flutter pub get
goto end

:build_adapters
echo Generating Hive adapters...
flutter pub run build_runner build --delete-conflicting-outputs
goto end

:clean
echo Cleaning project...
flutter clean
flutter pub get
goto end

:doctor
echo Checking Flutter installation...
flutter doctor -v
goto end

:analyze
echo Analyzing code...
flutter analyze
goto end

:release
echo Building release APK...
flutter build apk --release
echo.
echo APK location: build\app\outputs\flutter-apk\app-release.apk
goto end

:end
echo.
echo ========================================
echo Done!
echo ========================================
