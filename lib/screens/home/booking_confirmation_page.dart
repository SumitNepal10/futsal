import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../pages/payment_methods_page.dart';
import '../../models/futsal_court.dart';

class BookingConfirmationPage extends StatefulWidget {
  final FutsalCourt court;
  final DateTime selectedTime;

  const BookingConfirmationPage({
    super.key,
    required this.court,
    required this.selectedTime,
  });

  @override
  State<BookingConfirmationPage> createState() => _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  String? _selectedPaymentMethod;
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': '1',
      'type': 'Credit Card',
      'lastFour': '4242',
      'isDefault': true,
      'icon': Icons.credit_card,
    },
    {
      'id': '2',
      'type': 'Debit Card',
      'lastFour': '1234',
      'isDefault': false,
      'icon': Icons.credit_card,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Futsal Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Futsal Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Builder(
                              builder: (context) {
                                final imageUrl = (widget.court.images != null && widget.court.images!.isNotEmpty) ? widget.court.images![0] : null;
                                if (imageUrl != null && imageUrl.startsWith('http')) {
                                  return Image.network(
                                    imageUrl,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Image.asset(
                                      'assets/images/futsal_arena.png',
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                } else if (imageUrl != null && imageUrl.startsWith('data:image')) {
                                  try {
                                    return Image.memory(
                                      base64Decode(imageUrl.split(',').last),
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Image.asset(
                                        'assets/images/futsal_arena.png',
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  } catch (e) {
                                    // Handle potential base64 decoding errors
                                    return Image.asset(
                                      'assets/images/futsal_arena.png',
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                } else {
                                  // Placeholder when the images list is null, empty, or the first element is null/invalid
                                  return Image.asset(
                                    'assets/images/futsal_arena.png',
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.court.name ?? 'Unknown Futsal',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.court.location ?? 'Unknown Location',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Booking Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Date',
                      DateFormat('EEEE, MMMM d, y').format(widget.selectedTime),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Time',
                      DateFormat('h:mm a').format(widget.selectedTime),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Duration',
                      '1 hour',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Price',
                      '\$${widget.court.pricePerHour.toStringAsFixed(2)}',
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${widget.court.pricePerHour.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Method Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Method',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PaymentMethodsPage(),
                              ),
                            );
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._paymentMethods.map((method) => RadioListTile<String>(
                      value: method['id'],
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      },
                      title: Row(
                        children: [
                          Icon(method['icon'] as IconData),
                          const SizedBox(width: 12),
                          Text('${method['type']} (**** ${method['lastFour']})'),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Book Now Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedPaymentMethod == null
                    ? null
                    : () {
                        // TODO: Implement booking logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Booking successful!'),
                          ),
                        );
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Book Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 