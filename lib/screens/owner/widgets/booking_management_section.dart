import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/booking_model.dart';
import '../../../services/api_service.dart';
import 'package:provider/provider.dart';

class BookingManagementSection extends StatelessWidget {
  final List<Booking> pendingBookings;
  final List<Booking> confirmedBookings;
  final List<Booking> cancelledBookings;
  final VoidCallback onRefresh;

  const BookingManagementSection({
    super.key,
    required this.pendingBookings,
    required this.confirmedBookings,
    required this.cancelledBookings,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Booking Management Coming Soon'),
    );
  }

  Widget _buildBookingsList(BuildContext context, List<Booking> bookings, String status) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text('Booking #${booking.id}'),
            subtitle: Text('${booking.user.name} - ${DateFormat('MMM d, y').format(booking.date)}'),
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(booking.status),
              child: Icon(
                _getStatusIcon(booking.status),
                color: Colors.white,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Field', booking.field.name),
                    _buildInfoRow('Date', DateFormat('MMM d, y').format(booking.date)),
                    _buildInfoRow('Time', '${booking.startTime} - ${booking.endTime}'),
                    _buildInfoRow('Customer', booking.user.name),
                    _buildInfoRow('Phone', booking.user.phone),
                    _buildInfoRow('Status', booking.status.toUpperCase()),
                    if (booking.kitRental != null) ...[
                      const SizedBox(height: 8),
                      const Text('Kit Rental:', style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildInfoRow('Jerseys', '${booking.kitRental!.jerseys} sets'),
                      _buildInfoRow('Shoes', '${booking.kitRental!.shoes} pairs'),
                      _buildInfoRow('Balls', '${booking.kitRental!.balls}'),
                    ],
                    const SizedBox(height: 16),
                    if (status == 'pending')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _updateBookingStatus(context, booking.id, 'cancelled'),
                            child: const Text('REJECT'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _updateBookingStatus(context, booking.id, 'confirmed'),
                            child: const Text('APPROVE'),
                          ),
                        ],
                      ),
                    if (status == 'confirmed')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _updateBookingStatus(context, booking.id, 'cancelled'),
                            child: const Text('CANCEL'),
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus(BuildContext context, String bookingId, String status) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.patch('/bookings/$bookingId/status', {'status': status});
      onRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking $status successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating booking: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.close;
      default:
        return Icons.help;
    }
  }
} 