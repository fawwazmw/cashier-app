-- GRIYO POS Database Schema
-- Jalankan script ini untuk membuat database dan tabel

CREATE DATABASE IF NOT EXISTS griyo_pos;
USE griyo_pos;

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

-- Insert default admin user (password: 123456)
INSERT INTO users (username, password, nama, role, email, phone) VALUES 
('admin', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Administrator', 'admin', 'admin@griyopos.com', '081234567890'),
('kasir', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Kasir POS', 'kasir', 'kasir@griyopos.com', '081234567891');

-- Insert sample products
INSERT INTO products (nama, harga, stok, kategori, deskripsi) VALUES 
('Sabun Lifebuoy', 7000, 50, 'Toiletries', 'Sabun antiseptik untuk keluarga'),
('Shampo Pantene', 15000, 30, 'Toiletries', 'Shampo untuk rambut sehat'),
('Pasta Gigi Pepsodent', 12000, 25, 'Toiletries', 'Pasta gigi untuk gigi putih'),
('Beras Premium 5kg', 80000, 15, 'Makanan', 'Beras premium kualitas terbaik'),
('Minyak Goreng 2L', 35000, 20, 'Makanan', 'Minyak goreng berkualitas'),
('Susu Ultra 1L', 18000, 40, 'Minuman', 'Susu segar dan bergizi'),
('Teh Botol Sosro', 5000, 100, 'Minuman', 'Teh botol segar'),
('Kopi Kapal Api', 8000, 60, 'Minuman', 'Kopi bubuk pilihan'),
('Indomie Goreng', 3000, 200, 'Makanan', 'Mie instan rasa ayam bawang'),
('Tissue Nice', 4000, 80, 'Toiletries', 'Tissue wajah berkualitas');

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

-- Create indexes for performance
CREATE INDEX idx_transactions_date_status ON transactions(created_at, status);
CREATE INDEX idx_transaction_items_composite ON transaction_items(transaction_id, product_id);