/*
=======================================================================================================================================
API Route: set_picked
=======================================================================================================================================
Method: POST
Purpose: Allows users to pick or unpick items in the warehouse. Updates the qty field in localstock table.
         qty = 1 means "to be picked", qty = 0 means "picked"
=======================================================================================================================================
Request Payload:
{
  "id": "unique_id_123",              // string, required - unique identifier from localstock table
  "action": "pick"                    // string, required - either "pick" or "unpick"
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Item successfully picked",     // string, confirmation message
  "item": {
    "id": "unique_id_123",                   // string, the item ID that was updated
    "code": "SHOE123",                       // string, the shoe code
    "ordernum": "BC001234",                  // string, order number
    "location": "C3-Front-Rack-01",          // string, location of the item
    "qty": 0,                                // integer, new quantity (0=picked, 1=to be picked)
    "status": "picked"                       // string, human readable status
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_ACTION"
"ITEM_NOT_FOUND"
"ITEM_NOT_PICKABLE"
"DATABASE_ERROR"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');

// POST /set_picked
router.post('/', async (req, res) => {
    try {
        console.log('🔍 DEBUG Server: set_picked API called');
        console.log('🔍 DEBUG Server: Request body:', req.body);

        // Extract required fields from request body
        // Handle cases where req.body might be undefined or null
        const id = req.body && req.body.id ? req.body.id.trim() : null;
        const action = req.body && req.body.action ? req.body.action.trim().toLowerCase() : null;

        console.log('🔍 DEBUG Server: Extracted - ID:', id, 'Action:', action);
        
        // Validate required fields
        if (!id || !action) {
            return res.status(400).json({
                return_code: 'MISSING_FIELDS',
                message: 'Both id and action are required fields'
            });
        }
        
        // Validate action parameter
        if (action !== 'pick' && action !== 'unpick') {
            return res.status(400).json({
                return_code: 'INVALID_ACTION',
                message: 'Action must be either "pick" or "unpick"'
            });
        }
        
        // Determine the new quantity based on action
        // pick = set qty to 0 (picked)
        // unpick = set qty to 1 (to be picked)
        const newQty = action === 'pick' ? 0 : 1;
        const statusMessage = action === 'pick' ? 'picked' : 'unpicked';
        const humanStatus = action === 'pick' ? 'picked' : 'to be picked';
        
        // First, check if the item exists and is pickable
        const checkQuery = `
            SELECT 
                id,
                code,
                ordernum,
                location,
                qty,
                groupid,
                brand
            FROM localstock 
            WHERE id = $1 
            AND ordernum != '#FREE'
            AND (deleted IS NULL OR deleted = 0)
        `;
        
        const checkResult = await pool.query(checkQuery, [id]);
        
        // Check if item was found
        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                return_code: 'ITEM_NOT_FOUND',
                message: 'Item not found or not available for picking'
            });
        }
        
        const currentItem = checkResult.rows[0];
        
        // Validate that the item is in a pickable state
        // For pick action: item must have qty = 1 (to be picked)
        // For unpick action: item must have qty = 0 (already picked)
        if (action === 'pick' && currentItem.qty !== 1) {
            return res.status(400).json({
                return_code: 'ITEM_NOT_PICKABLE',
                message: 'Item is not available for picking (already picked or invalid state)'
            });
        }
        
        if (action === 'unpick' && currentItem.qty !== 0) {
            return res.status(400).json({
                return_code: 'ITEM_NOT_PICKABLE',
                message: 'Item is not available for unpicking (not yet picked or invalid state)'
            });
        }
        
        // Update the item quantity in the database
        const updateQuery = `
            UPDATE localstock 
            SET qty = $1,
                updated = NOW()::text
            WHERE id = $2
            RETURNING id, code, ordernum, location, qty, groupid, brand
        `;
        
        const updateResult = await pool.query(updateQuery, [newQty, id]);
        
        // Verify the update was successful
        if (updateResult.rows.length === 0) {
            return res.status(500).json({
                return_code: 'DATABASE_ERROR',
                message: 'Failed to update item status'
            });
        }
        
        const updatedItem = updateResult.rows[0];
        
        // Return successful response with updated item details
        res.json({
            return_code: 'SUCCESS',
            message: `Item successfully ${statusMessage}`,
            item: {
                id: updatedItem.id,
                code: updatedItem.code,
                ordernum: updatedItem.ordernum,
                location: updatedItem.location,
                qty: updatedItem.qty,
                status: humanStatus
            }
        });
        
    } catch (error) {
        // Log the error for debugging
        console.error('Error in set_picked:', error);
        
        // Return server error response
        res.status(500).json({
            return_code: 'SERVER_ERROR',
            message: 'Internal server error occurred',
            error: error.message
        });
    }
});

module.exports = router;
