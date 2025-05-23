import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/kit.dart';
import '../../services/kit_service.dart';
import '../../services/kit_booking_service.dart';
import '../../services/api_service.dart';
import '../../models/booking.dart';
import 'dart:convert';
import '../../services/auth_service.dart';

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
  late final KitService _kitService;
  late final KitBookingService _kitBookingService;
  final TextEditingController _searchController = TextEditingController();
  List<Kit> _kits = [];
  Map<String, List<Kit>> _kitsByCategory = {};
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  Map<String, int> _selectedKits = {};

  final List<String> _categories = [
    'All',
    'Jersey',
    'Shorts',
    'Socks',
    'Shoes',
    'Accessories',
  ];

  @override
  void initState() {
    super.initState();
    // Get services from Provider
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    _kitService = KitService(apiService);
    _kitBookingService = KitBookingService(apiService, authService); // Pass both services
    _loadKits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKits() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final kits = await _kitService.getKitsByCourt(widget.booking.futsal);
      
      // Group kits by category
      final Map<String, List<Kit>> groupedKits = {};
      for (var kit in kits) {
        if (!groupedKits.containsKey(kit.type)) {
          groupedKits[kit.type] = [];
        }
        groupedKits[kit.type]!.add(kit);
      }

      setState(() {
        _kits = kits;
        _kitsByCategory = groupedKits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterKits(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _updateSelectedKit(String kitId, int quantity) {
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

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Convert selected kits to the format expected by the API
      final kitRentals = _selectedKits.entries.map((entry) {
        final kit = _kits.firstWhere((k) => k.id == entry.key);
        return {
          'kit': kit.toJson(),
          'quantity': entry.value,
          'price': kit.price,
        };
      }).toList();

      // Create kit booking
      await _kitBookingService.createKitBooking(
        futsalId: widget.booking.futsal,
        bookingId: widget.booking.id,
        kitRentals: kitRentals,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kit rental confirmed successfully')),
        );
        // Navigate back to the main navigation page (clearing the stack above it)
        Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => route.isFirst);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
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
                        itemCount: _selectedCategory == 'All' 
                            ? _kitsByCategory.length 
                            : 1,
                        itemBuilder: (context, index) {
                          final category = _selectedCategory == 'All'
                              ? _kitsByCategory.keys.elementAt(index)
                              : _selectedCategory!;
                          final categoryKits = _kitsByCategory[category] ?? [];

                          if (categoryKits.isEmpty) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  category,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...categoryKits.map((kit) {
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
                                        if (kit.imageUrl != null || (kit.images != null && kit.images!.isNotEmpty))
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: CachedNetworkImage(
                                              imageUrl: kit.imageUrl ?? kit.images!.first,
                                              height: 150,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                height: 150,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 16),
                                        Text(
                                          kit.name,
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        if (kit.description != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            kit.description!,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
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
                                                      ? () => _updateSelectedKit(
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
                                                      ? () => _updateSelectedKit(
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
                              }).toList(),
                            ],
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
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Confirm Rental'),
                      ),
                    ),
                  ],
                ),
    );
  }
} 
