import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:futsal_application/services/favorites_service.dart';
import 'package:futsal_application/services/futsal_court_service.dart';
import 'package:futsal_application/models/futsal_court.dart';
import 'package:futsal_application/screens/home/booking_confirmation_page.dart';
import 'dart:convert';
import 'package:futsal_application/services/api_service.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../services/kit_service.dart';
import 'kit_rental_screen.dart';

class BookingScreen extends StatefulWidget {
  final String courtId;
  final String courtName;
  final double pricePerHour;

  const BookingScreen({
    Key? key,
    required this.courtId,
    required this.courtName,
    required this.pricePerHour,
  }) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _isMapView = false;
  final TextEditingController _searchController = TextEditingController();
  List<FutsalCourt> _courts = [];
  bool _isLoading = true;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  String? _error;
  DateTime _selectedDate = DateTime.now();
  List<TimeSlot> _availableSlots = [];
  TimeSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _loadCourts();
    _fetchAvailableSlots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadCourts() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.get('/api/futsals');
      setState(() {
        _courts = (response as List)
            .where((json) => json is Map<String, dynamic>)
            .map((json) => FutsalCourt.fromJson(json))
            .toList();
        _isLoading = false;
        _error = null;
        _updateMarkers();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _updateMarkers() {
    _markers = _courts.map((court) {
      // Extract latitude and longitude from location string
      // Assuming location is stored as "latitude,longitude" in the database
      final locationParts = court.location.split(',');
      double? latitude;
      double? longitude;
      
      if (locationParts.length == 2) {
        latitude = double.tryParse(locationParts[0].trim());
        longitude = double.tryParse(locationParts[1].trim());
      }

      // Use default location if parsing fails
      latitude ??= 3.1469;
      longitude ??= 101.6932;

      return Marker(
        markerId: MarkerId(court.id),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(
          title: court.name,
          snippet: court.location,
        ),
        onTap: () => _showBookingDialog(court),
      );
    }).toSet();
  }

  Future<void> _showBookingDialog(FutsalCourt court) async {
    final DateTime now = DateTime.now();
    final List<DateTime> availableSlots = [];
    
    // Convert opening and closing times to DateTime
    final openingTime = _parseTime(court.openingTime);
    final closingTime = _parseTime(court.closingTime);
    
    if (openingTime != null && closingTime != null) {
      for (int i = 0; i < 7; i++) {
        final DateTime date = DateTime(now.year, now.month, now.day + i);
        DateTime slot = DateTime(date.year, date.month, date.day, openingTime.hour, openingTime.minute);
        
        while (slot.isBefore(DateTime(date.year, date.month, date.day, closingTime.hour, closingTime.minute))) {
          if (slot.isAfter(now)) { // Only add future slots
            availableSlots.add(slot);
          }
          slot = slot.add(const Duration(hours: 1));
        }
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Builder(
                    builder: (context) {
                      final imageUrl = (court.images != null && court.images!.isNotEmpty) ? court.images![0] : null;
                      if (imageUrl != null && imageUrl.startsWith('http')) {
                        return Image.network(
                          imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/images/futsal_arena.png',
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        );
                      } else if (imageUrl != null && imageUrl.startsWith('data:image')) {
                        try {
                          return Image.memory(
                            base64Decode(imageUrl.split(',').last),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/images/futsal_arena.png',
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          );
                        } catch (e) {
                          return Image.asset(
                            'assets/images/futsal_arena.png',
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        }
                      } else {
                        return Image.asset(
                          'assets/images/futsal_arena.png',
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  court.name ?? 'Unknown Futsal',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  court.location ?? 'Unknown Location',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Price: \$${court.pricePerHour?.toStringAsFixed(2) ?? 'N/A'}/hour',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Available Time Slots',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: availableSlots.length,
                    itemBuilder: (context, index) {
                      final slot = availableSlots[index];
                      return ListTile(
                        title: Text(
                          slot != null ? DateFormat('EEEE, MMMM d, y').format(slot) : 'Unknown Date',
                        ),
                        subtitle: Text(
                          slot != null ? DateFormat('h:mm a').format(slot) : 'Unknown Time',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingConfirmationPage(
                                court: court,
                                selectedTime: slot,
                              ),
                            ),
                          ),
                          child: const Text('Book'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DateTime? _parseTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(2000, 1, 1, hour, minute);
      }
    } catch (e) {
      // Optionally handle or ignore the error
    }
    return null;
  }

  Future<void> _fetchAvailableSlots() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookingService = Provider.of<BookingService>(context, listen: false);
      final slots = await bookingService.getAvailableSlots(
        widget.courtId,
        _selectedDate,
      );
      setState(() {
        _availableSlots = slots;
        _selectedSlot = null;
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _fetchAvailableSlots();
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookingService = Provider.of<BookingService>(context, listen: false);
      final bookingData = {
        'futsal': widget.courtId,
        'futsalName': widget.courtName,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'startTime': _selectedSlot!.startTime,
        'endTime': _selectedSlot!.endTime,
        'totalPrice': _selectedSlot!.price,
        'status': 'pending',
      };

      final booking = await bookingService.createBooking(bookingData);

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Booking Successful'),
          content: const Text('Would you like to rent kits for this booking?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to previous screen
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KitRentalScreen(booking: booking),
                  ),
                );
              },
              child: const Text('Yes'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating booking: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createBooking(TimeSlot slot) async {
    try {
      final bookingService = Provider.of<BookingService>(context, listen: false);
      final bookingData = {
        'futsal': widget.courtId,
        'futsalName': widget.courtName,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'startTime': slot.startTime,
        'endTime': slot.endTime,
        'totalPrice': slot.price,
        'status': 'pending',
      };

      final booking = await bookingService.createBooking(bookingData);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingConfirmationPage(
              court: _courts.firstWhere((court) => court.id == widget.courtId),
              selectedTime: _selectedDate,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create booking: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_isMapView ? Icons.list : Icons.map),
                  onPressed: () {
                    setState(() {
                      _isMapView = !_isMapView;
                    });
                  },
                ),
              ],
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
                    : _isMapView
                        ? GoogleMap(
                            initialCameraPosition: const CameraPosition(
                              target: LatLng(3.1469, 101.6932),
                              zoom: 12,
                            ),
                            markers: _markers,
                            onMapCreated: (controller) {
                              _mapController = controller;
                            },
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCourts,
                            child: _courts.isEmpty
                                ? const Center(
                                    child: Text('No futsal courts available'),
                                  )
                                : ListView.builder(
                                    itemCount: _courts.length,
                                    itemBuilder: (context, index) {
                                      final court = _courts[index];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: InkWell(
                                          onTap: () => _showBookingDialog(court),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                  top: Radius.circular(4),
                                                ),
                                                child: Builder(
                                                  builder: (context) {
                                                    final imageUrl = (court.images != null && court.images!.isNotEmpty) ? court.images![0] : null;
                                                    if (imageUrl != null && imageUrl.startsWith('http')) {
                                                      return Image.network(
                                                        imageUrl,
                                                        height: 150,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) => Image.asset(
                                                          'assets/images/futsal_arena.png',
                                                          height: 150,
                                                          width: double.infinity,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      );
                                                    } else if (imageUrl != null && imageUrl.startsWith('data:image')) {
                                                      try {
                                                        return Image.memory(
                                                          base64Decode(imageUrl.split(',').last),
                                                          height: 150,
                                                          width: double.infinity,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) => Image.asset(
                                                            'assets/images/futsal_arena.png',
                                                            height: 150,
                                                            width: double.infinity,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        );
                                                      } catch (e) {
                                                        return Image.asset(
                                                          'assets/images/futsal_arena.png',
                                                          height: 150,
                                                          width: double.infinity,
                                                          fit: BoxFit.cover,
                                                        );
                                                      }
                                                    } else {
                                                      return Image.asset(
                                                        'assets/images/futsal_arena.png',
                                                        height: 150,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                      );
                                                    }
                                                  },
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
                                                            court.name ?? 'Unknown Futsal',
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .titleLarge,
                                                          ),
                                                        ),
                                                        Text(
                                                          '\$${court.pricePerHour?.toStringAsFixed(2) ?? 'N/A'}/hour',
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .titleMedium,
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      court.location ?? 'Unknown Location',
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
                          ),
          ),
        ],
      ),
    );
  }
} 