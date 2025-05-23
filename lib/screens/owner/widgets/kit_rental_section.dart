import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../services/kit_service.dart';
import '../../../models/kit_rental_model.dart';
import '../add_kit_screen.dart';

class KitsSection extends StatefulWidget {
  const KitsSection({Key? key}) : super(key: key);

  @override
  _KitsSectionState createState() => _KitsSectionState();
}

class _KitsSectionState extends State<KitsSection> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Jersey',
    'Shorts',
    'Shoes',
    'Socks',
    'Accessories',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchKits();
    });
  }

  Future<void> _fetchKits() async {
    if (!mounted) return;

    try {
      final kitService = Provider.of<KitService>(context, listen: false);
      await kitService.fetchKits(type: _selectedCategory == 'All' ? null : _selectedCategory);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching kits: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kitService = Provider.of<KitService>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Equipment & Kits',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  // Assuming AddKitPage is the screen to add kits
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddKitScreen(),
                    ),
                  );
                  _fetchKits(); // Refresh after adding a new kit
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Kit'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                    _fetchKits(); // Fetch when category changes
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: Theme.of(context).colorScheme.primary,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: kitService.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchKits,
                  child: kitService.kits.isEmpty
                      ? const Center(
                          child: Text(
                            'No kits found',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: kitService.kits.length,
                          itemBuilder: (context, index) {
                            final kit = kitService.kits[index];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: kit.images != null && kit.images!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: kit.images![0],
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              placeholder: (context, url) => Container(
                                                color: Colors.grey[200],
                                                child: const Center(child: CircularProgressIndicator()),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.sports_handball,
                                                  size: 48,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.sports_handball,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          kit.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Size: ${kit.size}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Rs.${kit.price.toString()}/day',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                            Text(
                                              'Qty: ${kit.quantity}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
} 