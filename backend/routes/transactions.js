const express = require('express');
const { body, query, param } = require('express-validator');
const {
    createTransaction,
    getTransactions,
    getTransaction,
    updateTransactionStatus,
    getSalesSummary
} = require('../controllers/transactionController');
const {
    authenticateToken,
    requireAdminOrKasir
} = require('../middleware/auth');

const router = express.Router();

// Validation rules
const createTransactionValidation = [
    body('total')
        .notEmpty()
        .withMessage('Total is required')
        .isFloat({ min: 0 })
        .withMessage('Total must be a positive number'),
    body('payment_method')
        .notEmpty()
        .withMessage('Payment method is required')
        .isIn(['cash', 'midtrans'])
        .withMessage('Payment method must be either cash or midtrans'),
    body('items')
        .isArray({ min: 1 })
        .withMessage('Items must be a non-empty array'),
    body('items.*.product_id')
        .notEmpty()
        .withMessage('Product ID is required')
        .isInt({ min: 1 })
        .withMessage('Product ID must be a positive integer'),
    body('items.*.qty')
        .notEmpty()
        .withMessage('Quantity is required')
        .isInt({ min: 1 })
        .withMessage('Quantity must be a positive integer'),
    body('customer_name')
        .optional({ nullable: true, checkFalsy: true })
        .isLength({ min: 2, max: 100 })
        .withMessage('Customer name must be between 2-100 characters'),
    body('customer_phone')
        .optional({ nullable: true, checkFalsy: true })
        .isMobilePhone('id-ID')
        .withMessage('Invalid Indonesian phone number format'),
    body('notes')
        .optional()
        .isLength({ max: 500 })
        .withMessage('Notes must not exceed 500 characters')
];

const updateStatusValidation = [
    body('status')
        .notEmpty()
        .withMessage('Status is required')
        .isIn(['pending', 'paid', 'cancelled'])
        .withMessage('Status must be pending, paid, or cancelled')
];

const transactionQueryValidation = [
    query('status')
        .optional()
        .isIn(['pending', 'paid', 'cancelled', 'Semua'])
        .withMessage('Invalid status filter'),
    query('payment_method')
        .optional()
        .isIn(['cash', 'midtrans'])
        .withMessage('Payment method must be cash or midtrans'),
    query('user_id')
        .optional()
        .isInt({ min: 1 })
        .withMessage('User ID must be a positive integer'),
    query('date_from')
        .optional()
        .isDate({ format: 'YYYY-MM-DD' })
        .withMessage('Invalid date format for date_from (use YYYY-MM-DD)'),
    query('date_to')
        .optional()
        .isDate({ format: 'YYYY-MM-DD' })
        .withMessage('Invalid date format for date_to (use YYYY-MM-DD)'),
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
        .isIn(['created_at', 'total', 'status', 'id'])
        .withMessage('Invalid orderBy field'),
    query('orderDir')
        .optional()
        .isIn(['ASC', 'DESC', 'asc', 'desc'])
        .withMessage('OrderDir must be ASC or DESC')
];

const transactionIdValidation = [
    param('id')
        .notEmpty()
        .withMessage('Transaction ID is required')
        .isLength({ min: 3, max: 50 })
        .withMessage('Transaction ID must be between 3-50 characters')
];

const salesSummaryValidation = [
    query('date')
        .optional()
        .isDate({ format: 'YYYY-MM-DD' })
        .withMessage('Invalid date format (use YYYY-MM-DD)')
];

// Routes

/**
 * @route   GET /api/transactions
 * @desc    Get transactions with filtering and pagination
 * @access  Private (Admin or Kasir - kasir can only see own transactions)
 * @query   status?, payment_method?, user_id?, date_from?, date_to?, search?, limit?, offset?, orderBy?, orderDir?
 */
router.get('/', 
    authenticateToken, 
    requireAdminOrKasir, 
    transactionQueryValidation, 
    getTransactions
);

/**
 * @route   GET /api/transactions/summary
 * @desc    Get sales summary for specific date
 * @access  Private (Admin or Kasir)
 * @query   date?
 */
router.get('/summary', 
    authenticateToken, 
    requireAdminOrKasir, 
    salesSummaryValidation,
    getSalesSummary
);

/**
 * @route   GET /api/transactions/:id
 * @desc    Get single transaction by ID
 * @access  Private (Admin or Kasir - kasir can only see own transactions)
 */
router.get('/:id', 
    authenticateToken, 
    requireAdminOrKasir, 
    transactionIdValidation,
    getTransaction
);

/**
 * @route   POST /api/transactions
 * @desc    Create new transaction
 * @access  Private (Admin or Kasir)
 * @body    { total, payment_method, items, customer_name?, customer_phone?, notes? }
 */
router.post('/', 
    authenticateToken, 
    requireAdminOrKasir, 
    createTransactionValidation, 
    createTransaction
);

/**
 * @route   PUT /api/transactions/:id/status
 * @desc    Update transaction status
 * @access  Private (Admin or Kasir - kasir can only update own transactions)
 * @body    { status }
 */
router.put('/:id/status', 
    authenticateToken, 
    requireAdminOrKasir, 
    transactionIdValidation,
    updateStatusValidation, 
    updateTransactionStatus
);

module.exports = router;