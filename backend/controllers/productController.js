const { validationResult } = require('express-validator');
const { findMany, findOne, insertRecord, updateRecord, deleteRecord, executeQuery } = require('../config/database');

// Get all products
const getProducts = async (req, res) => {
    try {
        const { 
            kategori, 
            search, 
            limit = 100, 
            offset = 0,
            orderBy = 'nama',
            orderDir = 'ASC'
        } = req.query;

        let query = 'SELECT * FROM products WHERE is_active = true';
        let params = [];

        // Filter by category
        if (kategori && kategori !== 'Semua') {
            query += ' AND kategori = ?';
            params.push(kategori);
        }

        // Search by name or description
        if (search) {
            query += ' AND (nama LIKE ? OR deskripsi LIKE ?)';
            params.push(`%${search}%`, `%${search}%`);
        }

        // Add ordering
        const validOrderBy = ['nama', 'harga', 'stok', 'kategori', 'created_at'];
        const validOrderDir = ['ASC', 'DESC'];
        
        if (validOrderBy.includes(orderBy) && validOrderDir.includes(orderDir.toUpperCase())) {
            query += ` ORDER BY ${orderBy} ${orderDir.toUpperCase()}`;
        }

        // Add pagination (avoid placeholders for LIMIT/OFFSET on some MySQL setups)
        const limitNum = Math.max(1, parseInt(limit));
        const offsetNum = Math.max(0, parseInt(offset));
        query += ` LIMIT ${limitNum} OFFSET ${offsetNum}`;

        const result = await executeQuery(query, params);
        
        if (!result.success) {
            throw new Error(result.error);
        }

        // Get total count for pagination
        let countQuery = 'SELECT COUNT(*) as total FROM products WHERE is_active = true';
        let countParams = [];

        if (kategori && kategori !== 'Semua') {
            countQuery += ' AND kategori = ?';
            countParams.push(kategori);
        }

        if (search) {
            countQuery += ' AND (nama LIKE ? OR deskripsi LIKE ?)';
            countParams.push(`%${search}%`, `%${search}%`);
        }

        const countResult = await executeQuery(countQuery, countParams);
        const total = countResult.success ? countResult.data[0].total : 0;

        res.json({
            success: true,
            data: result.data,
            pagination: {
                total: total,
                limit: parseInt(limit),
                offset: parseInt(offset),
                hasMore: (parseInt(offset) + parseInt(limit)) < total
            }
        });

    } catch (error) {
        console.error('Get products error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch products'
        });
    }
};

// Get single product
const getProduct = async (req, res) => {
    try {
        const { id } = req.params;

        const product = await findOne('products', { 
            id: parseInt(id),
            is_active: true 
        });

        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found'
            });
        }

        res.json({
            success: true,
            data: product
        });

    } catch (error) {
        console.error('Get product error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch product'
        });
    }
};

// Create new product (Admin only)
const createProduct = async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                message: 'Validation failed',
                errors: errors.array()
            });
        }

        const { nama, harga, stok, kategori, deskripsi, gambar } = req.body;

        // Check if product name already exists
        const existingProduct = await findOne('products', { 
            nama, 
            is_active: true 
        });

        if (existingProduct) {
            return res.status(400).json({
                success: false,
                message: 'Product name already exists'
            });
        }

        const productData = {
            nama,
            harga: parseFloat(harga),
            stok: parseInt(stok),
            kategori,
            deskripsi: deskripsi || null,
            gambar: gambar || null,
            is_active: true
        };

        const newProduct = await insertRecord('products', productData);

        if (!newProduct) {
            return res.status(500).json({
                success: false,
                message: 'Failed to create product'
            });
        }

        res.status(201).json({
            success: true,
            message: 'Product created successfully',
            product: newProduct
        });

        console.log(`✅ Product created: ${nama} by user ${req.user.username}`);

    } catch (error) {
        console.error('Create product error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create product'
        });
    }
};

// Update product (Admin only)
const updateProduct = async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                message: 'Validation failed',
                errors: errors.array()
            });
        }

        const { id } = req.params;
        const { nama, harga, stok, kategori, deskripsi, gambar } = req.body;

        // Check if product exists
        const existingProduct = await findOne('products', { 
            id: parseInt(id),
            is_active: true 
        });

        if (!existingProduct) {
            return res.status(404).json({
                success: false,
                message: 'Product not found'
            });
        }

        // Check if new name conflicts with other products
        if (nama && nama !== existingProduct.nama) {
            const nameConflict = await findOne('products', { 
                nama,
                is_active: true 
            });

            if (nameConflict && nameConflict.id !== parseInt(id)) {
                return res.status(400).json({
                    success: false,
                    message: 'Product name already exists'
                });
            }
        }

        const updateData = {};
        if (nama !== undefined) updateData.nama = nama;
        if (harga !== undefined) updateData.harga = parseFloat(harga);
        if (stok !== undefined) updateData.stok = parseInt(stok);
        if (kategori !== undefined) updateData.kategori = kategori;
        if (deskripsi !== undefined) updateData.deskripsi = deskripsi;
        if (gambar !== undefined) updateData.gambar = gambar;

        const updated = await updateRecord('products', updateData, { 
            id: parseInt(id) 
        });

        if (!updated) {
            return res.status(500).json({
                success: false,
                message: 'Failed to update product'
            });
        }

        // Get updated product
        const updatedProduct = await findOne('products', { id: parseInt(id) });

        res.json({
            success: true,
            message: 'Product updated successfully',
            product: updatedProduct
        });

        console.log(`✅ Product updated: ${nama || existingProduct.nama} by user ${req.user.username}`);

    } catch (error) {
        console.error('Update product error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update product'
        });
    }
};

// Delete product (Admin only)
const deleteProduct = async (req, res) => {
    try {
        const { id } = req.params;

        // Check if product exists
        const existingProduct = await findOne('products', { 
            id: parseInt(id),
            is_active: true 
        });

        if (!existingProduct) {
            return res.status(404).json({
                success: false,
                message: 'Product not found'
            });
        }

        // Check if product is used in transactions
        const isUsedInTransaction = await findOne('transaction_items', { 
            product_id: parseInt(id) 
        });

        if (isUsedInTransaction) {
            // Soft delete - set is_active to false
            const updated = await updateRecord('products', 
                { is_active: false }, 
                { id: parseInt(id) }
            );

            if (!updated) {
                return res.status(500).json({
                    success: false,
                    message: 'Failed to delete product'
                });
            }

            res.json({
                success: true,
                message: 'Product deactivated successfully (used in transactions)'
            });
        } else {
            // Hard delete
            const deleted = await deleteRecord('products', { id: parseInt(id) });

            if (!deleted) {
                return res.status(500).json({
                    success: false,
                    message: 'Failed to delete product'
                });
            }

            res.json({
                success: true,
                message: 'Product deleted successfully'
            });
        }

        console.log(`✅ Product deleted: ${existingProduct.nama} by user ${req.user.username}`);

    } catch (error) {
        console.error('Delete product error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete product'
        });
    }
};

// Get product categories
const getCategories = async (req, res) => {
    try {
        const query = 'SELECT DISTINCT kategori FROM products WHERE is_active = true ORDER BY kategori';
        const result = await executeQuery(query);

        if (!result.success) {
            throw new Error(result.error);
        }

        const categories = result.data.map(row => row.kategori);

        res.json({
            success: true,
            data: categories
        });

    } catch (error) {
        console.error('Get categories error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch categories'
        });
    }
};

// Get low stock products
const getLowStockProducts = async (req, res) => {
    try {
        const { threshold = 10 } = req.query;

        const query = 'SELECT * FROM products WHERE is_active = true AND stok <= ? ORDER BY stok ASC';
        const result = await executeQuery(query, [parseInt(threshold)]);

        if (!result.success) {
            throw new Error(result.error);
        }

        res.json({
            success: true,
            data: result.data,
            threshold: parseInt(threshold)
        });

    } catch (error) {
        console.error('Get low stock products error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch low stock products'
        });
    }
};

// Update product stock
const updateStock = async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                message: 'Validation failed',
                errors: errors.array()
            });
        }

        const { id } = req.params;
        const { stok } = req.body;

        // Check if product exists
        const existingProduct = await findOne('products', { 
            id: parseInt(id),
            is_active: true 
        });

        if (!existingProduct) {
            return res.status(404).json({
                success: false,
                message: 'Product not found'
            });
        }

        const updated = await updateRecord('products', 
            { stok: parseInt(stok) }, 
            { id: parseInt(id) }
        );

        if (!updated) {
            return res.status(500).json({
                success: false,
                message: 'Failed to update stock'
            });
        }

        // Get updated product
        const updatedProduct = await findOne('products', { id: parseInt(id) });

        res.json({
            success: true,
            message: 'Stock updated successfully',
            product: updatedProduct
        });

        console.log(`✅ Stock updated: ${existingProduct.nama} (${existingProduct.stok} → ${stok}) by user ${req.user.username}`);

    } catch (error) {
        console.error('Update stock error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update stock'
        });
    }
};

module.exports = {
    getProducts,
    getProduct,
    createProduct,
    updateProduct,
    deleteProduct,
    getCategories,
    getLowStockProducts,
    updateStock
};