import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:spendly/res/app_constants.dart';
import 'package:spendly/models/myuser.dart';

class FireChatUtils {
  static final fireStoreInstance = FirebaseFirestore.instance;

  static String getChatroomsCollection(String identifier) {
    // Logic for founder chat if needed
    if (identifier.contains("029202fs322d373hjd")) {
      return AppConstants.founderfirestoreChatrooms;
    }
    return AppConstants.firestoreChatrooms;
  }

  static Future<void> setStatus(bool status, String userId) async {
    await fireStoreInstance
        .collection(AppConstants.firestoreAllUsers)
        .doc(userId)
        .update({'active': status});
  }

  static Future<void> removeDot(bool status, String roomId, {required String receiverId}) async {
    await fireStoreInstance
        .collection(getChatroomsCollection(receiverId))
        .doc(roomId)
        .update({'dot': status});
  }

  static Future<void> saveChat({
    required String message,
    String? picture,
    required String senderId,
    required String chatRoomId,
    required bool isReply,
    required bool isBlocked,
    required String mainMessage,
    required String senderName,
    required String receiverId,
  }) async {
    final chatRef = fireStoreInstance.collection(
        '${getChatroomsCollection(receiverId)}/$chatRoomId/messages');
    String mId = const Uuid().v1().toString();
    final chatData = {
      'message': message,
      'image': picture,
      'timeStamp': FieldValue.serverTimestamp(),
      'time': DateTime.now().toUtc().toString().substring(0, 16),
      'read': false,
      'messageId': mId,
      'senderId': senderId,
      'name': senderName,
      'isReply': isReply,
      'type': 0,
      'mainMessage': mainMessage,
      'isBlocked': isBlocked,
    };
    await chatRef.doc(mId).set(chatData);

    // Update the chatroom metadata
    await updateChatroomMetadata(
      senderId: senderId,
      receiverId: receiverId,
      roomId: chatRoomId,
      lastMessage: message,
      dot: true,
    );
  }

  static Future<void> addToConnects({
    required String chatroomId,
    required String senderId,
    String lastMessage = '',
    required String receiverId,
  }) async {
    final chatroomsRef = fireStoreInstance.collection(getChatroomsCollection(receiverId));
    
    Map<String, dynamic> chatroomData = {
      'chatroomId': chatroomId,
      'chatroomname': "", // Will be dynamically displayed based on members
      'isGroup': false,
      'chatroomimage': "",
      'members': [senderId, receiverId],
      'lastmessage': lastMessage,
      'isBlocked': false,
      'timeStamp': DateTime.now().toUtc().toString().substring(0, 16),
      'createdAt': FieldValue.serverTimestamp(),
      'dot': true,
      'lastsender': senderId,
      'bothId': (senderId + receiverId).replaceAll("/", AppConstants.firebaseSlashEscape),
    };

    await chatroomsRef.doc(chatroomId).set(chatroomData);
  }

  static Future<void> updateChatroomMetadata({
    required String senderId,
    required String receiverId,
    required bool dot,
    required String roomId,
    required String lastMessage,
  }) async {
    await fireStoreInstance
        .collection(getChatroomsCollection(receiverId))
        .doc(roomId)
        .update({
      'createdAt': FieldValue.serverTimestamp(),
      'lastmessage': lastMessage,
      'lastsender': senderId,
      'dot': dot,
      'timeStamp': DateTime.now().toUtc().toString().substring(0, 16)
    });
  }

  static Future<void> updateRead({
    required String chatroomId,
    required String docId,
    required String receiverId,
  }) async {
    await fireStoreInstance
        .collection('${getChatroomsCollection(receiverId)}/$chatroomId/messages')
        .doc(docId)
        .update({'read': true});
    
    await fireStoreInstance
        .collection(getChatroomsCollection(receiverId))
        .doc(chatroomId)
        .update({'dot': false});
  }

  static Future<MyUser?> fetchUserData(String userId) async {
    final doc = await fireStoreInstance.collection(AppConstants.firestoreAllUsers).doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return MyUser.fromMap(doc.data()!);
    }
    return null;
  }

  static Future<void> deleteMessage({
    required String chatroomId,
    required String docId,
    required String receiverId,
  }) async {
    await fireStoreInstance
        .collection('${getChatroomsCollection(receiverId)}/$chatroomId/messages')
        .doc(docId)
        .delete();
  }

  static Future<List<MyUser>> getAllUsers() async {
    final snapshot = await fireStoreInstance
        .collection(AppConstants.firestoreAllUsers)
        .get();
    return snapshot.docs.map((doc) => MyUser.fromMap(doc.data())).toList();
  }

  static Future<List<MyUser>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    // Fetch all and filter locally for simplicity and flexibility with name/phone
    // or use Filter.or if query is exact or prefix.
    // For "name or phoneNumber", local filtering is often better for small-mid size datasets
    final snapshot = await fireStoreInstance
        .collection(AppConstants.firestoreAllUsers)
        .get();
    
    return snapshot.docs
        .map((doc) => MyUser.fromMap(doc.data()))
        .where((user) => 
            user.name.toLowerCase().contains(query.toLowerCase()) || 
            user.phoneNumber.contains(query))
        .toList();
  }
}
