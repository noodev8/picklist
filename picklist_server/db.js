/*
=======================================================================================================================================
Database Connection Module
=======================================================================================================================================
Purpose: Establishes and manages PostgreSQL database connection for the picklist application
Uses the pg library to connect to PostgreSQL database using environment variables
=======================================================================================================================================
*/

const { Pool } = require('pg');
require('dotenv').config();

// Create a connection pool for better performance and connection management
// Pool automatically handles connection creation, reuse, and cleanup
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    // SSL configuration - try with SSL disabled first, then enable if needed
    ssl: false,
    // Connection pool configuration for optimal performance
    max: 20,                    // Maximum number of connections in the pool
    idleTimeoutMillis: 30000,   // Close idle connections after 30 seconds
    connectionTimeoutMillis: 2000, // Timeout after 2 seconds if no connection available
});

// Test the database connection on startup
pool.on('connect', () => {
    console.log('Connected to PostgreSQL database');
});

// Handle database connection errors
pool.on('error', (err) => {
    console.error('Unexpected error on idle client', err);
    process.exit(-1);
});

// Export the pool for use in other modules
module.exports = pool;
