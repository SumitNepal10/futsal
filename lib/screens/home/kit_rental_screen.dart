import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/kit.dart';
import '../../services/kit_service.dart';
import '../../services/booking_service.dart';
import '../../models/booking.dart';
import 'dart:convert';

class KitRentalScreen extends StatefulWidget {
  final Booking booking;

  const KitRentalScreen({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  State<KitRentalScreen> createState() => _KitRentalScreenState();
}

class _KitRentalScreenState extends State<KitRentalScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Kit> _kits = [];
  List<Kit> _filteredKits = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final Map<String, int> _selectedKits = {};
  String? _error;

  final List<String> _categories = [
    'All',
    'Jerseys',
    'Shorts',
    'Socks',
    'Shoes',
    'Accessories',
  ];

  @override
  void initState() {
    super.initState();
    _loadKits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final kitService = Provider.of<KitService>(context, listen: false);
      final courtKits = await kitService.getKitsByCourt(widget.booking.futsal);
      setState(() {
        _kits = courtKits;
        _filteredKits = courtKits;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterKits(String query) {
    setState(() {
      _filteredKits = _kits.where((kit) {
        final matchesSearch = kit.name.toLowerCase().contains(query.toLowerCase());
        final matchesCategory = _selectedCategory == 'All' ||
            kit.type == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _updateKitQuantity(String kitId, int quantity) {
    setState(() {
      if (quantity > 0) {
        _selectedKits[kitId] = quantity;
      } else {
        _selectedKits.remove(kitId);
      }
    });
  }

  Future<void> _confirmRental() async {
    if (_selectedKits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one kit')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final kitService = Provider.of<KitService>(context, listen: false);
      final bookingService = Provider.of<BookingService>(context, listen: false);

      // Convert selected kits to the format expected by the API
      final kitRentals = _selectedKits.entries.map((entry) => {
        'kit': entry.key,
        'quantity': entry.value,
      }).toList();

      // Update the booking with kit rentals
      await bookingService.updateBooking(
        widget.booking.id,
        {'kitRentals': kitRentals},
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kit rental successful')),
      );

      // Navigate back to booking details
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error renting kits: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rent Kits'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search Kits',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onChanged: _filterKits,
                      ),
                    ),
                    SizedBox(
                      height: 50.0,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                  _filterKits(_searchController.text);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredKits.length,
                        itemBuilder: (context, index) {
                          final kit = _filteredKits[index];
                          final quantity = _selectedKits[kit.id] ?? 0;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    kit.name,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Type: ${kit.type}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Price: \$${kit.price}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Available: ${kit.quantity}',
                                        style: TextStyle(
                                          color: kit.quantity > 0
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: quantity > 0
                                                ? () => _updateKitQuantity(
                                                    kit.id, quantity - 1)
                                                : null,
                                          ),
                                          Text(
                                            quantity.toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: quantity < kit.quantity
                                                ? () => _updateKitQuantity(
                                                    kit.id, quantity + 1)
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: _selectedKits.isEmpty
                            ? null
                            : _confirmRental,
                        child: const Text('Confirm Rental'),
                      ),
                    ),
                  ],
                ),
    );
  }
} 
