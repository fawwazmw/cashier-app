const midtransClient = require('midtrans-client');
const { v4: uuidv4 } = require('uuid');
const { findOne, updateRecord, executeQuery } = require('../config/database');

// Initialize Midtrans client
const snap = new midtransClient.Snap({
    isProduction: process.env.MIDTRANS_IS_PRODUCTION === 'true',
    serverKey: process.env.MIDTRANS_SERVER_KEY,
    clientKey: process.env.MIDTRANS_CLIENT_KEY
});

// Create payment token for MIDTRANS
const createPaymentToken = async (req, res) => {
    try {
        const { transaction_id, customer_details } = req.body;

        // Get transaction details
        const transactionQuery = `
            SELECT t.*, ti.product_name, ti.qty, ti.harga, ti.subtotal
            FROM transactions t
            LEFT JOIN transaction_items ti ON t.id = ti.transaction_id
            WHERE t.id = ?
        `;

        const transactionResult = await executeQuery(transactionQuery, [transaction_id]);

        if (!transactionResult.success || transactionResult.data.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Transaction not found'
            });
        }

        const transactionData = transactionResult.data[0];
        const items = transactionResult.data;

        // Check if transaction belongs to current user (for kasir)
        if (req.user.role === 'kasir' && transactionData.user_id !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'Access denied'
            });
        }

        // Check transaction status
        if (transactionData.status !== 'pending') {
            return res.status(400).json({
                success: false,
                message: `Transaction is already ${transactionData.status}`
            });
        }

        // Prepare MIDTRANS parameters
        const parameter = {
            transaction_details: {
                order_id: transaction_id,
                gross_amount: Math.round(transactionData.total)
            },
            credit_card: {
                secure: true
            },
            customer_details: customer_details || {
                first_name: transactionData.customer_name || 'Customer',
                email: 'customer@griyopos.com',
                phone: transactionData.customer_phone || '08123456789'
            },
            item_details: items.map(item => ({
                id: item.product_id,
                price: Math.round(item.harga),
                quantity: item.qty,
                name: item.product_name
            })),
            callbacks: {
                finish: `${process.env.APP_URL}/payment/finish`,
                error: `${process.env.APP_URL}/payment/error`,
                pending: `${process.env.APP_URL}/payment/pending`
            }
        };

        // Create transaction token
        const transaction = await snap.createTransaction(parameter);

        // Update transaction with payment token
        const updated = await updateRecord('transactions', 
            { payment_token: transaction.token },
            { id: transaction_id }
        );

        if (!updated) {
            return res.status(500).json({
                success: false,
                message: 'Failed to update payment token'
            });
        }

        res.json({
            success: true,
            token: transaction.token,
            redirect_url: transaction.redirect_url,
            transaction_id: transaction_id
        });

        console.log(`✅ Payment token created for transaction: ${transaction_id}`);

    } catch (error) {
        console.error('Create payment token error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create payment token',
            error: error.message
        });
    }
};

// Handle MIDTRANS notification webhook
const handleNotification = async (req, res) => {
    try {
        const notification = req.body;
        
        // Verify notification signature
        const statusResponse = await snap.transaction.notification(notification);
        
        const orderId = statusResponse.order_id;
        const transactionStatus = statusResponse.transaction_status;
        const fraudStatus = statusResponse.fraud_status;

        console.log(`📧 Payment notification received:`, {
            order_id: orderId,
            transaction_status: transactionStatus,
            fraud_status: fraudStatus
        });

        // Determine payment status
        let paymentStatus = 'pending';

        if (transactionStatus === 'capture') {
            if (fraudStatus === 'challenge') {
                paymentStatus = 'pending';
            } else if (fraudStatus === 'accept') {
                paymentStatus = 'paid';
            }
        } else if (transactionStatus === 'settlement') {
            paymentStatus = 'paid';
        } else if (transactionStatus === 'deny' || 
                   transactionStatus === 'cancel' || 
                   transactionStatus === 'expire') {
            paymentStatus = 'cancelled';
        } else if (transactionStatus === 'pending') {
            paymentStatus = 'pending';
        }

        // Update transaction status
        const updated = await updateRecord('transactions', 
            { status: paymentStatus },
            { id: orderId }
        );

        if (updated) {
            console.log(`✅ Transaction ${orderId} updated to ${paymentStatus}`);
        } else {
            console.log(`❌ Failed to update transaction ${orderId}`);
        }

        // Send response to MIDTRANS
        res.json({
            success: true,
            message: 'Notification processed successfully'
        });

    } catch (error) {
        console.error('Handle notification error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to process notification'
        });
    }
};

// Check payment status
const checkPaymentStatus = async (req, res) => {
    try {
        const { transaction_id } = req.params;

        // Get transaction from database
        const transaction = await findOne('transactions', { id: transaction_id });

        if (!transaction) {
            return res.status(404).json({
                success: false,
                message: 'Transaction not found'
            });
        }

        // Check permission
        if (req.user.role === 'kasir' && transaction.user_id !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'Access denied'
            });
        }

        let midtransStatus = null;

        // Check status from MIDTRANS if payment token exists
        if (transaction.payment_token && transaction.payment_method === 'midtrans') {
            try {
                midtransStatus = await snap.transaction.status(transaction_id);
                
                // Update local status based on MIDTRANS status
                let newStatus = transaction.status;
                
                if (midtransStatus.transaction_status === 'settlement' || 
                    (midtransStatus.transaction_status === 'capture' && midtransStatus.fraud_status === 'accept')) {
                    newStatus = 'paid';
                } else if (midtransStatus.transaction_status === 'deny' || 
                          midtransStatus.transaction_status === 'cancel' || 
                          midtransStatus.transaction_status === 'expire') {
                    newStatus = 'cancelled';
                } else if (midtransStatus.transaction_status === 'pending') {
                    newStatus = 'pending';
                }

                // Update if status changed
                if (newStatus !== transaction.status) {
                    await updateRecord('transactions', 
                        { status: newStatus },
                        { id: transaction_id }
                    );
                    transaction.status = newStatus;
                }

            } catch (midtransError) {
                console.error('MIDTRANS status check error:', midtransError);
                // Continue with local status if MIDTRANS check fails
            }
        }

        res.json({
            success: true,
            transaction_id: transaction_id,
            status: transaction.status,
            payment_method: transaction.payment_method,
            midtrans_status: midtransStatus ? {
                transaction_status: midtransStatus.transaction_status,
                fraud_status: midtransStatus.fraud_status,
                payment_type: midtransStatus.payment_type
            } : null
        });

    } catch (error) {
        console.error('Check payment status error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to check payment status'
        });
    }
};

// Cancel payment
const cancelPayment = async (req, res) => {
    try {
        const { transaction_id } = req.params;

        // Get transaction from database
        const transaction = await findOne('transactions', { id: transaction_id });

        if (!transaction) {
            return res.status(404).json({
                success: false,
                message: 'Transaction not found'
            });
        }

        // Check permission
        if (req.user.role === 'kasir' && transaction.user_id !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'Access denied'
            });
        }

        // Check if transaction can be cancelled
        if (transaction.status === 'paid') {
            return res.status(400).json({
                success: false,
                message: 'Cannot cancel paid transaction'
            });
        }

        // Cancel in MIDTRANS if it's a MIDTRANS transaction
        if (transaction.payment_method === 'midtrans' && transaction.payment_token) {
            try {
                await snap.transaction.cancel(transaction_id);
                console.log(`✅ Payment cancelled in MIDTRANS: ${transaction_id}`);
            } catch (midtransError) {
                console.error('MIDTRANS cancel error:', midtransError);
                // Continue with local cancellation even if MIDTRANS cancel fails
            }
        }

        // Update transaction status to cancelled
        const updated = await updateRecord('transactions', 
            { status: 'cancelled' },
            { id: transaction_id }
        );

        if (!updated) {
            return res.status(500).json({
                success: false,
                message: 'Failed to cancel transaction'
            });
        }

        // TODO: Restore product stock here if needed
        // This should be handled by the updateTransactionStatus endpoint

        res.json({
            success: true,
            message: 'Payment cancelled successfully',
            transaction_id: transaction_id
        });

        console.log(`✅ Payment cancelled: ${transaction_id} by user ${req.user.username}`);

    } catch (error) {
        console.error('Cancel payment error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to cancel payment'
        });
    }
};

// Get payment methods
const getPaymentMethods = async (req, res) => {
    try {
        const paymentMethods = [
            {
                code: 'cash',
                name: 'Tunai',
                description: 'Pembayaran tunai',
                enabled: true
            },
            {
                code: 'midtrans',
                name: 'MIDTRANS',
                description: 'Kartu kredit, transfer bank, e-wallet',
                enabled: process.env.MIDTRANS_SERVER_KEY ? true : false,
                methods: [
                    'Credit Card',
                    'Bank Transfer (BCA, BNI, BRI, Mandiri)',
                    'E-Wallet (GoPay, OVO, Dana)',
                    'Virtual Account',
                    'Convenience Store'
                ]
            }
        ];

        res.json({
            success: true,
            payment_methods: paymentMethods
        });

    } catch (error) {
        console.error('Get payment methods error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch payment methods'
        });
    }
};

// Payment finish callback (for web)
const paymentFinish = (req, res) => {
    res.send(`
        <html>
        <head><title>Payment Complete</title></head>
        <body>
            <h2>Payment Process Complete</h2>
            <p>Please check your transaction status in the app.</p>
            <script>
                setTimeout(() => {
                    window.close();
                }, 3000);
            </script>
        </body>
        </html>
    `);
};

// Payment error callback (for web)
const paymentError = (req, res) => {
    res.send(`
        <html>
        <head><title>Payment Error</title></head>
        <body>
            <h2>Payment Error</h2>
            <p>There was an error processing your payment. Please try again.</p>
            <script>
                setTimeout(() => {
                    window.close();
                }, 3000);
            </script>
        </body>
        </html>
    `);
};

// Payment pending callback (for web)
const paymentPending = (req, res) => {
    res.send(`
        <html>
        <head><title>Payment Pending</title></head>
        <body>
            <h2>Payment Pending</h2>
            <p>Your payment is being processed. Please wait for confirmation.</p>
            <script>
                setTimeout(() => {
                    window.close();
                }, 3000);
            </script>
        </body>
        </html>
    `);
};

module.exports = {
    createPaymentToken,
    handleNotification,
    checkPaymentStatus,
    cancelPayment,
    getPaymentMethods,
    paymentFinish,
    paymentError,
    paymentPending
};