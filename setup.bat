@echo off
echo ============================================
echo   LINKY APP - Full Setup Script
echo ============================================
echo.

:: Check prerequisites
echo [1/10] Checking prerequisites...
where flutter >nul 2>&1 || (echo ERROR: Flutter not found. Install from flutter.dev && exit /b 1)
where firebase >nul 2>&1 || (echo ERROR: Firebase CLI not found. Run: npm install -g firebase-tools && exit /b 1)
where wrangler >nul 2>&1 || (echo ERROR: Wrangler not found. Run: npm install -g wrangler && exit /b 1)
echo All prerequisites found!
echo.

:: Step 1: Firebase Login
echo [2/10] Firebase Login...
echo Opening browser for Firebase login...
firebase login
if %errorlevel% neq 0 (
    echo ERROR: Firebase login failed
    exit /b 1
)
echo.

:: Step 2: FlutterFire Configure
echo [3/10] Configuring FlutterFire (creates firebase_options.dart)...
cd /d "%~dp0"
flutterfire configure
if %errorlevel% neq 0 (
    echo ERROR: FlutterFire configure failed
    echo Make sure you selected: Create a new Firebase project ^> linky-app
    exit /b 1
)
echo.

:: Step 3: Flutter packages
echo [4/10] Installing Flutter packages...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: flutter pub get failed
    exit /b 1
)
echo.

:: Step 4: Cloudflare Login
echo [5/10] Cloudflare Login...
echo Opening browser for Cloudflare login...
wrangler login
if %errorlevel% neq 0 (
    echo ERROR: Wrangler login failed
    exit /b 1
)
echo.

:: Step 5: Create D1 Database
echo [6/10] Creating D1 Database...
cd /d "%~dp0backend"
wrangler d1 create linky-db
echo.
echo IMPORTANT: Copy the database_id from above and paste it in wrangler.toml
echo Press any key when done...
pause >nul
echo.

:: Step 6: Create R2 Bucket
echo [7/10] Creating R2 Bucket...
wrangler r2 bucket create linky-images
echo.

:: Step 7: Create KV Namespace
echo [8/10] Creating KV Namespace...
wrangler kv namespace create CACHE
echo.
echo IMPORTANT: Copy the id from above and paste it in wrangler.toml (replace YOUR_KV_NAMESPACE_ID)
echo Press any key when done...
pause >nul
echo.

:: Step 8: Apply Database Schema
echo [9/10] Applying Database Schema...
wrangler d1 migrations apply linky-db
if %errorlevel% neq 0 (
    echo ERROR: Migration failed. Make sure D1 database_id is set in wrangler.toml
    exit /b 1
)
echo.

:: Step 9: Deploy Backend
echo [10/10] Deploying Cloudflare Worker...
wrangler deploy
if %errorlevel% neq 0 (
    echo ERROR: Deploy failed
    exit /b 1
)
echo.
echo IMPORTANT: Copy the worker URL from above (looks like: linky-api.XXXX.workers.dev)
echo Then update lib/core/config/app_config.dart with your real API URL
echo.

:: Done
echo ============================================
echo   SETUP COMPLETE!
echo ============================================
echo.
echo Next steps:
echo  1. Open lib/firebase_options.dart - should be auto-filled by flutterfire
echo  2. Update lib/core/config/app_config.dart with your API URL
echo  3. Update backend/wrangler.toml with D1 and KV IDs
echo  4. Run: flutter run
echo.
cd /d "%~dp0"
flutter run
