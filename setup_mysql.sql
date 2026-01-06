-- LAUNDRY POS Database Setup Script
-- Jalankan script ini setelah MySQL terinstall

-- Create database
CREATE DATABASE IF NOT EXISTS laundry_pos;
USE laundry_pos;

-- Tabel Users (Admin dan Kasir)
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    nama VARCHAR(100) NOT NULL,
    role ENUM('admin', 'kasir') NOT NULL DEFAULT 'kasir',
    email VARCHAR(100) NULL,
    phone VARCHAR(20) NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_role (role)
);

-- Tabel Products
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nama VARCHAR(255) NOT NULL,
    harga DECIMAL(10,2) NOT NULL,
    stok INT NOT NULL DEFAULT 0,
    kategori VARCHAR(100) NOT NULL,
    deskripsi TEXT NULL,
    gambar VARCHAR(500) NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_kategori (kategori),
    INDEX idx_nama (nama),
    INDEX idx_is_active (is_active)
);

-- Tabel Transactions
CREATE TABLE transactions (
    id VARCHAR(50) PRIMARY KEY,
    user_id INT NOT NULL,
    total DECIMAL(12,2) NOT NULL,
    status ENUM('pending', 'paid', 'cancelled') NOT NULL DEFAULT 'pending',
    payment_method ENUM('cash', 'midtrans') NOT NULL,
    payment_token VARCHAR(255) NULL,
    customer_name VARCHAR(100) NULL,
    customer_phone VARCHAR(20) NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    INDEX idx_payment_method (payment_method)
);

-- Tabel Transaction Items
CREATE TABLE transaction_items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    transaction_id VARCHAR(50) NOT NULL,
    product_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    qty INT NOT NULL,
    harga DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_transaction_id (transaction_id),
    INDEX idx_product_id (product_id)
);

-- Insert default users (password: 123456)
INSERT INTO users (username, password, nama, role, email, phone) VALUES 
('admin', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Administrator Laundry', 'admin', 'admin@laundrypos.com', '081234567890'),
('kasir', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Kasir Laundry', 'kasir', 'kasir@laundrypos.com', '081234567891');

-- Insert sample products (Layanan Laundry)
INSERT INTO products (nama, harga, stok, kategori, deskripsi) VALUES 
('Cuci Kering Lipat', 7000, 9999, 'Kiloan', 'Cuci bersih, kering, dan lipat rapi (per kg)'),
('Cuci Setrika', 9000, 9999, 'Kiloan', 'Cuci bersih dan setrika halus (per kg)'),
('Setrika Saja', 6000, 9999, 'Kiloan', 'Jasa setrika saja (per kg)'),
('Dry Clean Jas', 35000, 9999, 'Satuan', 'Dry cleaning khusus jas pria/wanita'),
('Bed Cover Kecil', 25000, 9999, 'Satuan', 'Cuci bed cover ukuran single/kecil'),
('Bed Cover Besar', 40000, 9999, 'Satuan', 'Cuci bed cover ukuran double/king'),
('Cuci Sepatu', 30000, 9999, 'Satuan', 'Deep cleaning sepatu'),
('Cuci Karpet', 15000, 9999, 'Satuan', 'Cuci karpet (per meter persegi)'),
('Boneka Kecil', 10000, 9999, 'Satuan', 'Cuci boneka ukuran kecil'),
('Express 3 Jam', 15000, 9999, 'Kilat', 'Layanan cuci kilat selesai 3 jam (per kg)');

-- Create views for reporting
CREATE VIEW v_daily_sales AS
SELECT 
    DATE(created_at) as tanggal,
    COUNT(*) as total_transaksi,
    SUM(total) as total_penjualan,
    AVG(total) as rata_rata_transaksi
FROM transactions 
WHERE status = 'paid'
GROUP BY DATE(created_at)
ORDER BY tanggal DESC;

CREATE VIEW v_product_sales AS
SELECT 
    p.nama,
    p.kategori,
    SUM(ti.qty) as total_terjual,
    SUM(ti.subtotal) as total_revenue,
    COUNT(DISTINCT ti.transaction_id) as total_transaksi
FROM products p
LEFT JOIN transaction_items ti ON p.id = ti.product_id
LEFT JOIN transactions t ON ti.transaction_id = t.id AND t.status = 'paid'
GROUP BY p.id, p.nama, p.kategori
ORDER BY total_terjual DESC;

-- Performance indexes
CREATE INDEX idx_transactions_date_status ON transactions(created_at, status);
CREATE INDEX idx_transaction_items_composite ON transaction_items(transaction_id, product_id);

-- Show success message
SELECT 'LAUNDRY POS Database setup completed successfully!' as message;