const express = require('express');
const router = express.Router();
const { getBusiness, updateBusiness } = require('../controllers/businessController');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// Get business info (authenticated users)
router.get('/', authenticateToken, getBusiness);

// Update business info (admin only)
router.put('/', authenticateToken, requireAdmin, updateBusiness);

module.exports = router;
