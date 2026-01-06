#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🚀 LAUNDRY POS Backend Setup\n');

// Check if Node.js version is compatible
const nodeVersion = process.version;
const majorVersion = parseInt(nodeVersion.slice(1).split('.')[0]);

if (majorVersion < 16) {
    console.error('❌ Node.js version 16 or higher is required');
    console.error(`   Current version: ${nodeVersion}`);
    process.exit(1);
}

console.log(`✅ Node.js version: ${nodeVersion}`);

// Check if .env exists
if (!fs.existsSync('.env')) {
    console.log('📝 Creating .env file...');
    
    if (fs.existsSync('.env.example')) {
        fs.copyFileSync('.env.example', '.env');
        console.log('✅ .env file created from .env.example');
        console.log('⚠️  Please edit .env file with your database and MIDTRANS credentials');
    } else {
        console.error('❌ .env.example not found');
        process.exit(1);
    }
} else {
    console.log('✅ .env file exists');
}

// Install dependencies
console.log('\n📦 Installing dependencies...');
try {
    execSync('npm install', { stdio: 'inherit' });
    console.log('✅ Dependencies installed successfully');
} catch (error) {
    console.error('❌ Failed to install dependencies');
    console.error(error.message);
    process.exit(1);
}

// Check if MySQL is accessible
console.log('\n🗄️  Checking database connection...');
try {
    require('dotenv').config();
    
    const mysql = require('mysql2/promise');
    
    const connection = mysql.createConnection({
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 3306,
        user: process.env.DB_USER || 'root',
        password: process.env.DB_PASSWORD || ''
    });
    
    connection.connect().then(() => {
        console.log('✅ MySQL connection successful');
        connection.end();
    }).catch((error) => {
        console.log('⚠️  MySQL connection failed:');
        console.log(`   ${error.message}`);
        console.log('   Please check your database credentials in .env file');
    });
    
} catch (error) {
    console.log('⚠️  Could not test database connection');
    console.log('   Please ensure MySQL is installed and running');
}

// Create logs directory
const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir, { recursive: true });
    console.log('✅ Logs directory created');
}

console.log('\n🎉 Setup completed!');
console.log('\n📋 Next steps:');
console.log('1. Edit .env file with your database credentials');
console.log('2. Setup MIDTRANS credentials in .env');
console.log('3. Create database: mysql -u root -p < database/schema.sql');
console.log('4. Start development server: npm run dev');
console.log('\n📖 For more information, see README.md');

// Create a simple test script
const testScript = `
const axios = require('axios');

const baseURL = 'http://localhost:8000';

async function testAPI() {
    try {
        console.log('🧪 Testing API endpoints...');
        
        // Test health check
        const healthResponse = await axios.get(\`\${baseURL}/health\`);
        console.log('✅ Health check:', healthResponse.data.message);
        
        // Test login
        const loginResponse = await axios.post(\`\${baseURL}/api/auth/login\`, {
            username: 'admin',
            password: '123456'
        });
        
        if (loginResponse.data.success) {
            console.log('✅ Login test successful');
            console.log('👤 User:', loginResponse.data.user.nama);
            
            // Test protected endpoint
            const token = loginResponse.data.token;
            const productsResponse = await axios.get(\`\${baseURL}/api/products\`, {
                headers: { Authorization: \`Bearer \${token}\` }
            });
            
            console.log('✅ Products endpoint test successful');
            console.log('📦 Products count:', productsResponse.data.data.length);
            
        } else {
            console.log('❌ Login test failed');
        }
        
    } catch (error) {
        console.log('❌ API test failed:', error.response?.data?.message || error.message);
        console.log('   Make sure the server is running: npm run dev');
    }
}

testAPI();
`;

fs.writeFileSync(path.join(__dirname, 'test-api.js'), testScript);
console.log('🧪 Test script created: node test-api.js');