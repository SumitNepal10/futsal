import 'package:flutter/material.dart';

class RegisterFutsalPage extends StatefulWidget {
  const RegisterFutsalPage({super.key});

  @override
  State<RegisterFutsalPage> createState() => _RegisterFutsalPageState();
}

class _RegisterFutsalPageState extends State<RegisterFutsalPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Futsal'),
      ),
      body: const Center(
        child: Text('Register Futsal Page'),
      ),
    );
  }
} 