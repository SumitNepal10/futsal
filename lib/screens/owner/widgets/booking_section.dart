import 'package:flutter/material.dart';
import '../../../models/booking_model.dart';
import 'package:intl/intl.dart';

class BookingSection extends StatelessWidget {
  final List<Booking> bookings;
  final Future<void> Function() onRefresh;

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
                  // Format date directly as it's already a DateTime object
                  final formattedDate = DateFormat('yyyy-MM-dd').format(booking.date);

                  // Format time
                  final startTime = DateTime.parse('${booking.date.toIso8601String().split('T')[0]} ${booking.startTime}');
                  final endTime = DateTime.parse('${booking.date.toIso8601String().split('T')[0]} ${booking.endTime}');
                  final formattedStartTime = DateFormat('h:mm a').format(startTime);
                  final formattedEndTime = DateFormat('h:mm a').format(endTime);

                  return Card(
                    child: ListTile(
                      title: Text('Booking #${booking.id}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (booking.futsal != null) ...[
                             Text('Futsal: ${booking.futsal!.name}'),
                             Text('Location: ${booking.futsal!.location}'),
                          ],
                          Text('User: ${booking.user.name}'),
                          Text('Date: $formattedDate'),
                          Text('Time: $formattedStartTime - $formattedEndTime'),
                          if (booking.futsal != null) ...[
                            Text('Price per Hour: \${booking.futsal!.pricePerHour}'),
                          ],
                          Text('Total Price: \${booking.totalPrice}'),
                          Text('Status: ${booking.status}'),
                          if (booking.kitRentals != null && booking.kitRentals!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Kit Rentals:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: booking.kitRentals!.length,
                              itemBuilder: (context, kitIndex) {
                                final kit = booking.kitRentals![kitIndex];
                                // Access kit details with null checks
                                final kitName = kit.kitId?.name ?? 'N/A';
                                final kitQuantity = kit.quantity ?? 'N/A';
                                final kitPrice = kit.price ?? 'N/A';
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                                  child: Text(
                                    '- $kitName (x$kitQuantity) - \$$kitPrice',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                      trailing: booking.status == 'pending'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () => _updateBookingStatus(context, booking.id!, 'approved'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _updateBookingStatus(context, booking.id!, 'rejected'),
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