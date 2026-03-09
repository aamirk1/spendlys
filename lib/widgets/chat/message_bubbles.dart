import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class SenderContainer extends StatelessWidget {
  final String message;
  final String? replyOn;
  final bool isReply;
  final String time;
  final bool isRead;
  final VoidCallback onLongPress;

  const SenderContainer({
    super.key,
    required this.message,
    required this.isRead,
    required this.time,
    this.replyOn,
    required this.isReply,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    double wd = MediaQuery.of(context).size.width;
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(left: wd * 0.15),
        alignment: Alignment.centerRight,
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14))),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isReply)
                ReplyMessagePreview(
                  mainMessage: message,
                  message: replyOn ?? "",
                  sender: "You",
                ),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(time),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: isRead ? Colors.blue : Colors.grey,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      DateTime dt = DateTime.parse(timeStr).toLocal();
      return intl.DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }
}

class ReciverContainer extends StatelessWidget {
  final String message;
  final String time;
  final String? replyOn;
  final String name;
  final bool isReply;
  final VoidCallback onLongPress;

  const ReciverContainer({
    super.key,
    required this.message,
    required this.time,
    this.replyOn,
    required this.name,
    required this.isReply,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    double wd = MediaQuery.of(context).size.width;
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(right: wd * 0.15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: const BorderRadius.only(
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isReply)
                ReplyMessagePreview(
                  message: replyOn ?? "",
                  sender: name,
                  mainMessage: message,
                ),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 5),
              Text(
                _formatTime(time),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              )
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      DateTime dt = DateTime.parse(timeStr).toLocal();
      return intl.DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }
}

class ReplyMessagePreview extends StatelessWidget {
  final String sender;
  final String message;
  final String mainMessage;
  final VoidCallback? onClose;

  const ReplyMessagePreview({
    super.key,
    required this.message,
    this.onClose,
    required this.sender,
    required this.mainMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 4.0,
          ),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sender,
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
              Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          if (onClose != null)
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, size: 16),
              ),
            )
        ],
      ),
    );
  }
}
