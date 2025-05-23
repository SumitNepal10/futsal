import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:html' if (dart.library.io) 'dart:io' as io;
import 'dart:typed_data';
import '../../services/api_service.dart';
import 'dart:convert';
import '../../services/futsal_court_service.dart';

class OwnerAddFutsalScreen extends StatefulWidget {
  const OwnerAddFutsalScreen({super.key});

  @override
  State<OwnerAddFutsalScreen> createState() => _OwnerAddFutsalScreenState();
}

class _OwnerAddFutsalScreenState extends State<OwnerAddFutsalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _openingTimeController = TextEditingController(text: '08:00');
  final _closingTimeController = TextEditingController(text: '22:00');
  List<XFile> _images = [];
  List<String> _selectedFacilities = [];
  bool _isLoading = false;
  String? _error;

  final List<String> _availableFacilities = [
    'Parking',
    'Changing Rooms',
    'Showers',
    'Cafeteria',
    'WiFi',
    'First Aid',
    'Security',
    'Water Dispenser',
    'Restrooms',
    'Lighting',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _images.addAll(images);
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick images: $e';
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _addFutsal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_images.isEmpty) {
      setState(() {
        _error = 'Please select at least one image';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.addFutsal(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        pricePerHour: double.parse(_priceController.text.trim()),
        description: _descriptionController.text.trim(),
        images: _images,
        openingTime: _openingTimeController.text.trim(),
        closingTime: _closingTimeController.text.trim(),
        facilities: _selectedFacilities,
      );

      if (!mounted) return;

      // Refresh the courts list in the FutsalCourtService
      final futsalCourtService = Provider.of<FutsalCourtService>(context, listen: false);
      await futsalCourtService.fetchOwnerCourts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Futsal added successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Futsal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Futsal Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter futsal name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price per Hour',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value!) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _openingTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Opening Time',
                        border: OutlineInputBorder(),
                        hintText: 'HH:MM',
                      ),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Please enter opening time';
                        }
                        // Add time format validation if needed
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _closingTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Closing Time',
                        border: OutlineInputBorder(),
                        hintText: 'HH:MM',
                      ),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Please enter closing time';
                        }
                        // Add time format validation if needed
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Facilities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableFacilities.map((facility) {
                  return FilterChip(
                    label: Text(facility),
                    selected: _selectedFacilities.contains(facility),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFacilities.add(facility);
                        } else {
                          _selectedFacilities.remove(facility);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Images'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              if (_images.isNotEmpty) ...[
                const Text(
                  'Selected Images:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      final imageFile = _images[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            FutureBuilder<List<int>>(
                              future: imageFile.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      Uint8List.fromList(snapshot.data!),
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                } else if (snapshot.hasError) {
                                  return Container(
                                    height: 100,
                                    width: 100,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.error, size: 48, color: Colors.redAccent),
                                  );
                                } else {
                                  return Container(
                                    height: 100,
                                    width: 100,
                                    color: Colors.grey[200],
                                    child: const Center(child: CircularProgressIndicator()),
                                  );
                                }
                              },
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeImage(index),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _addFutsal,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add Futsal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 