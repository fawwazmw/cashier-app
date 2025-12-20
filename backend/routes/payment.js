const express = require('express');
const { body, param } = require('express-validator');
const {
    createPaymentToken,
    handleNotification,
    checkPaymentStatus,
    cancelPayment,
    getPaymentMethods,
    paymentFinish,
    paymentError,
    paymentPending
} = require('../controllers/paymentController');
const {
    authenticateToken,
    requireAdminOrKasir
} = require('../middleware/auth');

const router = express.Router();

// Validation rules
const createTokenValidation = [
    body('transaction_id')
        .notEmpty()
        .withMessage('Transaction ID is required')
        .isLength({ min: 3, max: 50 })
        .withMessage('Transaction ID must be between 3-50 characters'),
    body('customer_details')
        .optional()
        .isObject()
        .withMessage('Customer details must be an object'),
    body('customer_details.first_name')
        .optional()
        .isLength({ min: 2, max: 50 })
        .withMessage('First name must be between 2-50 characters'),
    body('customer_details.email')
        .optional()
        .isEmail()
        .withMessage('Invalid email format'),
    body('customer_details.phone')
        .optional()
        .isMobilePhone('id-ID')
        .withMessage('Invalid Indonesian phone number format')
];

const transactionIdValidation = [
    param('transaction_id')
        .notEmpty()
        .withMessage('Transaction ID is required')
        .isLength({ min: 3, max: 50 })
        .withMessage('Transaction ID must be between 3-50 characters')
];

// Routes

/**
 * @route   GET /api/payment/methods
 * @desc    Get available payment methods
 * @access  Private (Admin or Kasir)
 */
router.get('/methods', 
    authenticateToken, 
    requireAdminOrKasir, 
    getPaymentMethods
);

/**
 * @route   POST /api/payment/create-token
 * @desc    Create MIDTRANS payment token
 * @access  Private (Admin or Kasir)
 * @body    { transaction_id, customer_details? }
 */
router.post('/create-token', 
    authenticateToken, 
    requireAdminOrKasir, 
    createTokenValidation, 
    createPaymentToken
);

/**
 * @route   GET /api/payment/status/:transaction_id
 * @desc    Check payment status
 * @access  Private (Admin or Kasir - kasir can only check own transactions)
 */
router.get('/status/:transaction_id', 
    authenticateToken, 
    requireAdminOrKasir, 
    transactionIdValidation,
    checkPaymentStatus
);

/**
 * @route   POST /api/payment/cancel/:transaction_id
 * @desc    Cancel payment
 * @access  Private (Admin or Kasir - kasir can only cancel own transactions)
 */
router.post('/cancel/:transaction_id', 
    authenticateToken, 
    requireAdminOrKasir, 
    transactionIdValidation,
    cancelPayment
);

/**
 * @route   POST /api/payment/notification
 * @desc    Handle MIDTRANS webhook notification
 * @access  Public (MIDTRANS webhook)
 */
router.post('/notification', handleNotification);

/**
 * @route   GET /api/payment/finish
 * @desc    Payment finish callback page
 * @access  Public (MIDTRANS callback)
 */
router.get('/finish', paymentFinish);

/**
 * @route   GET /api/payment/error
 * @desc    Payment error callback page
 * @access  Public (MIDTRANS callback)
 */
router.get('/error', paymentError);

/**
 * @route   GET /api/payment/pending
 * @desc    Payment pending callback page
 * @access  Public (MIDTRANS callback)
 */
router.get('/pending', paymentPending);

module.exports = router;