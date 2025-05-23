import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/futsal_court_service.dart';
import '../../models/futsal_court.dart';
import 'booking_screen.dart';
import 'kit_rental_screen.dart';
import '../../models/booking.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          courtId: court.id,
          courtName: court.name,
          pricePerHour: court.pricePerHour,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Futsal Courts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourts,
          ),
        ],
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
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
                              'Error loading courts: $_error',
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
                          final courts = futsalCourtService.courts;
                          return RefreshIndicator(
                            onRefresh: _loadCourts,
                            child: courts.isEmpty
                                ? const Center(
                                    child: Text('No futsal courts available'),
                                  )
                                : ListView.builder(
                                    itemCount: courts.length,
                                    itemBuilder: (context, index) {
                                      final court = courts[index];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: InkWell(
                                          onTap: () => _navigateToBooking(court),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (court.images != null && court.images!.isNotEmpty)
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Builder(
                                                    builder: (context) {
                                                      final imageUrl = court.images![0];
                                                      if (imageUrl != null && imageUrl.startsWith('http')) {
                                                        return Image.network(
                                                          imageUrl,
                                                          height: 150,
                                                          width: double.infinity,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error,
                                                                  stackTrace) =>
                                                              Container(
                                                            height: 150,
                                                            color: Colors.grey[300],
                                                            child: const Icon(
                                                              Icons.error_outline,
                                                              size: 48,
                                                              color: Colors.grey,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                      return Image.asset(
                                                        'assets/images/futsal_arena.png',
                                                        height: 150,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  ),
                                                )
                                              else
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.asset(
                                                    'assets/images/futsal_arena.png',
                                                    height: 150,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            court.name,
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .titleLarge,
                                                          ),
                                                        ),
                                                        Text(
                                                          '\$${court.pricePerHour}/hour',
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .titleMedium,
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      court.location,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Hours: ${court.openingTime} - ${court.closingTime}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium,
                                                    ),
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
    );
  }
} 