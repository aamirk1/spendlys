import 'package:cloud_firestore/cloud_firestore.dart';

/// This model class for [containing] data for [single chat connection]
class ChatConnectionModel {
  final String title;
  final String lastMessage;
  String? image;
  String id;
  final bool isBlocked;
  final Timestamp createdAt;
  final String time;
  final String? userID;
  final String lastsender;
  final bool dot;

  ChatConnectionModel({
    required this.title,
    this.lastsender = '',
    this.dot = false,
    this.userID,
    required this.lastMessage,
    this.image,
    required this.id,
    required this.isBlocked,
    required this.createdAt,
    required this.time,
  });
}
