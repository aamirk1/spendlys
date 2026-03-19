import 'package:flutter/material.dart';

class LoanTypeSelector extends StatefulWidget {
  const LoanTypeSelector({
    super.key,
    required this.type,
  });
  final String type;

  @override
  State<LoanTypeSelector> createState() => _LoanTypeSelectorState();
}

class _LoanTypeSelectorState extends State<LoanTypeSelector> {
  late String type;

  @override
  void initState() {
    super.initState();
    type = widget.type;
  }

  @override
  Widget build(BuildContext context) {
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
}
