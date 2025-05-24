import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/futsal_court_service.dart';
import '../models/futsal_court.dart';
import 'dart:typed_data';

class FutsalListScreen extends StatefulWidget {
  const FutsalListScreen({Key? key}) : super(key: key);

  @override
  _FutsalListScreenState createState() => _FutsalListScreenState();
}

class _FutsalListScreenState extends State<FutsalListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FutsalCourtService>(context, listen: false).fetchCourts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Futsal Courts'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<FutsalCourtService>(context, listen: false).fetchCourts(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<FutsalCourtService>(
        builder: (context, futsalCourtService, child) {
          final courts = futsalCourtService.courts;
          final isLoading = futsalCourtService.isLoading;
          final error = futsalCourtService.error;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading courts: ${error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => futsalCourtService.fetchCourts(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (courts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.sports_soccer,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No futsals available',
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
            itemCount: courts.length,
            itemBuilder: (context, index) {
              final futsal = courts[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    // TODO: Navigate to futsal details screen
                    // Navigator.of(context).pushNamed(
                    //   '/futsal-details',
                    //   arguments: futsal,
                    // );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (futsal.images != null && futsal.images!.isNotEmpty)
                        Builder(
                          builder: (context) {
                            final img = futsal.images![0];
                            if (img != null && img.startsWith('http')) {
                              return ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(
                                  img,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Center(child: Icon(Icons.broken_image, size: 48)),
                                  ),
                                ),
                              );
                            } else if (img != null && img.startsWith('data:image')) {
                              try {
                                return ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.memory(
                                    base64Decode(img.split(',').last),
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 200,
                                      color: Colors.grey[300],
                                      child: const Center(child: Icon(Icons.broken_image, size: 48)),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Center(child: Icon(Icons.broken_image, size: 48)),
                                );
                              }
                            } else {
                              return Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(child: Icon(Icons.image, size: 48)),
                              );
                            }
                          },
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    futsal.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: futsal.isAvailable == true ? Colors.green : Colors.grey,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    futsal.isAvailable == true ? 'Available' : 'Not Available',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    futsal.location,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${futsal.openingTime} - ${futsal.closingTime}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.attach_money, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'RM ${futsal.pricePerHour.toStringAsFixed(2)}/hour',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.star, size: 18, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '${futsal.rating?.toStringAsFixed(1) ?? '0.0'} (${futsal.totalRatings} reviews)',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            if (futsal.description.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                futsal.description,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (futsal.facilities.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: futsal.facilities.map((facility) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.blue[200]!),
                                    ),
                                    child: Text(
                                      facility,
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Kit Rental',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            // Already on home
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/bookings');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/kit-rental');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    );
  }
} 