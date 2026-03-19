import 'package:flutter/material.dart';
import 'package:spendly/models/chat_message_model.dart';

class BusinessMessageCard extends StatelessWidget {
  final ChatMessageModel message;
  final bool isSender;

  const BusinessMessageCard({
    super.key,
    required this.message,
    required this.isSender,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInvoice = message.type == 'invoice';
    final Color accentColor = isInvoice ? Colors.blue : Colors.teal;
    final String label = isInvoice ? "INVOICE" : "QUOTATION";

    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Icon(
                  isInvoice ? Icons.receipt_long : Icons.request_quote,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.message, // This should contain the preview text (e.g. INV #123)
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 5),
                const Text("Click below to view details or download PDF.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 1),
          TextButton(
            onPressed: () {
              // Open viewer or download
              print("Viewing ${message.type}: ${message.invoiceId}");
            },
            child: Text(
              "VIEW $label",
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
