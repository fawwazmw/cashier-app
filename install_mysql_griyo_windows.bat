@echo off
title GRIYO POS MySQL Setup for Windows
color 0A

echo.
echo ===============================================
echo    GRIYO POS MySQL Setup for Windows
echo ===============================================
echo.

REM Check if running as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Please run this script as Administrator!
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo ✅ Running as Administrator
echo.

REM Check if MySQL is already installed
mysql --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ MySQL is already installed
    mysql --version
    goto :setup_database
)

echo 🔍 MySQL not found. Starting installation...
echo.

REM Check if MySQL Installer exists
if exist "%TEMP%\mysql-installer-community.msi" (
    echo 📦 MySQL installer found in temp folder
    goto :install_mysql
)

echo 📥 Downloading MySQL Installer...
echo Please wait, this may take a few minutes...

REM Download MySQL Installer using PowerShell
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://dev.mysql.com/get/Downloads/MySQLInstaller/mysql-installer-community-8.0.35.0.msi' -OutFile '%TEMP%\mysql-installer-community.msi'}"

if not exist "%TEMP%\mysql-installer-community.msi" (
    echo ❌ Download failed!
    echo Please download MySQL manually from: https://dev.mysql.com/downloads/installer/
    pause
    exit /b 1
)

:install_mysql
echo 🚀 Starting MySQL installation...
echo.
echo ⚠️  IMPORTANT INSTALLATION NOTES:
echo    1. Choose "Developer Default" setup type
echo    2. Set root password to: griyo123
echo    3. Remember this password!
echo    4. Configure as Windows Service
echo    5. Start MySQL at system startup
echo.
echo Press any key to continue with installation...
pause >nul

start /wait msiexec /i "%TEMP%\mysql-installer-community.msi"

echo.
echo ⏳ Waiting for MySQL installation to complete...
echo Please complete the MySQL installation wizard
echo Set root password to: griyo123
echo.
echo Press any key after installation is complete...
pause >nul

REM Verify MySQL installation
mysql --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ MySQL installation verification failed
    echo Please check if MySQL is properly installed
    echo Try running: mysql -u root -p
    pause
    exit /b 1
)

echo ✅ MySQL installation verified!

:setup_database
echo.
echo 🗄️ Setting up GRIYO POS database...
echo.

REM Check if setup_mysql.sql exists
if not exist "setup_mysql.sql" (
    echo ❌ setup_mysql.sql file not found!
    echo Please make sure you have the database setup file
    echo Download it from the project repository
    pause
    exit /b 1
)

echo 📝 Please enter your MySQL root password:
echo (Should be: griyo123 if you followed the installation guide)
set /p mysql_password=Password: 

echo.
echo 🧪 Testing MySQL connection...

REM Test MySQL connection
mysql -u root -p%mysql_password% -e "SELECT 1" >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ MySQL connection failed!
    echo Please check your password and try again
    echo You can test manually with: mysql -u root -p
    pause
    exit /b 1
)

echo ✅ MySQL connection successful!
echo.

echo 📊 Creating GRIYO POS database...
mysql -u root -p%mysql_password% -e "CREATE DATABASE IF NOT EXISTS griyo_pos;"

echo 📥 Importing database schema and sample data...
mysql -u root -p%mysql_password% griyo_pos < setup_mysql.sql

if %errorlevel% neq 0 (
    echo ❌ Database import failed!
    pause
    exit /b 1
)

echo ✅ Database setup completed!
echo.

echo ⚙️ Creating backend configuration...

REM Create backend directory if it doesn't exist
if not exist "backend" mkdir backend

REM Generate JWT secret
set jwt_secret=griyo_pos_%RANDOM%%RANDOM%_secret_key_%DATE:/=%%TIME::=%

REM Create .env file
echo # GRIYO POS Backend Configuration> backend\.env
echo DB_HOST=localhost>> backend\.env
echo DB_PORT=3306>> backend\.env
echo DB_NAME=griyo_pos>> backend\.env
echo DB_USER=root>> backend\.env
echo DB_PASSWORD=%mysql_password%>> backend\.env
echo.>> backend\.env
echo JWT_SECRET=%jwt_secret%>> backend\.env
echo.>> backend\.env
echo PORT=8000>> backend\.env
echo NODE_ENV=development>> backend\.env
echo.>> backend\.env
echo MIDTRANS_SERVER_KEY=SB-Mid-server-your_sandbox_key>> backend\.env
echo MIDTRANS_CLIENT_KEY=SB-Mid-client-your_sandbox_key>> backend\.env
echo MIDTRANS_IS_PRODUCTION=false>> backend\.env
echo.>> backend\.env
echo APP_NAME=GRIYO POS>> backend\.env
echo APP_URL=http://localhost:8000>> backend\.env

echo ✅ Backend configuration created!
echo.

echo 🧪 Testing database connection...
if exist "test_mysql_connection.js" (
    REM Update test file with correct password
    powershell -Command "(gc test_mysql_connection.js) -replace 'your_mysql_password', '%mysql_password%' | Out-File test_mysql_connection.js -encoding UTF8"
    
    echo Running connection test...
    node test_mysql_connection.js
    
    if %errorlevel% equ 0 (
        echo ✅ Connection test passed!
    ) else (
        echo ⚠️  Connection test had issues, but setup should still work
    )
) else (
    echo ⚠️  Connection test file not found, skipping test
)

echo.
echo 🎉 GRIYO POS MySQL Setup Completed Successfully!
echo ==============================================
echo.
echo 🚀 Next Steps:
echo    1. Open Command Prompt in backend folder
echo    2. Run: npm install
echo    3. Run: npm run dev
echo    4. Backend will be available at: http://localhost:8000
echo.
echo 📱 Flutter Setup:
echo    1. Open Command Prompt in project root
echo    2. Run: flutter pub get
echo    3. Run: flutter run
echo.
echo 🔐 Login Credentials:
echo    Admin: username=admin, password=123456
echo    Kasir: username=kasir, password=123456
echo.
echo 🌐 API Endpoints:
echo    Health Check: http://localhost:8000/health
echo    Documentation: http://localhost:8000/api-docs
echo    Login: POST http://localhost:8000/api/auth/login
echo.
echo 📋 Database Info:
echo    Database: griyo_pos
echo    Host: localhost:3306
echo    Username: root
echo    Password: %mysql_password%
echo.
echo 💡 Troubleshooting:
echo    - If backend fails to start, check .env file
echo    - If database connection fails, verify MySQL is running
echo    - Check MySQL service in Services.msc
echo.
echo Happy coding! 💻✨
echo.
pause