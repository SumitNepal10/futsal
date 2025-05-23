const cron = require('node-cron');
const Booking = require('../models/Booking');
const mongoose = require('mongoose');

// Run at midnight every day
cron.schedule('0 0 * * *', async () => {
    try {
        console.log('Running daily booking reset...');
        
        // Get all pending bookings from previous days
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        yesterday.setHours(23, 59, 59, 999);

        const oldBookings = await Booking.find({
            date: { $lt: yesterday },
            status: 'pending'
        });

        // Update their status to 'cancelled'
        if (oldBookings.length > 0) {
            await Booking.updateMany(
                { _id: { $in: oldBookings.map(b => b._id) } },
                { $set: { status: 'cancelled' } }
            );
            console.log(`Reset ${oldBookings.length} old bookings`);
        }

        console.log('Daily booking reset completed successfully');
    } catch (error) {
        console.error('Error in daily booking reset:', error);
    }
});

module.exports = cron; 