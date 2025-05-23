import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../models/booking_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/login_screen.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final userData = await apiService.getCurrentUser();
      
      setState(() {
        user = userData;
        if (user?.phone == null) {
          user = user?.copyWith(phone: null);
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.logout();
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Header Section
            CircleAvatar(
              radius: 60,
              backgroundImage: (user?.profilePicture != null && user!.profilePicture is String)
                  ? (user!.profilePicture!.startsWith('data:image/')
                      ? Image.memory(base64Decode(user!.profilePicture!.split(',').last)).image
                      : NetworkImage(user!.profilePicture!))
                  : null,
              child: (user?.profilePicture == null || user!.profilePicture is! String || (user!.profilePicture is String && user!.profilePicture!.isEmpty))
                  ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'No Name',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.role ?? 'No Role',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // List of Options
            Card(
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  _buildProfileOption(context, Icons.edit_outlined, 'Edit Profile', () {
                    // TODO: Implement navigation to Edit Profile screen
                  }),
                  _buildDivider(),
                  _buildProfileOption(context, Icons.lock_outline, 'Change Password', () {
                    // TODO: Implement navigation to Change Password screen
                  }),
                  _buildDivider(),
                  _buildProfileOption(context, Icons.payment_outlined, 'Payment Methods', () {
                    // TODO: Navigate to Payment Methods screen
                  }),
                  _buildDivider(),
                  _buildProfileOption(context, Icons.help_outline, 'Help & Support', () {
                    // TODO: Navigate to Help & Support screen
                  }),
                  _buildDivider(),
                  _buildProfileOption(context, Icons.logout, 'Log Out', () => _handleLogout(context)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Container();
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.purple[100],
              child: Icon(icon, size: 20, color: Colors.purple[700]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 16, endIndent: 16);
  }
} 