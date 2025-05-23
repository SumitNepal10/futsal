import 'package:flutter/material.dart';
import '../../../models/field_model.dart';

class AddFieldDialog extends StatefulWidget {
  final Function(Field) onAdd;

  const AddFieldDialog({
    Key? key,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<AddFieldDialog> createState() => _AddFieldDialogState();
}

class _AddFieldDialogState extends State<AddFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedType = '5-a-side';
  String _selectedSurface = 'artificial';

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final field = Field(
        id: '', // This will be set by the server
        name: _nameController.text,
        type: _selectedType,
        surface: _selectedSurface,
        price: double.parse(_priceController.text),
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      widget.onAdd(field);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Field'),
      content: const Text('Field form coming soon'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
} 