import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/favorites_service.dart';
import '../widgets/animated_favorite_button.dart';

class FutsalListPage extends StatefulWidget {
  const FutsalListPage({super.key});

  @override
  State<FutsalListPage> createState() => _FutsalListPageState();
}

class _FutsalListPageState extends State<FutsalListPage> {
  // Sample futsal data - replace with your actual data source
  final List<Map<String, dynamic>> _futsals = [
    {
      'id': '1',
      'name': 'Futsal Arena 1',
      'location': 'Location 1',
      'price': 'RM 50/hour',
      'imageUrl': 'assets/images/futsal_arena.png',
    },
    {
      'id': '2',
      'name': 'Futsal Arena 2',
      'location': 'Location 2',
      'price': 'RM 45/hour',
      'imageUrl': 'assets/images/futsal_arena.png',
    },
    // Add more futsal venues as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Futsal List'),
      ),
      body: Consumer<FavoritesService>(
        builder: (context, favoritesService, child) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _futsals.length,
            itemBuilder: (context, index) {
              final futsal = _futsals[index];
              final isFavorite = favoritesService.isFavorite(futsal['id']);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Image.asset(
                          futsal['imageUrl'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: AnimatedFavoriteButton(
                            isFavorite: isFavorite,
                            onPressed: () {
                              favoritesService.toggleFavorite(futsal['id']);
                            },
                            size: 32.0,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            futsal['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16),
                              const SizedBox(width: 4),
                              Text(futsal['location']),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.attach_money, size: 16),
                              const SizedBox(width: 4),
                              Text(futsal['price']),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate to booking screen
                              },
                              child: const Text('Book Now'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 