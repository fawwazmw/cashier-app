const jwt = require('jsonwebtoken');
const { findOne } = require('../config/database');

// Middleware untuk verifikasi JWT token
const authenticateToken = async (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

        if (!token) {
            return res.status(401).json({
                success: false,
                message: 'Access token required'
            });
        }

        // Verify token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // Get user from database
        const user = await findOne('users', { id: decoded.userId, is_active: true });
        
        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Invalid token or user not found'
            });
        }

        // Remove password from user object
        delete user.password;
        
        // Add user to request object
        req.user = user;
        next();
    } catch (error) {
        console.error('Auth middleware error:', error);
        
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({
                success: false,
                message: 'Token expired'
            });
        } else if (error.name === 'JsonWebTokenError') {
            return res.status(401).json({
                success: false,
                message: 'Invalid token'
            });
        }
        
        return res.status(500).json({
            success: false,
            message: 'Authentication failed'
        });
    }
};

// Middleware untuk check role
const requireRole = (roles) => {
    return (req, res, next) => {
        try {
            if (!req.user) {
                return res.status(401).json({
                    success: false,
                    message: 'Authentication required'
                });
            }

            // Convert single role to array
            const allowedRoles = Array.isArray(roles) ? roles : [roles];
            
            if (!allowedRoles.includes(req.user.role)) {
                return res.status(403).json({
                    success: false,
                    message: `Access denied. Required role: ${allowedRoles.join(' or ')}`
                });
            }

            next();
        } catch (error) {
            console.error('Role check error:', error);
            return res.status(500).json({
                success: false,
                message: 'Authorization failed'
            });
        }
    };
};

// Middleware untuk admin only
const requireAdmin = requireRole(['admin']);

// Middleware untuk admin atau kasir
const requireAdminOrKasir = requireRole(['admin', 'kasir']);

// Generate JWT token
const generateToken = (userId, role) => {
    try {
        const payload = {
            userId: userId,
            role: role,
            iat: Math.floor(Date.now() / 1000)
        };

        const options = {
            expiresIn: '24h', // Token expires in 24 hours
            issuer: process.env.APP_NAME || 'GRIYO POS',
            audience: 'griyo-pos-users'
        };

        return jwt.sign(payload, process.env.JWT_SECRET, options);
    } catch (error) {
        console.error('Token generation error:', error);
        return null;
    }
};

// Verify token without middleware (for internal use)
const verifyToken = (token) => {
    try {
        return jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
        console.error('Token verification error:', error);
        return null;
    }
};

// Optional auth - allows access with or without token
const optionalAuth = async (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];

        if (token) {
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            const user = await findOne('users', { id: decoded.userId, is_active: true });
            
            if (user) {
                delete user.password;
                req.user = user;
            }
        }
        
        next();
    } catch (error) {
        // Silent fail for optional auth
        next();
    }
};

module.exports = {
    authenticateToken,
    requireRole,
    requireAdmin,
    requireAdminOrKasir,
    generateToken,
    verifyToken,
    optionalAuth
};