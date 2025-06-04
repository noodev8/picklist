/*
=======================================================================================================================================
JWT Authentication Middleware
=======================================================================================================================================
Purpose: Validates JWT tokens for protected routes in the picklist application
Checks for valid JWT token in Authorization header and verifies it
=======================================================================================================================================
*/

const jwt = require('jsonwebtoken');

// JWT secret key - in production this should be a strong, randomly generated secret
const JWT_SECRET = process.env.JWT_SECRET || 'picklist_default_secret_key_change_in_production';

/*
=======================================================================================================================================
Authentication Middleware Function
=======================================================================================================================================
Purpose: Middleware to verify JWT tokens for protected routes
Checks Authorization header for Bearer token and validates it
=======================================================================================================================================
*/
const authenticateToken = (req, res, next) => {
    // Get the authorization header from the request
    const authHeader = req.headers['authorization'];
    
    // Extract token from "Bearer TOKEN" format
    const token = authHeader && authHeader.split(' ')[1];
    
    // If no token provided, return unauthorized error
    if (!token) {
        return res.status(401).json({
            return_code: 'UNAUTHORIZED',
            message: 'Access token required'
        });
    }
    
    // Verify the JWT token
    jwt.verify(token, JWT_SECRET, (err, user) => {
        // If token is invalid or expired
        if (err) {
            return res.status(403).json({
                return_code: 'FORBIDDEN',
                message: 'Invalid or expired token'
            });
        }
        
        // Token is valid, add user info to request object
        req.user = user;
        
        // Continue to the next middleware or route handler
        next();
    });
};

// Export the middleware function and JWT secret for use in other modules
module.exports = {
    authenticateToken,
    JWT_SECRET
};
