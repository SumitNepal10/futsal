import 'package:flutter/material.dart';

class FutsalDashboard extends StatefulWidget {
  const FutsalDashboard({super.key});

  @override
  State<FutsalDashboard> createState() => _FutsalDashboardState();
}

class _FutsalDashboardState extends State<FutsalDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Futsal Dashboard'),
      ),
      body: const Center(
        child: Text('Futsal Dashboard'),
      ),
    );
  }
} 