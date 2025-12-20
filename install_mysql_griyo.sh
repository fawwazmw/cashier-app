#!/bin/bash

# GRIYO POS MySQL Auto Installer Script
# Supports: macOS, Linux Ubuntu/Debian
# For Windows, please use manual installation guide

echo "🚀 GRIYO POS MySQL Auto Installer"
echo "=================================="
echo ""

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN"
esac

echo "🔍 Detected OS: $MACHINE"

# Check if MySQL is already installed
if command -v mysql &> /dev/null; then
    echo "✅ MySQL is already installed"
    mysql --version
    
    echo ""
    echo "🔧 Would you like to setup GRIYO POS database? (y/n)"
    read -r setup_db
    
    if [[ $setup_db == "y" || $setup_db == "Y" ]]; then
        echo "📝 Please enter your MySQL root password:"
        read -s mysql_password
        
        echo ""
        echo "🗄️ Setting up GRIYO POS database..."
        
        # Test connection
        mysql -u root -p"$mysql_password" -e "SELECT 1" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✅ MySQL connection successful"
            
            # Create database and import schema
            echo "📊 Creating database..."
            mysql -u root -p"$mysql_password" -e "CREATE DATABASE IF NOT EXISTS griyo_pos;"
            
            if [ -f "setup_mysql.sql" ]; then
                echo "📥 Importing database schema..."
                mysql -u root -p"$mysql_password" griyo_pos < setup_mysql.sql
                echo "✅ Database setup completed!"
            else
                echo "❌ setup_mysql.sql file not found"
                echo "Please download it from the project repository"
                exit 1
            fi
            
            # Create .env file
            echo "⚙️ Creating backend .env configuration..."
            cat > backend/.env << EOF
# GRIYO POS Backend Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=griyo_pos
DB_USER=root
DB_PASSWORD=$mysql_password

JWT_SECRET=griyo_pos_$(date +%s)_$(openssl rand -hex 16)

PORT=8000
NODE_ENV=development

MIDTRANS_SERVER_KEY=SB-Mid-server-your_sandbox_key
MIDTRANS_CLIENT_KEY=SB-Mid-client-your_sandbox_key
MIDTRANS_IS_PRODUCTION=false

APP_NAME=GRIYO POS
APP_URL=http://localhost:8000
EOF
            echo "✅ Backend configuration created"
            
            echo ""
            echo "🎉 GRIYO POS MySQL setup completed!"
            echo "🚀 Next steps:"
            echo "   1. cd backend"
            echo "   2. npm install"
            echo "   3. npm run dev"
            echo ""
            echo "🔐 Login credentials:"
            echo "   Admin: username=admin, password=123456"
            echo "   Kasir: username=kasir, password=123456"
            
        else
            echo "❌ MySQL connection failed"
            echo "Please check your root password"
            exit 1
        fi
    fi
    
    exit 0
fi

# Install MySQL based on OS
case $MACHINE in
    Mac)
        echo "🍎 Installing MySQL on macOS..."
        
        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            echo "📦 Installing Homebrew first..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        echo "📥 Installing MySQL via Homebrew..."
        brew install mysql
        
        echo "🔄 Starting MySQL service..."
        brew services start mysql
        
        echo "🔐 Setting up MySQL security..."
        echo "Please set root password to: griyo123"
        mysql_secure_installation
        ;;
        
    Linux)
        echo "🐧 Installing MySQL on Linux..."
        
        # Detect Linux distribution
        if [ -f /etc/debian_version ]; then
            # Ubuntu/Debian
            echo "📦 Installing MySQL on Ubuntu/Debian..."
            sudo apt update
            sudo apt install -y mysql-server
            
            echo "🔄 Starting MySQL service..."
            sudo systemctl start mysql
            sudo systemctl enable mysql
            
            echo "🔐 Setting up MySQL security..."
            echo "Please set root password to: griyo123"
            sudo mysql_secure_installation
            
        elif [ -f /etc/redhat-release ]; then
            # CentOS/RHEL/Rocky
            echo "📦 Installing MySQL on CentOS/RHEL..."
            sudo dnf install -y mysql-server
            
            echo "🔄 Starting MySQL service..."
            sudo systemctl start mysqld
            sudo systemctl enable mysqld
            
            echo "🔐 Getting temporary password..."
            temp_pass=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
            echo "Temporary password: $temp_pass"
            echo "Please set root password to: griyo123"
            mysql_secure_installation
            
        else
            echo "❌ Unsupported Linux distribution"
            echo "Please install MySQL manually"
            exit 1
        fi
        ;;
        
    *)
        echo "❌ Unsupported operating system: $OS"
        echo "Please use manual installation guide"
        exit 1
        ;;
esac

echo ""
echo "✅ MySQL installation completed!"
echo ""
echo "🔧 Now setting up GRIYO POS database..."
echo "📝 Please enter your MySQL root password (should be: griyo123):"
read -s mysql_password

# Create database and setup
mysql -u root -p"$mysql_password" -e "CREATE DATABASE IF NOT EXISTS griyo_pos;"

if [ -f "setup_mysql.sql" ]; then
    mysql -u root -p"$mysql_password" griyo_pos < setup_mysql.sql
    echo "✅ Database setup completed!"
else
    echo "❌ setup_mysql.sql file not found"
    echo "Please download it from the project repository"
    exit 1
fi

# Create backend directory if it doesn't exist
mkdir -p backend

# Create .env file
cat > backend/.env << EOF
# GRIYO POS Backend Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=griyo_pos
DB_USER=root
DB_PASSWORD=$mysql_password

JWT_SECRET=griyo_pos_$(date +%s)_$(openssl rand -hex 16)

PORT=8000
NODE_ENV=development

MIDTRANS_SERVER_KEY=SB-Mid-server-your_sandbox_key
MIDTRANS_CLIENT_KEY=SB-Mid-client-your_sandbox_key
MIDTRANS_IS_PRODUCTION=false

APP_NAME=GRIYO POS
APP_URL=http://localhost:8000
EOF

echo ""
echo "🎉 GRIYO POS Complete Setup Finished!"
echo "====================================="
echo ""
echo "🚀 Next steps:"
echo "   1. cd backend"
echo "   2. npm install"
echo "   3. npm run dev"
echo ""
echo "📱 Flutter setup:"
echo "   1. flutter pub get"
echo "   2. flutter run"
echo ""
echo "🔐 Login credentials:"
echo "   Admin: username=admin, password=123456"
echo "   Kasir: username=kasir, password=123456"
echo ""
echo "🌐 API URLs:"
echo "   Backend: http://localhost:8000"
echo "   Health: http://localhost:8000/health"
echo "   Docs: http://localhost:8000/api-docs"
echo ""
echo "Happy coding! 💻✨"