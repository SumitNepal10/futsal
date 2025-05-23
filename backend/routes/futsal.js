const express = require('express');
const router = express.Router();
const Futsal = require('../models/Futsal');
const { verifyToken, checkRole } = require('../middleware/auth');

// Get all futsals - no auth required
router.get('/', async (req, res) => {
    try {
        const futsals = await Futsal.find()
            .populate('owner', 'name email phone')
            .sort({ createdAt: -1 });
        res.json(futsals);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get futsals by owner
router.get('/owner/me', async (req, res) => {
    try {
        console.log('Fetching all futsals for owner');
        const futsals = await Futsal.find()
            .populate('owner', 'name email')
            .sort({ createdAt: -1 });
        console.log(`Found ${futsals.length} futsals`);
        res.json(futsals);
    } catch (error) {
        console.error('Error fetching owner futsals:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get single futsal - no auth required
router.get('/:id', async (req, res) => {
    try {
        const futsal = await Futsal.findById(req.params.id).populate('owner', 'name email phone');
        if (!futsal) {
            return res.status(404).json({ message: 'Futsal not found' });
        }
        res.json(futsal);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Create a new futsal court - requires auth
router.post('/', verifyToken, checkRole(['futsal_owner']), async (req, res) => {
    try {
        const {
            name,
            description,
            location,
            pricePerHour,
            images,
            facilities,
            openingTime,
            closingTime
        } = req.body;

        // Validate required fields
        if (!name || !description || !location || !pricePerHour || !images || !images.length) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        // Create new futsal court
        const futsal = new Futsal({
            name,
            description,
            location,
            pricePerHour,
            images,
            facilities: facilities || [],
            openingTime: openingTime || '08:00',
            closingTime: closingTime || '22:00',
            owner: req.user.id
        });

        await futsal.save();
        res.status(201).json(futsal);
    } catch (error) {
        console.error('Error creating futsal court:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Update futsal - requires auth
router.put('/:id', verifyToken, checkRole(['futsal_owner']), async (req, res) => {
    try {
        const {
            name,
            description,
            location,
            pricePerHour,
            images,
            facilities,
            openingTime,
            closingTime,
            isAvailable
        } = req.body;
        
        const futsal = await Futsal.findById(req.params.id);
        if (!futsal) {
            return res.status(404).json({ message: 'Futsal not found' });
        }

        // Check if user is the owner of this futsal
        if (futsal.owner.toString() !== req.user.id.toString()) {
            return res.status(403).json({ message: 'You can only update your own futsals' });
        }

        // Update fields
        futsal.name = name || futsal.name;
        futsal.description = description || futsal.description;
        futsal.location = location || futsal.location;
        futsal.pricePerHour = pricePerHour || futsal.pricePerHour;
        futsal.images = images || futsal.images;
        futsal.facilities = facilities || futsal.facilities;
        futsal.openingTime = openingTime || futsal.openingTime;
        futsal.closingTime = closingTime || futsal.closingTime;
        if (isAvailable !== undefined) {
            futsal.isAvailable = isAvailable;
        }

        await futsal.save();
        res.json(futsal);
    } catch (error) {
        console.error('Error updating futsal court:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Delete futsal - requires auth
router.delete('/:id', verifyToken, checkRole(['futsal_owner']), async (req, res) => {
    try {
        const futsal = await Futsal.findById(req.params.id);
        if (!futsal) {
            return res.status(404).json({ message: 'Futsal not found' });
        }

        // Check if user is the owner of this futsal
        if (futsal.owner.toString() !== req.user.id.toString()) {
            return res.status(403).json({ message: 'You can only delete your own futsals' });
        }

        await futsal.remove();
        res.json({ message: 'Futsal removed' });
    } catch (error) {
        console.error('Error deleting futsal court:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

module.exports = router; 