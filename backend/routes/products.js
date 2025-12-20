const express = require('express');
const { body, query, param } = require('express-validator');
const {
    getProducts,
    getProduct,
    createProduct,
    updateProduct,
    deleteProduct,
    getCategories,
    getLowStockProducts,
    updateStock
} = require('../controllers/productController');
const {
    authenticateToken,
    requireAdmin,
    requireAdminOrKasir
} = require('../middleware/auth');

const router = express.Router();

// Validation rules
const productValidation = [
    body('nama')
        .notEmpty()
        .withMessage('Product name is required')
        .isLength({ min: 2, max: 255 })
        .withMessage('Product name must be between 2-255 characters'),
    body('harga')
        .notEmpty()
        .withMessage('Price is required')
        .isFloat({ min: 0 })
        .withMessage('Price must be a positive number'),
    body('stok')
        .notEmpty()
        .withMessage('Stock is required')
        .isInt({ min: 0 })
        .withMessage('Stock must be a non-negative integer'),
    body('kategori')
        .notEmpty()
        .withMessage('Category is required')
        .isLength({ min: 2, max: 100 })
        .withMessage('Category must be between 2-100 characters'),
    body('deskripsi')
        .optional()
        .isLength({ max: 1000 })
        .withMessage('Description must not exceed 1000 characters'),
    body('gambar')
        .optional()
        .isURL()
        .withMessage('Image must be a valid URL')
];

const updateProductValidation = [
    body('nama')
        .optional()
        .isLength({ min: 2, max: 255 })
        .withMessage('Product name must be between 2-255 characters'),
    body('harga')
        .optional()
        .isFloat({ min: 0 })
        .withMessage('Price must be a positive number'),
    body('stok')
        .optional()
        .isInt({ min: 0 })
        .withMessage('Stock must be a non-negative integer'),
    body('kategori')
        .optional()
        .isLength({ min: 2, max: 100 })
        .withMessage('Category must be between 2-100 characters'),
    body('deskripsi')
        .optional()
        .isLength({ max: 1000 })
        .withMessage('Description must not exceed 1000 characters'),
    body('gambar')
        .optional()
        .isURL()
        .withMessage('Image must be a valid URL')
];

const updateStockValidation = [
    body('stok')
        .notEmpty()
        .withMessage('Stock is required')
        .isInt({ min: 0 })
        .withMessage('Stock must be a non-negative integer')
];

const productQueryValidation = [
    query('limit')
        .optional()
        .isInt({ min: 1, max: 1000 })
        .withMessage('Limit must be between 1-1000'),
    query('offset')
        .optional()
        .isInt({ min: 0 })
        .withMessage('Offset must be non-negative'),
    query('orderBy')
        .optional()
        .isIn(['nama', 'harga', 'stok', 'kategori', 'created_at'])
        .withMessage('Invalid orderBy field'),
    query('orderDir')
        .optional()
        .isIn(['ASC', 'DESC', 'asc', 'desc'])
        .withMessage('OrderDir must be ASC or DESC')
];

const productIdValidation = [
    param('id')
        .isInt({ min: 1 })
        .withMessage('Product ID must be a positive integer')
];

const lowStockQueryValidation = [
    query('threshold')
        .optional()
        .isInt({ min: 0, max: 1000 })
        .withMessage('Threshold must be between 0-1000')
];

// Routes

/**
 * @route   GET /api/products
 * @desc    Get all products with filtering and pagination
 * @access  Private (Admin or Kasir)
 * @query   kategori?, search?, limit?, offset?, orderBy?, orderDir?
 */
router.get('/', 
    authenticateToken, 
    requireAdminOrKasir, 
    productQueryValidation, 
    getProducts
);

/**
 * @route   GET /api/products/categories
 * @desc    Get all product categories
 * @access  Private (Admin or Kasir)
 */
router.get('/categories', 
    authenticateToken, 
    requireAdminOrKasir, 
    getCategories
);

/**
 * @route   GET /api/products/low-stock
 * @desc    Get products with low stock
 * @access  Private (Admin or Kasir)
 * @query   threshold?
 */
router.get('/low-stock', 
    authenticateToken, 
    requireAdminOrKasir, 
    lowStockQueryValidation,
    getLowStockProducts
);

/**
 * @route   GET /api/products/:id
 * @desc    Get single product by ID
 * @access  Private (Admin or Kasir)
 */
router.get('/:id', 
    authenticateToken, 
    requireAdminOrKasir, 
    productIdValidation,
    getProduct
);

/**
 * @route   POST /api/products
 * @desc    Create new product
 * @access  Private (Admin only)
 * @body    { nama, harga, stok, kategori, deskripsi?, gambar? }
 */
router.post('/', 
    authenticateToken, 
    requireAdmin, 
    productValidation, 
    createProduct
);

/**
 * @route   PUT /api/products/:id
 * @desc    Update product
 * @access  Private (Admin only)
 * @body    { nama?, harga?, stok?, kategori?, deskripsi?, gambar? }
 */
router.put('/:id', 
    authenticateToken, 
    requireAdmin, 
    productIdValidation,
    updateProductValidation, 
    updateProduct
);

/**
 * @route   PUT /api/products/:id/stock
 * @desc    Update product stock only
 * @access  Private (Admin only)
 * @body    { stok }
 */
router.put('/:id/stock', 
    authenticateToken, 
    requireAdmin, 
    productIdValidation,
    updateStockValidation, 
    updateStock
);

/**
 * @route   DELETE /api/products/:id
 * @desc    Delete product (soft delete if used in transactions)
 * @access  Private (Admin only)
 */
router.delete('/:id', 
    authenticateToken, 
    requireAdmin, 
    productIdValidation,
    deleteProduct
);

module.exports = router;