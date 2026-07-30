import 'package:flutter/material.dart';

class InfoColumn extends StatelessWidget {
  const InfoColumn(
      {super.key,
      required this.title,
      required this.value,
      required this.color});
  final String title;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return buildInfoColumn(title: title, value: value, color: color);
  }

  Widget buildInfoColumn(
      {required String title,
      required String value,
      required Color color,
      double fontSize = 16}) {
    return Column(
      children: [
        Text(title,
            style: TextStyle(
                color: Colors.blueGrey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: fontSize - 1)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: fontSize)),
      ],
    );
  }
}
