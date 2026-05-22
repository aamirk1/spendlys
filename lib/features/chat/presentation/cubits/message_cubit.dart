import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendly/features/chat/data/models/chat_connection_model.dart';
import 'package:spendly/features/chat/data/models/chat_message_model.dart';
import 'package:spendly/core/utils/fire_chat_utils.dart';

class MessageState extends Equatable {
  final List<QueryDocumentSnapshot<ChatMessageModel>> localChats;
  final ChatConnectionModel? chatConnectionModel;
  final String senderId;
  final bool isConnected;
  final bool isReplying;
  final String replyMessage;
  final String replyMessageSender;
  final bool isActive;
  final bool isBlocked;
  final bool showEmoji;
  final bool isLoading;

  const MessageState({
    this.localChats = const [],
    this.chatConnectionModel,
    this.senderId = '',
    this.isConnected = true,
    this.isReplying = false,
    this.replyMessage = '',
    this.replyMessageSender = '',
    this.isActive = false,
    this.isBlocked = false,
    this.showEmoji = false,
    this.isLoading = false,
  });

  MessageState copyWith({
    List<QueryDocumentSnapshot<ChatMessageModel>>? localChats,
    ChatConnectionModel? chatConnectionModel,
    String? senderId,
    bool? isConnected,
    bool? isReplying,
    String? replyMessage,
    String? replyMessageSender,
    bool? isActive,
    bool? isBlocked,
    bool? showEmoji,
    bool? isLoading,
  }) {
    return MessageState(
      localChats: localChats ?? this.localChats,
      chatConnectionModel: chatConnectionModel ?? this.chatConnectionModel,
      senderId: senderId ?? this.senderId,
      isConnected: isConnected ?? this.isConnected,
      isReplying: isReplying ?? this.isReplying,
      replyMessage: replyMessage ?? this.replyMessage,
      replyMessageSender: replyMessageSender ?? this.replyMessageSender,
      isActive: isActive ?? this.isActive,
      isBlocked: isBlocked ?? this.isBlocked,
      showEmoji: showEmoji ?? this.showEmoji,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        localChats,
        chatConnectionModel,
        senderId,
        isConnected,
        isReplying,
        replyMessage,
        replyMessageSender,
        isActive,
        isBlocked,
        showEmoji,
        isLoading,
      ];
}

class MessageCubit extends Cubit<MessageState> {
  StreamSubscription? _chatsSubscription;
  StreamSubscription? _activeStatusSubscription;

  MessageCubit() : super(const MessageState());

  void initializeChat({
    required ChatConnectionModel connection,
    required String senderId,
    required bool isConnected,
  }) {
    _chatsSubscription?.cancel();
    _activeStatusSubscription?.cancel();

    emit(state.copyWith(
      chatConnectionModel: connection,
      senderId: senderId.isNotEmpty ? senderId : (FirebaseAuth.instance.currentUser?.uid ?? ''),
      isConnected: isConnected,
      localChats: const [],
      isReplying: false,
      replyMessage: '',
      replyMessageSender: '',
      showEmoji: false,
    ));

    if (isConnected) {
      loadChats(connection);
    }
    checkActive(connection.userID!);
  }

  void toggleEmoji() {
    emit(state.copyWith(showEmoji: !state.showEmoji));
  }

  void setEmojiVisibility(bool visible) {
    emit(state.copyWith(showEmoji: visible));
  }

  void loadChats(ChatConnectionModel connection) {
    _chatsSubscription?.cancel();
    _chatsSubscription = FirebaseFirestore.instance
        .collection('${FireChatUtils.getChatroomsCollection(connection.userID!)}/${connection.id}/messages')
        .orderBy('timeStamp', descending: true)
        .limit(30)
        .withConverter<ChatMessageModel>(
          fromFirestore: (snap, _) => ChatMessageModel.fromJson(snap.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .snapshots()
        .listen((snapshot) {
      emit(state.copyWith(localChats: snapshot.docs));
    });
  }

  void startReply(String message, String sender) {
    emit(state.copyWith(
      isReplying: true,
      replyMessage: message,
      replyMessageSender: sender,
    ));
  }

  void cancelReply() {
    emit(state.copyWith(
      isReplying: false,
      replyMessage: '',
      replyMessageSender: '',
    ));
  }

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || state.chatConnectionModel == null) return;

    var connection = state.chatConnectionModel!;
    var isConnectedVar = state.isConnected;

    if (!isConnectedVar) {
      // Create new chatroom
      String roomId = const Uuid().v4();
      connection = connection.copyWithId(roomId); // Ensure copyWithId exists or set it directly
      await FireChatUtils.addToConnects(
        chatroomId: roomId,
        senderId: state.senderId,
        receiverId: connection.userID!,
        lastMessage: cleanText,
      );
      emit(state.copyWith(
        chatConnectionModel: connection,
        isConnected: true,
      ));
      loadChats(connection);
    }

    await FireChatUtils.saveChat(
      message: cleanText,
      senderId: state.senderId,
      chatRoomId: connection.id,
      isReply: state.isReplying,
      isBlocked: false,
      mainMessage: state.replyMessage,
      senderName: "User",
      receiverId: connection.userID!,
    );

    emit(state.copyWith(
      isReplying: false,
      replyMessage: '',
      replyMessageSender: '',
    ));
  }

  void checkActive(String userId) {
    _activeStatusSubscription?.cancel();
    _activeStatusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        emit(state.copyWith(isActive: doc.data()?['active'] ?? false));
      }
    });
  }

  void deleteMessage(String docId) {
    if (state.chatConnectionModel == null) return;
    FireChatUtils.deleteMessage(
      chatroomId: state.chatConnectionModel!.id,
      docId: docId,
      receiverId: state.chatConnectionModel!.userID!,
    );
  }

  void updateReadStatus(ChatMessageModel model) {
    if (state.chatConnectionModel == null) return;
    bool isMe = model.senderId == state.senderId;
    if (!isMe && !model.isSeen) {
      FireChatUtils.updateRead(
        chatroomId: state.chatConnectionModel!.id,
        docId: model.messageId,
        receiverId: state.chatConnectionModel!.userID!,
      );
    }
  }

  @override
  Future<void> close() {
    _chatsSubscription?.cancel();
    _activeStatusSubscription?.cancel();
    return super.close();
  }
}

extension on ChatConnectionModel {
  ChatConnectionModel copyWithId(String newId) {
    return ChatConnectionModel(
      title: title,
      image: image,
      userID: userID,
      lastMessage: lastMessage,
      id: newId,
      isBlocked: isBlocked,
      createdAt: createdAt,
      time: time,
      lastsender: lastsender,
      dot: dot,
    );
  }
}
