import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/components/customAppBar.dart';
import 'package:spendly/res/components/customBotton.dart';
import '../../models/loan_modal.dart';
import '../../controllers/loan_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AddLoanScreen extends StatefulWidget {
  final LoanController controller;
  final MyUser myUser;
  AddLoanScreen({required this.myUser, Key? key, required this.controller})
      : super(key: key);

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final personController = TextEditingController();
  final amountController = TextEditingController();
  final reasonController = TextEditingController();
  String type = 'borrowed'; // Default
  DateTime? expectedReturnDate;
  DateTime date = DateTime.now();

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    String? hint,
    IconData? prefixIcon,
    TextInputType keyboardType,
    String? Function(String?)? validator,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.blueGrey.shade400),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.blueGrey.shade400)
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildLoanTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Loan Type",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey.shade700)),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text("Borrowed",
                      style: TextStyle(color: Colors.indigo.shade500)),
                  value: 'borrowed',
                  groupValue: type,
                  onChanged: (value) => setState(() => type = value!),
                  activeColor: Colors.indigo.shade500,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text("Lent",
                      style: TextStyle(color: Colors.indigo.shade500)),
                  value: 'lent',
                  groupValue: type,
                  onChanged: (value) => setState(() => type = value!),
                  activeColor: Colors.indigo.shade500,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerButton(BuildContext context) {
    final formattedDate = expectedReturnDate != null
        ? DateFormat('dd MMM yyyy').format(expectedReturnDate!)
        : 'Select Due Date';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: expectedReturnDate ?? DateTime.now(),
            firstDate: DateTime(2023),
            lastDate: DateTime(2030),
            builder: (BuildContext context, Widget? child) {
              return Theme(
                data: ThemeData.light().copyWith(
                  primaryColor: Colors.indigo.shade500,
                  hintColor: Colors.indigo.shade500,
                  colorScheme:
                      ColorScheme.light(primary: Colors.indigo.shade500),
                  buttonTheme:
                      const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                ),
                child: child!,
              );
            },
          );
          if (pickedDate != null) {
            setState(() {
              expectedReturnDate = pickedDate;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  color: Colors.indigo.shade500),
              const SizedBox(width: 16),
              Expanded(
                child: Text(formattedDate,
                    style: TextStyle(
                        fontSize: 16, color: Colors.blueGrey.shade700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.indigo.shade500, Colors.purple.shade400],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CustomButton(
          text: 'Save Loan',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              if (expectedReturnDate == null) {
                Get.snackbar(
                  "Warning",
                  "Please select the expected return date.",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange.shade100,
                  colorText: Colors.orange.shade800,
                  borderRadius: 10,
                  margin: const EdgeInsets.all(15),
                );
                return;
              }
              final loan = Loan(
                userId: widget.myUser.userId,
                id: const Uuid().v4(),
                personName: personController.text,
                amount: double.parse(amountController.text),
                paidAmount: 0.0.obs,
                expectedReturnDate: expectedReturnDate!,
                reason: reasonController.text.isEmpty
                    ? null
                    : reasonController.text,
                type: type,
                date: date,
                status: 'pending'.obs,
              );
              widget.controller.addLoan(loan);
              Get.back();
            }
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Add Loan',
      ),
      // AppBar(
      //   title: const Text("Add Loan",
      //       style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      //   backgroundColor: Colors.indigo.shade600,
      //   elevation: 8,
      //   centerTitle: true,
      //   iconTheme: const IconThemeData(color: Colors.white),
      //   shape: const RoundedRectangleBorder(
      //     borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      //   ),
      // ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade50, Colors.blueGrey.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Record a New Transaction",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700)),
                const SizedBox(height: 30),
                _buildInputField(
                  personController,
                  'Person Name',
                  'Enter name of lender/borrower',
                  Icons.person_outline,
                  TextInputType.text,
                  (value) =>
                      value!.isEmpty ? 'Please enter the person\'s name' : null,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  amountController,
                  'Amount',
                  'Enter the loan amount',
                  Icons.currency_rupee_outlined,
                  TextInputType.number,
                  (value) =>
                      value!.isEmpty ? 'Please enter the loan amount' : null,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  reasonController,
                  'Reason (Optional)',
                  'Brief description (optional)',
                  Icons.note_alt_outlined,
                  TextInputType.text,
                  null,
                ),
                const SizedBox(height: 24),
                _buildLoanTypeSelector(),
                const SizedBox(height: 24),
                _buildDatePickerButton(context),
                const SizedBox(height: 40),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
