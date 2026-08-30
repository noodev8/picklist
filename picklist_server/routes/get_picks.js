/*
=======================================================================================================================================
API Route: get_picks
=======================================================================================================================================
Method: POST
Purpose: Retrieves the picks that still need picking, for one of two separate picking jobs:
           - "customer" (the default): real customer orders, identified by ordernum != '#FREE'.
             These are picked by setting qty to 0.
           - "amazon": stock allocated to Amazon (allocated = 'amz') that has not yet been moved to
             the C3-Amazon staging area. These are picked by moving their location to C3-Amazon.
         The two lists never overlap - Amazon stock always carries ordernum = '#FREE', which the
         customer query excludes. A picker works one job or the other, never both at once.
Authentication: Required - JWT token in Authorization header
=======================================================================================================================================
Request Headers:
{
  "Authorization": "Bearer <JWT_TOKEN>",  // string, required - JWT token from login_pin
  "Content-Type": "application/json"     // string, required
}

Request Payload:
{
  // All parameters optional
  "pick_type": "customer",         // optional, string, "customer" (default) or "amazon" - which picking job to list
  "location_filter": "C3-Front"    // optional, string, filter picks by location containing this text
}

Success Response:
{
  "return_code": "SUCCESS",
  "pick_type": "customer",             // string, the pick type this list was built for
  "picks": [
    {
      "id": "unique_id_123",           // string, unique identifier from localstock table
      "code": "SHOE123",               // string, the actual shoe code being picked
      "ordernum": "BC001234",          // string, order number ('#FREE' for Amazon picks)
      "location": "C3-Front-Rack-01",  // string, exact location of the pick
      "groupid": "GRP123",             // string, group identifier for linking with other tables
      "brand": "Nike",                 // string, brand of the shoe
      "supplier": "MainSupplier",      // string, supplier information from skusummary
      "colour": "Navy",                // string, colour from skusummary ('' if not recorded)
      "allocated": "amz",              // string, allocation of the stock ('' if unallocated)
      "qty": 1,                        // integer, quantity to pick (always 1 for picks)
      "pickorder": 1                   // integer, suggested pick order for efficiency
    }
  ],
  "total_picks": 25                    // integer, total number of picks available
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"INVALID_PICK_TYPE"   // pick_type was supplied but is not "customer" or "amazon"
"UNAUTHORIZED"        // Missing or invalid JWT token
"FORBIDDEN"           // Expired JWT token
"DATABASE_ERROR"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const { authenticateToken } = require('../middleware/auth');
const { AMAZON_LOCATION, AMAZON_ALLOCATION } = require('../constants');

// POST /get_picks - Protected route requiring authentication
router.post('/', authenticateToken, async (req, res) => {
    try {
        // Safely extract optional fields from request body
        // Handle cases where req.body might be undefined or null
        const location_filter = req.body && req.body.location_filter ? req.body.location_filter : null;
        const pick_type = req.body && req.body.pick_type ? req.body.pick_type.trim().toLowerCase() : 'customer';

        // Validate the requested pick type before touching the database
        if (pick_type !== 'customer' && pick_type !== 'amazon') {
            return res.status(400).json({
                return_code: 'INVALID_PICK_TYPE',
                message: 'pick_type must be either "customer" or "amazon"'
            });
        }

        // The selected columns are identical for both pick types so the app can use a single model
        // Join localstock with skusummary to get additional details like supplier and colour
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
                l.allocated,
                s.supplier,
                s.colour
            FROM localstock l
            LEFT JOIN skusummary s ON l.groupid = s.groupid
        `;

        // Array to hold query parameters, built up in the same order they are referenced
        let queryParams = [];

        if (pick_type === 'amazon') {
            // Amazon picks: stock allocated to Amazon that is still out in the warehouse.
            // Picking moves an item into the C3-Amazon staging area, which is how it leaves
            // this list - hence excluding that location rather than checking qty.
            queryParams.push(AMAZON_ALLOCATION, AMAZON_LOCATION);
            query += `
                WHERE l.allocated = $1
                AND l.location != $2
                AND (l.deleted IS NULL OR l.deleted = 0)
            `;
        } else {
            // Customer picks: real orders, picked by setting qty to 0
            query += `
                WHERE l.ordernum != '#FREE'
                AND (l.deleted IS NULL OR l.deleted = 0)
            `;
        }

        // Add location filter if provided
        if (location_filter && location_filter.trim() !== '') {
            queryParams.push(`%${location_filter.trim()}%`);
            query += ` AND l.location ILIKE $${queryParams.length}`;
        }

        // Order by location for better picking workflow
        // This groups picks by location so pickers can work efficiently
        query += ` ORDER BY l.location, l.pickorder, l.code`;

        // Execute the query
        const result = await pool.query(query, queryParams);

        // Format the response data
        const picks = result.rows.map(row => ({
            id: row.id,
            code: row.code,
            ordernum: row.ordernum,
            location: row.location,
            groupid: row.groupid,
            brand: row.brand || 'Unknown',  // Default to 'Unknown' if brand is null
            supplier: row.supplier || 'Unknown',  // Default to 'Unknown' if supplier is null
            colour: row.colour || '',  // Empty string if no colour is recorded
            allocated: row.allocated || '',  // Empty string if the stock is not allocated
            qty: row.qty,
            pickorder: row.pickorder || 0  // Default to 0 if pickorder is null
        }));

        // Return successful response with picks data
        const response = {
            return_code: 'SUCCESS',
            pick_type: pick_type,
            picks: picks,
            total_picks: picks.length
        };

        res.json(response);

    } catch (error) {
        // Log the error for debugging
        console.error('Error in get_picks:', error);

        // Return database error response
        res.status(500).json({
            return_code: 'DATABASE_ERROR',
            message: 'Failed to retrieve picks from database',
            error: error.message
        });
    }
});

module.exports = router;
