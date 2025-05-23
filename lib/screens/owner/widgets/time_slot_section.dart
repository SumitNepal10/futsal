import 'package:flutter/material.dart';
import '../../../models/time_slot_model.dart';
import '../../../services/api_service.dart';
import 'package:provider/provider.dart';

class TimeSlotSection extends StatelessWidget {
  final List<TimeSlot> timeSlots;
  final VoidCallback onRefresh;

  const TimeSlotSection({
    Key? key,
    required this.timeSlots,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Time Slots',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (timeSlots.isEmpty)
              const Center(child: Text('No time slots found'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: timeSlots.length,
                itemBuilder: (context, index) {
                  final slot = timeSlots[index];
                  return Card(
                    child: ListTile(
                      title: Text('${slot.startTime} - ${slot.endTime}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Field: ${slot.field.name}'),
                          Text('Price: \$${slot.price.toStringAsFixed(2)}'),
                          Text('Status: ${slot.isAvailable ? "Available" : "Booked"}'),
                        ],
                      ),
                      trailing: Switch(
                        value: slot.isAvailable,
                        onChanged: (value) => _updateTimeSlotAvailability(context, slot.id, value),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTimeSlotAvailability(BuildContext context, String slotId, bool isAvailable) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.patch(
        '/time-slots/$slotId/availability',
        body: {'isAvailable': isAvailable},
      );
      onRefresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update time slot availability: $e')),
      );
    }
  }
} 