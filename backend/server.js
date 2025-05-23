const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables
dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Serve static files from uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/futsal_app', {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    serverSelectionTimeoutMS: 5000,
    family: 4
})
.then(() => console.log('Connected to MongoDB'))
.catch(err => {
    console.error('MongoDB connection error details:', {
        name: err.name,
        message: err.message,
        code: err.code,
        reason: err.reason
    });
});

// Routes
const authRoutes = require('./routes/auth');
const futsalRoutes = require('./routes/futsal');
const bookingRoutes = require('./routes/booking');
const kitRoutes = require('./routes/kit');
const kitBookingRoutes = require('./routes/kit_booking');

app.use('/api/auth', authRoutes);
app.use('/api/futsals', futsalRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/kits', kitRoutes);
app.use('/api/kit-bookings', kitBookingRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    
    if (err.name === 'CastError') {
        return res.status(400).json({ message: 'Invalid ID format' });
    }
    
    if (err.name === 'PayloadTooLargeError') {
        return res.status(413).json({ message: 'Request payload too large' });
    }
    
    res.status(500).json({ message: 'Something went wrong!' });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
}); 