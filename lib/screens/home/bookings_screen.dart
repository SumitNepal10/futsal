import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../models/booking.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final List<dynamic> data = await apiService.getOwnerBookings(_selectedFilter);
      final bookings = data.map((json) => Booking.fromJson(json)).toList();
      setState(() => _bookings = List<Booking>.from(bookings));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching bookings: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Active'),
            Tab(text: 'Past'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedFilter = value);
              _fetchBookings();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Futsals'),
              ),
              const PopupMenuItem(
                value: 'today',
                child: Text('Today'),
              ),
              const PopupMenuItem(
                value: 'week',
                child: Text('This Week'),
              ),
              const PopupMenuItem(
                value: 'month',
                child: Text('This Month'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBookings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList('upcoming'),
                _buildBookingsList('active'),
                _buildBookingsList('past'),
              ],
            ),
    );
  }

  Widget _buildBookingsList(String type) {
    final now = DateTime.now();
    final filteredBookings = _bookings.where((booking) {
      final status = booking.status?.toLowerCase() ?? '';
      final bookingStartDateTime = DateTime(
        booking.date.year,
        booking.date.month,
        booking.date.day,
        int.parse(booking.startTime.split(':')[0]),
        int.parse(booking.startTime.split(':')[1]),
      );
      final bookingEndDateTime = DateTime(
        booking.date.year,
        booking.date.month,
        booking.date.day,
        int.parse(booking.endTime.split(':')[0]),
        int.parse(booking.endTime.split(':')[1]),
      );

      switch (type) {
        case 'upcoming':
          // Upcoming: Booking date is in the future, or today but start time is in the future
          return (status == 'pending' || status == 'confirmed') &&
                 bookingStartDateTime.isAfter(now);
        case 'active':
          // Active: Booking date is today and current time is between start and end time
          return (status == 'confirmed' || status == 'active') &&
                 bookingStartDateTime.isBefore(now) &&
                 bookingEndDateTime.isAfter(now);
        case 'past':
          // Past: Booking date is in the past, or today but end time is in the past
          return (status == 'completed' || status == 'cancelled') ||
                 bookingEndDateTime.isBefore(now);
        default:
          return true;
      }
    }).toList();

    if (filteredBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type.toLowerCase()} bookings',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(booking.status),
              child: const Icon(
                Icons.sports_soccer,
                color: Colors.white,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Court: ${booking.futsalName}'),
                Text(
                  'Date: ${DateFormat('MMM d, y').format(booking.date)} (${booking.startTime} - ${booking.endTime})',
                ),
                Text('Booked by: ${booking.user.name}'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(booking.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                booking.status ?? 'Unknown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () => Navigator.of(context).pushNamed(
              '/booking-details',
              arguments: booking,
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 