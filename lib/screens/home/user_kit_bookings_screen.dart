import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/kit_booking_service.dart';
import '../../models/kit_booking.dart';
import '../../models/kit.dart';

class UserKitBookingsScreen extends StatefulWidget {
  const UserKitBookingsScreen({Key? key}) : super(key: key);

  @override
  _UserKitBookingsScreenState createState() => _UserKitBookingsScreenState();
}

class _UserKitBookingsScreenState extends State<UserKitBookingsScreen> {
  late KitBookingService _kitBookingService;
  List<KitBooking> _kitBookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    print('UserKitBookingsScreen: initState called.');
    super.initState();
    // print('UserKitBookingsScreen: initState called.'); // Keep this log

    // Defer Provider access and data fetching until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
       print('UserKitBookingsScreen: Inside addPostFrameCallback.');
       try {
          print('UserKitBookingsScreen: Attempting to access KitBookingService via Provider.of.');
          _kitBookingService = Provider.of<KitBookingService>(context, listen: false);
          print('UserKitBookingsScreen: Successfully accessed KitBookingService.');
          _fetchUserKitBookings();
       } catch (e) {
          print('UserKitBookingsScreen: Error accessing Provider in addPostFrameCallback: $e');
          setState(() {
             _error = 'Failed to initialize: ${e.toString()}';
             _isLoading = false;
          });
       }
    });
  }

  Future<void> _fetchUserKitBookings() async {
    print('UserKitBookingsScreen: _fetchUserKitBookings called.');
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bookings = await _kitBookingService.getUserKitBookings();
      // Add detailed logging of the received bookings
      print('UserKitBookingsScreen: Fetched bookings: ${bookings.length} items.');
      if (bookings.isNotEmpty) {
        print('UserKitBookingsScreen: First booking item (if any): ${bookings[0]}');
        if (bookings.first.kitRentals.isNotEmpty) {
          print('UserKitBookingsScreen: First kit rental details: ${bookings.first.kitRentals.first}');
          print('UserKitBookingsScreen: First kit details within rental: ${bookings.first.kitRentals.first.kit}');
        }
      }
      setState(() {
        _kitBookings = bookings;
        _isLoading = false;
      });
      print('UserKitBookingsScreen: _kitBookings list updated in setState: ${_kitBookings.length} items.');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('UserKitBookingsScreen: build method called.');
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Kit Rentals'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _kitBookings.isEmpty
                  ? const Center(
                      child: Text('You have no kit rentals yet.'),
                    )
                  : Builder(
                    builder: (context) {
                      return ListView.builder(
                          itemCount: _kitBookings.length,
                          itemBuilder: (context, index) {
                            final booking = _kitBookings[index];
                            // Add logging here to check individual booking data
                            print('--- Building Booking Card for index: $index ---');
                            print('  Booking object: ${booking}');
                            print('  Booking ID: ${booking.id}');
                            print('  Booking Status: ${booking.status}');
                            print('  Total Amount: ${booking.totalAmount}');
                            print('  Futsal ID: ${booking.futsal}');
                            print('  Futsal Details object (from KitBooking model): ${booking.futsalDetails}');
                            print('  Booking ID (from KitBooking model): ${booking.booking}');
                            print('  Booking Details object (from KitBooking model): ${booking.bookingDetails}');

                            if (booking.bookingDetails != null) {
                              print('  Booking Date: ${booking.bookingDetails?['date']}');
                              print('  Booking StartTime: ${booking.bookingDetails?['startTime']}');
                              print('  Booking EndTime: ${booking.bookingDetails?['endTime']}');
                            }

                            if (booking.futsalDetails != null) {
                              print('  Futsal Name: ${booking.futsalDetails?['name']}');
                            }

                            print('  KitRentals list: ${booking.kitRentals.length} items');

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (booking.bookingDetails != null) ...[
                                      Text('Booking Date: ${booking.bookingDetails!['date'] ?? 'N/A'}'),
                                      Text('Time: ${booking.bookingDetails!['startTime'] ?? 'N/A'} - ${booking.bookingDetails!['endTime'] ?? 'N/A'}'),
                                    ],
                                    Text('Futsal: ${booking.futsalDetails?['name'] ?? 'Unknown Futsal'}'),
                                    SizedBox(height: 8),
                                    Text('Status: ${booking.status}'),
                                    SizedBox(height: 8),
                                    Text('Total Amount: \$${booking.totalAmount.toStringAsFixed(2)}'),
                                    SizedBox(height: 16),
                                    Text('Rented Kits:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    SizedBox(height: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: booking.kitRentals.map((rental) {
                                        // Add logging here to check individual rental and kit data
                                        print('  Building rental item for Booking ID ${booking.id}:');
                                        print('    Rental object: ${rental}');
                                        print('    Kit object within rental: ${rental.kit}');
                                        if (rental.kit != null) {
                                          print('    Kit Name: ${rental.kit?.name}');
                                          print('    Kit Size: ${rental.kit?.size}');
                                        }
                                        print('    Quantity: ${rental.quantity}');
                                        print('    Price: ${rental.price}');
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                                          child: Text(
                                            ' - ${rental.kit.name ?? 'Unknown Kit'} (Size: ${rental.kit.size ?? 'N/A'}, Qty: ${rental.quantity}) - \$${(rental.kit.price * rental.quantity).toStringAsFixed(2)}',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}