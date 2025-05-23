import 'package:flutter/material.dart';

class SearchFutsalPage extends StatefulWidget {
  const SearchFutsalPage({super.key});

  @override
  State<SearchFutsalPage> createState() => _SearchFutsalPageState();
}

class _SearchFutsalPageState extends State<SearchFutsalPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Futsal'),
      ),
      body: const Center(
        child: Text('Search Futsal Page'),
      ),
    );
  }
} 