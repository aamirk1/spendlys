import 'package:flutter/material.dart';

class NeedHelpScreen extends StatelessWidget {
  const NeedHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Need Help'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('FAQs'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Contact Support'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Submit Feedback'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
