import 'package:flutter/material.dart';

class RentalHistoryPage extends StatelessWidget {
  const RentalHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample rental history data - replace with actual data
    final List<Map<String, dynamic>> rentalHistory = [
      {
        'id': '1',
        'date': '2024-03-15',
        'venue': 'Futsal Arena 1',
        'items': ['Nike Team Jersey', 'Adidas Training Shorts'],
        'total': 27.00,
        'status': 'Completed',
      },
      {
        'id': '2',
        'date': '2024-03-10',
        'venue': 'Futsal Arena 2',
        'items': ['Puma Performance Socks', 'Shin Guards'],
        'total': 18.00,
        'status': 'Completed',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental History'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rentalHistory.length,
        itemBuilder: (context, index) {
          final rental = rentalHistory[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        rental['date'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          rental['status'],
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rental['venue'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rented Items:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...rental['items'].map((item) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text('• $item'),
                      )),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${rental['total'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 