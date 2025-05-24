import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/booking_model.dart';
import '../../models/time_slot_model.dart';
import '../../models/kit_rental_model.dart' as kit_rental;
import '../../services/api_service.dart';
import 'widgets/booking_section.dart';
import 'widgets/time_slot_section.dart';
import 'widgets/kit_rental_section.dart';
import '../../services/futsal_court_service.dart';
import '../../models/futsal_court.dart';
import 'owner_add_futsal_screen.dart';
import 'add_kit_page.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/kit_service.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({Key? key}) : super(key: key);

  @override
  _OwnerDashboardScreenState createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _selectedIndex = 0;
  List<Booking> _ownerBookings = [];
  bool _isLoadingOwnerBookings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _fetchOwnerBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final apiService = Provider.of<ApiService>(context, listen: false);
              await apiService.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          MyCourtsSection(),
          KitsSection(),
          _isLoadingOwnerBookings
              ? Center(child: CircularProgressIndicator())
              : BookingsSection(
                  bookings: _ownerBookings,
                  onRefresh: () async {
                    await _refreshOwnerBookings();
                  },
                ),
          AnalyticsSection(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'My Courts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_handball),
            label: 'Kits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          )
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }



  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      final futsalCourtService = Provider.of<FutsalCourtService>(context, listen: false);
      await futsalCourtService.fetchOwnerCourts();
      
      if (!mounted) return;
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Error fetching courts: $e')),
             );
           }
        });
      }
    }
  }

  Future<void> _fetchOwnerBookings() async {
    if (!mounted) return;
    setState(() => _isLoadingOwnerBookings = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getOwnerBookings('all');
      print('Owner Bookings Data: $data'); // Debug log
      
      final bookings = data.map((json) {
        print('Processing booking JSON: $json'); // Debug log
        return Booking.fromJson(json);
      }).toList();
      
      if (mounted) {
        setState(() => _ownerBookings = bookings);
      }
    } catch (e, stackTrace) {
      print('Error in _fetchOwnerBookings: $e\n$stackTrace'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching bookings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingOwnerBookings = false);
      }
    }
  }

  Future<void> _refreshOwnerBookings() async {
    await _fetchOwnerBookings();
  }
}

class MyCourtsSection extends StatefulWidget {
  const MyCourtsSection({Key? key}) : super(key: key);

  @override
  _MyCourtsSectionState createState() => _MyCourtsSectionState();
}

class _MyCourtsSectionState extends State<MyCourtsSection> {
  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      final futsalCourtService = Provider.of<FutsalCourtService>(context, listen: false);
      await futsalCourtService.fetchOwnerCourts();
      
      if (!mounted) return;
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Error fetching courts: $e')),
             );
           }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FutsalCourtService>(
      builder: (context, futsalCourtService, child) {
        if (futsalCourtService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (futsalCourtService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${futsalCourtService.error}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => futsalCourtService.fetchOwnerCourts(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final courts = futsalCourtService.ownerCourts;

        if (courts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No futsal courts added yet',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OwnerAddFutsalScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Futsal'),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Futsal Courts',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OwnerAddFutsalScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Futsal'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courts.length,
                itemBuilder: (context, index) {
                  final court = courts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  court.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: court.isAvailable
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  court.isAvailable ? 'Available' : 'Unavailable',
                                  style: TextStyle(
                                    color: court.isAvailable
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            court.description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  court.location,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${court.openingTime} - ${court.closingTime}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.attach_money, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Rs. ${court.pricePerHour}/hour',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${court.rating} (${court.totalRatings} ratings)',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          if (court.facilities.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Facilities:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: court.facilities.map((facility) {
                                return Chip(
                                  label: Text(facility),
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                );
                              }).toList(),
                            ),
                          ],
                          if (court.images?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: court.images?.length ?? 0,
                                itemBuilder: (context, index) {
                                  final imageUrl = court.images?[index];
                                  if (imageUrl == null) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        base64Decode(imageUrl.split(',').last),
                                        height: 200,
                                        width: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 200,
                                            width: 200,
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.error,
                                              size: 48,
                                              color: Colors.redAccent,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class KitsSection extends StatefulWidget {
  const KitsSection({Key? key}) : super(key: key);

  @override
  _KitsSectionState createState() => _KitsSectionState();
}

class _KitsSectionState extends State<KitsSection> {
  List<Map<String, dynamic>> _kits = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Jersey',
    'Shorts',
    'Shoes',
    'Socks',
    'Accessories',
  ];

  @override
  void initState() {
    super.initState();
    // Fetch kits when the section is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchKits();
    });
  }

  Future<void> _fetchKits() async {
    if (!mounted) return;


    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      // Ensure authentication token is loaded before fetching
      if (!apiService.isAuthenticated) {
        print('_fetchKits: User not authenticated');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to view kits')),
          );
        }
        setState(() => _isLoading = false); // Set loading to false if not authenticated
        return;
      }

      final response = await apiService.get(
        '/api/kits/owner',
        queryParams: _selectedCategory == 'All' ? null : {'category': _selectedCategory},
      );


      if (mounted) {
        if (response != null && response is List) {
          setState(() => _kits = List<Map<String, dynamic>>.from(response));
        } else {
          setState(() => _kits = []);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching kits: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, List<Map<String, dynamic>>> get _kitsByCategory {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final kit in _kits) {
      final type = (kit['type'] ?? 'Other').toString();
      if (!grouped.containsKey(type)) grouped[type] = [];
      grouped[type]!.add(kit);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final ownerName = authService.currentUser?.name ?? 'Owner';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Equipment & Kits',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Owner: $ownerName',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        value: Provider.of<KitService>(context, listen: false),
                        child: const AddKitPage(),
                      ),
                    ),
                  );
                  _fetchKits(); // Refresh after adding a new kit
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Kit'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                    _fetchKits(); // Fetch when category changes
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: Theme.of(context).colorScheme.primary,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchKits,
                  child: _kits.isEmpty
                      ? const Center(
                          child: Text(
                            'No kits found',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _kitsByCategory.length,
                          itemBuilder: (context, index) {
                            final category = _kitsByCategory.keys.elementAt(index);
                            final categoryKits = _kitsByCategory[category]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.8,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: categoryKits.length,
                                  itemBuilder: (context, kitIndex) {
                                    final kit = categoryKits[kitIndex];
                                    return Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                              child: kit['images'] != null && kit['images'].isNotEmpty
                                                  ? Image.memory(
                                                      base64Decode((kit['images'][0] as String).split(',').last),
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                    )
                                                  : Container(
                                                      color: Colors.grey[200],
                                                      child: const Icon(
                                                        Icons.sports_handball,
                                                        size: 48,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  kit['name'] ?? 'Unnamed Kit',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Size: ${kit['size'] ?? 'N/A'}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Rs.${kit['price']?.toString() ?? '0'}/day',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Qty: ${kit['quantity'] ?? '0'}',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

class BookingsSection extends StatefulWidget {
  const BookingsSection({Key? key, required this.bookings, required this.onRefresh}) : super(key: key);

  final List<Booking> bookings;
  final Future<void> Function() onRefresh;

  @override
  _BookingsSectionState createState() => _BookingsSectionState();
}

class _BookingsSectionState extends State<BookingsSection> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Bookings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: widget.bookings.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No bookings found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final booking = widget.bookings[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                '/booking-details',
                                arguments: booking,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      booking.futsal?.name ?? 'Unknown Futsal',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: booking.status == 'pending'
                                            ? Colors.orange
                                            : Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        booking.status,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Date: ${booking.date.year}-${booking.date.month.toString().padLeft(2, '0')}-${booking.date.day.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Time: ${booking.startTime.replaceAll(':00:00', '')} - ${booking.endTime.replaceAll(':00:00', '')}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Booked by: ${booking.user.name}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Phone: ${booking.user.phone.isEmpty ? 'Not provided' : booking.user.phone}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: booking.user.phone.isEmpty ? Colors.grey : null,
                                      ),
                                    ),
                                  ],
                                ),
                                if (booking.kitRentals?.isNotEmpty ?? false) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.sports_soccer, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Kit Rentals:',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ...booking.kitRentals?.map((rental) => Padding(
                                    padding: const EdgeInsets.only(left: 24, bottom: 4),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${rental.kitId?.name ?? 'Unknown Kit'} x${rental.quantity}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(Rs. ${rental.price})',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList() ?? [],
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.attach_money, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Total Price: Rs. ${booking.totalPrice}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                      },
                      childCount: widget.bookings.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class AnalyticsSection extends StatelessWidget {
  const AnalyticsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Analytics Coming Soon'),
    );
  }
} 