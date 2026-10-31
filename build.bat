@echo off
cd /d "%~dp0"
if not exist out mkdir out
java -jar tools\apktool.jar b apktool-project -o out\RealPing-V22-unsigned.apk
if errorlevel 1 exit /b 1
echo Build complete. Align and sign the unsigned APK before installing.
