import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../models/kit_booking.dart';
import '../services/kit_booking_service.dart';
import '../models/kit.dart';
import '../models/booking_model.dart';

class KitRentalsScreen extends StatefulWidget {
  const KitRentalsScreen({Key? key}) : super(key: key);

  @override
  _KitRentalsScreenState createState() => _KitRentalsScreenState();
}

class _KitRentalsScreenState extends State<KitRentalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _inventory = [];
  List<KitBooking> _rentals = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final kitBookingService = Provider.of<KitBookingService>(context, listen: false);
      final inventory = await apiService.getKitInventory();
      final rentals = await kitBookingService.getUserKitBookings();
      
      print('KitRentalsScreen: Fetched rentals: ${rentals.length} items.');
      print('KitRentalsScreen: First rental item (if any): ${rentals.isNotEmpty ? rentals[0] : 'N/A'}');

      setState(() {
        _inventory = List<Map<String, dynamic>>.from(inventory);
        _rentals = rentals;
        print('KitRentalsScreen: _rentals list updated in setState: ${_rentals.length} items.');
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kit Rentals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Inventory'),
            Tab(text: 'Rentals'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).pushNamed('/add-kit'),
            tooltip: 'Add New Kit',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInventoryTab(),
                _buildRentalsTab(),
              ],
            ),
    );
  }

  Widget _buildInventoryTab() {
    if (_inventory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports_handball,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No items in inventory',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/add-kit'),
              child: const Text('Add New Kit'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _inventory.length,
      itemBuilder: (context, index) {
        final item = _inventory[index];
        return Card(
          child: ListTile(
            leading: Icon(
              Icons.sports_handball,
              color: item['available'] > 0 ? Colors.green : Colors.red,
            ),
            title: Text(item['name'] ?? ''),
            subtitle: Text('Size: ${item['size'] ?? 'N/A'}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Available: ${item['available']}',
                  style: TextStyle(
                    color: item['available'] > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total: ${item['total']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: () => Navigator.of(context).pushNamed(
              '/edit-kit',
              arguments: item,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRentalsTab() {
    if (_rentals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No active rentals',
              style: TextStyle(
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
      itemCount: _rentals.length,
      itemBuilder: (context, index) {
        final rental = _rentals[index];

        // Add extensive logging for debugging
        print('--- Building Rental Card for index: $index ---');
        print('Rental ID: ${rental.id}');
        print('Rental Status: ${rental.status}');
        print('Total Amount: ${rental.totalAmount}');
        print('Booking ID (from KitBooking model): ${rental.booking}');
        print('Booking Details object (from KitBooking model): ${rental.bookingDetails}');

        if (rental.bookingDetails != null) {
          print(' Booking Date: ${rental.bookingDetails?['date']}');
          print(' Booking StartTime: ${rental.bookingDetails?['startTime']}');
          print(' Booking EndTime: ${rental.bookingDetails?['endTime']}');
        }
        print('Futsal ID (from KitBooking model): ${rental.futsal}');
        print('Futsal Details object (from KitBooking model): ${rental.futsalDetails}');

        if (rental.futsalDetails != null) {
           print(' Futsal Name: ${rental.futsalDetails?['name']}');
        }
        print('KitRentals list: ${rental.kitRentals?.length ?? 0} items');
        if (rental.kitRentals != null) {
          for (int i = 0; i < rental.kitRentals!.length; i++) {
            final kitRentalItem = rental.kitRentals![i];
            print('  KitRentalItem #$i: $kitRentalItem');
            print('    Kit object: ${kitRentalItem.kit}');
            if (kitRentalItem.kit != null) {
              print('    Kit Name: ${kitRentalItem.kit?.name}');
              print('    Kit Size: ${kitRentalItem.kit?.size}');
            }
            print('    Quantity: ${kitRentalItem.quantity}');
            print('    Price: ${kitRentalItem.price}');
          }
        }
         print('--- End Rental Card Logging ---');

        // Format dates and times
        String rentalPeriod = 'N/A';
        if (rental.bookingDetails != null && rental.bookingDetails?['date'] != null) {
          try {
             final bookingDate = DateTime.parse(rental.bookingDetails!['date']); 
             final startTime = rental.bookingDetails!['startTime'];
             final endTime = rental.bookingDetails!['endTime'];
             rentalPeriod = 'From: ${bookingDate.toLocal().toString().split(' ')[0]} ${startTime ?? ''} To: ${bookingDate.toLocal().toString().split(' ')[0]} ${endTime ?? ''}';
          } catch (e) {
            print('Error parsing date or time for rental ${rental.id}: $e');
          }
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking ID: ${rental.id}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Futsal: ${rental.futsalDetails?['name'] ?? 'Unknown Futsal'}',
                ),
                Text('Rental Period: $rentalPeriod'),
                const SizedBox(height: 10),

                // Display list of rented kits
                if (rental.kitRentals != null && rental.kitRentals!.isNotEmpty)
                  ...rental.kitRentals!.map((kitRentalItem) {
                    final kit = kitRentalItem.kit;
                    final quantity = kitRentalItem.quantity;
                    final price = kitRentalItem.price;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: Icon(Icons.sports_soccer, size: 30, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kit?.name ?? 'Unknown Kit',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('Size: ${kit?.size ?? 'N/A'}'),
                                Text('Quantity: ${quantity ?? 'N/A'}'),
                                Text('Price per item: \$${price?.toString() ?? '0.00'}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()
                else
                   const Text('No kits rented for this booking.'),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '\$${rental.totalAmount?.toString() ?? '0.00'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getRentalStatusColor(rental.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rental.status ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRentalStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'returned':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
} 