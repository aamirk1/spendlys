import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/chat/message_controller.dart';
import 'package:spendly/widgets/chat/message_bubbles.dart';

class MessageView extends StatelessWidget {
  const MessageView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MessageController());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(controller.chatConnectionModel.title),
            Obx(() => Text(
              controller.isActive.value ? "Online" : "Offline",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            )),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => ListView.builder(
              controller: controller.scrollController,
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: controller.localChats.length,
              itemBuilder: (context, index) {
                final message = controller.localChats[index].data()!;
                return controller.buildMessageBubble(message, index);
              },
            )),
          ),
          _buildInputArea(controller),
        ],
      ),
    );
  }

  Widget _buildInputArea(MessageController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            if (controller.isReplying.value) {
              return ReplyMessagePreview(
                sender: controller.replyMessageSender.value,
                message: controller.replyMessage.value,
                mainMessage: "",
                onClose: () {
                  controller.isReplying.value = false;
                  controller.replyMessage.value = '';
                },
              );
            }
            return const SizedBox.shrink();
          }),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.messageController,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  maxLines: 5,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: controller.sendMessage,
                icon: const Icon(Icons.send, color: Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
