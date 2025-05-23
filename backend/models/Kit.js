const mongoose = require('mongoose');

const kitSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    description: {
        type: String,
    },
    price: {
        type: Number,
        required: true
    },
    size: {
        type: String,
        required: true
    },
    quantity: {
        type: Number,
        required: true
    },
    type: {
        type: String,
        required: true,
        enum: ['Jersey', 'Shorts', 'Shoes', 'Socks', 'Accessories']
    },
    futsal: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Futsal',
        required: true
    },
    isAvailable: {
        type: Boolean,
        default: true
    },
    images: [{
        type: String
    }],
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Kit', kitSchema); 