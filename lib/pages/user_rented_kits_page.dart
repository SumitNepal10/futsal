import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/kit_booking_service.dart';
import '../models/kit_booking.dart';
import '../models/kit.dart'; // Assuming Kit model is needed for displaying details
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart'; // Import the intl package

class UserRentedKitsPage extends StatefulWidget {
  const UserRentedKitsPage({Key? key}) : super(key: key);

  @override
  _UserRentedKitsPageState createState() => _UserRentedKitsPageState();
}

class _UserRentedKitsPageState extends State<UserRentedKitsPage> {
  late KitBookingService _kitBookingService;
  List<KitBooking> _rentedKits = []; // Use a different name for clarity
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer Provider access and data fetching
    WidgetsBinding.instance.addPostFrameCallback((_) {
       try {
          _kitBookingService = Provider.of<KitBookingService>(context, listen: false);
          _fetchUserRentedKits(); // New fetching function name
       } catch (e) {
          setState(() {
             _error = 'Failed to initialize: ${e.toString()}';
             _isLoading = false;
          });
       }
    });
  }

  Future<void> _fetchUserRentedKits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bookings = await _kitBookingService.getUserKitBookings(); // Fetch user bookings
      // For this page, we are interested in the *rented kits* within the bookings
      // We need to flatten the list of kitRentals from all bookings
      List<KitBooking> allRentedKits = [];
      for (var booking in bookings) {
        if (booking.kitRentals != null) {
          allRentedKits.add(booking); // We will display bookings, not flattened rentals
        }
      }

      setState(() {
        _rentedKits = allRentedKits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rented Kits'), // Updated title
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _rentedKits.isEmpty
                  ? const Center(
                      child: Text('You have not rented any kits yet.'), // Updated empty message
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rentedKits.length,
                      itemBuilder: (context, index) {
                        final booking = _rentedKits[index]; // Each item is a KitBooking

                        // Add extensive logging for debugging
                        // print('--- Building Rented Kit Card for index: $index ---');
                        // print('  Booking object: ${booking}');
                        // print('  Booking ID: ${booking.id}');
                        // print('  Booking Status: ${booking.status}');
                        //  print('  Total Amount: ${booking.totalAmount}');
                        //  print('  Futsal ID (from KitBooking model): ${booking.futsal}'); // Log the futsal ID string
                        // print('  Futsal Details object (from KitBooking model): ${booking.futsalDetails}'); // Log the futsalDetails map

                        // if (booking.futsalDetails != null) {
                        //    print('  Futsal Name: ${booking.futsalDetails?['name']}'); // Access futsal name from futsalDetails
                        // }
                        // print('  Booking ID (from KitBooking model): ${booking.booking}'); // Log the booking ID string
                        // print('  Booking Details object (from KitBooking model): ${booking.bookingDetails}'); // Log the bookingDetails map

                        // if (booking.bookingDetails != null) {
                        //     print('  Booking Date: ${booking.bookingDetails?['date']}'); // Access date from bookingDetails
                        //     print('  Booking StartTime: ${booking.bookingDetails?['startTime']}'); // Access startTime from bookingDetails
                        //     print('  Booking EndTime: ${booking.bookingDetails?['endTime']}'); // Access endTime from bookingDetails
                        // }
                        // print('  KitRentals list: ${booking.kitRentals.length} items');

                        return Card(
                           margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Restore horizontal margin for better spacing
                          child: Padding(
                            padding: const EdgeInsets.all(16.0), // Consistent padding
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Display Booking Details (like futsal name, date, time, status, total amount)
                                 if (booking.futsalDetails != null) // Display Futsal name if available
                                   Text('Futsal: ${booking.futsalDetails!['name'] ?? 'Unknown Futsal'}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Increase font size and weight for Futsal name
                                 SizedBox(height: 8),
                                if (booking.bookingDetails != null) ...[ // Display Date and Time if available
                                  // Format and display Date
                                  Text('Date: ${booking.bookingDetails!['date'] != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(booking.bookingDetails!['date'])) : 'N/A'}'),
                                  Text('Time: ${booking.bookingDetails!['startTime'] ?? 'N/A'} - ${booking.bookingDetails!['endTime'] ?? 'N/A'}'),
                                ],
                                SizedBox(height: 8),
                                Text('Status: ${booking.status}'),
                                SizedBox(height: 8),
                                Text('Total Amount: \$${booking.totalAmount.toStringAsFixed(2)}'),
                                SizedBox(height: 16),

                                // Separator line before Rented Kits section
                                if (booking.kitRentals != null && booking.kitRentals!.isNotEmpty) ...[
                                   Divider(height: 1, thickness: 1, color: Colors.grey[300]), // Add a divider
                                   SizedBox(height: 16), // Add space after divider
                                ],

                                // Display list of rented kits within this booking
                                if (booking.kitRentals != null && booking.kitRentals!.isNotEmpty) ...[ // Check if there are rented kits
                                   Text('Rented Kits:', style: TextStyle(fontWeight: FontWeight.bold)),
                                   SizedBox(height: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: booking.kitRentals!.map((kitRentalItem) { // Iterate through KitRental objects
                                      final kit = kitRentalItem.kit; // kit is a Kit object
                                      final quantity = kitRentalItem.quantity; // quantity is an int
                                      final price = kitRentalItem.price; // price is a double

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0), // Increase space between kit items
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Display Kit Image
                                            if (kit?.images != null && kit!.images!.isNotEmpty) // Check if images list exists and is not empty
                                               ClipRRect(
                                                borderRadius: BorderRadius.circular(8), // Rounded corners for image
                                                child: CachedNetworkImage(
                                                  imageUrl: kit.images!.first, // Use the first image URL
                                                  width: 60, // Adjust image size
                                                  height: 60, // Adjust image size
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(
                                                     width: 60,
                                                     height: 60,
                                                      color: Colors.grey[300],
                                                      child: Center(child: CircularProgressIndicator()), // Placeholder while loading
                                                  ),
                                                  errorWidget: (context, url, error) => Container(
                                                     width: 60,
                                                     height: 60,
                                                      color: Colors.grey[300],
                                                      child: Icon(Icons.image_not_supported, size: 30, color: Colors.grey[600]), // Error icon
                                                  ),
                                                ),
                                              )
                                            else // Placeholder if no image is available
                                               Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey[300],
                                                child: Icon(Icons.sports_soccer, size: 30, color: Colors.grey[600]),
                                              ),
                                            SizedBox(width: 10), // Space between image and kit details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    kit?.name ?? 'Unknown Kit', // Access kit name
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), // Adjust font size
                                                  ),
                                                  Text('Size: ${kit?.size ?? 'N/A'}', style: TextStyle(fontSize: 14)), // Adjust font size
                                                  Text('Quantity: ${quantity ?? 'N/A'}', style: TextStyle(fontSize: 14)), // Access quantity
                                                  Text('Price per item: \$${price?.toString() ?? '0.00'}', style: TextStyle(fontSize: 14)), // Access price
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(), // Convert mapped widgets to a list
                                  ),
                                ] else ...[ // Display if no kits rented for this booking
                                   SizedBox(height: 8), // Add spacing
                                  Text('No kits rented for this booking.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600], fontSize: 13)), // Adjusted message and font size
                                ],

                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
} 