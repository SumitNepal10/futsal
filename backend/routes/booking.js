const express = require('express');
const router = express.Router();
const Booking = require('../models/Booking');
const Futsal = require('../models/Futsal');
const { verifyToken } = require('../middleware/auth');

// Get all bookings
router.get('/', async (req, res) => {
    try {
        const bookings = await Booking.find()
            .populate('user', 'name email phone')
            .populate('futsal', 'name location pricePerHour');
        res.json(bookings);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get user's bookings
router.get('/user/:userId', async (req, res) => {
    try {
        const bookings = await Booking.find({ user: req.params.userId })
            .populate('futsal', 'name location pricePerHour');
        res.json(bookings);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get futsal's bookings
router.get('/futsal/:futsalId', async (req, res) => {
    try {
        const bookings = await Booking.find({ futsal: req.params.futsalId })
            .populate('user', 'name email phone');
        res.json(bookings);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get available time slots for a court on a specific date
router.get('/available-slots/:futsalId', async (req, res) => {
    try {
        const { futsalId } = req.params;
        const { date } = req.query;

        if (!date) {
            return res.status(400).json({ message: 'Date is required' });
        }

        const futsal = await Futsal.findById(futsalId);
        if (!futsal) {
            return res.status(404).json({ message: 'Futsal court not found' });
        }

        // Get all bookings for the date
        const bookings = await Booking.getAvailableSlots(futsalId, date);

        // Generate all possible time slots
        const slots = [];
        const startTime = new Date(`${date}T${futsal.openingTime}`);
        const endTime = new Date(`${date}T${futsal.closingTime}`);
        
        for (let time = startTime; time < endTime; time.setHours(time.getHours() + 1)) {
            const slotStart = time.toLocaleTimeString('en-US', { hour12: false });
            const slotEnd = new Date(time.getTime() + 60 * 60 * 1000)
                .toLocaleTimeString('en-US', { hour12: false });
            
            const isBooked = bookings.some(booking => 
                booking.startTime === slotStart && booking.endTime === slotEnd
            );

            slots.push({
                startTime: slotStart,
                endTime: slotEnd,
                isAvailable: !isBooked,
                price: futsal.pricePerHour
            });
        }

        res.json({ slots });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Create booking
router.post('/', verifyToken, async (req, res) => {
    try {
        const { futsal, date, startTime, endTime, kitRentals } = req.body;
        const user = req.user.id;

        // Check if futsal exists and get price
        const futsalCourt = await Futsal.findById(futsal);
        if (!futsalCourt) {
            return res.status(404).json({ message: 'Futsal not found' });
        }

        // Check if slot is available
        const isAvailable = await Booking.isSlotAvailable(futsal, date, startTime, endTime);
        if (!isAvailable) {
            return res.status(400).json({ message: 'Time slot already booked' });
        }

        // Calculate total price
        const start = new Date(`${date}T${startTime}`);
        const end = new Date(`${date}T${endTime}`);
        const hours = (end - start) / (1000 * 60 * 60);
        const totalPrice = hours * futsalCourt.pricePerHour;

        const booking = new Booking({
            user,
            futsal,
            date,
            startTime,
            endTime,
            totalPrice,
            kitRentals,
            status: 'pending',
            paymentStatus: 'pending'
        });

        await booking.save();
        res.status(201).json(booking);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get user's bookings
router.get('/my-bookings', verifyToken, async (req, res) => {
    try {
        const bookings = await Booking.find({ user: req.user.id })
            .populate('futsal')
            .sort({ date: -1, startTime: -1 });
        res.json(bookings);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get futsal owner's bookings - no auth required
router.get('/owner', async (req, res) => {
    try {
        // Get all futsals
        const futsals = await Futsal.find();
        const futsalIds = futsals.map(f => f._id);
        
        const bookings = await Booking.find({ futsal: { $in: futsalIds } })
            .populate('user', 'name email phone')
            .populate('futsal')
            .sort({ date: -1, startTime: -1 });
            
        res.json(bookings);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Update booking status (owner only)
router.patch('/:bookingId/status', verifyToken, async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { status } = req.body;

        const booking = await Booking.findById(bookingId);
        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        const futsal = await Futsal.findById(booking.futsal);
        if (futsal.owner.toString() !== req.user.id) {
            return res.status(403).json({ message: 'Not authorized' });
        }

        booking.status = status;
        await booking.save();

        res.json(booking);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Update payment status
router.put('/:id/payment', async (req, res) => {
    try {
        const { paymentStatus } = req.body;
        const booking = await Booking.findById(req.params.id);

        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        booking.paymentStatus = paymentStatus;
        await booking.save();
        res.json(booking);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

module.exports = router; 