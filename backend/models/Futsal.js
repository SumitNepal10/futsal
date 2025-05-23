const mongoose = require('mongoose');

const futsalSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    description: {
        type: String,
        required: true
    },
    location: {
        type: String,
        required: true
    },
    pricePerHour: {
        type: Number,
        required: true
    },
    images: [{
        type: String, // Store base64 images
        required: true
    }],
    facilities: [{
        type: String
    }],
    owner: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    openingTime: {
        type: String,
        required: true,
        default: '08:00'
    },
    closingTime: {
        type: String,
        required: true,
        default: '22:00'
    },
    rating: {
        type: Number,
        default: 0
    },
    totalRatings: {
        type: Number,
        default: 0
    },
    isAvailable: {
        type: Boolean,
        default: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Futsal', futsalSchema); 