const bcrypt = require('bcryptjs');
const { validationResult } = require('express-validator');
const { findOne, insertRecord } = require('../config/database');
const { generateToken } = require('../middleware/auth');

// Login user
const login = async (req, res) => {
    try {
        // Check for validation errors
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                message: 'Validation failed',
                errors: errors.array()
            });
        }

        const { username, password } = req.body;

        // Find user by username
        const user = await findOne('users', { 
            username: username,
            is_active: true 
        });

        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Username atau password salah'
            });
        }

        // Verify password
        const isValidPassword = await bcrypt.compare(password, user.password);
        
        if (!isValidPassword) {
            return res.status(401).json({
                success: false,
                message: 'Username atau password salah'
            });
        }

        // Generate JWT token
        const token = generateToken(user.id, user.role);
        
        if (!token) {
            return res.status(500).json({
                success: false,
                message: 'Failed to generate token'
            });
        }

        // Remove password from response
        const { password: _, ...userWithoutPassword } = user;

        // Success response
        res.json({
            success: true,
            message: 'Login successful',
            token: token,
            user: {
                id: userWithoutPassword.id,
                username: userWithoutPassword.username,
                nama: userWithoutPassword.nama,
                role: userWithoutPassword.role,
                email: userWithoutPassword.email,
                phone: userWithoutPassword.phone,
                created_at: userWithoutPassword.created_at
            }
        });

        console.log(`✅ Login successful: ${username} (${user.role})`);

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
};

// Register new user (admin only)
const register = async (req, res) => {
    try {
        // Check for validation errors
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                message: 'Validation failed',
                errors: errors.array()
            });
        }

        const { username, password, nama, role, email, phone } = req.body;

        // Check if username already exists
        const existingUser = await findOne('users', { username });
        
        if (existingUser) {
            return res.status(400).json({
                success: false,
                message: 'Username sudah digunakan'
            });
        }

        // Hash password
        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(password, saltRounds);

        // Create user data
        const userData = {
            username,
            password: hashedPassword,
            nama,
            role: role || 'kasir',
            email: email || null,
            phone: phone || null,
            is_active: true
        };

        // Insert user to database
        const newUser = await insertRecord('users', userData);

        if (!newUser) {
            return res.status(500).json({
                success: false,
                message: 'Failed to create user'
            });
        }

        // Remove password from response
        const { password: _, ...userResponse } = newUser;

        res.status(201).json({
            success: true,
            message: 'User created successfully',
            user: userResponse
        });

        console.log(`✅ New user registered: ${username} (${role || 'kasir'})`);

    } catch (error) {
        console.error('Register error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
};

// Get current user profile
const getProfile = async (req, res) => {
    try {
        // User already attached by auth middleware
        const user = req.user;

        res.json({
            success: true,
            user: {
                id: user.id,
                username: user.username,
                nama: user.nama,
                role: user.role,
                email: user.email,
                phone: user.phone,
                created_at: user.created_at
            }
        });

    } catch (error) {
        console.error('Get profile error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
};

// Update user profile
const updateProfile = async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                message: 'Validation failed',
                errors: errors.array()
            });
        }

        const userId = req.user.id;
        const { nama, email, phone } = req.body;

        // Prepare update data
        const updateData = {};
        if (nama) updateData.nama = nama;
        if (email) updateData.email = email;
        if (phone) updateData.phone = phone;

        // Update user
        const { updateRecord } = require('../config/database');
        const updated = await updateRecord('users', updateData, { id: userId });

        if (!updated) {
            return res.status(500).json({
                success: false,
                message: 'Failed to update profile'
            });
        }

        // Get updated user
        const updatedUser = await findOne('users', { id: userId });
        const { password: _, ...userResponse } = updatedUser;

        res.json({
            success: true,
            message: 'Profile updated successfully',
            user: userResponse
        });

    } catch (error) {
        console.error('Update profile error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
};

// Change password
const changePassword = async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                message: 'Validation failed',
                errors: errors.array()
            });
        }

        const userId = req.user.id;
        const { currentPassword, newPassword } = req.body;

        // Get user with password
        const user = await findOne('users', { id: userId });

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        // Verify current password
        const isValidPassword = await bcrypt.compare(currentPassword, user.password);
        
        if (!isValidPassword) {
            return res.status(400).json({
                success: false,
                message: 'Password saat ini salah'
            });
        }

        // Hash new password
        const saltRounds = 10;
        const hashedNewPassword = await bcrypt.hash(newPassword, saltRounds);

        // Update password
        const { updateRecord } = require('../config/database');
        const updated = await updateRecord('users', 
            { password: hashedNewPassword }, 
            { id: userId }
        );

        if (!updated) {
            return res.status(500).json({
                success: false,
                message: 'Failed to change password'
            });
        }

        res.json({
            success: true,
            message: 'Password changed successfully'
        });

    } catch (error) {
        console.error('Change password error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
};

module.exports = {
    login,
    register,
    getProfile,
    updateProfile,
    changePassword
};