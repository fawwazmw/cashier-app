const mysql = require('mysql2/promise');
require('dotenv').config();

// Database configuration
const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'griyo_pos',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    acquireTimeout: 60000,
    timeout: 60000,
    reconnect: true,
    charset: 'utf8mb4'
};

// Create connection pool
const pool = mysql.createPool(dbConfig);

// Test database connection
const testConnection = async () => {
    try {
        const connection = await pool.getConnection();
        console.log('✅ Database connected successfully');
        console.log(`📊 Connected to: ${process.env.DB_NAME} on ${process.env.DB_HOST}`);
        connection.release();
        return true;
    } catch (error) {
        console.error('❌ Database connection failed:', error.message);
        return false;
    }
};

// Execute query with error handling
const executeQuery = async (query, params = []) => {
    try {
        const [results] = await pool.execute(query, params);
        return { success: true, data: results };
    } catch (error) {
        console.error('Database Query Error:', error);
        return { success: false, error: error.message };
    }
};

// Get single record
const findOne = async (table, conditions = {}, fields = '*') => {
    try {
        let query = `SELECT ${fields} FROM ${table}`;
        let params = [];
        
        if (Object.keys(conditions).length > 0) {
            const whereClause = Object.keys(conditions).map(key => `${key} = ?`).join(' AND ');
            query += ` WHERE ${whereClause}`;
            params = Object.values(conditions);
        }
        
        query += ' LIMIT 1';
        
        const result = await executeQuery(query, params);
        return result.success ? result.data[0] || null : null;
    } catch (error) {
        console.error('FindOne Error:', error);
        return null;
    }
};

// Get multiple records
const findMany = async (table, conditions = {}, options = {}) => {
    try {
        let query = `SELECT ${options.fields || '*'} FROM ${table}`;
        let params = [];
        
        if (Object.keys(conditions).length > 0) {
            const whereClause = Object.keys(conditions).map(key => `${key} = ?`).join(' AND ');
            query += ` WHERE ${whereClause}`;
            params = Object.values(conditions);
        }
        
        if (options.orderBy) {
            query += ` ORDER BY ${options.orderBy}`;
        }
        
        if (options.limit) {
            query += ` LIMIT ${options.limit}`;
        }
        
        if (options.offset) {
            query += ` OFFSET ${options.offset}`;
        }
        
        const result = await executeQuery(query, params);
        return result.success ? result.data : [];
    } catch (error) {
        console.error('FindMany Error:', error);
        return [];
    }
};

// Insert record
const insertRecord = async (table, data) => {
    try {
        const fields = Object.keys(data).join(', ');
        const placeholders = Object.keys(data).map(() => '?').join(', ');
        const values = Object.values(data);
        
        const query = `INSERT INTO ${table} (${fields}) VALUES (${placeholders})`;
        const result = await executeQuery(query, values);
        
        return result.success ? { id: result.data.insertId, ...data } : null;
    } catch (error) {
        console.error('Insert Error:', error);
        return null;
    }
};

// Update record
const updateRecord = async (table, data, conditions) => {
    try {
        const setClause = Object.keys(data).map(key => `${key} = ?`).join(', ');
        const whereClause = Object.keys(conditions).map(key => `${key} = ?`).join(' AND ');
        
        const query = `UPDATE ${table} SET ${setClause} WHERE ${whereClause}`;
        const params = [...Object.values(data), ...Object.values(conditions)];
        
        const result = await executeQuery(query, params);
        return result.success ? result.data.affectedRows > 0 : false;
    } catch (error) {
        console.error('Update Error:', error);
        return false;
    }
};

// Delete record
const deleteRecord = async (table, conditions) => {
    try {
        const whereClause = Object.keys(conditions).map(key => `${key} = ?`).join(' AND ');
        const query = `DELETE FROM ${table} WHERE ${whereClause}`;
        const params = Object.values(conditions);
        
        const result = await executeQuery(query, params);
        return result.success ? result.data.affectedRows > 0 : false;
    } catch (error) {
        console.error('Delete Error:', error);
        return false;
    }
};

// Begin transaction
const beginTransaction = async () => {
    const connection = await pool.getConnection();
    await connection.beginTransaction();
    return connection;
};

// Commit transaction
const commitTransaction = async (connection) => {
    await connection.commit();
    connection.release();
};

// Rollback transaction
const rollbackTransaction = async (connection) => {
    await connection.rollback();
    connection.release();
};

// Close pool
const closePool = async () => {
    await pool.end();
    console.log('📊 Database pool closed');
};

module.exports = {
    pool,
    testConnection,
    executeQuery,
    findOne,
    findMany,
    insertRecord,
    updateRecord,
    deleteRecord,
    beginTransaction,
    commitTransaction,
    rollbackTransaction,
    closePool
};