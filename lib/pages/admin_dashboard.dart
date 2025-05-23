import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  void _checkAdminAccess() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    
    if (user.role != 'admin') {
      if (user.role == 'futsal_owner') {
        Navigator.of(context).pushReplacementNamed('/owner-dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
      return;
    }
    
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final stats = await apiService.getAdminStats();
      setState(() => _stats = stats);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching stats: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.logout();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  void _navigateToFutsalList() {
    Navigator.of(context).pushNamed('/futsal-list');
  }

  void _navigateToKitRentals() {
    Navigator.of(context).pushNamed('/kit-rentals');
  }

  void _navigateToBookings() {
    Navigator.of(context).pushNamed('/bookings');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    'Total Users',
                    _stats['totalUsers']?.toString() ?? '0',
                    Icons.people,
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    'Total Courts',
                    _stats['totalCourts']?.toString() ?? '0',
                    Icons.sports_soccer,
                    Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    'Total Bookings',
                    _stats['totalBookings']?.toString() ?? '0',
                    Icons.calendar_today,
                    Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    'Total Revenue',
                    '\$${_stats['totalRevenue']?.toString() ?? '0'}',
                    Icons.attach_money,
                    Colors.purple,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          'Manage Futsals',
                          Icons.sports_soccer,
                          Colors.blue,
                          _navigateToFutsalList,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionCard(
                          'Kit Rentals',
                          Icons.sports_handball,
                          Colors.green,
                          _navigateToKitRentals,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildActionCard(
                    'View Bookings',
                    Icons.calendar_month,
                    Colors.orange,
                    _navigateToBookings,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 