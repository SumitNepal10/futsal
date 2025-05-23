import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';

class KitRentalsScreen extends StatefulWidget {
  const KitRentalsScreen({Key? key}) : super(key: key);

  @override
  _KitRentalsScreenState createState() => _KitRentalsScreenState();
}

class _KitRentalsScreenState extends State<KitRentalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _inventory = [];
  List<Map<String, dynamic>> _rentals = [];
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
      final inventory = await apiService.getKitInventory();
      final rentals = await apiService.getKitRentals();
      setState(() {
        _inventory = List<Map<String, dynamic>>.from(inventory);
        _rentals = List<Map<String, dynamic>>.from(rentals);
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
        return Card(
          child: ListTile(
            leading: const Icon(Icons.assignment),
            title: Text(rental['itemName'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rented by: ${rental['userName'] ?? ''}'),
                Text(
                  'From: ${rental['startDate'] ?? ''} - To: ${rental['endDate'] ?? ''}',
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getRentalStatusColor(rental['status']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                rental['status'] ?? 'Unknown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () => Navigator.of(context).pushNamed(
              '/rental-details',
              arguments: rental,
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