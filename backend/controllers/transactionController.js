const { validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const moment = require('moment');
const { 
    findMany, 
    findOne, 
    insertRecord, 
    updateRecord, 
    executeQuery,
    beginTransaction,
    commitTransaction,
    rollbackTransaction
} = require('../config/database');

// Create new transaction
const createTransaction = async (req, res) => {
    let connection = null;
    
    try {
        // Debug: log received data
        console.log('📦 Received transaction data:', JSON.stringify(req.body, null, 2));
        
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            console.log('❌ Validation errors:', JSON.stringify(errors.array(), null, 2));
            return res.status(400).json({
                success: false,
                message: 'Validation failed',
                errors: errors.array()
            });
        }

        const { 
            total, 
            payment_method, 
            customer_name, 
            customer_phone, 
            items,
            notes 
        } = req.body;

        // Validate items
        if (!items || !Array.isArray(items) || items.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Transaction items are required'
            });
        }

        // Start transaction
        connection = await beginTransaction();

        // Generate transaction ID
        const transactionId = `TRX${Date.now()}${Math.random().toString(36).substr(2, 3).toUpperCase()}`;

        // Validate and check stock for each item
        let calculatedTotal = 0;
        const validatedItems = [];

        for (const item of items) {
            const product = await findOne('products', {
                id: parseInt(item.product_id),
                is_active: true
            });

            if (!product) {
                await rollbackTransaction(connection);
                return res.status(400).json({
                    success: false,
                    message: `Product with ID ${item.product_id} not found`
                });
            }

            if (product.stok < parseInt(item.qty)) {
                await rollbackTransaction(connection);
                return res.status(400).json({
                    success: false,
                    message: `Insufficient stock for ${product.nama}. Available: ${product.stok}, Requested: ${item.qty}`
                });
            }

            const subtotal = product.harga * parseInt(item.qty);
            calculatedTotal += subtotal;

            validatedItems.push({
                product_id: product.id,
                product_name: product.nama,
                qty: parseInt(item.qty),
                harga: product.harga,
                subtotal: subtotal
            });

            // Update product stock
            const newStock = product.stok - parseInt(item.qty);
            const stockQuery = 'UPDATE products SET stok = ? WHERE id = ?';
            await connection.execute(stockQuery, [newStock, product.id]);
        }

        // Verify total amount
        if (Math.abs(calculatedTotal - parseFloat(total)) > 0.01) {
            await rollbackTransaction(connection);
            return res.status(400).json({
                success: false,
                message: `Total amount mismatch. Expected: ${calculatedTotal}, Received: ${total}`
            });
        }

        // Insert transaction
        const transactionData = {
            id: transactionId,
            user_id: req.user.id,
            total: calculatedTotal,
            status: 'pending',
            payment_method: payment_method,
            customer_name: customer_name || null,
            customer_phone: customer_phone || null,
            notes: notes || null
        };

        const insertTransactionQuery = `
            INSERT INTO transactions (id, user_id, total, status, payment_method, customer_name, customer_phone, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `;
        
        await connection.execute(insertTransactionQuery, [
            transactionData.id,
            transactionData.user_id,
            transactionData.total,
            transactionData.status,
            transactionData.payment_method,
            transactionData.customer_name,
            transactionData.customer_phone,
            transactionData.notes
        ]);

        // Insert transaction items
        for (const item of validatedItems) {
            const insertItemQuery = `
                INSERT INTO transaction_items (transaction_id, product_id, product_name, qty, harga, subtotal)
                VALUES (?, ?, ?, ?, ?, ?)
            `;
            
            await connection.execute(insertItemQuery, [
                transactionId,
                item.product_id,
                item.product_name,
                item.qty,
                item.harga,
                item.subtotal
            ]);
        }

        // Commit transaction
        await commitTransaction(connection);

        // Get complete transaction data
        const completeTransaction = await getTransactionById(transactionId);

        res.status(201).json({
            success: true,
            message: 'Transaction created successfully',
            transaction: completeTransaction
        });

        console.log(`✅ Transaction created: ${transactionId} by user ${req.user.username}`);

    } catch (error) {
        if (connection) {
            await rollbackTransaction(connection);
        }
        
        console.error('Create transaction error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create transaction'
        });
    }
};

// Get transactions with filtering
const getTransactions = async (req, res) => {
    try {
        const {
            status,
            payment_method,
            user_id,
            date_from,
            date_to,
            search,
            limit = 50,
            offset = 0,
            orderBy = 'created_at',
            orderDir = 'DESC'
        } = req.query;

        let query = `
            SELECT t.*, u.nama as user_name
            FROM transactions t
            LEFT JOIN users u ON t.user_id = u.id
            WHERE 1=1
        `;
        let params = [];

        // Filter by status
        if (status && status !== 'Semua') {
            query += ' AND t.status = ?';
            params.push(status);
        }

        // Filter by payment method
        if (payment_method) {
            query += ' AND t.payment_method = ?';
            params.push(payment_method);
        }

        // Filter by user (for non-admin users, only show their transactions)
        if (req.user.role === 'kasir') {
            query += ' AND t.user_id = ?';
            params.push(req.user.id);
        } else if (user_id) {
            query += ' AND t.user_id = ?';
            params.push(parseInt(user_id));
        }

        // Filter by date range
        if (date_from) {
            query += ' AND DATE(t.created_at) >= ?';
            params.push(date_from);
        }

        if (date_to) {
            query += ' AND DATE(t.created_at) <= ?';
            params.push(date_to);
        }

        // Search by transaction ID or customer name
        if (search) {
            query += ' AND (t.id LIKE ? OR t.customer_name LIKE ?)';
            params.push(`%${search}%`, `%${search}%`);
        }

        // Add ordering
        const validOrderBy = ['created_at', 'total', 'status', 'id'];
        const validOrderDir = ['ASC', 'DESC'];
        
        if (validOrderBy.includes(orderBy) && validOrderDir.includes(orderDir.toUpperCase())) {
            query += ` ORDER BY t.${orderBy} ${orderDir.toUpperCase()}`;
        }

        // Add pagination (avoid placeholders for LIMIT/OFFSET on some MySQL setups)
        const limitNum = Math.max(1, parseInt(limit));
        const offsetNum = Math.max(0, parseInt(offset));
        query += ` LIMIT ${limitNum} OFFSET ${offsetNum}`;

        const result = await executeQuery(query, params);
        
        if (!result.success) {
            throw new Error(result.error);
        }

        // Get transaction items for each transaction
        const transactions = await Promise.all(
            result.data.map(async (transaction) => {
                const items = await getTransactionItems(transaction.id);
                return {
                    ...transaction,
                    items: items
                };
            })
        );

        // Get total count for pagination
        let countQuery = 'SELECT COUNT(*) as total FROM transactions t WHERE 1=1';
        let countParams = [];

        if (status && status !== 'Semua') {
            countQuery += ' AND t.status = ?';
            countParams.push(status);
        }

        if (payment_method) {
            countQuery += ' AND t.payment_method = ?';
            countParams.push(payment_method);
        }

        if (req.user.role === 'kasir') {
            countQuery += ' AND t.user_id = ?';
            countParams.push(req.user.id);
        } else if (user_id) {
            countQuery += ' AND t.user_id = ?';
            countParams.push(parseInt(user_id));
        }

        if (date_from) {
            countQuery += ' AND DATE(t.created_at) >= ?';
            countParams.push(date_from);
        }

        if (date_to) {
            countQuery += ' AND DATE(t.created_at) <= ?';
            countParams.push(date_to);
        }

        if (search) {
            countQuery += ' AND (t.id LIKE ? OR t.customer_name LIKE ?)';
            countParams.push(`%${search}%`, `%${search}%`);
        }

        const countResult = await executeQuery(countQuery, countParams);
        const total = countResult.success ? countResult.data[0].total : 0;

        res.json({
            success: true,
            data: transactions,
            pagination: {
                total: total,
                limit: parseInt(limit),
                offset: parseInt(offset),
                hasMore: (parseInt(offset) + parseInt(limit)) < total
            }
        });

    } catch (error) {
        console.error('Get transactions error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch transactions'
        });
    }
};

// Get single transaction
const getTransaction = async (req, res) => {
    try {
        const { id } = req.params;

        const transaction = await getTransactionById(id);

        if (!transaction) {
            return res.status(404).json({
                success: false,
                message: 'Transaction not found'
            });
        }

        // Check permission - kasir can only view their own transactions
        if (req.user.role === 'kasir' && transaction.user_id !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'Access denied'
            });
        }

        res.json({
            success: true,
            data: transaction
        });

    } catch (error) {
        console.error('Get transaction error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch transaction'
        });
    }
};

// Update transaction status
const updateTransactionStatus = async (req, res) => {
    let connection = null;
    
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
        const { status } = req.body;

        const validStatuses = ['pending', 'paid', 'cancelled'];
        if (!validStatuses.includes(status)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid status. Valid statuses: ' + validStatuses.join(', ')
            });
        }

        // Get existing transaction
        const existingTransaction = await getTransactionById(id);

        if (!existingTransaction) {
            return res.status(404).json({
                success: false,
                message: 'Transaction not found'
            });
        }

        // Check permission - kasir can only update their own transactions
        if (req.user.role === 'kasir' && existingTransaction.user_id !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'Access denied'
            });
        }

        // Don't allow status change if already paid or cancelled
        if (existingTransaction.status === 'paid' || existingTransaction.status === 'cancelled') {
            return res.status(400).json({
                success: false,
                message: `Cannot change status from ${existingTransaction.status}`
            });
        }

        // Start transaction for stock adjustment
        connection = await beginTransaction();

        // If changing to cancelled, restore stock
        if (status === 'cancelled' && existingTransaction.status === 'pending') {
            for (const item of existingTransaction.items) {
                const currentProduct = await findOne('products', { id: item.product_id });
                if (currentProduct) {
                    const newStock = currentProduct.stok + item.qty;
                    const stockQuery = 'UPDATE products SET stok = ? WHERE id = ?';
                    await connection.execute(stockQuery, [newStock, currentProduct.id]);
                }
            }
        }

        // Update transaction status
        const updateQuery = 'UPDATE transactions SET status = ? WHERE id = ?';
        await connection.execute(updateQuery, [status, id]);

        await commitTransaction(connection);

        // Get updated transaction
        const updatedTransaction = await getTransactionById(id);

        res.json({
            success: true,
            message: 'Transaction status updated successfully',
            transaction: updatedTransaction
        });

        console.log(`✅ Transaction status updated: ${id} → ${status} by user ${req.user.username}`);

    } catch (error) {
        if (connection) {
            await rollbackTransaction(connection);
        }
        
        console.error('Update transaction status error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update transaction status'
        });
    }
};

// Get sales summary
const getSalesSummary = async (req, res) => {
    try {
        const { date = moment().format('YYYY-MM-DD') } = req.query;

        // Daily sales summary
        const dailySalesQuery = `
            SELECT 
                COUNT(*) as total_transactions,
                SUM(total) as total_sales,
                AVG(total) as average_transaction,
                payment_method,
                COUNT(*) as method_count
            FROM transactions 
            WHERE DATE(created_at) = ? AND status = 'paid'
            GROUP BY payment_method
        `;

        const dailySalesResult = await executeQuery(dailySalesQuery, [date]);

        // Top selling products
        const topProductsQuery = `
            SELECT 
                ti.product_name,
                SUM(ti.qty) as total_qty,
                SUM(ti.subtotal) as total_revenue,
                COUNT(DISTINCT ti.transaction_id) as transaction_count
            FROM transaction_items ti
            JOIN transactions t ON ti.transaction_id = t.id
            WHERE DATE(t.created_at) = ? AND t.status = 'paid'
            GROUP BY ti.product_id, ti.product_name
            ORDER BY total_qty DESC
            LIMIT 10
        `;

        const topProductsResult = await executeQuery(topProductsQuery, [date]);

        // Hourly sales
        const hourlySalesQuery = `
            SELECT 
                HOUR(created_at) as hour,
                COUNT(*) as transactions,
                SUM(total) as sales
            FROM transactions 
            WHERE DATE(created_at) = ? AND status = 'paid'
            GROUP BY HOUR(created_at)
            ORDER BY hour
        `;

        const hourlySalesResult = await executeQuery(hourlySalesQuery, [date]);

        // Calculate totals
        const summary = dailySalesResult.success ? dailySalesResult.data : [];
        const totalTransactions = summary.reduce((sum, row) => sum + row.method_count, 0);
        const totalSales = summary.reduce((sum, row) => sum + row.total_sales, 0);

        res.json({
            success: true,
            date: date,
            summary: {
                total_transactions: totalTransactions,
                total_sales: totalSales,
                average_transaction: totalTransactions > 0 ? totalSales / totalTransactions : 0,
                payment_methods: summary
            },
            top_products: topProductsResult.success ? topProductsResult.data : [],
            hourly_sales: hourlySalesResult.success ? hourlySalesResult.data : []
        });

    } catch (error) {
        console.error('Get sales summary error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch sales summary'
        });
    }
};

// Helper function to get transaction by ID with items
const getTransactionById = async (id) => {
    try {
        const transactionQuery = `
            SELECT t.*, u.nama as user_name
            FROM transactions t
            LEFT JOIN users u ON t.user_id = u.id
            WHERE t.id = ?
        `;
        
        const transactionResult = await executeQuery(transactionQuery, [id]);
        
        if (!transactionResult.success || transactionResult.data.length === 0) {
            return null;
        }

        const transaction = transactionResult.data[0];
        const items = await getTransactionItems(id);

        return {
            ...transaction,
            items: items
        };
    } catch (error) {
        console.error('Get transaction by ID error:', error);
        return null;
    }
};

// Helper function to get transaction items
const getTransactionItems = async (transactionId) => {
    try {
        const itemsQuery = `
            SELECT * FROM transaction_items 
            WHERE transaction_id = ?
            ORDER BY id
        `;
        
        const itemsResult = await executeQuery(itemsQuery, [transactionId]);
        
        return itemsResult.success ? itemsResult.data : [];
    } catch (error) {
        console.error('Get transaction items error:', error);
        return [];
    }
};

module.exports = {
    createTransaction,
    getTransactions,
    getTransaction,
    updateTransactionStatus,
    getSalesSummary
};