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
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    // TODO: Navigate to futsal details screen
                    // Navigator.of(context).pushNamed(
                    //   '/futsal-details',
                    //   arguments: futsal,
                    // );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (futsal.images != null && futsal.images!.isNotEmpty)
                          Builder(
                            builder: (context) {
                              final img = futsal.images![0];
                              if (img != null && img.startsWith('http')) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    img,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 150,
                                      color: Colors.grey[300],
                                      child: const Center(child: Icon(Icons.broken_image, size: 48)),
                                    ),
                                  ),
                                );
                              } else if (img != null && img.startsWith('data:image')) {
                                try {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      base64Decode(img.split(',').last),
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 150,
                                        color: Colors.grey[300],
                                        child: const Center(child: Icon(Icons.broken_image, size: 48)),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  return Container(
                                    height: 150,
                                    color: Colors.grey[300],
                                    child: const Center(child: Icon(Icons.broken_image, size: 48)),
                                  );
                                }
                              } else {
                                return Container(
                                  height: 150,
                                  color: Colors.grey[200],
                                  child: const Center(child: Icon(Icons.image, size: 48)),
                                );
                              }
                            },
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                futsal.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: futsal.isAvailable == true ? Colors.green : Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                futsal.isAvailable == true ? 'Available' : 'Not Available',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          futsal.location,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.sports,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${futsal.rating?.toStringAsFixed(1) ?? '0.0'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Set to 0 since this is the home/futsal list screen
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