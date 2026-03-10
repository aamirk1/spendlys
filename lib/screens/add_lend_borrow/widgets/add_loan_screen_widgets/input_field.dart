import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  const InputField(
      {super.key,
      required this.controller,
      required this.label,
      required this.hint,
      required this.prefixIcon,
      required this.keyboardType,
      required this.validator});
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final FormFieldValidator<String> validator;
  @override
  Widget build(BuildContext context) {
    return buildInputField(
      controller,
      label,
      hint,
      prefixIcon,
      keyboardType,
      validator,
    );
  }

  Widget buildInputField(
    TextEditingController controller,
    String label,
    String hint,
    IconData prefixIcon,
    TextInputType keyboardType,
    FormFieldValidator<String> validator,
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
}
