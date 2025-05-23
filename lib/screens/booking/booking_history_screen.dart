import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/booking_service.dart';
import '../../models/booking_model.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final bookingService = Provider.of<BookingService>(context, listen: false);
    await bookingService.getUserBookings();
  }

  String _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return '#FFA500'; // Orange
      case BookingStatus.confirmed:
        return '#4CAF50'; // Green
      case BookingStatus.cancelled:
        return '#F44336'; // Red
      case BookingStatus.completed:
        return '#2196F3'; // Blue
      default:
        return '#9E9E9E'; // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
      ),
      body: Consumer<BookingService>(
        builder: (context, bookingService, child) {
          if (bookingService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bookingService.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${bookingService.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBookings,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final bookings = bookingService.bookings;
          if (bookings.isEmpty) {
            return const Center(
              child: Text('No bookings found'),
            );
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            booking.futsalName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(
                                  _getStatusColor(booking.status).replaceAll('#', '0xFF'),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking.status.toString().split('.').last,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${booking.date.day}/${booking.date.month}/${booking.date.year}',
                      ),
                      Text(
                        'Time: ${booking.startTime} - ${booking.endTime}',
                      ),
                      Text(
                        'Total Price: RM${booking.totalPrice.toStringAsFixed(2)}',
                      ),
                      if (booking.status == BookingStatus.pending) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                final success = await bookingService.cancelBooking(booking.id);
                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Booking cancelled successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Cancel Booking'),
                            ),
                          ],
                        ),
                      ],
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