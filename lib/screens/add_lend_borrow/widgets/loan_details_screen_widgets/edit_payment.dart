import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/res/components/custom_button.dart';

class EditPaymentDialog extends StatefulWidget {
  final double initialAmount;
  final Function(double) onConfirm;

  const EditPaymentDialog({
    Key? key,
    required this.initialAmount,
    required this.onConfirm,
  }) : super(key: key);

  @override
  _EditPaymentDialogState createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends State<EditPaymentDialog> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "New Amount",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            prefixIcon: const Icon(Icons.currency_rupee, color: Colors.indigo),
          ),
        ),
        const SizedBox(height: 20),
        CustomButton(
          text: "Update",
          onPressed: () {
            final newAmount = double.tryParse(_amountController.text);
            if (newAmount != null) {
              widget.onConfirm(newAmount);
            } else {
              Get.snackbar("Error", "Invalid amount entered");
            }
          },
        ),
      ],
    );
  }
}
