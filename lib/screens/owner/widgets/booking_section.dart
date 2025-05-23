import 'package:flutter/material.dart';
import '../../../models/booking_model.dart';

class BookingSection extends StatelessWidget {
  final List<Booking> bookings;
  final VoidCallback onRefresh;

  const BookingSection({
    Key? key,
    required this.bookings,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bookings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (bookings.isEmpty)
              const Center(child: Text('No bookings found'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return Card(
                    child: ListTile(
                      title: Text('Booking #${booking.id}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User: ${booking.user.name}'),
                          Text('Date: ${booking.date}'),
                          Text('Time: ${booking.startTime} - ${booking.endTime}'),
                          Text('Status: ${booking.status}'),
                        ],
                      ),
                      trailing: booking.status == 'pending'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () => _updateBookingStatus(context, booking.id, 'approved'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _updateBookingStatus(context, booking.id, 'rejected'),
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateBookingStatus(BuildContext context, String bookingId, String status) async {
    try {
      // Update booking status logic here
      onRefresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking status: $e')),
      );
    }
  }
} 