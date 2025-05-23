import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/kit_service.dart';
import '../../models/kit.dart';

class KitBrowseScreen extends StatefulWidget {
  const KitBrowseScreen({Key? key}) : super(key: key);

  @override
  State<KitBrowseScreen> createState() => _KitBrowseScreenState();
}

class _KitBrowseScreenState extends State<KitBrowseScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadKits();
  }

  Future<void> _loadKits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final kitService = Provider.of<KitService>(context, listen: false);
      await kitService.fetchKits();
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
        title: const Text('Available Kits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadKits,
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
                        'Error loading kits: $_error',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadKits,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Consumer<KitService>(
                  builder: (context, kitService, child) {
                    final kits = kitService.kits;
                    return RefreshIndicator(
                      onRefresh: _loadKits,
                      child: kits.isEmpty
                          ? const Center(
                              child: Text('No kits available'),
                            )
                          : ListView.builder(
                              itemCount: kits.length,
                              itemBuilder: (context, index) {
                                final kit = kits[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    leading: kit.imageUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: Image.network(
                                              kit.imageUrl!,
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Container(
                                                width: 56,
                                                height: 56,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.error_outline,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            width: 56,
                                            height: 56,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.sports_soccer,
                                              color: Colors.grey,
                                            ),
                                          ),
                                    title: Text(kit.name),
                                    subtitle: Text(
                                        'Size: ${kit.size}, Quantity: ${kit.quantity}'),
                                    trailing: Text(
                                      '\$${kit.price}/day',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    );
                  },
                ),
    );
  }
} 