# GRIYO POS - Backend API

Backend API untuk aplikasi GRIYO POS dengan MySQL database dan MIDTRANS payment gateway integration.

## 🚀 Quick Start

### Prerequisites
- Node.js (v16 or higher)
- MySQL (v8.0 or higher)
- NPM or Yarn

### Installation

1. **Clone dan Setup**
```bash
cd backend
npm install
```

2. **Environment Configuration**
```bash
cp .env.example .env
```

Edit `.env` file dengan konfigurasi Anda:
```env
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=griyo_pos
DB_USER=root
DB_PASSWORD=your_mysql_password

# JWT Secret
JWT_SECRET=your_super_secret_jwt_key_here

# Server Configuration
PORT=8000
NODE_ENV=development

# MIDTRANS Configuration
MIDTRANS_SERVER_KEY=your_midtrans_server_key
MIDTRANS_CLIENT_KEY=your_midtrans_client_key
MIDTRANS_IS_PRODUCTION=false
```

3. **Database Setup**
```bash
# Login ke MySQL
mysql -u root -p

# Jalankan schema SQL
mysql -u root -p < database/schema.sql
```

4. **Start Server**
```bash
# Development
npm run dev

# Production
npm start
```

## 📊 Database Schema

### Tables
- `users` - Admin dan Kasir accounts
- `products` - Master data produk
- `transactions` - Transaksi penjualan
- `transaction_items` - Detail item per transaksi

### Default Users
- **Admin**: username=`admin`, password=`123456`
- **Kasir**: username=`kasir`, password=`123456`

## 🔐 API Authentication

Menggunakan JWT Bearer token:
```bash
Authorization: Bearer <your_jwt_token>
```

## 📝 API Endpoints

### Authentication
```
POST /api/auth/login
POST /api/auth/register (Admin only)
GET  /api/auth/profile
PUT  /api/auth/profile
POST /api/auth/change-password
```

### Products
```
GET    /api/products
POST   /api/products (Admin only)
GET    /api/products/:id
PUT    /api/products/:id (Admin only)
DELETE /api/products/:id (Admin only)
GET    /api/products/categories
GET    /api/products/low-stock
```

### Transactions
```
GET  /api/transactions
POST /api/transactions
GET  /api/transactions/:id
PUT  /api/transactions/:id/status
GET  /api/transactions/summary
```

### Payment (MIDTRANS)
```
GET  /api/payment/methods
POST /api/payment/create-token
GET  /api/payment/status/:transaction_id
POST /api/payment/cancel/:transaction_id
POST /api/payment/notification (Webhook)
```

## 🎯 Role-Based Access

### Admin
- Full access ke semua endpoints
- Dapat kelola products
- Dapat lihat semua transactions
- Dapat register user baru

### Kasir
- Akses terbatas
- Tidak dapat kelola products
- Hanya dapat lihat transaksi sendiri
- Dapat buat transaksi baru

## 🔧 Development

### Run Development Server
```bash
npm run dev
```

### API Documentation
Akses: `http://localhost:8000/api-docs`

### Health Check
Akses: `http://localhost:8000/health`

## 🚀 Production Deployment

1. **Environment Variables**
```env
NODE_ENV=production
DB_HOST=your_production_db_host
MIDTRANS_IS_PRODUCTION=true
```

2. **Start Production Server**
```bash
npm start
```

## 🔌 Flutter Integration

Update Flutter API service:
```dart
// For Android Emulator
static const String baseUrl = 'http://10.0.2.2:8000/api';

// For iOS Simulator  
static const String baseUrl = 'http://localhost:8000/api';

// For Production
static const String baseUrl = 'https://your-domain.com/api';
```

## 📋 Testing

### Test Login
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}'
```

### Test Products
```bash
curl -X GET http://localhost:8000/api/products \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 🐛 Troubleshooting

### Common Issues

1. **Database Connection Error**
   - Check MySQL service running
   - Verify database credentials in `.env`
   - Ensure database `griyo_pos` exists

2. **CORS Error**
   - Check allowed origins in `server.js`
   - Ensure proper headers sent from Flutter

3. **Authentication Error**
   - Verify JWT token not expired
   - Check Authorization header format

## 📞 Support

Untuk issues dan questions, silakan buat issue di repository atau contact development team.

---

**GRIYO POS Backend API v1.0.0**  
Ready for Production! 🎉