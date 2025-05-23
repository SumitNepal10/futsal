const express = require('express');
const router = express.Router();
const KitBooking = require('../models/KitBooking');
const Kit = require('../models/Kit');
const { verifyToken } = require('../middleware/auth');
const mongoose = require('mongoose');

// Create kit booking
router.post('/', verifyToken, async (req, res) => {
    try {
        console.log('Received kit booking request:', req.body);
        console.log('User ID:', req.user.id);

        const { futsal, booking, kitRentals } = req.body;
        const userId = req.user.id;

        // Validate required fields
        if (!futsal || !booking || !kitRentals || !Array.isArray(kitRentals)) {
            console.error('Missing required fields:', { futsal, booking, kitRentals });
            return res.status(400).json({ 
                message: 'Missing required fields',
                details: { futsal, booking, kitRentals }
            });
        }

        // Validate futsal and booking IDs
        if (!mongoose.Types.ObjectId.isValid(futsal) || !mongoose.Types.ObjectId.isValid(booking)) {
            console.error('Invalid IDs:', { futsal, booking });
            return res.status(400).json({ 
                message: 'Invalid futsal or booking ID',
                details: { futsal, booking }
            });
        }

        // Get kit details and validate quantities
        console.log('Validating kit quantities...');
        const kitDetails = await Promise.all(
            kitRentals.map(async (rental) => {
                console.log('Processing rental:', rental);
                const kit = await Kit.findById(rental.kit);
                if (!kit) {
                    throw new Error(`Kit not found: ${rental.kit}`);
                }
                if (kit.quantity < rental.quantity) {
                    throw new Error(`Insufficient quantity for kit: ${kit.name}`);
                }
                return {
                    kit: rental.kit,
                    quantity: rental.quantity,
                    price: kit.price
                };
            })
        );

        // Calculate total amount
        const totalAmount = kitDetails.reduce((total, rental) => {
            return total + (rental.price * rental.quantity);
        }, 0);

        console.log('Creating kit booking with total amount:', totalAmount);
        // Create kit booking
        const kitBooking = new KitBooking({
            user: userId,
            futsal,
            booking,
            kitRentals: kitDetails,
            totalAmount,
            status: 'pending'
        });

        await kitBooking.save();
        console.log('Kit booking created:', kitBooking);

        // Update kit quantities
        console.log('Updating kit quantities...');
        await Promise.all(
            kitRentals.map(async (rental) => {
                await Kit.findByIdAndUpdate(rental.kit, {
                    $inc: { quantity: -rental.quantity }
                });
            })
        );

        console.log('Kit booking process completed successfully');
        res.status(201).json(kitBooking);
    } catch (error) {
        console.error('Error creating kit booking:', error);
        res.status(500).json({ 
            message: error.message || 'Server error',
            details: error.stack
        });
    }
});

// Get user's kit bookings
router.get('/user/:userId', async (req, res) => {
    try {
        console.log('Fetching kit bookings for user:', req.params.userId);
        const bookings = await KitBooking.find({ user: req.params.userId })
            .populate('futsal', 'name location')
            .populate('booking')
            .populate('kitRentals.kit')
            .sort({ createdAt: -1 });
        console.log('Found bookings:', bookings);
        res.json(bookings);
    } catch (error) {
        console.error('Error fetching user kit bookings:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get futsal's kit bookings
router.get('/futsal/:futsalId', verifyToken, async (req, res) => {
    try {
        const bookings = await KitBooking.find({ futsal: req.params.futsalId })
            .populate('user', 'name email')
            .populate('booking')
            .populate('kitRentals.kit')
            .sort({ createdAt: -1 });
        res.json(bookings);
    } catch (error) {
        console.error('Error fetching futsal kit bookings:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Update kit booking status
router.put('/:id/status', verifyToken, async (req, res) => {
    try {
        const { status } = req.body;
        const booking = await KitBooking.findById(req.params.id);
        
        if (!booking) {
            return res.status(404).json({ message: 'Kit booking not found' });
        }

        booking.status = status;
        await booking.save();

        // If cancelled, return quantities to inventory
        if (status === 'cancelled') {
            await Promise.all(
                booking.kitRentals.map(async (rental) => {
                    await Kit.findByIdAndUpdate(rental.kit, {
                        $inc: { quantity: rental.quantity }
                    });
                })
            );
        }

        res.json(booking);
    } catch (error) {
        console.error('Error updating kit booking status:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

module.exports = router; 