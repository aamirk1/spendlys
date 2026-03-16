import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/chat/message_controller.dart';
import 'package:spendly/widgets/chat/message_bubbles.dart';

class MessageView extends StatelessWidget {
  const MessageView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MessageController());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (controller.showEmoji.value) {
          controller.showEmoji.value = false;
        } else {
          Get.back();
        }
      },
      child: Scaffold(
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
                  focusNode: controller.focusNode,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    prefixIcon: IconButton(
                      onPressed: controller.toggleEmoji,
                      icon: Obx(() => Icon(
                            controller.showEmoji.value
                                ? Icons.keyboard
                                : Icons.emoji_emotions_outlined,
                            color: Colors.grey,
                          )),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
          Obx(() => Offstage(
                offstage: !controller.showEmoji.value,
                child: SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    textEditingController: controller.messageController,
                    config: Config(
                      height: 250,
                      emojiViewConfig: EmojiViewConfig(
                        columns: 7,
                        emojiSizeMax: 32 * (GetPlatform.isIOS ? 1.30 : 1.0),
                        verticalSpacing: 0,
                        horizontalSpacing: 0,
                        gridPadding: EdgeInsets.zero,
                        buttonMode: ButtonMode.MATERIAL,
                      ),
                      categoryViewConfig: CategoryViewConfig(
                        initCategory: Category.RECENT,
                        backgroundColor: const Color(0xFFF2F2F2),
                        indicatorColor: Colors.blue,
                        iconColor: Colors.grey,
                        iconColorSelected: Colors.blue,
                        backspaceColor: Colors.blue,
                        categoryIcons: const CategoryIcons(),
                      ),
                      skinToneConfig: const SkinToneConfig(
                        enabled: true,
                        indicatorColor: Colors.grey,
                        dialogBackgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
