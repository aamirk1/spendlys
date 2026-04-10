import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spendly/screens/home/views/profile_screens/feedback_screen.dart';

class NeedHelpScreen extends StatelessWidget {
  const NeedHelpScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Error', 'Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('need_help'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.blue),
              title: Text('faqs'.tr),
              subtitle: const Text('View frequently asked questions'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _launchURL('https://dailybachat.in/faqs');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.green),
              title: Text('contact_support'.tr),
              subtitle: const Text('Chat with us on WhatsApp'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // WhatsApp link: https://wa.me/<number>
                _launchURL('https://wa.me/919175402434');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.feedback, color: Colors.amber),
              title: Text('feedback'.tr),
              subtitle: const Text('Share your thoughts with us'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Get.to(() => const FeedbackScreen());
              },
            ),
          ],
        ),
      ),
    );
  }
}
