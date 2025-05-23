import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/theme.dart';
import 'screens/auth/login_screen.dart';
import 'pages/main_navigation_page.dart';
import 'screens/owner/owner_dashboard_screen.dart';
import 'screens/futsal_list_screen.dart';
import 'screens/kit_rentals_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/owner/owner_add_futsal_screen.dart';
import 'screens/owner/add_kit_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/favorites_service.dart';
import 'services/futsal_court_service.dart';
import 'services/kit_service.dart';
import 'services/booking_service.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ApiService(),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthService(apiService: context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => FutsalCourtService(apiService: context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => KitService(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => BookingService(apiService: context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => FavoritesService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Futsal Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/owner-dashboard': (context) => const OwnerDashboardScreen(),
        '/home': (context) => const HomeScreen(),
        '/add-court': (context) => const OwnerAddFutsalScreen(),
        '/add-kit': (context) => const AddKitScreen(),
      },
    );
  }
}
