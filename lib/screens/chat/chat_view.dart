import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/chat/chat_controller.dart';
import 'package:intl/intl.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.searchUsers,
              decoration: InputDecoration(
                hintText: "Search users...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isSearching.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.searchController.text.isNotEmpty) {
          return ListView.builder(
            itemCount: controller.searchUserList.length,
            itemBuilder: (context, index) {
              final user = controller.searchUserList[index];
              return ListTile(
                leading: CircleAvatar(child: Text(user.name[0])),
                title: Text(user.name),
                subtitle: Text(user.email),
                onTap: () => controller.startNewChat(user),
              );
            },
          );
        }

        if (controller.isLoading.value && controller.chatConnections.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.chatConnections.isEmpty) {
          return const Center(child: Text("No conversations yet"));
        }

        return ListView.builder(
          itemCount: controller.chatConnections.length,
          itemBuilder: (context, index) {
            final chat = controller.chatConnections[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: chat.image != null ? NetworkImage(chat.image!) : null,
                child: chat.image == null ? Text(chat.title[0]) : null,
              ),
              title: Text(chat.title),
              subtitle: Text(
                chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: chat.dot && chat.lastsender != controller.currentUserId 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(chat.time),
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (chat.dot && chat.lastsender != controller.currentUserId)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              onTap: () => controller.gotoMessage(chat),
            );
          },
        );
      }),
    );
  }

  String _formatTime(String timeStr) {
    try {
      if (timeStr.isEmpty) return "";
      DateTime dt = DateTime.parse(timeStr).toLocal();
      DateTime now = DateTime.now();
      if (now.day == dt.day && now.month == dt.month && now.year == dt.year) {
        return DateFormat('hh:mm a').format(dt);
      }
      return DateFormat('dd/MM/yy').format(dt);
    } catch (_) {
      return "";
    }
  }
}
