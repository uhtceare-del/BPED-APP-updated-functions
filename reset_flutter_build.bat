@echo off
REM ===============================
REM Flutter + Kotlin + Gradle Full Reset Script
REM With Safe Re-enabling of Incremental Compilation
REM ===============================

echo ========================================
echo 1. Closing any flutter/gradle processes...
echo ========================================
taskkill /F /IM java.exe >nul 2>&1
taskkill /F /IM gradle.exe >nul 2>&1

echo ========================================
echo 2. Cleaning Flutter build files...
echo ========================================
flutter clean

echo ========================================
echo 3. Repairing Flutter pub cache...
echo ========================================
flutter pub cache repair

echo ========================================
echo 4. Deleting Gradle & Kotlin caches...
echo ========================================
rmdir /s /q "%USERPROFILE%\.gradle\caches"
rmdir /s /q "%USERPROFILE%\.gradle\daemon"
rmdir /s /q "%USERPROFILE%\AppData\Local\Temp\kotlin-*"

echo ========================================
echo 5. Setting consistent PUB_CACHE...
echo ========================================
setx PUB_CACHE "%USERPROFILE%\AppData\Local\Pub\Cache"

echo ========================================
echo 6. Temporarily disabling Kotlin incremental compilation...
echo ========================================
if not exist android\gradle.properties echo. > android\gradle.properties
findstr /v "kotlin.incremental=" android\gradle.properties > temp_gradle.properties
move /Y temp_gradle.properties android\gradle.properties
echo kotlin.incremental=false >> android\gradle.properties
echo org.gradle.daemon=true >> android\gradle.properties
echo org.gradle.jvmargs=-Xmx2048m >> android\gradle.properties

echo ========================================
echo 7. Fetching dependencies...
echo ========================================
flutter pub get

echo ========================================
echo 8. Building APK...
echo ========================================
flutter build apk

echo ========================================
echo 9. Re-enabling Kotlin incremental compilation...
echo ========================================
findstr /v "kotlin.incremental=" android\gradle.properties > temp_gradle.properties
move /Y temp_gradle.properties android\gradle.properties
echo kotlin.incremental=true >> android\gradle.properties

echo ========================================
echo RESET AND REBUILD COMPLETE
echo Kotlin incremental compilation re-enabled
echo ========================================
pause