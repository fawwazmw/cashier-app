const express = require('express');
const { body } = require('express-validator');
const { 
    login, 
    register, 
    getProfile, 
    updateProfile, 
    changePassword 
} = require('../controllers/authController');
const { 
    authenticateToken, 
    requireAdmin 
} = require('../middleware/auth');

const router = express.Router();

// Validation rules
const loginValidation = [
    body('username')
        .notEmpty()
        .withMessage('Username is required')
        .isLength({ min: 3, max: 50 })
        .withMessage('Username must be between 3-50 characters'),
    body('password')
        .notEmpty()
        .withMessage('Password is required')
        .isLength({ min: 6 })
        .withMessage('Password must be at least 6 characters')
];

const registerValidation = [
    body('username')
        .notEmpty()
        .withMessage('Username is required')
        .isLength({ min: 3, max: 50 })
        .withMessage('Username must be between 3-50 characters')
        .matches(/^[a-zA-Z0-9_]+$/)
        .withMessage('Username can only contain letters, numbers, and underscores'),
    body('password')
        .notEmpty()
        .withMessage('Password is required')
        .isLength({ min: 6 })
        .withMessage('Password must be at least 6 characters'),
    body('nama')
        .notEmpty()
        .withMessage('Name is required')
        .isLength({ min: 2, max: 100 })
        .withMessage('Name must be between 2-100 characters'),
    body('role')
        .optional()
        .isIn(['admin', 'kasir'])
        .withMessage('Role must be either admin or kasir'),
    body('email')
        .optional()
        .isEmail()
        .withMessage('Invalid email format'),
    body('phone')
        .optional()
        .isMobilePhone('id-ID')
        .withMessage('Invalid Indonesian phone number format')
];

const updateProfileValidation = [
    body('nama')
        .optional()
        .isLength({ min: 2, max: 100 })
        .withMessage('Name must be between 2-100 characters'),
    body('email')
        .optional()
        .isEmail()
        .withMessage('Invalid email format'),
    body('phone')
        .optional()
        .isMobilePhone('id-ID')
        .withMessage('Invalid Indonesian phone number format')
];

const changePasswordValidation = [
    body('currentPassword')
        .notEmpty()
        .withMessage('Current password is required'),
    body('newPassword')
        .notEmpty()
        .withMessage('New password is required')
        .isLength({ min: 6 })
        .withMessage('New password must be at least 6 characters')
];

// Routes

/**
 * @route   POST /api/auth/login
 * @desc    Login user
 * @access  Public
 * @body    { username, password }
 */
router.post('/login', loginValidation, login);

/**
 * @route   POST /api/auth/register
 * @desc    Register new user (Admin only)
 * @access  Private (Admin)
 * @body    { username, password, nama, role?, email?, phone? }
 */
router.post('/register', authenticateToken, requireAdmin, registerValidation, register);

/**
 * @route   GET /api/auth/profile
 * @desc    Get current user profile
 * @access  Private
 */
router.get('/profile', authenticateToken, getProfile);

/**
 * @route   PUT /api/auth/profile
 * @desc    Update user profile
 * @access  Private
 * @body    { nama?, email?, phone? }
 */
router.put('/profile', authenticateToken, updateProfileValidation, updateProfile);

/**
 * @route   POST /api/auth/change-password
 * @desc    Change user password
 * @access  Private
 * @body    { currentPassword, newPassword }
 */
router.post('/change-password', authenticateToken, changePasswordValidation, changePassword);

module.exports = router;