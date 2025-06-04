const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Initialize Express app
const app = express();

// Middleware
app.use(cors());
app.use(express.json());


// Root route
app.get('/', (req, res) => {
    res.json({ message: 'Welcome to Picklist API' });
});

// Start server
const PORT = process.env.PORT;
app.listen(PORT, '0.0.0.0', () => {
     console.log(`Server running on port ${PORT}`);
 });
