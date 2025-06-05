/*
=======================================================================================================================================
API Route: login_pin
=======================================================================================================================================
Method: POST
Purpose: Authenticates a user using their PIN from the pickpin database table. Returns a JWT token valid for 90 days upon success.
=======================================================================================================================================
Request Payload:
{
  "pin": 1234                          // integer, required - user's PIN number
}

Success Response:
{
  "return_code": "SUCCESS",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", // string, JWT token for auth (90 days validity)
  "user": {
    "pin": 1234,                       // integer, user's PIN
    "name": "John Doe"                 // string, user's name from pickpin table
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_PIN"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const jwt = require('jsonwebtoken');
const pool = require('../db');
const { JWT_SECRET } = require('../middleware/auth');

const router = express.Router();

// POST /login_pin
router.post('/', async (req, res) => {
    const { pin } = req.body;
    
    try {
        // Validate required fields
        if (!pin) {
            return res.json({
                return_code: 'MISSING_FIELDS',
                message: 'PIN is required'
            });
        }
        
        // Validate PIN is a number
        const pinNumber = parseInt(pin);
        if (isNaN(pinNumber)) {
            return res.json({
                return_code: 'INVALID_PIN',
                message: 'PIN must be a valid number'
            });
        }
        
        // Query the pickpin table to find matching PIN
        const query = 'SELECT pin, name FROM pickpin WHERE pin = $1';
        const result = await pool.query(query, [pinNumber]);
        
        // Check if PIN exists in database
        if (result.rows.length === 0) {
            return res.json({
                return_code: 'INVALID_PIN',
                message: 'Invalid PIN'
            });
        }
        
        // Get user data from database result
        const user = result.rows[0];
        
        // Create JWT token payload
        const tokenPayload = {
            pin: user.pin,
            name: user.name,
            loginTime: new Date().toISOString()
        };
        
        // Generate JWT token with 90 days expiration
        const token = jwt.sign(
            tokenPayload,
            JWT_SECRET,
            { 
                expiresIn: '90d',  // 90 days validity
                issuer: 'picklist-app',
                subject: user.pin.toString()
            }
        );
        
        // Return success response with token and user data
        return res.json({
            return_code: 'SUCCESS',
            token: token,
            user: {
                pin: user.pin,
                name: user.name
            }
        });
        
    } catch (error) {
        // Log error for debugging
        console.error('Login PIN error:', error);
        
        // Return server error response
        return res.json({
            return_code: 'SERVER_ERROR',
            message: 'Internal server error occurred'
        });
    }
});

module.exports = router;
