const express = require('express');
const router = express.Router();
const Booking = require('../models/Booking');
const Futsal = require('../models/Futsal');
const Kit = require('../models/Kit');
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
        console.log('Received date:', date);
        console.log('Futsal opening time:', futsal.openingTime);
        console.log('Futsal closing time:', futsal.closingTime);

        const slots = [];
        
        // Get current time in local timezone
        const now = new Date();
        
        // Parse the request date and set it to midnight
        const [year, month, day] = date.split('-').map(Number);
        const requestDate = new Date(year, month - 1, day); // month is 0-based in JS
        
        console.log('Current time:', now.toLocaleString());
        console.log('Request date (midnight):', requestDate.toLocaleString());
        
        // Set hours and minutes from opening time
        const [openHours, openMinutes] = futsal.openingTime.split(':').map(Number);
        const [closeHours, closeMinutes] = futsal.closingTime.split(':').map(Number);
        
        console.log(`Opening time: ${openHours}:${openMinutes.toString().padStart(2, '0')}`);
        console.log(`Closing time: ${closeHours}:${closeMinutes.toString().padStart(2, '0')}`);
        
        // Create start and end times for the requested date
        const startTime = new Date(year, month - 1, day, openHours, openMinutes, 0);
        const endTime = new Date(year, month - 1, day, closeHours, closeMinutes, 0);
        
        console.log('Start time:', startTime.toLocaleString());
        console.log('End time:', endTime.toLocaleString());
        
        // Compare dates using year, month, and day
        const isToday = requestDate.getFullYear() === now.getFullYear() &&
                        requestDate.getMonth() === now.getMonth() &&
                        requestDate.getDate() === now.getDate();
        
        console.log('Is today:', isToday);
        
        // If it's today and current time is past closing time or too close to it
        const currentHour = now.getHours();
        console.log('Current hour:', currentHour);
        
        if (isToday && currentHour >= closeHours - 1) {
            console.log('Current time is past or too close to closing time');
            
            // Instead of returning empty slots, calculate tomorrow's slots
            console.log('Returning slots for tomorrow instead');
            
            // Create tomorrow's date
            const tomorrow = new Date(now);
            tomorrow.setDate(tomorrow.getDate() + 1);
            tomorrow.setHours(0, 0, 0, 0); // Reset to midnight
            
            console.log('Tomorrow date:', tomorrow.toLocaleString());
            
            // Calculate slots for tomorrow
            const tomorrowSlots = [];
            
            const tomorrowStartTime = new Date(tomorrow);
            tomorrowStartTime.setHours(openHours, openMinutes, 0);
            
            const tomorrowEndTime = new Date(tomorrow);
            tomorrowEndTime.setHours(closeHours, closeMinutes, 0);
            
            // Generate slots for tomorrow
            for (let time = new Date(tomorrowStartTime); time < tomorrowEndTime; time.setHours(time.getHours() + 1)) {
                const slotStart = time.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit' });
                const slotEnd = new Date(time.getTime() + 60 * 60 * 1000)
                    .toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit' });
                
                tomorrowSlots.push({
                    startTime: slotStart,
                    endTime: slotEnd,
                    isAvailable: true,
                    price: futsal.pricePerHour
                });
            }
            
            return res.json({ slots: tomorrowSlots });
        }
        
        // If today but not past closing time, start from next hour
        if (isToday) {
            // Start from next hour, but don't exceed closing time
            const nextHour = Math.min(Math.max(currentHour + 1, openHours), closeHours - 1);
            console.log('Current hour:', currentHour, 'Next available hour:', nextHour);
            startTime.setHours(nextHour, 0, 0);
            console.log('Adjusted start time:', startTime.toLocaleString());
        }
        
        // Don't generate any slots if start time is after or equal to end time
        if (startTime >= endTime) {
            console.log('No slots available - start time is after end time');
            return res.json({ slots: [] });
        }

        for (let time = new Date(startTime); time < endTime; time.setHours(time.getHours() + 1)) {
            const slotStart = time.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit' });
            const slotEnd = new Date(time.getTime() + 60 * 60 * 1000)
                .toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit' });
            
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

        // Calculate court rental price
        const start = new Date(`${date}T${startTime}`);
        const end = new Date(`${date}T${endTime}`);
        const hours = (end - start) / (1000 * 60 * 60);
        const courtPrice = hours * futsalCourt.pricePerHour;

        // Process kit rentals if any
        let processedKitRentals = [];
        let kitRentalsPrice = 0;

        if (kitRentals && kitRentals.length > 0) {
            console.log('Processing kit rentals:', kitRentals);

            // Fetch all kit details in one query
            const kitIds = kitRentals.map(rental => rental.kit);
            const kits = await Kit.find({ _id: { $in: kitIds } });

            // Create a map for quick lookup
            const kitMap = new Map(kits.map(kit => [kit._id.toString(), kit]));

            for (const rental of kitRentals) {
                const kit = kitMap.get(rental.kit.toString());
                if (!kit) {
                    return res.status(404).json({ 
                        message: `Kit not found: ${rental.kit}` 
                    });
                }

                if (!kit.isAvailable) {
                    return res.status(400).json({ 
                        message: `Kit ${kit.name} is not available` 
                    });
                }

                if (rental.quantity > kit.quantity) {
                    return res.status(400).json({ 
                        message: `Insufficient quantity for kit: ${kit.name}` 
                    });
                }

                const rentalPrice = kit.price * rental.quantity;
                kitRentalsPrice += rentalPrice;

                processedKitRentals.push({
                    kit: kit._id,
                    quantity: rental.quantity,
                    price: rentalPrice
                });
            }
        }

        const totalPrice = courtPrice + kitRentalsPrice;

        const booking = new Booking({
            user,
            futsal,
            date,
            startTime,
            endTime,
            totalPrice,
            kitRentals: processedKitRentals,
            status: 'pending',
            paymentStatus: 'pending'
        });

        console.log('Creating booking with data:', {
            totalPrice,
            courtPrice,
            kitRentalsPrice,
            kitRentals: processedKitRentals
        });

        await booking.save();
        res.status(201).json(booking);
    } catch (error) {
        console.error('Error creating booking:', error);
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
        
        // Get all bookings for these futsals
        let bookings = await Booking.find({ futsal: { $in: futsalIds } })
            .populate('user', 'name email phone')
            .populate('futsal')
            .populate({
                path: 'kitRentals.kit',
                model: 'Kit',
                select: 'name price size type'
            })
            .sort({ date: -1, startTime: -1 });

        console.log('Found bookings:', bookings.length);
        
        // Check if KitBooking model exists and import it
        let KitBooking;
        try {
            KitBooking = require('../models/KitBooking');
        } catch (err) {
            console.log('KitBooking model not found:', err.message);
        }

        // If KitBooking model exists, fetch kit rentals and merge them with bookings
        if (KitBooking) {
            console.log('Fetching kit bookings to merge with regular bookings...');
            // Convert bookings to array of plain objects so we can modify them
            bookings = bookings.map(booking => booking.toObject());
            
            // Get all kit bookings related to these bookings
            const bookingIds = bookings.map(b => b._id);
            const kitBookings = await KitBooking.find({ booking: { $in: bookingIds } })
                .populate({
                    path: 'kitRentals.kit',
                    model: 'Kit',
                    select: 'name price size type'
                });
                
            console.log('Kit bookings data sample:', 
                kitBookings.length > 0 ? 
                JSON.stringify(kitBookings[0].kitRentals, null, 2) : 'No kit bookings found');
                
            console.log('Found kit bookings:', kitBookings.length);
            
            // Create a map for easy lookup
            const kitBookingsMap = {};
            kitBookings.forEach(kb => {
                kitBookingsMap[kb.booking.toString()] = kb.kitRentals;
            });
            
            // Merge kit rentals into bookings
            bookings.forEach(booking => {
                const bookingId = booking._id.toString();
                if (kitBookingsMap[bookingId]) {
                    console.log(`Merging kit rentals for booking ${bookingId}`);
                    
                    // Convert kit field to kitId field to match frontend expectations
                    const formattedRentals = kitBookingsMap[bookingId].map(rental => {
                        return {
                            kitId: rental.kit, // Rename kit to kitId
                            quantity: rental.quantity,
                            price: rental.price
                        };
                    });
                    
                    // Calculate the total kit rental price
                    const kitRentalTotal = formattedRentals.reduce((total, rental) => {
                        return total + (rental.price || 0);
                    }, 0);
                    
                    console.log(`Original booking total price: ${booking.totalPrice}, Kit rental total: ${kitRentalTotal}`);
                    
                    // Update the total price to include kit rentals
                    booking.originalCourtPrice = booking.totalPrice;
                    booking.totalPrice = (booking.totalPrice || 0) + kitRentalTotal;
                    
                    console.log(`Updated total price: ${booking.totalPrice}`);
                    
                    booking.kitRentals = formattedRentals;
                }
            });
        }
        
        // Log some sample data for debugging
        if (bookings.length > 0) {
            console.log('Sample booking kitRentals after merge:', 
                bookings[0].kitRentals && bookings[0].kitRentals.length ? 
                bookings[0].kitRentals : 'None');
        }
            
        res.json(bookings);
    } catch (error) {
        console.error('Error in /owner route:', error);
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