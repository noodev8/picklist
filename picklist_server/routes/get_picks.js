/*
=======================================================================================================================================
API Route: get_picks
=======================================================================================================================================
Method: POST
Purpose: Retrieves all available picks from the database. Returns picks that need to be picked (qty=1, ordernum!='#FREE')
         with location details and brand information for warehouse picking operations.
=======================================================================================================================================
Request Payload:
{
  // No required parameters - returns all available picks
  "location_filter": "C3-Front"    // optional, string, filter picks by location containing this text
}

Success Response:
{
  "return_code": "SUCCESS",
  "picks": [
    {
      "id": "unique_id_123",           // string, unique identifier from localstock table
      "code": "SHOE123",               // string, the actual shoe code being picked
      "ordernum": "BC001234",          // string, order number (not '#FREE')
      "location": "C3-Front-Rack-01",  // string, exact location of the pick
      "groupid": "GRP123",             // string, group identifier for linking with other tables
      "brand": "Nike",                 // string, brand of the shoe
      "supplier": "MainSupplier",      // string, supplier information from skusummary
      "qty": 1,                        // integer, quantity to pick (always 1 for picks)
      "pickorder": 1                   // integer, suggested pick order for efficiency
    }
  ],
  "total_picks": 25                    // integer, total number of picks available
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"DATABASE_ERROR"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');

// POST /get_picks
router.post('/', async (req, res) => {
    try {
        console.log('🔍 DEBUG Server: get_picks API called');
        console.log('🔍 DEBUG Server: Request body:', req.body);

        // Safely extract optional location filter from request body
        // Handle cases where req.body might be undefined or null
        const location_filter = req.body && req.body.location_filter ? req.body.location_filter : null;

        console.log('🔍 DEBUG Server: Location filter:', location_filter);

        // Optional: Add location filter if provided
        if (location_filter) {
            console.log('🔍 DEBUG Server: Will filter by location containing:', location_filter);
        } else {
            console.log('🔍 DEBUG Server: No location filter - returning all picks');
        }
        
        // Build the SQL query to get all available picks
        // Join localstock with skusummary to get additional details like supplier
        let query = `
            SELECT 
                l.id,
                l.code,
                l.ordernum,
                l.location,
                l.groupid,
                l.brand,
                l.qty,
                l.pickorder,
                s.supplier
            FROM localstock l
            LEFT JOIN skusummary s ON l.groupid = s.groupid
            WHERE l.ordernum != '#FREE' 
            AND l.qty = 1
            AND (l.deleted IS NULL OR l.deleted = 0)
        `;
        
        // Array to hold query parameters
        let queryParams = [];
        
        // Add location filter if provided
        if (location_filter && location_filter.trim() !== '') {
            query += ` AND l.location ILIKE $1`;
            queryParams.push(`%${location_filter.trim()}%`);
        }
        
        // Order by location for better picking workflow
        // This groups picks by location so pickers can work efficiently
        query += ` ORDER BY l.location, l.pickorder, l.code`;

        console.log('🔍 DEBUG Server: Final SQL query:', query);
        console.log('🔍 DEBUG Server: Query parameters:', queryParams);

        // Execute the query
        const result = await pool.query(query, queryParams);

        console.log('🔍 DEBUG Server: Query executed successfully');
        console.log('🔍 DEBUG Server: Number of rows returned:', result.rows.length);
        console.log('🔍 DEBUG Server: First few rows:', result.rows.slice(0, 2));

        // Format the response data
        const picks = result.rows.map(row => ({
            id: row.id,
            code: row.code,
            ordernum: row.ordernum,
            location: row.location,
            groupid: row.groupid,
            brand: row.brand || 'Unknown',  // Default to 'Unknown' if brand is null
            supplier: row.supplier || 'Unknown',  // Default to 'Unknown' if supplier is null
            qty: row.qty,
            pickorder: row.pickorder || 0  // Default to 0 if pickorder is null
        }));
        
        console.log('🔍 DEBUG Server: Formatted picks data:', picks.slice(0, 2));
        console.log('🔍 DEBUG Server: Total picks to return:', picks.length);

        // Return successful response with picks data
        const response = {
            return_code: 'SUCCESS',
            picks: picks,
            total_picks: picks.length
        };

        console.log('🔍 DEBUG Server: Sending response with return_code:', response.return_code);
        res.json(response);

    } catch (error) {
        // Log the error for debugging
        console.error('🔍 DEBUG Server: Error in get_picks:', error);
        
        // Return database error response
        res.status(500).json({
            return_code: 'DATABASE_ERROR',
            message: 'Failed to retrieve picks from database',
            error: error.message
        });
    }
});

module.exports = router;
