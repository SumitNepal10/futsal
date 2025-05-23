const jwt = require('jsonwebtoken');
const User = require('../models/User');

const verifyToken = async (req, res, next) => {
    try {
        const token = req.header('Authorization')?.replace('Bearer ', '');
        
        if (!token) {
            console.log('No token provided');
            return res.status(401).json({ message: 'No authentication token, access denied' });
        }

        console.log('Verifying token:', token);
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
        console.log('Decoded token:', decoded);

        // Check for either userId or id in the decoded token
        const userId = decoded.userId || decoded.id;
        if (!userId) {
            console.log('No user ID found in token');
            throw new Error('Invalid token structure');
        }

        const user = await User.findById(userId);
        if (!user) {
            console.log('User not found for ID:', userId);
            throw new Error('User not found');
        }

        console.log('User authenticated:', user._id);
        req.user = user;
        next();
    } catch (error) {
        console.error('Authentication error:', error);
        res.status(401).json({ 
            message: 'Please authenticate',
            details: error.message
        });
    }
};

const checkRole = (roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ message: 'Authentication required' });
        }

        if (!roles.includes(req.user.role)) {
            return res.status(403).json({ message: 'Access denied. Insufficient permissions.' });
        }

        next();
    };
};

module.exports = { verifyToken, checkRole }; 