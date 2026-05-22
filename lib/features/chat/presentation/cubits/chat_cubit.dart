import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendly/features/chat/data/models/chat_connection_model.dart';
import 'package:spendly/features/auth/data/models/my_user_model.dart';
import 'package:spendly/core/constants/app_constants.dart';
import 'package:spendly/core/utils/fire_chat_utils.dart';
import 'package:spendly/features/auth/data/services/auth_service.dart';

class ChatState extends Equatable {
  final List<ChatConnectionModel> chatConnections;
  final List<MyUser> searchUserList;
  final bool isLoading;
  final bool isSearching;
  final String currentUserId;
  final String? errorMessage;

  const ChatState({
    this.chatConnections = const [],
    this.searchUserList = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.currentUserId = '',
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatConnectionModel>? chatConnections,
    List<MyUser>? searchUserList,
    bool? isLoading,
    bool? isSearching,
    String? currentUserId,
    String? errorMessage,
  }) {
    return ChatState(
      chatConnections: chatConnections ?? this.chatConnections,
      searchUserList: searchUserList ?? this.searchUserList,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      currentUserId: currentUserId ?? this.currentUserId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        chatConnections,
        searchUserList,
        isLoading,
        isSearching,
        currentUserId,
        errorMessage,
      ];
}

class ChatCubit extends Cubit<ChatState> {
  final AuthService _authService;
  StreamSubscription? _chatConnectionsSub;

  ChatCubit(this._authService) : super(const ChatState()) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? _authService.currentUserId ?? '';
    if (uid.isNotEmpty) {
      emit(state.copyWith(currentUserId: uid));
      loadChatConnects(uid);
      FireChatUtils.setStatus(true, uid);
    }
  }

  void loadChatConnects(String uid) {
    emit(state.copyWith(isLoading: true));
    _chatConnectionsSub?.cancel();

    _chatConnectionsSub = FirebaseFirestore.instance
        .collection(AppConstants.firestoreChatrooms)
        .where('members', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      List<ChatConnectionModel> tempConnections = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        var members = data['members'] as List<dynamic>;
        String otherUserId = members.firstWhere((id) => id != uid, orElse: () => "");

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

      emit(state.copyWith(
        chatConnections: tempConnections,
        isLoading: false,
      ));
    }, onError: (err) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: err.toString(),
      ));
    });
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      emit(state.copyWith(searchUserList: const [], isSearching: false));
      return;
    }

    emit(state.copyWith(isSearching: true));
    try {
      List<MyUser> users = await FireChatUtils.searchUsers(query);
      final filteredList = users.where((user) => user.userId != state.currentUserId).toList();
      emit(state.copyWith(
        searchUserList: filteredList,
        isSearching: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSearching: false,
        errorMessage: 'Search error: $e',
      ));
    }
  }

  void markChatAsRead(ChatConnectionModel model) {
    if (model.lastsender != state.currentUserId && model.dot) {
      FireChatUtils.removeDot(false, model.id, receiverId: model.userID!);
    }
  }

  @override
  Future<void> close() {
    _chatConnectionsSub?.cancel();
    if (state.currentUserId.isNotEmpty) {
      FireChatUtils.setStatus(false, state.currentUserId);
    }
    return super.close();
  }
}
