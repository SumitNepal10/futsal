import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../models/booking_model.dart';
import '../../../models/kit_rental_model.dart' as kit_rental;

class FinancialSection extends StatefulWidget {
  final List<Booking> bookings;
  final List<kit_rental.KitRental> kitRentals;

  const FinancialSection({
    Key? key,
    required this.bookings,
    required this.kitRentals,
  }) : super(key: key);

  @override
  State<FinancialSection> createState() => _FinancialSectionState();
}

class _FinancialSectionState extends State<FinancialSection> {
  Map<String, dynamic> _financialData = {};
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.get(
        '/financial/summary',
        queryParams: {
          'year': _selectedDate.year.toString(),
          'month': _selectedDate.month.toString(),
        },
      );
      setState(() {
        _financialData = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load financial data: $e')),
      );
    }
  }

  double get _totalBookingRevenue {
    return widget.bookings
        .where((booking) => booking.status == 'confirmed')
        .fold(0.0, (sum, booking) => sum + booking.totalPrice);
  }

  double get _totalKitRentalRevenue {
    return widget.kitRentals
        .where((rental) => rental.status == 'confirmed')
        .fold(0.0, (sum, rental) => sum + rental.price);
  }

  double get _totalRevenue => _totalBookingRevenue + _totalKitRentalRevenue;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Financial Analytics Coming Soon'),
    );
  }

  Widget _buildRevenueRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}