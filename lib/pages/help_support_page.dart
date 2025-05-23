import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample FAQ data - replace with actual data
    final List<Map<String, String>> faqs = [
      {
        'question': 'How do I book a futsal court?',
        'answer':
            'To book a futsal court, go to the Book tab, select your preferred venue, choose a date and time, and complete the payment process.',
      },
      {
        'question': 'How do I rent equipment?',
        'answer':
            'You can rent equipment from the Rent Kit tab. Browse through available items, select what you need, and add them to your cart.',
      },
      {
        'question': 'What is your cancellation policy?',
        'answer':
            'You can cancel your booking up to 24 hours before the scheduled time for a full refund. Late cancellations may incur a fee.',
      },
      {
        'question': 'How do I add a payment method?',
        'answer':
            'Go to your Profile, select Payment Methods, and tap on Add Payment Method to add a new card or payment option.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...faqs.map((faq) => ExpansionTile(
                title: Text(faq['question']!),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(faq['answer']!),
                  ),
                ],
              )),
          const SizedBox(height: 24),
          const Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email Support'),
                  subtitle: const Text('support@futsalapp.com'),
                  onTap: () {
                    // Open email client
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Phone Support'),
                  subtitle: const Text('+1 234 567 8900'),
                  onTap: () {
                    // Open phone dialer
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: const Text('Live Chat'),
                  subtitle: const Text('Available 24/7'),
                  onTap: () {
                    // Open live chat
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'App Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Version'),
                  trailing: const Text('1.0.0'),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to terms of service
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to privacy policy
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 