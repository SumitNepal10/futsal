import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _bookings = [];
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
      final bookings = await apiService.getOwnerBookings(_selectedFilter);
      setState(() => _bookings = List<Map<String, dynamic>>.from(bookings));
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
    final filteredBookings = _bookings.where((booking) {
      final status = booking['status']?.toLowerCase() ?? '';
      switch (type) {
        case 'upcoming':
          return status == 'pending' || status == 'confirmed';
        case 'active':
          return status == 'active';
        case 'past':
          return status == 'completed' || status == 'cancelled';
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
        final futsalName = booking['futsalName'] ?? 'N/A';
        final courtNumber = booking['courtNumber'] ?? 'N/A';
        final date = booking['date'] ?? 'N/A';
        final startTime = booking['startTime'] ?? 'N/A';
        final endTime = booking['endTime'] ?? 'N/A';
        final userName = booking['userName'] ?? 'N/A';
        final status = booking['status'] ?? 'Unknown';
        final statusColor = _getStatusColor(status);
        final futsalLocation = booking['futsal']?['location'] ?? 'N/A';
        final pricePerHour = booking['futsal']?['pricePerHour'] ?? 'N/A';
        final totalPrice = booking['totalPrice'] ?? 'N/A';
        final kitRentals = booking['kitRentals'] as List<dynamic>? ?? [];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10.0),
            onTap: () => Navigator.of(context).pushNamed(
              '/booking-details',
              arguments: booking,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          futsalName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Court: $courtNumber',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
                      const SizedBox(width: 4.0),
                      Text(
                        '$date ($startTime - $endTime)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Icon(Icons.person, size: 18, color: Colors.grey[700]),
                      const SizedBox(width: 4.0),
                      Text(
                        'Booked by: $userName',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Location: $futsalLocation',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Price per Hour: \$$pricePerHour',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Total Price: \$$totalPrice',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (kitRentals.isNotEmpty) ...[
                    const SizedBox(height: 8.0),
                    Text(
                      'Kit Rentals:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: kitRentals.length,
                      itemBuilder: (context, kitIndex) {
                        final kit = kitRentals[kitIndex];
                        final kitName = kit['kitId']?['name'] ?? 'N/A';
                        final kitQuantity = kit['quantity'] ?? 'N/A';
                        final kitPrice = kit['price'] ?? 'N/A';
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