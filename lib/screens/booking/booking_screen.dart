import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/booking_service.dart';
import '../../services/payment_service.dart';
import '../../models/booking_model.dart';

class BookingScreen extends StatefulWidget {
  final String futsalId;
  final String futsalName;
  final double pricePerHour;

  const BookingScreen({
    super.key,
    required this.futsalId,
    required this.futsalName,
    required this.pricePerHour,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String _selectedStartTime = '09:00';
  String _selectedEndTime = '10:00';
  String _selectedPaymentMethod = '';
  bool _isLoading = false;

  final List<String> _timeSlots = [
    '09:00', '10:00', '11:00', '12:00', '13:00', '14:00',
    '15:00', '16:00', '17:00', '18:00', '19:00', '20:00',
    '21:00', '22:00', '23:00'
  ];

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    final paymentService = Provider.of<PaymentService>(context, listen: false);
    final methods = await paymentService.getPaymentMethods();
    if (methods.isNotEmpty) {
      setState(() {
        _selectedPaymentMethod = methods[0]['id'];
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  double _calculateTotalPrice() {
    final startIndex = _timeSlots.indexOf(_selectedStartTime);
    final endIndex = _timeSlots.indexOf(_selectedEndTime);
    final hours = endIndex - startIndex;
    return hours * widget.pricePerHour;
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final bookingService = Provider.of<BookingService>(context, listen: false);
      final paymentService = Provider.of<PaymentService>(context, listen: false);

      // Create booking
      final booking = await bookingService.createBooking(
        futsalId: widget.futsalId,
        date: _selectedDate,
        startTime: _selectedStartTime,
        endTime: _selectedEndTime,
        totalPrice: _calculateTotalPrice(),
      );

      if (booking != null) {
        // Process payment
        final payment = await paymentService.processPayment(
          bookingId: booking.id,
          amount: booking.totalPrice,
          paymentMethod: _selectedPaymentMethod,
        );

        if (payment != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${widget.futsalName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Selection
              ListTile(
                title: const Text('Select Date'),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              // Time Selection
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStartTime,
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                      ),
                      items: _timeSlots.map((time) {
                        return DropdownMenuItem(
                          value: time,
                          child: Text(time),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedStartTime = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedEndTime,
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                      ),
                      items: _timeSlots.map((time) {
                        return DropdownMenuItem(
                          value: time,
                          child: Text(time),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedEndTime = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Payment Method Selection
              Consumer<PaymentService>(
                builder: (context, paymentService, child) {
                  if (paymentService.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: paymentService.getPaymentMethods(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final methods = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        value: _selectedPaymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                        ),
                        items: methods.map((method) {
                          return DropdownMenuItem(
                            value: method['id'],
                            child: Text(method['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPaymentMethod = value);
                          }
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Total Price
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Total Price',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RM${_calculateTotalPrice().toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Book Button
              ElevatedButton(
                onPressed: _isLoading ? null : _createBooking,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Book Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 