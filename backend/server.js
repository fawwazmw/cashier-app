const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// Import database and middleware
const { testConnection, closePool } = require('./config/database');

// Import routes
const authRoutes = require('./routes/auth');
const productRoutes = require('./routes/products');
const transactionRoutes = require('./routes/transactions');
const paymentRoutes = require('./routes/payment');
const businessRoutes = require('./routes/business');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 8000;

// Security middleware
app.use(helmet({
    contentSecurityPolicy: false, // Disable for development
    crossOriginEmbedderPolicy: false
}));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 1000, // Limit each IP to 1000 requests per windowMs
    message: {
        success: false,
        message: 'Too many requests from this IP, please try again later.'
    },
    standardHeaders: true,
    legacyHeaders: false,
});

app.use('/api/', limiter);

// CORS configuration
const corsOptions = {
    origin: function (origin, callback) {
        // Allow requests with no origin (like mobile apps or curl requests)
        if (!origin) return callback(null, true);
        
        const allowedOrigins = [
            'http://localhost:3000',     // React dev
            'http://localhost:8080',     // Vue dev
            'http://localhost:4200',     // Angular dev
            'http://localhost',          // Flutter web dev
            process.env.FRONTEND_URL     // Production frontend
        ];
        
        if (allowedOrigins.includes(origin)) {
            return callback(null, true);
        }
        
        // For development, allow any origin
        if (process.env.NODE_ENV === 'development') {
            return callback(null, true);
        }
        
        const msg = 'The CORS policy for this site does not allow access from the specified Origin.';
        return callback(new Error(msg), false);
    },
    credentials: true,
    optionsSuccessStatus: 200,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
};

app.use(cors(corsOptions));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware
app.use((req, res, next) => {
    const timestamp = new Date().toISOString();
    console.log(`${timestamp} - ${req.method} ${req.path} - ${req.ip}`);
    next();
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        success: true,
        message: 'GRIYO POS API is running',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        environment: process.env.NODE_ENV || 'development'
    });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/business', businessRoutes);

// Welcome endpoint
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'Welcome to GRIYO POS API',
        version: '1.0.0',
        documentation: {
            auth: '/api/auth',
            products: '/api/products',
            transactions: '/api/transactions',
            payment: '/api/payment'
        },
        endpoints: {
            health_check: '/health',
            api_docs: '/api-docs'
        }
    });
});

// API documentation endpoint
app.get('/api-docs', (req, res) => {
    res.json({
        success: true,
        title: 'GRIYO POS API Documentation',
        version: '1.0.0',
        base_url: `${req.protocol}://${req.get('host')}/api`,
        authentication: 'Bearer Token (JWT)',
        endpoints: {
            authentication: {
                login: 'POST /auth/login',
                register: 'POST /auth/register (Admin only)',
                profile: 'GET /auth/profile',
                update_profile: 'PUT /auth/profile',
                change_password: 'POST /auth/change-password'
            },
            products: {
                list: 'GET /products',
                create: 'POST /products (Admin only)',
                get: 'GET /products/:id',
                update: 'PUT /products/:id (Admin only)',
                delete: 'DELETE /products/:id (Admin only)',
                categories: 'GET /products/categories',
                low_stock: 'GET /products/low-stock',
                update_stock: 'PUT /products/:id/stock (Admin only)'
            },
            transactions: {
                list: 'GET /transactions',
                create: 'POST /transactions',
                get: 'GET /transactions/:id',
                update_status: 'PUT /transactions/:id/status',
                summary: 'GET /transactions/summary'
            },
            payment: {
                methods: 'GET /payment/methods',
                create_token: 'POST /payment/create-token',
                check_status: 'GET /payment/status/:transaction_id',
                cancel: 'POST /payment/cancel/:transaction_id',
                notification: 'POST /payment/notification (Webhook)'
            }
        },
        roles: {
            admin: 'Full access to all endpoints',
            kasir: 'Limited access - cannot manage products, can only view own transactions'
        }
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        success: false,
        message: 'Endpoint not found',
        path: req.originalUrl,
        method: req.method
    });
});

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('Error occurred:', error);
    
    // Handle specific error types
    if (error.type === 'entity.parse.failed') {
        return res.status(400).json({
            success: false,
            message: 'Invalid JSON format'
        });
    }
    
    if (error.type === 'entity.too.large') {
        return res.status(413).json({
            success: false,
            message: 'Request entity too large'
        });
    }
    
    // CORS error
    if (error.message && error.message.includes('CORS')) {
        return res.status(403).json({
            success: false,
            message: 'CORS policy violation'
        });
    }
    
    // Generic error response
    res.status(error.status || 500).json({
        success: false,
        message: error.message || 'Internal server error',
        ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
});

// Graceful shutdown
const gracefulShutdown = async (signal) => {
    console.log(`\n📢 Received ${signal}. Shutting down gracefully...`);
    
    try {
        // Close database connection
        await closePool();
        console.log('✅ Database connections closed');
        
        // Close server
        process.exit(0);
    } catch (error) {
        console.error('❌ Error during shutdown:', error);
        process.exit(1);
    }
};

// Handle shutdown signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
    console.error('❌ Uncaught Exception:', error);
    process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
    process.exit(1);
});

// Start server
const startServer = async () => {
    try {
        // Test database connection
        const dbConnected = await testConnection();
        
        if (!dbConnected) {
            console.error('❌ Failed to connect to database. Exiting...');
            process.exit(1);
        }
        
        // Start HTTP server
        app.listen(PORT, () => {
            console.log('\n🚀 GRIYO POS API Server Started');
            console.log(`📍 Server URL: http://localhost:${PORT}`);
            console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
            console.log(`📖 API Documentation: http://localhost:${PORT}/api-docs`);
            console.log(`❤️  Health Check: http://localhost:${PORT}/health`);
            console.log('\n📚 Available Endpoints:');
            console.log('   🔐 Auth: /api/auth');
            console.log('   📦 Products: /api/products');
            console.log('   💳 Transactions: /api/transactions');
            console.log('   💰 Payment: /api/payment');
            console.log('\n✨ Server is ready to accept connections!');
        });
        
    } catch (error) {
        console.error('❌ Failed to start server:', error);
        process.exit(1);
    }
};

// Start the server
startServer();