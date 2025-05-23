const express = require('express');
const router = express.Router();
const Kit = require('../models/Kit');
const { verifyToken, checkRole } = require('../middleware/auth');
const mongoose = require('mongoose');
const Futsal = require('../models/Futsal');

// Get all kits
router.get('/', async (req, res) => {
    try {
        const kits = await Kit.find().populate('futsal', 'name location');
        res.json(kits);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get kits by futsal
router.get('/futsal/:futsalId', async (req, res) => {
    try {
        // Validate futsalId
        if (!mongoose.Types.ObjectId.isValid(req.params.futsalId)) {
            return res.status(400).json({ message: 'Invalid futsal ID' });
        }

        const kits = await Kit.find({ futsal: req.params.futsalId });
        res.json(kits);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get kits by owner and category
router.get('/owner', verifyToken, checkRole(['futsal_owner']), async (req, res) => {
    try {
        const { category } = req.query;
        const ownerId = req.user.id;
        console.log('Fetching kits for ownerId:', ownerId);
        // Find all futsals owned by the user
        const futsals = await Futsal.find({ owner: ownerId }).select('_id');
        const futsalIds = futsals.map(f => f._id);
        console.log('Found futsalIds for owner:', futsalIds.map(id => id.toString())); // Log as strings for readability
        // Build query
        const query = { futsal: { $in: futsalIds } };
        if (category && category !== 'All') {
            query.type = category;
        }
        console.log('Executing kit query:', query);
        const kits = await Kit.find(query)
            .populate('futsal', 'name location')
            .sort({ type: 1, name: 1 });
        res.json(kits);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get single kit
router.get('/:id', async (req, res) => {
    try {
        // Validate kit ID
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: 'Invalid kit ID' });
        }

        const kit = await Kit.findById(req.params.id).populate('futsal', 'name location');
        if (!kit) {
            return res.status(404).json({ message: 'Kit not found' });
        }
        res.json(kit);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Create kit (owner only)
router.post('/', verifyToken, checkRole(['futsal_owner']), async (req, res) => {
    try {
        const { name, description, price, size, quantity, futsal, images, type } = req.body;
        
        // Validate futsal ID
        if (!mongoose.Types.ObjectId.isValid(futsal)) {
            return res.status(400).json({ message: 'Invalid futsal ID' });
        }

        const kit = new Kit({
            name,
            description,
            price,
            size,
            quantity,
            futsal,
            images,
            type: type || 'Jersey' // Default to Jersey if no type provided
        });

        await kit.save();
        res.status(201).json({ data: kit });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Update kit (owner only)
router.put('/:id', verifyToken, checkRole(['futsal_owner']), async (req, res) => {
    try {
        // Validate kit ID
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: 'Invalid kit ID' });
        }

        const { name, description, price, size, quantity, isAvailable, images } = req.body;
        
        const kit = await Kit.findById(req.params.id);
        if (!kit) {
            return res.status(404).json({ message: 'Kit not found' });
        }

        kit.name = name || kit.name;
        kit.description = description || kit.description;
        kit.price = price || kit.price;
        kit.size = size || kit.size;
        kit.quantity = quantity || kit.quantity;
        kit.isAvailable = isAvailable !== undefined ? isAvailable : kit.isAvailable;
        kit.images = images || kit.images;

        await kit.save();
        res.json(kit);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Delete kit (owner only)
router.delete('/:id', verifyToken, checkRole(['futsal_owner']), async (req, res) => {
    try {
        // Validate kit ID
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: 'Invalid kit ID' });
        }

        const kit = await Kit.findById(req.params.id);
        if (!kit) {
            return res.status(404).json({ message: 'Kit not found' });
        }

        await kit.remove();
        res.json({ message: 'Kit removed' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

module.exports = router; 