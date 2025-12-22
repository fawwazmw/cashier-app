# Instruksi Update Database untuk Fitur Business/Usaha

## Langkah-Langkah:

### 1. Jalankan Migration SQL
Buka terminal/command prompt dan jalankan perintah berikut:

**Linux/Mac:**
```bash
mysql -u root -p griyo_pos < backend/database/migrations/add_business_table.sql
```

**Windows:**
```cmd
mysql -u root -p griyo_pos < backend\database\migrations\add_business_table.sql
```

Masukkan password MySQL Anda saat diminta.

### 2. Restart Backend Server
```bash
cd backend
node server.js
```

### 3. Restart Flutter App
```bash
flutter run
```

## Verifikasi

Setelah semua langkah selesai, buka halaman "Usahaku" di aplikasi. Data yang ditampilkan seharusnya:
- Nama Usaha: GRIYO Store
- Pemilik: Administrator
- Alamat: Jl. Contoh No. 123, Jakarta Selatan, DKI Jakarta
- Telepon: 081234567890
- Deskripsi: Toko retail yang menyediakan berbagai kebutuhan sehari-hari...

## Catatan:
- Tabel `business` sekarang menyimpan informasi usaha
- Data dapat diupdate melalui halaman Edit Usaha
- API endpoint: GET /api/business dan PUT /api/business
