import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/field_service.dart';
import '../services/booking_service.dart';
import '../services/kit_service.dart';

class Providers {
  static List<ChangeNotifierProvider> providers = [
    ChangeNotifierProvider<AuthService>(
      create: (_) => AuthService(),
    ),
    ChangeNotifierProvider<FieldService>(
      create: (_) => FieldService(),
    ),
    ChangeNotifierProvider<BookingService>(
      create: (_) => BookingService(),
    ),
    ChangeNotifierProvider<KitService>(
      create: (_) => KitService(),
    ),
  ];
} 