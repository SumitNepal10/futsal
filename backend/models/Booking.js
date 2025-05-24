const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    futsal: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Futsal',
        required: true
    },
    date: {
        type: Date,
        required: true
    },
    startTime: {
        type: String,
        required: true
    },
    endTime: {
        type: String,
        required: true
    },
    totalPrice: {
        type: Number,
        required: true
    },
    status: {
        type: String,
        enum: ['pending', 'confirmed', 'cancelled', 'completed'],
        default: 'pending'
    },
    kitRentals: [{
        kit: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Kit',
            required: true
        },
        quantity: {
            type: Number,
            required: true,
            min: 1,
            validate: {
                validator: Number.isInteger,
                message: '{VALUE} is not an integer value'
            }
        },
        price: {
            type: Number,
            required: true,
            min: 0
        }
    }],
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Index for efficient querying of bookings by date and futsal
bookingSchema.index({ futsal: 1, date: 1 });

// Static method to get available time slots for a court on a specific date
bookingSchema.statics.getAvailableSlots = async function(futsalId, date) {
    const bookings = await this.find({
        futsal: futsalId,
        date: date,
        status: { $in: ['pending', 'confirmed'] }
    });
    
    return bookings;
};

// Static method to check if a time slot is available
bookingSchema.statics.isSlotAvailable = async function(futsalId, date, startTime, endTime) {
    const conflictingBooking = await this.findOne({
        futsal: futsalId,
        date: date,
        status: { $in: ['pending', 'confirmed'] },
        $or: [
            { startTime: { $lt: endTime }, endTime: { $gt: startTime } }
        ]
    });
    
    return !conflictingBooking;
};

module.exports = mongoose.model('Booking', bookingSchema); 