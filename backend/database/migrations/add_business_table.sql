-- Migration: Add business table
-- Tabel untuk menyimpan informasi usaha

USE griyo_pos;

CREATE TABLE IF NOT EXISTS business (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nama_usaha VARCHAR(255) NOT NULL,
    pemilik VARCHAR(100) NOT NULL,
    alamat TEXT NOT NULL,
    telepon VARCHAR(20) NOT NULL,
    email VARCHAR(100) NULL,
    deskripsi TEXT NULL,
    kategori VARCHAR(100) DEFAULT 'Retail',
    logo VARCHAR(500) NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_nama_usaha (nama_usaha),
    INDEX idx_is_active (is_active)
);

-- Insert default business data
INSERT INTO business (nama_usaha, pemilik, alamat, telepon, email, deskripsi, kategori) VALUES 
('GRIYO Store', 'Administrator', 'Jl. Contoh No. 123, Jakarta Selatan, DKI Jakarta', '081234567890', 'info@griyostore.com', 'Toko retail yang menyediakan berbagai kebutuhan sehari-hari dengan harga terjangkau dan pelayanan terbaik untuk kepuasan pelanggan', 'Retail')
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;
