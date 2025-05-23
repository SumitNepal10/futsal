const mongoose = require('mongoose');

const kitBookingSchema = new mongoose.Schema({
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
    booking: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Booking',
        required: true
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
            min: 1
        },
        price: {
            type: Number,
            required: true
        }
    }],
    totalAmount: {
        type: Number,
        required: true
    },
    status: {
        type: String,
        enum: ['pending', 'confirmed', 'cancelled', 'completed'],
        default: 'pending'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Calculate total amount before saving
kitBookingSchema.pre('save', function(next) {
    this.totalAmount = this.kitRentals.reduce((total, rental) => {
        return total + (rental.price * rental.quantity);
    }, 0);
    next();
});

module.exports = mongoose.model('KitBooking', kitBookingSchema); 