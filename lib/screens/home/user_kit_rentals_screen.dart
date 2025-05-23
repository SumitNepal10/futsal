import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/kit_service.dart';
import '../../services/auth_service.dart';
import '../../models/kit.dart';

class UserKitRentalsScreen extends StatefulWidget {
  const UserKitRentalsScreen({Key? key}) : super(key: key);

  @override
  State<UserKitRentalsScreen> createState() => _UserKitRentalsScreenState();
}

class _UserKitRentalsScreenState extends State<UserKitRentalsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _userRentals = [];

  @override
  void initState() {
    super.initState();
    _loadUserRentals();
  }

  Future<void> _loadUserRentals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final kitService = Provider.of<KitService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (authService.currentUser != null) {
        final rentals = await kitService.getUserRentals(authService.currentUser!.id);
        setState(() {
          _userRentals = List<Map<String, dynamic>>.from(rentals);
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Kit Rentals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserRentals,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading rentals: $_error',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserRentals,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _userRentals.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No active kit rentals',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUserRentals,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _userRentals.length,
                        itemBuilder: (context, index) {
                          final rental = _userRentals[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (rental['kitImage'] != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            rental['kitImage'],
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.sports_soccer,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.sports_soccer,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rental['kitName'] ?? 'Unknown Kit',
                                              style: Theme.of(context).textTheme.titleLarge,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Size: ${rental['size'] ?? 'N/A'}',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Quantity: ${rental['quantity'] ?? 1}',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Rental Period',
                                            style: Theme.of(context).textTheme.titleSmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'From: ${rental['startDate'] ?? 'N/A'}',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                          Text(
                                            'To: ${rental['endDate'] ?? 'N/A'}',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Total Price',
                                            style: Theme.of(context).textTheme.titleSmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${rental['totalPrice']?.toStringAsFixed(2) ?? '0.00'}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(rental['status']),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      rental['status']?.toUpperCase() ?? 'UNKNOWN',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 