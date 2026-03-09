import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/res/routes/routes_name.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chat'),
            onTap: () {
              Get.toNamed(RoutesName.chatListView);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(value: false, onChanged: (val) {}),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
