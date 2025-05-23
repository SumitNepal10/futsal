import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/field_model.dart';
import '../../../models/booking_model.dart';
import '../../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../../models/time_slot_model.dart';

class TimeSlotManagementSection extends StatelessWidget {
  final List<TimeSlot> timeSlots;
  final VoidCallback onRefresh;

  const TimeSlotManagementSection({
    Key? key,
    required this.timeSlots,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Time Slot Management Coming Soon'),
    );
  }
} 