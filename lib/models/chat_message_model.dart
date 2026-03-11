import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spendly/utils/chat_utils.dart';

class ChatMessageModel {
  String message;
  bool isBlocked;
  String senderId;
  bool isReply;
  String replyOn;
  String senderName;
  bool isSeen;
  String time;
  String messageId;
  String createdAt;
  
  // New fields for Business Module
  String type; // 'text', 'invoice', 'quotation'
  String? invoiceId;
  String? quotationId;
  String? pdfUrl;
  String? shareLink;

  ChatMessageModel({
    required this.message,
    required this.isBlocked,
    required this.senderId,
    required this.isReply,
    required this.replyOn,
    required this.senderName,
    required this.isSeen,
    required this.time,
    required this.messageId,
    required this.createdAt,
    this.type = 'text',
    this.invoiceId,
    this.quotationId,
    this.pdfUrl,
    this.shareLink,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) => ChatMessageModel(
        message: json['message'] ?? '',
        isBlocked: (json['isBlocked'] ?? json['isBloacked']) as bool? ?? false,
        senderId: json['senderId'] as String? ?? '',
        isReply: json['isReply'] as bool? ?? false,
        replyOn: json['mainMessage'] as String? ?? '',
        senderName: json['name'] as String? ?? '',
        isSeen: (json['read'] ?? json['isSeen']) as bool? ?? false,
        time: json['time'] != null 
            ? ChatUtils.utcToLocal(DateTime.parse(json['time']), forChat: true)
            : '',
        messageId: json['messageId'] as String? ?? '',
        createdAt: json['createdAt']?.toString() ?? ' ',
        type: json['type'] as String? ?? 'text',
        invoiceId: json['invoice_id'] as String?,
        quotationId: json['quotation_id'] as String?,
        pdfUrl: json['pdf_url'] as String?,
        shareLink: json['share_link'] as String?,
      );

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'isBlocked': isBlocked,
      'senderId': senderId,
      'isReply': isReply,
      'name': senderName,
      'read': isSeen,
      'time': time,
      'messageId': messageId,
      'createdAt': createdAt,
      'mainMessage': replyOn,
      'type': type,
      'invoice_id': invoiceId,
      'quotation_id': quotationId,
      'pdf_url': pdfUrl,
      'share_link': shareLink,
    };
  }
}
