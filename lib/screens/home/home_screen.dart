import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/futsal_court_service.dart';
import '../../models/futsal_court.dart';
import '../../models/time_slot.dart';
import 'booking_screen.dart';
import 'kit_rental_screen.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futsalCourtService = Provider.of<FutsalCourtService>(context, listen: false);
      print('_loadCourts: Calling fetchCourts...');
      await futsalCourtService.fetchCourts();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString() ?? 'Failed to load futsal courts.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToBooking(FutsalCourt court) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Futsal Image
                if (court.images != null && court.images!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      court.images![0] ?? '',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/futsal_arena.png',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Futsal Details
                Text(
                  court.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  court.location,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Price: RS${court.pricePerHour.toStringAsFixed(2)}/hour',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                // Available Time Slots
                Text(
                  'Available Time Slots',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<TimeSlot>>(
                  future: Provider.of<BookingService>(context, listen: false)
                      .getAvailableSlots(court.id, DateTime.now()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final slots = snapshot.data ?? [];
                    // Filter out slots that are not available
                    final availableSlots = slots.where((slot) => slot.isAvailable).toList();
                    
                    if (availableSlots.isEmpty) {
                      return const Center(
                        child: Text('No available slots for today'),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: availableSlots.length,
                      itemBuilder: (context, index) {
                        final slot = availableSlots[index];
                        return Card(
                          child: ListTile(
                            title: Text(slot.formattedTimeRange),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(slot.formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Price: RS${slot.price.toStringAsFixed(2)}'),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookingScreen(
                                      courtId: court.id,
                                      courtName: court.name,
                                      pricePerHour: court.pricePerHour,
                                      selectedSlot: slot,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Book'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToKitRental(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KitRentalScreen(booking: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('HomeScreen build method called');
    return Material(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Futsal Courts'),
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search futsal courts...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          FocusScope.of(context).unfocus(); // Dismiss keyboard
                        },
                      )
                    : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Error loading courts: ${_error}',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadCourts,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : Consumer<FutsalCourtService>(
                          builder: (context, futsalCourtService, child) {
                            final allCourts = futsalCourtService.courts;
                            
                            // Filter courts based on search query
                            final courts = _searchQuery.isEmpty
                                ? allCourts
                                : allCourts.where((court) {
                                    return court.name.toLowerCase().contains(_searchQuery) ||
                                           court.location.toLowerCase().contains(_searchQuery) ||
                                           court.description.toLowerCase().contains(_searchQuery) ||
                                           court.facilities.any((facility) => 
                                             facility.toLowerCase().contains(_searchQuery));
                                  }).toList();
                            return RefreshIndicator(
                              onRefresh: _loadCourts,
                              child: courts.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.sports_soccer,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'No futsals available',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: courts.length,
                                      itemBuilder: (context, index) {
                                        final futsal = courts[index];
                                        // Filter based on search query
                                        if (_searchQuery.isNotEmpty &&
                                            !futsal.name.toLowerCase().contains(_searchQuery) &&
                                            !futsal.location.toLowerCase().contains(_searchQuery) &&
                                            !futsal.facilities.any((facility) => facility.toLowerCase().contains(_searchQuery)))
                                        {
                                          return const SizedBox.shrink(); // Hide item if it doesn't match search
                                        }

                                        return Card(
                                          elevation: 4,
                                          margin: const EdgeInsets.only(bottom: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: InkWell(
                                            onTap: () => _navigateToBooking(futsal),
                                            borderRadius: BorderRadius.circular(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (futsal.images != null && futsal.images!.isNotEmpty)
                                                  ClipRRect(
                                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                                    child: Image.network(
                                                      futsal.images![0] ?? '',
                                                      height: 200,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Image.asset(
                                                        'assets/images/futsal_arena.png',
                                                        height: 200,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                Padding(
                                                  padding: const EdgeInsets.all(16),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              futsal.name,
                                                              style: const TextStyle(
                                                                fontSize: 20,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 6,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: futsal.isAvailable == true ? Colors.green : Colors.grey,
                                                              borderRadius: BorderRadius.circular(20),
                                                            ),
                                                            child: Text(
                                                              futsal.isAvailable == true ? 'Available' : 'Not Available',
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 12),
                                                      Row(
                                                        children: [
                                                          Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                                                          const SizedBox(width: 4),
                                                          Expanded(
                                                            child: Text(
                                                              futsal.location,
                                                              style: TextStyle(
                                                                color: Colors.grey[600],
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            '${futsal.openingTime} - ${futsal.closingTime}',
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Icon(Icons.attach_money, size: 18, color: Colors.grey[600]),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'RS ${futsal.pricePerHour.toStringAsFixed(2)}/hour',
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 12),
                                                      Row(
                                                        children: [
                                                          Icon(Icons.star, size: 18, color: Colors.amber),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            '${futsal.rating?.toStringAsFixed(1) ?? '0.0'} (${futsal.totalRatings} reviews)',
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (futsal.description.isNotEmpty) ...[
                                                        const SizedBox(height: 12),
                                                        Text(
                                                          futsal.description,
                                                          style: TextStyle(
                                                            color: Colors.grey[700],
                                                            fontSize: 14,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                      if (futsal.facilities.isNotEmpty) ...[
                                                        const SizedBox(height: 12),
                                                        Wrap(
                                                          spacing: 8,
                                                          runSpacing: 8,
                                                          children: futsal.facilities.map((facility) {
                                                            return Container(
                                                              padding: const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 6,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: Colors.blue[50],
                                                                borderRadius: BorderRadius.circular(20),
                                                                border: Border.all(color: Colors.blue[200]!),
                                                              ),
                                                              child: Text(
                                                                facility,
                                                                style: TextStyle(
                                                                  color: Colors.blue[700],
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
} 