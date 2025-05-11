import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/screens/add_lend_borrow/loan_modal.dart';
import 'loan_controller.dart';
import 'package:uuid/uuid.dart';

class AddLoanScreen extends StatefulWidget {
  final LoanController controller;

  AddLoanScreen({required this.controller});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final personController = TextEditingController();
  final amountController = TextEditingController();
  final reasonController = TextEditingController();
  String type = 'borrowed'; // Default to borrowed
  DateTime? expectedReturnDate;
  DateTime dateBorrowed = DateTime.now(); // Default to current date

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text("Add Loan",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 10,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Person Name Input
                _buildTextField(
                    personController, 'Person Name', 'Please enter a name',
                    icon: Icons.person),

                SizedBox(height: 20),

                // Amount Input
                _buildTextField(
                    amountController, 'Amount', 'Please enter an amount',
                    isNumber: true, icon: Icons.attach_money),

                SizedBox(height: 20),

                // Reason Input (Optional)
                _buildTextField(reasonController, 'Reason (Optional)', null,
                    icon: Icons.note_alt),

                SizedBox(height: 20),

                // Loan Type Selection
                _buildLoanTypeSelector(),

                SizedBox(height: 20),

                // Expected Return Date Picker
                _buildDatePickerButton(),

                SizedBox(height: 30),

                // Save Button
                Center(child: _buildSaveButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function for text fields
  Widget _buildTextField(TextEditingController controller, String labelText,
      String? validationMessage,
      {bool isNumber = false, IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 5))
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(fontSize: 16, color: Colors.deepPurpleAccent),
          prefixIcon:
              icon != null ? Icon(icon, color: Colors.deepPurpleAccent) : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (value!.isEmpty && validationMessage != null) {
            return validationMessage;
          }
          return null;
        },
      ),
    );
  }

  // Loan Type Selector
  Widget _buildLoanTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text("Borrowed",
                      style: TextStyle(
                          fontSize: 16, color: Colors.deepPurpleAccent)),
                  leading: Radio<String>(
                    value: 'borrowed',
                    groupValue: type,
                    onChanged: (val) => setState(() => type = val!),
                  ),
                ),
              ),
              Expanded(
                child: ListTile(
                  title: Text("Lent",
                      style: TextStyle(
                          fontSize: 16, color: Colors.deepPurpleAccent)),
                  leading: Radio<String>(
                    value: 'lent',
                    groupValue: type,
                    onChanged: (val) => setState(() => type = val!),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Expected Return Date Picker
  Widget _buildDatePickerButton() {
    return ElevatedButton(
      onPressed: () async {
        // Date picker for expected return date
        expectedReturnDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2023),
          lastDate: DateTime(2030),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Colors.deepPurple.withOpacity(0.3),
        elevation: 6,
        side: BorderSide(color: Colors.deepPurpleAccent, width: 2),
      ),
      child:
          Text("Select Expected Return Date", style: TextStyle(fontSize: 16)),
    );
  }

  // Save Button
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          // Create a Loan object from the form data
          final loan = Loan(
            id: Uuid().v4(), // Generate a unique ID for the loan
            userId: widget.controller.myUser.userId, // Set user ID
            personName: personController.text,
            amount: double.parse(amountController.text),
            type: type,
            reason:
                reasonController.text.isEmpty ? null : reasonController.text,
            dateBorrowed: dateBorrowed, // Set current date
            expectedReturnDate: expectedReturnDate!,
            status: 'pending', // Set status as 'pending' initially
            paidAmount: 0.0, // Add initial paid amount
          );

          // Call the controller method to add the loan
          widget.controller.addLoan(loan);

          // Go back to the previous screen
          Get.back();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Colors.deepPurple.withOpacity(0.3),
        elevation: 6,
        side: BorderSide(color: Colors.deepPurpleAccent, width: 2),
      ),
      child: Text("Save",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
