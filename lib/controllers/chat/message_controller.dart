import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendly/models/chat_connection_model.dart';
import 'package:spendly/models/chat_message_model.dart';
import 'package:spendly/utils/fire_chat_utils.dart';
import 'package:spendly/widgets/chat/message_bubbles.dart';
import 'package:spendly/widgets/chat/swipe_to.dart';
import 'package:spendly/widgets/chat/business_message_card.dart';

class MessageController extends GetxController {
  TextEditingController messageController = TextEditingController();
  ScrollController scrollController = ScrollController();
  FocusNode focusNode = FocusNode();
  RxBool showEmoji = false.obs;
  
  RxList<DocumentSnapshot<ChatMessageModel>> localChats = <DocumentSnapshot<ChatMessageModel>>[].obs;
  
  late ChatConnectionModel chatConnectionModel;
  late String senderId;
  bool isConnected = true;

  RxBool isReplying = false.obs;
  RxString replyMessage = ''.obs;
  RxString replyMessageSender = ''.obs;
  RxBool isActive = false.obs;
  RxBool isBlocked = false.obs;

  @override
  void onInit() {
    super.onInit();
    chatConnectionModel = Get.arguments['data'];
    isConnected = Get.arguments['connected'] ?? true;
    senderId = Get.arguments['senderId'] ?? FirebaseAuth.instance.currentUser?.uid ?? "";
    
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        showEmoji.value = false;
      }
    });

    if (isConnected) {
      loadChats();
    }
    checkActive(chatConnectionModel.userID!);
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  void toggleEmoji() {
    showEmoji.value = !showEmoji.value;
    if (showEmoji.value) {
      focusNode.unfocus();
    } else {
      focusNode.requestFocus();
    }
  }

  void loadChats() {
    FirebaseFirestore.instance
        .collection('${FireChatUtils.getChatroomsCollection(chatConnectionModel.userID!)}/${chatConnectionModel.id}/messages')
        .orderBy('timeStamp', descending: true)
        .limit(30)
        .withConverter<ChatMessageModel>(
          fromFirestore: (snap, _) => ChatMessageModel.fromJson(snap.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .snapshots()
        .listen((snapshot) {
          localChats.value = snapshot.docs;
        });
  }

  Future<void> sendMessage() async {
    String text = messageController.text.trim();
    if (text.isEmpty) return;
    
    messageController.clear();

    if (!isConnected) {
      // Create new chatroom
      String roomId = const Uuid().v4();
      chatConnectionModel.id = roomId;
      await FireChatUtils.addToConnects(
        chatroomId: roomId,
        senderId: senderId,
        receiverId: chatConnectionModel.userID!,
        lastMessage: text,
      );
      isConnected = true;
      loadChats();
    }

    await FireChatUtils.saveChat(
      message: text,
      senderId: senderId,
      chatRoomId: chatConnectionModel.id,
      isReply: isReplying.value,
      isBlocked: false,
      mainMessage: replyMessage.value,
      senderName: "User", // Ideally get from storage
      receiverId: chatConnectionModel.userID!,
    );

    isReplying.value = false;
    replyMessage.value = '';
    replyMessageSender.value = '';
    
    // Scroll to bottom
    if (scrollController.hasClients) {
      scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void checkActive(String userId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((doc) {
          if (doc.exists) {
            isActive.value = doc.data()?['active'] ?? false;
          }
        });
  }

  Widget buildMessageBubble(ChatMessageModel model, int index) {
    bool isMe = model.senderId == senderId;
    
    if (!isMe && !model.isSeen) {
      FireChatUtils.updateRead(
        chatroomId: chatConnectionModel.id,
        docId: model.messageId,
        receiverId: chatConnectionModel.userID!,
      );
    }

    Widget content;
    if (model.type == 'invoice' || model.type == 'quotation') {
      content = BusinessMessageCard(message: model, isSender: isMe);
    } else {
      if (isMe) {
        content = SenderContainer(
          message: model.message,
          isRead: model.isSeen,
          time: model.time,
          isReply: model.isReply,
          replyOn: model.replyOn,
          onLongPress: () => _deleteMessage(model.messageId),
        );
      } else {
        content = ReciverContainer(
          message: model.message,
          time: model.time,
          name: chatConnectionModel.title,
          isReply: model.isReply,
          replyOn: model.replyOn,
          onLongPress: () => _deleteMessage(model.messageId),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SwipeTo(
        onRightSwipe: (_) {
          isReplying.value = true;
          replyMessage.value = model.message;
          replyMessageSender.value = isMe ? "You" : chatConnectionModel.title;
        },
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: content,
        ),
      ),
    );
  }

  void _deleteMessage(String docId) {
    Get.dialog(
      AlertDialog(
        title: const Text("Delete Message"),
        content: const Text("Are you sure you want to delete this message?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FireChatUtils.deleteMessage(
                chatroomId: chatConnectionModel.id,
                docId: docId,
                receiverId: chatConnectionModel.userID!,
              );
              Get.back();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
