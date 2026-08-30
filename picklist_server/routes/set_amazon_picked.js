/*
=======================================================================================================================================
API Route: set_amazon_picked
=======================================================================================================================================
Method: POST
Purpose: Picks or unpicks an Amazon item. Amazon picking works differently to customer picking:
         instead of setting qty to 0, the item is physically moved to the C3-Amazon staging area,
         which is what takes it off the Amazon pick list. The allocation ('amz') is never changed.
         Unpick reverses the move by putting the item back at the location it was picked from, so
         the caller must supply that location - the database does not remember where it came from.
         Customer picks use set_picked instead; the two mechanics do not mix.
Authentication: Required - JWT token in Authorization header
=======================================================================================================================================
Request Headers:
{
  "Authorization": "Bearer <JWT_TOKEN>",  // string, required - JWT token from login_pin
  "Content-Type": "application/json"     // string, required
}

Request Payload:
{
  "id": "unique_id_123",              // string, required - unique identifier from localstock table
  "action": "pick",                   // string, required - either "pick" or "unpick"
  "original_location": "C3-Back-05"   // string, required for "unpick" only - the location to put the item back at
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Item successfully picked",     // string, confirmation message
  "item": {
    "id": "unique_id_123",                   // string, the item ID that was updated
    "code": "SHOE123",                       // string, the shoe code
    "ordernum": "#FREE",                     // string, order number (always '#FREE' for Amazon stock)
    "location": "C3-Amazon",                 // string, the item's location after the update
    "allocated": "amz",                      // string, unchanged allocation
    "assigned": "2332",                      // string, PIN of the picker who made the change
    "status": "picked"                       // string, human readable status
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"UNAUTHORIZED"        // Missing or invalid JWT token
"FORBIDDEN"           // Expired JWT token
"MISSING_FIELDS"
"INVALID_ACTION"
"INVALID_LOCATION"    // original_location for an unpick was missing or was the staging area itself
"ITEM_NOT_FOUND"      // No such item, or it is not Amazon allocated stock
"ITEM_NOT_PICKABLE"   // Already in the staging area when picking, or not in it when unpicking
"DATABASE_ERROR"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const { authenticateToken } = require('../middleware/auth');
const { AMAZON_LOCATION, AMAZON_ALLOCATION } = require('../constants');

// POST /set_amazon_picked - Protected route requiring authentication
router.post('/', authenticateToken, async (req, res) => {
    try {
        // Extract fields from request body
        // Handle cases where req.body might be undefined or null
        const id = req.body && req.body.id ? req.body.id.trim() : null;
        const action = req.body && req.body.action ? req.body.action.trim().toLowerCase() : null;
        const original_location = req.body && req.body.original_location ? req.body.original_location.trim() : null;

        // The picker is taken from the verified token, never from the request body
        const assigned = req.user && req.user.pin ? req.user.pin.toString() : '';

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

        // An unpick has to know where to put the item back
        if (action === 'unpick') {
            if (!original_location) {
                return res.status(400).json({
                    return_code: 'INVALID_LOCATION',
                    message: 'original_location is required when unpicking an Amazon item'
                });
            }

            // Putting it "back" into the staging area would leave it stranded off the pick list
            if (original_location === AMAZON_LOCATION) {
                return res.status(400).json({
                    return_code: 'INVALID_LOCATION',
                    message: `original_location cannot be ${AMAZON_LOCATION}`
                });
            }
        }

        // Check the item exists and is genuinely Amazon allocated stock
        const checkQuery = `
            SELECT
                id,
                code,
                ordernum,
                location,
                allocated,
                groupid,
                brand
            FROM localstock
            WHERE id = $1
            AND allocated = $2
            AND (deleted IS NULL OR deleted = 0)
        `;

        const checkResult = await pool.query(checkQuery, [id, AMAZON_ALLOCATION]);

        // Check if item was found
        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                return_code: 'ITEM_NOT_FOUND',
                message: 'Item not found or is not Amazon allocated stock'
            });
        }

        const currentItem = checkResult.rows[0];
        const alreadyInStaging = currentItem.location === AMAZON_LOCATION;

        // Validate that the item is in a state the requested action makes sense for.
        // Picking an item already in staging, or unpicking one that never left, would both
        // be no-ops that quietly mislead the picker about what happened.
        if (action === 'pick' && alreadyInStaging) {
            return res.status(400).json({
                return_code: 'ITEM_NOT_PICKABLE',
                message: `Item has already been picked (it is already in ${AMAZON_LOCATION})`
            });
        }

        if (action === 'unpick' && !alreadyInStaging) {
            return res.status(400).json({
                return_code: 'ITEM_NOT_PICKABLE',
                message: `Item has not been picked (it is not in ${AMAZON_LOCATION})`
            });
        }

        // Pick moves the item into staging, unpick puts it back where the picker found it
        const newLocation = action === 'pick' ? AMAZON_LOCATION : original_location;
        const statusMessage = action === 'pick' ? 'picked' : 'unpicked';
        const humanStatus = action === 'pick' ? 'picked' : 'to be picked';

        // Update the location, recording which picker did it.
        // allocated is deliberately left alone - the stock stays allocated to Amazon.
        // updated is written in the 'YYYYMMDD HH24:MI:SS' form every existing row in this
        // column uses, rather than a raw timestamp cast.
        const updateQuery = `
            UPDATE localstock
            SET location = $1,
                assigned = $2,
                updated = TO_CHAR(NOW(), 'YYYYMMDD HH24:MI:SS')
            WHERE id = $3
            RETURNING id, code, ordernum, location, allocated, assigned, groupid, brand
        `;

        const updateResult = await pool.query(updateQuery, [newLocation, assigned, id]);

        // Verify the update was successful
        if (updateResult.rows.length === 0) {
            return res.status(500).json({
                return_code: 'DATABASE_ERROR',
                message: 'Failed to update item location'
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
                allocated: updatedItem.allocated,
                assigned: updatedItem.assigned,
                status: humanStatus
            }
        });

    } catch (error) {
        // Log the error for debugging
        console.error('Error in set_amazon_picked:', error);

        // Return server error response
        res.status(500).json({
            return_code: 'SERVER_ERROR',
            message: 'Internal server error occurred',
            error: error.message
        });
    }
});

module.exports = router;
