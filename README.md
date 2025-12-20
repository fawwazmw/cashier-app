# 🏪 GRIYO POS - Point of Sale Application

Aplikasi Point of Sale (POS) berbasis Flutter dengan backend Node.js + MySQL untuk mengelola usaha retail/toko dengan mudah dan efisien.

![Flutter](https://img.shields.io/badge/Flutter-3.9.0-blue?logo=flutter)
![Node.js](https://img.shields.io/badge/Node.js-16+-green?logo=node.js)
![MySQL](https://img.shields.io/badge/MySQL-8.0-orange?logo=mysql)
![License](https://img.shields.io/badge/License-MIT-yellow)

## ✨ Features

### 🔐 Authentication
- Login & Register dengan JWT Token
- Secure password hashing dengan bcrypt
- Session management dengan shared preferences

### 📦 Product Management
- Tambah, edit, dan hapus produk
- Upload foto produk (base64)
- Kelola stok dan harga produk
- Kategori produk

### 💰 Transaction & Cashier
- Sistem kasir yang user-friendly
- Keranjang belanja dengan quantity management
- Riwayat transaksi lengkap
- Detail transaksi per item

### 💳 Payment Integration
- Integrasi **Midtrans Payment Gateway**
- Support multiple payment methods (Credit Card, GoPay, QRIS, dll)
- WebView untuk Snap Payment
- Auto-update status transaksi

### 👤 Profile & Business Management
- Kelola profil usaha
- Ubah informasi user
- Manajemen PIN untuk keamanan

## 📸 Screenshots

> *Add your app screenshots here*

## 🛠️ Tech Stack

### Frontend (Mobile)
- **Framework:** Flutter 3.9.0
- **State Management:** Provider
- **HTTP Client:** Dio & HTTP
- **Payment:** WebView Flutter (Midtrans Snap)
- **Local Storage:** Shared Preferences

### Backend (API)
- **Runtime:** Node.js
- **Framework:** Express.js
- **Database:** MySQL 8.0
- **Authentication:** JWT (jsonwebtoken)
- **Password Hashing:** bcrypt
- **Payment Gateway:** Midtrans API

## 📋 Prerequisites

Pastikan Anda sudah menginstall:

- **Flutter SDK** (3.0 atau lebih baru)
- **Dart SDK** (3.9.0 atau lebih baru)
- **Node.js** (16 atau lebih baru)
- **npm** atau **yarn**
- **MySQL** (8.0 atau lebih baru)
- **Android Studio** / **Xcode** (untuk development mobile)
- **Git**

## 🚀 Installation

### 1. Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/griyo-pos.git
cd griyo-pos
```

### 2. Setup Backend

#### Install Dependencies

```bash
cd backend
npm install
```

#### Configure Environment

Buat file `.env` dari template:

```bash
cp .env.example .env
```

Edit file `.env` dan sesuaikan dengan konfigurasi Anda:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=griyo_pos
DB_USER=root
DB_PASSWORD=your_mysql_password

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_change_this

# Server Configuration
PORT=8000
NODE_ENV=development

# Midtrans Configuration
MIDTRANS_SERVER_KEY=your_midtrans_server_key
MIDTRANS_CLIENT_KEY=your_midtrans_client_key
MIDTRANS_IS_PRODUCTION=false

# App Configuration
APP_NAME=GRIYO POS
APP_URL=http://localhost:8000
```

#### Setup Database

Jalankan setup script untuk membuat database dan tabel:

```bash
node setup.js
```

Script ini akan:
- Membuat database `griyo_pos`
- Membuat tabel yang diperlukan (users, products, transactions, dll)
- Insert sample data (opsional)

#### Start Backend Server

```bash
npm start
```

Server akan berjalan di `http://localhost:8000`

### 3. Setup Flutter App

#### Install Dependencies

```bash
# Kembali ke root project
cd ..

# Install Flutter packages
flutter pub get
```

#### Configure API URL

Edit file `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Ganti dengan IP address komputer Anda jika test di device fisik
  // Untuk emulator Android: 10.0.2.2
  // Untuk device fisik: 192.168.x.x (IP lokal komputer Anda)
  static const String baseUrl = 'http://localhost:8000';
  
  // Atau untuk testing di device fisik:
  // static const String baseUrl = 'http://192.168.1.100:8000';
}
```

#### Run the App

```bash
# Run di emulator/simulator
flutter run

# Atau pilih device spesifik
flutter devices
flutter run -d <device_id>
```

## 📱 Build untuk Production

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (untuk Google Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
flutter build ios --release
```

> **Note:** iOS build memerlukan Mac dengan Xcode terinstall

## 🗄️ Database Schema

Database schema tersedia di `backend/database/schema.sql`

### Main Tables:
- **users** - Data pengguna dan autentikasi
- **products** - Data produk
- **transactions** - Header transaksi
- **transaction_items** - Detail item per transaksi

## 🔑 API Endpoints

Dokumentasi lengkap API tersedia di `backend/README.md`

### Authentication
- `POST /api/auth/register` - Register user baru
- `POST /api/auth/login` - Login user

### Products
- `GET /api/products` - Get semua produk
- `GET /api/products/:id` - Get produk by ID
- `POST /api/products` - Tambah produk baru
- `PUT /api/products/:id` - Update produk
- `DELETE /api/products/:id` - Hapus produk

### Transactions
- `GET /api/transactions` - Get riwayat transaksi
- `GET /api/transactions/:id` - Get detail transaksi
- `POST /api/transactions` - Buat transaksi baru

### Payment
- `POST /api/payment/create` - Create Midtrans payment token
- `POST /api/payment/notification` - Midtrans payment notification handler

## 🔐 Security

### Best Practices Implemented:
- ✅ Password hashing dengan bcrypt
- ✅ JWT token untuk authentication
- ✅ Environment variables untuk kredensial sensitif
- ✅ Input validation dan sanitization
- ✅ CORS configuration
- ✅ Secure payment handling dengan Midtrans

### Security Notes:
- **JANGAN** commit file `.env` ke repository
- Gunakan JWT secret yang kuat dan random (minimal 32 karakter)
- Untuk production, gunakan HTTPS
- Simpan Midtrans Server Key dengan aman
- Aktifkan SSL untuk koneksi database di production

## 🧪 Testing

### Backend API Testing

```bash
cd backend
npm test
```

Atau test manual dengan file test:

```bash
node test-api-full.js
```

### Flutter Testing

```bash
flutter test
```

## 📦 Deployment

### Backend Deployment (Contoh: VPS / Cloud Server)

1. Setup MySQL di server
2. Clone repository
3. Configure `.env` dengan kredensial production
4. Install dependencies: `npm install --production`
5. Setup database: `node setup.js`
6. Start dengan PM2: `pm2 start server.js --name griyo-pos-api`

### Flutter App Deployment

1. Build APK/AAB untuk Android
2. Upload ke Google Play Store atau distribute manual
3. Untuk iOS, build dan upload ke App Store via Xcode

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Your Name** - *Initial work* - [YourGitHub](https://github.com/yourusername)

## 🙏 Acknowledgments

- Flutter Team untuk framework yang amazing
- Midtrans untuk payment gateway integration
- Express.js community
- Dan semua contributors!

## 📞 Support & Contact

Jika ada pertanyaan atau issue:
- 📧 Email: your.email@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/griyo-pos/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/griyo-pos/discussions)

---

**Made with ❤️ using Flutter & Node.js**
