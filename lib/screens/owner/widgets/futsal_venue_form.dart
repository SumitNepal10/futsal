import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../models/futsal_venue_model.dart';
import '../../../models/field_model.dart';
import '../../../services/api_service.dart';
import 'add_field_dialog.dart';
import '../../../../services/futsal_venue_service.dart';

class FutsalVenueForm extends StatefulWidget {
  final FutsalVenue? venue;
  final VoidCallback? onSuccess;

  const FutsalVenueForm({
    Key? key,
    this.venue,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<FutsalVenueForm> createState() => _FutsalVenueFormState();
}

class _FutsalVenueFormState extends State<FutsalVenueForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final List<String> _selectedFacilities = [];
  final List<Field> _fields = [];
  File? _imageFile;
  bool _isLoading = false;

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
  void initState() {
    super.initState();
    if (widget.venue != null) {
      _nameController.text = widget.venue!.name;
      _descriptionController.text = widget.venue!.description;
      _addressController.text = widget.venue!.address;
      _phoneController.text = widget.venue!.phone;
      _emailController.text = widget.venue!.email;
      _selectedFacilities.addAll(widget.venue!.facilities);
      _fields.addAll(widget.venue!.fields);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final venueService = Provider.of<FutsalVenueService>(context, listen: false);
      await venueService.createVenue(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        facilities: _selectedFacilities,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venue added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding venue: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addField() async {
    final field = await showDialog<Field>(
      context: context,
      builder: (context) => AddFieldDialog(
        onAdd: (field) => field,
      ),
    );

    if (field != null) {
      setState(() {
        _fields.add(field);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Venue Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Please enter venue name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Please enter address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Please enter email';
                }
                if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value!)) {
                  return 'Please enter a valid email address';
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Add Venue'),
            ),
          ],
        ),
      ),
    );
  }
} 