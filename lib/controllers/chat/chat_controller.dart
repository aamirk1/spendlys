import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendly/models/chat_connection_model.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/app_constants.dart';
import 'package:spendly/utils/fire_chat_utils.dart';
import 'package:spendly/utils/chat_utils.dart';
import 'package:spendly/screens/chat/message_view.dart';

class ChatController extends GetxController {
  RxList<ChatConnectionModel> chatConnections = <ChatConnectionModel>[].obs;
  RxList<MyUser> searchUserList = <MyUser>[].obs;
  RxBool isLoading = false.obs;
  RxBool isSearching = false.obs;
  String currentUserId = "";

  TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (currentUserId.isNotEmpty) {
      loadChatConnects();
      FireChatUtils.setStatus(true, currentUserId);
    }
  }

  void loadChatConnects() {
    isLoading.value = true;
    
    // Listen to chatrooms where the user is a member
    FirebaseFirestore.instance
        .collection(AppConstants.firestoreChatrooms)
        .where('members', arrayContains: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      List<ChatConnectionModel> tempConnections = [];
      
      for (var doc in snapshot.docs) {
        var data = doc.data();
        var members = data['members'] as List<dynamic>;
        String otherUserId = members.firstWhere((id) => id != currentUserId, orElse: () => "");
        
        if (otherUserId.isNotEmpty) {
          var user = await FireChatUtils.fetchUserData(otherUserId);
          String title = user?.name ?? "User";
          String? image = user?.image;
          
          tempConnections.add(ChatConnectionModel(
            title: title,
            image: image,
            userID: otherUserId,
            lastMessage: data['lastmessage'] ?? "",
            id: data['chatroomId'] ?? "",
            isBlocked: data['isBlocked'] ?? false,
            createdAt: data['createdAt'] ?? Timestamp.now(),
            time: data['timeStamp'] ?? "",
            lastsender: data['lastsender'] ?? "",
            dot: data['dot'] ?? false,
          ));
        }
      }
      
      chatConnections.value = tempConnections;
      isLoading.value = false;
    });
  }

  void searchUsers(String query) async {
    if (query.isEmpty) {
      searchUserList.clear();
      isSearching.value = false;
      return;
    }

    isSearching.value = true;
    try {
      List<MyUser> users = await FireChatUtils.searchUsers(query);
      // Exclude current user from search results
      searchUserList.value = users.where((user) => user.userId != currentUserId).toList();
    } catch (e) {
      debugPrint("Search Error: $e");
    } finally {
      isSearching.value = false;
    }
  }

  void gotoMessage(ChatConnectionModel model, {bool isConnected = true}) {
    Get.to(() => const MessageView(), arguments: {
      'data': model,
      'connected': isConnected,
      'senderId': currentUserId,
    });
    
    if (isConnected && model.lastsender != currentUserId && model.dot) {
      FireChatUtils.removeDot(false, model.id, receiverId: model.userID!);
    }
  }

  void startNewChat(MyUser user) {
    // Check if chat already exists locally first for better UX
    var existing = chatConnections.firstWhereOrNull((conn) => conn.userID == user.userId);
    if (existing != null) {
      gotoMessage(existing);
      return;
    }

    // Create a temporary model
    ChatConnectionModel model = ChatConnectionModel(
      title: user.name,
      lastMessage: "",
      id: "", // Will be generated on first message
      userID: user.userId,
      isBlocked: false,
      createdAt: Timestamp.now(),
      time: "",
    );
    
    gotoMessage(model, isConnected: false);
  }
}
