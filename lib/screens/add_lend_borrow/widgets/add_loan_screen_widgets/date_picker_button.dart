import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerButton extends StatefulWidget {
  const DatePickerButton({
    super.key,
    required this.datePickerButton,
    required this.onDateSelected,
  });

  final DateTime? datePickerButton;
  final Function(DateTime) onDateSelected;

  @override
  State<DatePickerButton> createState() => _DatePickerButtonState();
}

class _DatePickerButtonState extends State<DatePickerButton> {
  late DateTime? _datePickerButton;

  @override
  void initState() {
    super.initState();
    _datePickerButton = widget.datePickerButton;
  }

  @override
  Widget build(BuildContext context) {
    return buildDatePickerButton(context);
  }

  Widget buildDatePickerButton(BuildContext context) {
    final formattedDate = _datePickerButton != null
        ? DateFormat('dd MMM yyyy').format(_datePickerButton!)
        : 'Select Due Date';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: _datePickerButton ?? DateTime.now(),
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
              _datePickerButton = pickedDate;
            });
            widget.onDateSelected(pickedDate); // <--- send back to parent
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
}
