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
import '../../models/time_slot.dart';
import '../../services/booking_service.dart';
import '../../services/kit_service.dart';
import '../../services/time_slot_service.dart'; // Added TimeSlotService
import 'kit_rental_screen.dart';
import 'dart:async'; // Import dart:async for Timer

class BookingScreen extends StatefulWidget {
  final String courtId;
  final String courtName;
  final double pricePerHour;
  final TimeSlot? selectedSlot;

  const BookingScreen({
    Key? key,
    required this.courtId,
    required this.courtName,
    required this.pricePerHour,
    this.selectedSlot,
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
  late DateTime _selectedDate;

  DateTime _getInitialDate() {
    final now = DateTime.now();
    print("Current time: ${now.toString()}");
    print("Current hour (local): ${now.hour}");
    
    // Convert to local time and check if it's past 9 PM (21:00)
    final hour = now.hour;
    print("Hour in 24-hour format: $hour");
    
    if (hour >= 21 || hour < 6) { // If it's past 9 PM or before 6 AM
      print("Past 9 PM or before 6 AM, selecting tomorrow");
      // Get tomorrow's date at midnight local time
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      print("Selected date (tomorrow): ${tomorrow.toString()}");
      return tomorrow;
    }
    
    print("Between 6 AM and 9 PM, selecting today");
    // Get today's date at midnight local time
    final today = DateTime(now.year, now.month, now.day);
    print("Selected date (today): ${today.toString()}");
    return today;
  }
  List<TimeSlot> _availableSlots = [];
  TimeSlot? _selectedSlot;
  Timer? _timer; // Add a Timer variable

  @override
  void initState() {
    super.initState();
    print("Initializing BookingScreen");
    
    // Set tomorrow's date if after 9 PM
    final now = DateTime.now();
    if (now.hour >= 21) {
      _selectedDate = DateTime(now.year, now.month, now.day + 1);
      print("After 9 PM, using tomorrow's date: ${_selectedDate.toString()}");
    } else {
      _selectedDate = DateTime(now.year, now.month, now.day);
      print("Before 9 PM, using today's date: ${_selectedDate.toString()}");
    }
    
    _loadCourts();
    
    if (widget.selectedSlot != null) {
      setState(() {
        _selectedSlot = widget.selectedSlot;
      });
    }
    
    // Fetch available slots once initialization is complete
    _fetchAvailableSlots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    _timer?.cancel(); // Cancel the timer in dispose
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
    // Cancel any existing timer before showing a new dialog
    _timer?.cancel();

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
          // Only add future slots based on current time for today, or all slots for future days
          if (date.isAfter(DateTime(now.year, now.month, now.day)) || slot.isAfter(DateTime.now())) {
            availableSlots.add(slot);
          }
          slot = slot.add(const Duration(hours: 1));
        }
      }
    }

    if (!mounted) return;

    // Filter out past slots before showing the dialog
    List<DateTime> currentAvailableSlots = availableSlots.where((slot) => slot.isAfter(DateTime.now())).toList();

    // Start a timer to periodically refresh the dialog
    _timer = Timer.periodic(const Duration(seconds: 30), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        // Re-filter the list to update the UI
        currentAvailableSlots = availableSlots.where((slot) => slot.isAfter(DateTime.now())).toList();
      });
    });

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
                    itemCount: currentAvailableSlots.length,
                    itemBuilder: (context, index) {
                      final slot = currentAvailableSlots[index];
                      // Create a card for the time slot with cleaner formatting
                      return Card(
                        child: ListTile(
                          title: Text(
                            slot != null ? DateFormat('HH:mm').format(slot) : 'Unknown Time',
                          ),
                          subtitle: Text(
                            slot != null ? DateFormat('EEEE, MMMM d').format(slot) : 'Unknown Date',
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

    // Cancel the timer after the dialog is dismissed
    _timer?.cancel();
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
      // Use TimeSlotService instead of BookingService
      final timeSlotService = Provider.of<TimeSlotService>(context, listen: false);
      
      final now = DateTime.now();
      print('Current time: ${now.toString()}');
      
      // If it's past 9 PM, use tomorrow's date
      DateTime targetDate;
      if (now.hour >= 21) {
        targetDate = DateTime(now.year, now.month, now.day + 1);
        print('Past 9 PM, using tomorrow: ${targetDate.toString()}');
      } else {
        targetDate = DateTime(now.year, now.month, now.day);
        print('Before 9 PM, using today: ${targetDate.toString()}');
      }
      
      // Fetch slots using the time slot service
      await timeSlotService.fetchTimeSlots(widget.courtId, targetDate);
      final slots = timeSlotService.timeSlots;
      
      // Filter slots if it's today
      final isToday = targetDate.day == now.day && targetDate.month == now.month && targetDate.year == now.year;
      print('Is today: $isToday');
      
      final availableSlots = isToday
        ? slots.where((slot) => slot.isAvailable && slot.startTime.isAfter(now)).toList()
        : slots.where((slot) => slot.isAvailable).toList();
      
      setState(() {
        _availableSlots = availableSlots;
        _isLoading = false;
        _error = null;
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
        'startTime': _selectedSlot!.formattedStartTime, // Use the formatted time string
        'endTime': _selectedSlot!.formattedEndTime, // Use the formatted time string
        'totalPrice': _selectedSlot!.price,
        'status': 'pending',
      };

      final booking = await bookingService.createBooking(bookingData);

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Booking Successful!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your booking has been confirmed.'),
              const SizedBox(height: 8),
              Text('Court: ${widget.courtName}'),
              Text('Date: ${DateFormat('MMM d, y').format(_selectedDate)}'),
              Text('Time: ${_selectedSlot!.formattedTimeRange}'),
              Text('Price: RS${_selectedSlot!.price.toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to home screen
              },
              child: const Text('Back to Home'),
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
              child: const Text('Rent Kits'),
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
        'startTime': slot.formattedStartTime, // Use the formatted time string
        'endTime': slot.formattedEndTime, // Use the formatted time string
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

  bool _isToday(TimeSlot slot) {
    final now = DateTime.now();
    final slotDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return slotDate.isAtSameMomentAs(today);
  }

  bool _isTomorrow(TimeSlot slot) {
    final now = DateTime.now();
    final slotDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return slotDate.isAtSameMomentAs(tomorrow);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${widget.courtName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selected Time Slot
            if (_selectedSlot != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Time Slot',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time: ${_selectedSlot!.formattedTimeRange}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Price: RS${_selectedSlot!.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirm Booking'),
              ),
            ] else ...[
              // Date Selection
              ListTile(
                title: const Text('Select Date'),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),

              // Available Time Slots
              if (_availableSlots.isEmpty) ...[
                Text(
                  'No available slots for today',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tomorrow\'s Time Slots',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ] else ...[
                Text(
                  'Available Time Slots',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              const SizedBox(height: 8),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                      : _availableSlots.isEmpty
                          ? const Center(child: Text('No available slots for selected date'))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Today's slots
                                if (_availableSlots.any((slot) => _isToday(slot))) ...[                                  
                                  const Text('Today\'s Slots',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _availableSlots.where((slot) => _isToday(slot)).length,
                                    itemBuilder: (context, index) {
                                      final slot = _availableSlots.where((slot) => _isToday(slot)).toList()[index];
                                      return Card(
                                        child: ListTile(
                                          title: Text(slot.formattedTimeRange),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(slot.formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Text('Price: RS${slot.price.toStringAsFixed(2)}'),
                                            ],
                                          ),
                                          trailing: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _selectedSlot = slot;
                                              });
                                            },
                                            child: const Text('Select'),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                
                                // Tomorrow's slots
                                if (_availableSlots.any((slot) => _isTomorrow(slot))) ...[                                  
                                  const Text('Tomorrow\'s Slots',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _availableSlots.where((slot) => _isTomorrow(slot)).length,
                                    itemBuilder: (context, index) {
                                      final slot = _availableSlots.where((slot) => _isTomorrow(slot)).toList()[index];
                                      return Card(
                                        child: ListTile(
                                          title: Text(slot.formattedTimeRange),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(slot.formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Text('Price: RS${slot.price.toStringAsFixed(2)}'),
                                            ],
                                          ),
                                          trailing: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _selectedSlot = slot;
                                              });
                                            },
                                            child: const Text('Select'),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Set to 1 since this is the booking screen
        type: BottomNavigationBarType.fixed, // Add this to show all items
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Kit Rental',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            // Navigate to home
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            // Already on bookings screen
          } else if (index == 2) {
            // Navigate to kit rental
            Navigator.pushReplacementNamed(context, '/kit-rental');
          } else if (index == 3) {
            // Navigate to profile
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    );
  }
} 